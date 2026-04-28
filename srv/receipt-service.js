'use strict';

const cds = require('@sap/cds');

module.exports = class ReceiptService extends cds.ApplicationService {

  async init() {
    const { MaterialReceipts, MaterialReceiptItems, DamagedMaterials } = this.entities;

    // ── AUTO-NUMBERING ────────────────────────────────────────────
    this.before('CREATE', MaterialReceipts, this._generateReceiptNumber.bind(this));

    // ── RECEIPT VALIDATIONS ───────────────────────────────────────
    this.before('CREATE', MaterialReceiptItems, this._validateReceiptItem.bind(this));
    this.before('UPDATE', MaterialReceiptItems, this._validateReceiptItem.bind(this));

    // ── POST-CREATE: UPDATE DOWNSTREAM QUANTITIES ─────────────────
    this.after('CREATE', MaterialReceiptItems, this._updateDeliveredQty.bind(this));

    // ── RECEIPT ACTIONS ───────────────────────────────────────────
    this.on('verifyReceipt', MaterialReceipts, this._verifyReceipt.bind(this));
    this.on('rejectReceipt', MaterialReceipts, this._rejectReceipt.bind(this));

    // ── DAMAGED MATERIAL ACTIONS ──────────────────────────────────
    this.on('raiseClaim',   DamagedMaterials, this._raiseClaim.bind(this));
    this.on('settleClaim',  DamagedMaterials, this._settleClaim.bind(this));
    this.on('rejectClaim',  DamagedMaterials, this._rejectClaim.bind(this));

    await super.init();
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTO-NUMBERING
  // ═══════════════════════════════════════════════════════════════

  async _generateReceiptNumber(req) {
    const year = new Date().getFullYear();
    const result = await SELECT.one.from(this.entities.MaterialReceipts)
      .columns('receiptNumber')
      .orderBy('createdAt desc');

    let seq = 1;
    if (result?.receiptNumber) {
      const match = result.receiptNumber.match(/GRN-\d{4}-(\d{4})$/);
      if (match) seq = parseInt(match[1]) + 1;
    }
    req.data.receiptNumber = `GRN-${year}-${String(seq).padStart(4, '0')}`;
    req.data.receiptDate   = req.data.receiptDate || new Date().toISOString();
    req.data.status        = 'PENDING';
  }

  // ═══════════════════════════════════════════════════════════════
  // VALIDATIONS
  // ═══════════════════════════════════════════════════════════════

  _validateReceiptItem(req) {
    const item = req.data;

    if (item.receivedQty !== undefined && item.receivedQty < 0) {
      return req.error(400, 'Received quantity cannot be negative', 'receivedQty');
    }
    if (item.acceptedQty !== undefined && item.rejectedQty !== undefined) {
      const received = item.receivedQty ?? 0;
      const sumCheck = parseFloat(((item.acceptedQty || 0) + (item.rejectedQty || 0)).toFixed(3));
      if (received > 0 && Math.abs(sumCheck - received) > 0.001) {
        return req.error(
          400,
          `Accepted qty (${item.acceptedQty}) + Rejected qty (${item.rejectedQty}) must equal Received qty (${received})`,
          'acceptedQty'
        );
      }
    }
    if (item.acceptedQty !== undefined && item.acceptedQty < 0) {
      return req.error(400, 'Accepted quantity cannot be negative', 'acceptedQty');
    }
    if (item.rejectedQty !== undefined && item.rejectedQty < 0) {
      return req.error(400, 'Rejected quantity cannot be negative', 'rejectedQty');
    }

    // Derive condition from rejection
    if (item.rejectedQty > 0 && item.acceptedQty > 0) {
      req.data.condition = 'PARTIAL';
    } else if (item.rejectedQty > 0 && (!item.acceptedQty || item.acceptedQty === 0)) {
      req.data.condition = 'DAMAGED';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // POST-CREATE: DOWNSTREAM QUANTITY UPDATES
  // ═══════════════════════════════════════════════════════════════

  async _updateDeliveredQty(receiptItem, req) {
    if (!receiptItem || !receiptItem.poItem_ID) return;

    const { PurchaseOrderItems } = cds.entities('solar.epc');
    const poItem = await SELECT.one.from(PurchaseOrderItems)
      .where({ ID: receiptItem.poItem_ID });
    if (!poItem) return;

    const newDeliveredQty = parseFloat(
      ((poItem.deliveredQty || 0) + (receiptItem.acceptedQty || 0)).toFixed(3)
    );
    const newPendingQty = parseFloat(
      Math.max(0, (poItem.orderedQty || 0) - newDeliveredQty).toFixed(3)
    );
    await UPDATE(PurchaseOrderItems)
      .set({ deliveredQty: newDeliveredQty, pendingQty: newPendingQty })
      .where({ ID: receiptItem.poItem_ID });

    // Update BOQ received qty via POItem → RequestItem → BOQItem chain
    if (poItem.requestItem_ID) {
      const { MaterialRequestItems } = cds.entities('solar.epc');
      const reqItem = await SELECT.one.from(MaterialRequestItems)
        .where({ ID: poItem.requestItem_ID });
      if (reqItem?.boqItem_ID) {
        const { BOQItems } = cds.entities('solar.epc');
        const boq = await SELECT.one.from(BOQItems).where({ ID: reqItem.boqItem_ID });
        if (boq) {
          await UPDATE(BOQItems)
            .set({ receivedQty: parseFloat(((boq.receivedQty || 0) + (receiptItem.acceptedQty || 0)).toFixed(3)) })
            .where({ ID: reqItem.boqItem_ID });
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RECEIPT ACTIONS
  // ═══════════════════════════════════════════════════════════════

  async _verifyReceipt(req) {
    const { ID } = req.params[0];
    const { verificationRemarks } = req.data;
    const receipt = await SELECT.one.from(this.entities.MaterialReceipts).where({ ID });
    if (!receipt) return req.error(404, `Receipt ${ID} not found`);
    if (receipt.status !== 'PENDING') {
      return req.error(400, `Only PENDING receipts can be verified. Current status: ${receipt.status}`);
    }

    // Determine status based on accepted/rejected items
    const items = await SELECT.from(this.entities.MaterialReceiptItems).where({ receipt_ID: ID });
    if (!items || items.length === 0) {
      return req.error(400, 'Cannot verify receipt with no items');
    }

    const totalAccepted = items.reduce((s, i) => s + (i.acceptedQty || 0), 0);
    const totalRejected = items.reduce((s, i) => s + (i.rejectedQty || 0), 0);

    let newStatus;
    if (totalRejected === 0) {
      newStatus = 'VERIFIED';
    } else if (totalAccepted > 0) {
      newStatus = 'PARTIALLY_ACCEPTED';
    } else {
      newStatus = 'FULLY_REJECTED';
    }

    await UPDATE(this.entities.MaterialReceipts)
      .set({
        status          : newStatus,
        overallRemarks  : verificationRemarks || receipt.overallRemarks,
        verificationDate: new Date().toISOString()
      })
      .where({ ID });

    // Update vendor quality score for damaged receipts
    if (totalRejected > 0) {
      await this._penalizeVendorQuality(receipt.purchaseOrder_ID);
    }

    return SELECT.one.from(this.entities.MaterialReceipts).where({ ID });
  }

  async _rejectReceipt(req) {
    const { ID } = req.params[0];
    const { rejectionReason } = req.data;
    if (!rejectionReason) return req.error(400, 'Rejection reason is mandatory');
    const receipt = await SELECT.one.from(this.entities.MaterialReceipts).where({ ID });
    if (!receipt) return req.error(404, `Receipt ${ID} not found`);
    if (receipt.status !== 'PENDING') {
      return req.error(400, `Only PENDING receipts can be rejected. Current status: ${receipt.status}`);
    }
    await UPDATE(this.entities.MaterialReceipts)
      .set({
        status        : 'FULLY_REJECTED',
        overallRemarks: rejectionReason
      })
      .where({ ID });
    return SELECT.one.from(this.entities.MaterialReceipts).where({ ID });
  }

  // ═══════════════════════════════════════════════════════════════
  // DAMAGED MATERIAL ACTIONS
  // ═══════════════════════════════════════════════════════════════

  async _raiseClaim(req) {
    const { ID } = req.params[0];
    const { claimAmount } = req.data;
    const damage = await SELECT.one.from(this.entities.DamagedMaterials).where({ ID });
    if (!damage) return req.error(404, `Damage record ${ID} not found`);
    if (damage.claimStatus !== 'PENDING') {
      return req.error(400, `Claim already raised. Current status: ${damage.claimStatus}`);
    }
    if (!claimAmount || claimAmount <= 0) {
      return req.error(400, 'Claim amount must be greater than zero', 'claimAmount');
    }
    await UPDATE(this.entities.DamagedMaterials)
      .set({ claimStatus: 'CLAIMED', claimAmount })
      .where({ ID });
    return SELECT.one.from(this.entities.DamagedMaterials).where({ ID });
  }

  async _settleClaim(req) {
    const { ID } = req.params[0];
    const { settlementAmount, response } = req.data;
    const damage = await SELECT.one.from(this.entities.DamagedMaterials).where({ ID });
    if (!damage) return req.error(404, `Damage record ${ID} not found`);
    if (damage.claimStatus !== 'CLAIMED') {
      return req.error(400, `Only CLAIMED damages can be settled. Current status: ${damage.claimStatus}`);
    }
    await UPDATE(this.entities.DamagedMaterials)
      .set({
        claimStatus  : 'SETTLED',
        claimAmount  : settlementAmount || damage.claimAmount,
        vendorResponse: response || '',
        resolvedDate : new Date().toISOString().slice(0, 10)
      })
      .where({ ID });
    return SELECT.one.from(this.entities.DamagedMaterials).where({ ID });
  }

  async _rejectClaim(req) {
    const { ID } = req.params[0];
    const { reason } = req.data;
    if (!reason) return req.error(400, 'Rejection reason is mandatory');
    const damage = await SELECT.one.from(this.entities.DamagedMaterials).where({ ID });
    if (!damage) return req.error(404, `Damage record ${ID} not found`);
    if (damage.claimStatus !== 'CLAIMED') {
      return req.error(400, `Only CLAIMED damages can be rejected. Current status: ${damage.claimStatus}`);
    }
    await UPDATE(this.entities.DamagedMaterials)
      .set({
        claimStatus   : 'REJECTED',
        vendorResponse: reason,
        resolvedDate  : new Date().toISOString().slice(0, 10)
      })
      .where({ ID });
    return SELECT.one.from(this.entities.DamagedMaterials).where({ ID });
  }

  // ═══════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════

  async _penalizeVendorQuality(poId) {
    if (!poId) return;
    const { PurchaseOrders } = cds.entities('solar.epc');
    const po = await SELECT.one.from(PurchaseOrders).where({ ID: poId });
    if (!po?.vendor_ID) return;

    const { VendorMaster } = cds.entities('solar.epc');
    const vendor = await SELECT.one.from(VendorMaster).where({ ID: po.vendor_ID });
    if (!vendor) return;

    // Decrement quality score by 0.5 per damaged receipt, floor at 0
    const newScore = parseFloat(Math.max(0, (vendor.qualityScore || 5) - 0.5).toFixed(2));
    await UPDATE(VendorMaster)
      .set({ qualityScore: newScore })
      .where({ ID: po.vendor_ID });
  }
};
