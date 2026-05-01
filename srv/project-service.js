'use strict';

const cds = require('@sap/cds');

module.exports = class ProjectService extends cds.ApplicationService {

  async init() {
    const {
      Projects,
      ActiveProjects,
      SeniorActiveProjects,
      MaterialRequests,
      ActiveProjects_MaterialRequests,
      SeniorActiveProjects_MaterialRequests,
      ApprovedMaterialRequests,
      MaterialRequestItems,
      ActiveProjects_MaterialRequestItems,
      SeniorActiveProjects_MaterialRequestItems,
      BOQItems,
      ActiveProjects_BOQItems,
      SeniorActiveProjects_BOQItems,
      VendorMaster,
      Invoices,
      InvoiceItems,
      ThreeWayMatchResults
    } = this.entities;

    // ── AUTO-NUMBERING ────────────────────────────────────────────
    this.before('CREATE', Projects,                              this._generateProjectCode.bind(this));
    this.before('CREATE', MaterialRequests,                      this._generateRequestNumber.bind(this));
    this.before('CREATE', ActiveProjects_MaterialRequests,       this._generateRequestNumber.bind(this));
    this.before('CREATE', SeniorActiveProjects_MaterialRequests, this._generateRequestNumber.bind(this));
    this.before('CREATE', VendorMaster,                          this._generateVendorCode.bind(this));
    this.before('CREATE', Invoices,                              this._generateInvoiceNumber.bind(this));

    // ── DERIVED FIELD CALCULATION ────────────────────────────────
    this.before('CREATE', MaterialRequestItems,                      this._validateRequestItem.bind(this));
    this.before('CREATE', ActiveProjects_MaterialRequestItems,       this._validateRequestItem.bind(this));
    this.before('CREATE', SeniorActiveProjects_MaterialRequestItems, this._validateRequestItem.bind(this));
    this.before('SAVE',   BOQItems,                                  this._calculateBOQValue.bind(this));
    this.before('SAVE',   ActiveProjects_BOQItems,                   this._calculateBOQValue.bind(this));
    this.before('SAVE',   SeniorActiveProjects_BOQItems,             this._calculateBOQValue.bind(this));
    this.before('CREATE', Invoices,                                  this._validateInvoice.bind(this));
    this.before(['CREATE','UPDATE'], InvoiceItems,                   this._calculateInvoiceItemAmounts.bind(this));
    this.after(['CREATE','UPDATE','DELETE'], InvoiceItems, (_, req) => this._recalculateInvoiceTotals(req));

    // ── BUSINESS GATING ──────────────────────────────────────────
    this.before(['CREATE', 'UPDATE', 'DELETE'], BOQItems,                              this._checkProjectActiveGate.bind(this));
    this.before(['CREATE', 'UPDATE', 'DELETE'], ActiveProjects_BOQItems,               this._checkProjectActiveGate.bind(this));
    this.before(['CREATE', 'UPDATE', 'DELETE'], MaterialRequests,                      this._checkProjectActiveGate.bind(this));
    this.before(['CREATE', 'UPDATE', 'DELETE'], ActiveProjects_MaterialRequests,       this._checkProjectActiveGate.bind(this));
    this.before(['CREATE', 'UPDATE', 'DELETE'], SeniorActiveProjects_MaterialRequests, this._checkProjectActiveGate.bind(this));
    this.before('UPDATE', Projects,                                                    this._preventHeaderUpdateByEngineer.bind(this));

    // ── PROJECT ACTIONS ───────────────────────────────────────────
    this.on('activateProject',  Projects, this._activateProject.bind(this));
    this.on('putOnHold',        Projects, this._putProjectOnHold.bind(this));
    this.on('completeProject',  Projects, this._completeProject.bind(this));
    this.on('cancelProject',    Projects, this._cancelProject.bind(this));

    // ── MATERIAL REQUEST ACTIONS (all entity paths) ───────────────
    const mrEntities = [MaterialRequests, ActiveProjects_MaterialRequests, SeniorActiveProjects_MaterialRequests];
    for (const entity of mrEntities) {
      this.on('submitRequest',  entity, this._submitRequest.bind(this));
      this.on('approveRequest', entity, this._approveRequest.bind(this));
      this.on('rejectRequest',  entity, this._rejectRequest.bind(this));
      this.on('closeRequest',   entity, this._closeRequest.bind(this));
    }

    // ── VENDOR MASTER ACTIONS ─────────────────────────────────────
    this.on('activateVendor',   VendorMaster, this._activateVendor.bind(this));
    this.on('deactivateVendor', VendorMaster, this._deactivateVendor.bind(this));

    // ── INVOICE ACTIONS ───────────────────────────────────────────
    this.on('submitInvoice',        Invoices, this._submitInvoice.bind(this));
    this.on('performThreeWayMatch', Invoices, this._performThreeWayMatch.bind(this));
    this.on('approveInvoice',       Invoices, this._approveInvoice.bind(this));
    this.on('rejectInvoice',        Invoices, this._rejectInvoice.bind(this));
    this.on('markPaid',             Invoices, this._markPaid.bind(this));

    // ── POST-READ ENRICHMENT ──────────────────────────────────────
    this.after('READ', Projects,                    this._enrichProjects.bind(this));
    this.after('READ', ActiveProjects,              this._enrichProjects.bind(this));
    this.after('READ', SeniorActiveProjects,        this._enrichProjects.bind(this));
    this.after('READ', MaterialRequests,            this._enrichRequests.bind(this));
    this.after('READ', ActiveProjects_MaterialRequests,       this._enrichRequests.bind(this));
    this.after('READ', SeniorActiveProjects_MaterialRequests, this._enrichRequests.bind(this));
    this.after('READ', ApprovedMaterialRequests,    this._enrichRequests.bind(this));

    await super.init();
  }

  // ═══════════════════════════════════════════════════════════════
  // VENDOR MASTER
  // ═══════════════════════════════════════════════════════════════

  async _generateVendorCode(req) {
    if (req.data.vendorCode) return;
    const year = new Date().getFullYear();
    const result = await SELECT.one.from(this.entities.VendorMaster)
      .columns('vendorCode').orderBy('createdAt desc');
    let seq = 1;
    if (result?.vendorCode) {
      const match = result.vendorCode.match(/VND-\d{4}-(\d{4})$/);
      if (match) seq = parseInt(match[1]) + 1;
    }
    req.data.vendorCode       = `VND-${year}-${String(seq).padStart(4, '0')}`;
    req.data.isActive         = req.data.isActive         ?? true;
    req.data.performanceScore = req.data.performanceScore ?? 0;
    req.data.totalOrders      = req.data.totalOrders      ?? 0;
    req.data.onTimeDeliveries = req.data.onTimeDeliveries ?? 0;
    req.data.qualityScore     = req.data.qualityScore     ?? 0;
  }

  async _activateVendor(req) {
    const { ID } = req.params[0];
    await UPDATE(this.entities.VendorMaster).set({ isActive: true }).where({ ID });
    return SELECT.one.from(this.entities.VendorMaster).where({ ID });
  }

  async _deactivateVendor(req) {
    const { ID } = req.params[0];
    await UPDATE(this.entities.VendorMaster).set({ isActive: false }).where({ ID });
    return SELECT.one.from(this.entities.VendorMaster).where({ ID });
  }

  // ═══════════════════════════════════════════════════════════════
  // INVOICE — AUTO-NUMBERING & VALIDATION
  // ═══════════════════════════════════════════════════════════════

  async _generateInvoiceNumber(req) {
    if (req.data.invoiceNumber) return;
    const year = new Date().getFullYear();
    const result = await SELECT.one.from(this.entities.Invoices)
      .columns('invoiceNumber').orderBy('createdAt desc');
    let seq = 1;
    if (result?.invoiceNumber) {
      const match = result.invoiceNumber.match(/INV-\d{4}-(\d{4})$/);
      if (match) seq = parseInt(match[1]) + 1;
    }
    req.data.invoiceNumber = `INV-${year}-${String(seq).padStart(4, '0')}`;
    req.data.invoiceDate   = req.data.invoiceDate || new Date().toISOString().slice(0, 10);
    req.data.status        = 'DRAFT';
    req.data.subtotal      = 0;
    req.data.taxAmount     = 0;
    req.data.totalAmount   = 0;
  }

  async _validateInvoice(req) {
    const inv = req.data;
    if (!inv.vendorInvoiceNo)  return req.error(400, 'Vendor Invoice Number is mandatory', 'vendorInvoiceNo');
    if (!inv.purchaseOrder_ID) return req.error(400, 'Purchase Order reference is mandatory', 'purchaseOrder_ID');
    const existing = await SELECT.one.from(this.entities.Invoices)
      .where({ vendorInvoiceNo: inv.vendorInvoiceNo, vendor_ID: inv.vendor_ID });
    if (existing) return req.error(400, `Vendor invoice ${inv.vendorInvoiceNo} already exists for this vendor`, 'vendorInvoiceNo');
  }

  _calculateInvoiceItemAmounts(req) {
    const item = req.data;
    if (item.invoicedQty !== undefined && item.unitPrice !== undefined) {
      const base     = parseFloat((item.invoicedQty * item.unitPrice).toFixed(4));
      const taxPct   = item.taxPercent ?? 18;
      item.taxAmount   = parseFloat((base * taxPct / 100).toFixed(2));
      item.totalAmount = parseFloat((base + item.taxAmount).toFixed(2));
    }
  }

  async _recalculateInvoiceTotals(req) {
    const invoiceId = req.data?.invoice_ID;
    if (!invoiceId) return;
    const items = await SELECT.from(this.entities.InvoiceItems).where({ invoice_ID: invoiceId });
    let subtotal = 0, taxAmount = 0;
    for (const item of items) {
      const base = parseFloat(((item.invoicedQty || 0) * (item.unitPrice || 0)).toFixed(4));
      const tax  = parseFloat((base * (item.taxPercent || 18) / 100).toFixed(2));
      subtotal  += base;
      taxAmount += tax;
    }
    await UPDATE(this.entities.Invoices)
      .set({ subtotal, taxAmount, totalAmount: parseFloat((subtotal + taxAmount).toFixed(2)) })
      .where({ ID: invoiceId });
  }

  // ═══════════════════════════════════════════════════════════════
  // INVOICE ACTIONS
  // ═══════════════════════════════════════════════════════════════

  async _submitInvoice(req) {
    const { ID } = req.params[0];
    const inv = await SELECT.one.from(this.entities.Invoices).where({ ID });
    if (!inv) return req.error(404, `Invoice ${ID} not found`);
    if (inv.status !== 'DRAFT') return req.error(400, `Only DRAFT invoices can be submitted. Current: ${inv.status}`);
    const items = await SELECT.from(this.entities.InvoiceItems).where({ invoice_ID: ID });
    if (!items?.length) return req.error(400, 'Cannot submit invoice with no line items');
    await UPDATE(this.entities.Invoices).set({ status: 'SUBMITTED' }).where({ ID });
    return SELECT.one.from(this.entities.Invoices).where({ ID });
  }

  async _performThreeWayMatch(req) {
    const { ID } = req.params[0];
    const inv = await SELECT.one.from(this.entities.Invoices).where({ ID });
    if (!inv) return req.error(404, `Invoice ${ID} not found`);
    if (!['SUBMITTED','UNDER_REVIEW','MISMATCH'].includes(inv.status))
      return req.error(400, `Cannot run three-way match on invoice in status: ${inv.status}`);
    if (!inv.receipt_ID) return req.error(400, 'Invoice must be linked to a Material Receipt before three-way match');

    const invItems    = await SELECT.from(this.entities.InvoiceItems).where({ invoice_ID: ID });
    const poItems     = await SELECT.from(cds.entities('solar.epc').PurchaseOrderItems).where({ purchaseOrder_ID: inv.purchaseOrder_ID });
    const receiptItems= await SELECT.from(cds.entities('solar.epc').MaterialReceiptItems).where({ receipt_ID: inv.receipt_ID });

    await DELETE.from(this.entities.ThreeWayMatchResults).where({ invoice_ID: ID });

    let overallStatus = 'MATCHED';
    const records = [];

    for (const invItem of invItems) {
      const poItem      = poItems.find(p => p.ID === invItem.poItem_ID || p.material_ID === invItem.material_ID);
      const receiptItem = receiptItems.find(r => r.material_ID === invItem.material_ID || (poItem && r.poItem_ID === poItem.ID));

      const poQty      = poItem?.orderedQty      || 0;
      const receivedQty= receiptItem?.acceptedQty || 0;
      const invoicedQty= invItem.invoicedQty      || 0;
      const poPrice    = poItem?.unitPrice         || 0;
      const invPrice   = invItem.unitPrice         || 0;

      const qtyOk   = Math.abs(invoicedQty - receivedQty) <= 0.001;
      const priceOk = Math.abs(invPrice - poPrice)        <= 0.01;

      const quantityMatch = qtyOk   ? 'MATCHED' : 'QUANTITY_MISMATCH';
      const priceMatch    = priceOk ? 'MATCHED' : 'PRICE_MISMATCH';
      let   lineStatus;
      if      ( qtyOk &&  priceOk) { lineStatus = 'MATCHED'; }
      else if (!qtyOk && !priceOk) { lineStatus = 'BOTH_MISMATCH';     overallStatus = 'BOTH_MISMATCH'; }
      else if (!qtyOk)             { lineStatus = 'QUANTITY_MISMATCH'; if (overallStatus === 'MATCHED') overallStatus = 'QUANTITY_MISMATCH'; }
      else                         { lineStatus = 'PRICE_MISMATCH';    if (overallStatus === 'MATCHED') overallStatus = 'PRICE_MISMATCH'; }

      const qtyVariance   = parseFloat((invoicedQty - receivedQty).toFixed(3));
      const priceVariance = parseFloat((invPrice    - poPrice).toFixed(4));
      records.push({
        ID: cds.utils.uuid(), invoice_ID: ID,
        purchaseOrder_ID: inv.purchaseOrder_ID, receipt_ID: inv.receipt_ID,
        invoiceItem_ID: invItem.ID, poItem_ID: poItem?.ID || null, receiptItem_ID: receiptItem?.ID || null,
        material_ID: invItem.material_ID, poQty, receivedQty, invoicedQty,
        poUnitPrice: poPrice, invoiceUnitPrice: invPrice,
        quantityMatch, priceMatch, overallStatus: lineStatus,
        qtyVariance, priceVariance,
        valueVariance: parseFloat((qtyVariance * invPrice).toFixed(2)),
        remarks: [Math.abs(qtyVariance) > 0.001 && `Qty variance: ${qtyVariance}`, Math.abs(priceVariance) > 0.01 && `Price variance: ${priceVariance}`].filter(Boolean).join('; ') || 'Fully matched'
      });
    }

    await INSERT.into(this.entities.ThreeWayMatchResults).entries(records);
    const invoiceStatus = overallStatus === 'MATCHED' ? 'MATCHED' : 'MISMATCH';
    await UPDATE(this.entities.Invoices).set({ status: invoiceStatus }).where({ ID });
    return SELECT.one.from(this.entities.Invoices).where({ ID });
  }

  async _approveInvoice(req) {
    const { ID } = req.params[0];
    const inv = await SELECT.one.from(this.entities.Invoices).where({ ID });
    if (!inv) return req.error(404, `Invoice ${ID} not found`);
    if (!['MATCHED','MISMATCH','UNDER_REVIEW'].includes(inv.status))
      return req.error(400, `Invoice must be MATCHED or UNDER_REVIEW to approve. Current: ${inv.status}`);
    await UPDATE(this.entities.Invoices).set({ status: 'APPROVED', approvalDate: new Date().toISOString() }).where({ ID });
    // Update project spent amount
    const po = await SELECT.one.from(cds.entities('solar.epc').PurchaseOrders).where({ ID: inv.purchaseOrder_ID });
    if (po?.project_ID) await UPDATE(cds.entities('solar.epc').Projects).set({ spentAmount: { '+=': inv.totalAmount } }).where({ ID: po.project_ID });
    // Update vendor performance
    const vm = await SELECT.one.from(cds.entities('solar.epc').VendorMaster).where({ ID: inv.vendor_ID });
    if (vm) await UPDATE(cds.entities('solar.epc').VendorMaster).set({ performanceScore: parseFloat(Math.min(10, (vm.performanceScore || 5) + 0.2).toFixed(2)) }).where({ ID: inv.vendor_ID });
    return SELECT.one.from(this.entities.Invoices).where({ ID });
  }

  async _rejectInvoice(req) {
    const { ID } = req.params[0];
    const { reason } = req.data;
    if (!reason) return req.error(400, 'Rejection reason is mandatory');
    const inv = await SELECT.one.from(this.entities.Invoices).where({ ID });
    if (!inv) return req.error(404, `Invoice ${ID} not found`);
    if (['PAID','REJECTED'].includes(inv.status)) return req.error(400, `Cannot reject invoice in status: ${inv.status}`);
    await UPDATE(this.entities.Invoices).set({ status: 'REJECTED', rejectionReason: reason }).where({ ID });
    const vm = await SELECT.one.from(cds.entities('solar.epc').VendorMaster).where({ ID: inv.vendor_ID });
    if (vm) await UPDATE(cds.entities('solar.epc').VendorMaster).set({ performanceScore: parseFloat(Math.max(0, (vm.performanceScore || 5) - 0.3).toFixed(2)) }).where({ ID: inv.vendor_ID });
    return SELECT.one.from(this.entities.Invoices).where({ ID });
  }

  async _markPaid(req) {
    const { ID } = req.params[0];
    const { paymentReference, paymentDate } = req.data;
    if (!paymentReference) return req.error(400, 'Payment reference is mandatory', 'paymentReference');
    const inv = await SELECT.one.from(this.entities.Invoices).where({ ID });
    if (!inv) return req.error(404, `Invoice ${ID} not found`);
    if (inv.status !== 'APPROVED') return req.error(400, `Only APPROVED invoices can be marked as paid. Current: ${inv.status}`);
    await UPDATE(this.entities.Invoices).set({ status: 'PAID', paymentReference, paymentDate: paymentDate || new Date().toISOString().slice(0, 10) }).where({ ID });
    return SELECT.one.from(this.entities.Invoices).where({ ID });
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTO-NUMBERING
  // ═══════════════════════════════════════════════════════════════

  async _generateProjectCode(req) {
    const year = new Date().getFullYear();
    const { Projects } = this.entities;
    const result = await SELECT.one.from(Projects)
      .columns('projectCode')
      .orderBy('createdAt desc');

    let seq = 1;
    if (result?.projectCode) {
      const match = result.projectCode.match(/PRJ-\d{4}-(\d{4})$/);
      if (match) seq = parseInt(match[1]) + 1;
    }
    req.data.projectCode = `PRJ-${year}-${String(seq).padStart(4, '0')}`;
    req.data.requestDate  = req.data.requestDate || new Date().toISOString().slice(0, 10);
    req.data.status       = 'DRAFT';
    req.data.spentAmount  = 0;
  }

  async _generateRequestNumber(req) {
    const year = new Date().getFullYear();
    const { MaterialRequests } = this.entities;
    const result = await SELECT.one.from(MaterialRequests)
      .columns('requestNumber')
      .orderBy('createdAt desc');

    let seq = 1;
    if (result?.requestNumber) {
      const match = result.requestNumber.match(/MR-\d{4}-(\d{4})$/);
      if (match) seq = parseInt(match[1]) + 1;
    }
    req.data.requestNumber = `MR-${year}-${String(seq).padStart(4, '0')}`;
    req.data.requestDate   = req.data.requestDate || new Date().toISOString().slice(0, 10);
    req.data.status        = 'DRAFT';
    req.data.priority      = req.data.priority || 'MEDIUM';

    // Auto-fill requestedBy from the logged-in user
    if (!req.data.requestedBy_ID && req.user?.id) {
      const { Users } = this.entities;
      const user = await SELECT.one.from(Users).where({ userName: req.user.id });
      if (user) req.data.requestedBy_ID = user.ID;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VALIDATIONS
  // ═══════════════════════════════════════════════════════════════

  async _checkProjectActiveGate(req) {
    let project_ID = req.data?.project_ID;

    // If project_ID is not in the payload (e.g. UPDATE/DELETE without providing it), fetch it from DB
    if (!project_ID) {
      const ID = req.data?.ID || (req.params && req.params[0]?.ID);
      if (!ID) return; // Might be a deep insert inherited from parent

      const record = await SELECT.one.from(req.target).where({ ID });
      if (record) project_ID = record.project_ID || record.project_ID;
    }

    if (project_ID) {
      const project = await SELECT.one.from(this.entities.Projects).where({ ID: project_ID });
      if (project && project.status !== 'ACTIVE') {
        return req.error(403, `Action blocked: Engineering activities are only allowed when the Project is ACTIVE. Current status is ${project.status}.`);
      }
    }
  }

  async _preventHeaderUpdateByEngineer(req) {
    // Skip during draft activation — full entity payload is written back by CAP, not a real header edit
    if (req.data.IsActiveEntity === true) return;

    if (req.user && req.user.is('Engineer') && !req.user.is('BDM') && !req.user.is('Management')) {
      const updatedFields = Object.keys(req.data).filter(key =>
        !['ID', 'IsActiveEntity', 'HasActiveEntity', 'HasDraftEntity', 'DraftAdministrativeData_DraftUUID', 'boqItems', 'materialRequests'].includes(key)
      );

      if (updatedFields.length > 0) {
        return req.error(403, `Engineers are restricted to editing Bill of Quantities and Material Requests. Modifying project header details is not allowed.`);
      }
    }
  }

  async _validateRequestItem(req) {
    const item = req.data;
    if (!item.requestedQty || item.requestedQty <= 0) {
      req.error(400, 'Requested quantity must be greater than zero', 'requestedQty');
    }
    if (!item.material_ID) {
      req.error(400, 'Material is mandatory', 'material_ID');
    }

    // Auto-assign line number for new items
    if (!item.lineNumber && item.request_ID) {
      const existing = await SELECT.from(this.entities.MaterialRequestItems)
        .where({ request_ID: item.request_ID });
      item.lineNumber = (existing?.length || 0) + 1;
    }

    // Compute estimated value from rate × qty
    if (item.estimatedRate && item.requestedQty) {
      item.estimatedValue = parseFloat((item.estimatedRate * item.requestedQty).toFixed(2));
    }
    // Check BOQ availability if linked
    if (item.boqItem_ID) {
      const { BOQItems } = this.entities;
      const boq = await SELECT.one.from(BOQItems).where({ ID: item.boqItem_ID });
      if (boq) {
        const available = boq.plannedQty - boq.requestedQty;
        if (item.requestedQty > available) {
          req.error(400,
            `Requested qty ${item.requestedQty} exceeds BOQ available qty ${available}`,
            'requestedQty'
          );
        }
      }
    }
  }

  _calculateBOQValue(req) {
    if (req.data.plannedQty && req.data.estimatedRate) {
      req.data.estimatedValue = parseFloat(
        (req.data.plannedQty * req.data.estimatedRate).toFixed(2)
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PROJECT ACTIONS
  // ═══════════════════════════════════════════════════════════════

  async _activateProject(req) {
    const { ID } = req.params[0];
    const project = await SELECT.one.from(this.entities.Projects).where({ ID });
    if (!project) return req.error(404, `Project ${ID} not found`);
    if (project.status !== 'DRAFT' && project.status !== 'ON_HOLD') {
      return req.error(400, `Cannot activate project in status: ${project.status}`);
    }
    await UPDATE(this.entities.Projects).set({ status: 'ACTIVE' }).where({ ID });
    return SELECT.one.from(this.entities.Projects).where({ ID });
  }

  async _putProjectOnHold(req) {
    const { ID } = req.params[0];
    const { reason } = req.data;
    const project = await SELECT.one.from(this.entities.Projects).where({ ID });
    if (!project) return req.error(404, `Project ${ID} not found`);
    if (project.status !== 'ACTIVE') {
      return req.error(400, `Only ACTIVE projects can be put on hold`);
    }
    await UPDATE(this.entities.Projects)
      .set({ status: 'ON_HOLD', description: reason || project.description })
      .where({ ID });
    return SELECT.one.from(this.entities.Projects).where({ ID });
  }

  async _completeProject(req) {
    const { ID } = req.params[0];
    const project = await SELECT.one.from(this.entities.Projects).where({ ID });
    if (!project) return req.error(404, `Project ${ID} not found`);
    if (project.status !== 'ACTIVE') {
      return req.error(400, `Only ACTIVE projects can be completed`);
    }
    await UPDATE(this.entities.Projects)
      .set({ status: 'COMPLETED', endDate: new Date().toISOString().slice(0, 10) })
      .where({ ID });
    return SELECT.one.from(this.entities.Projects).where({ ID });
  }

  async _cancelProject(req) {
    const { ID } = req.params[0];
    const project = await SELECT.one.from(this.entities.Projects).where({ ID });
    if (!project) return req.error(404, `Project ${ID} not found`);
    if (['COMPLETED', 'CANCELLED'].includes(project.status)) {
      return req.error(400, `Cannot cancel a ${project.status} project`);
    }
    await UPDATE(this.entities.Projects).set({ status: 'CANCELLED' }).where({ ID });
    return SELECT.one.from(this.entities.Projects).where({ ID });
  }

  // ═══════════════════════════════════════════════════════════════
  // MATERIAL REQUEST ACTIONS
  // ═══════════════════════════════════════════════════════════════

  async _submitRequest(req) {
    const { ID } = req.params[0];
    const mr = await SELECT.one.from(this.entities.MaterialRequests).where({ ID });
    if (!mr) return req.error(404, `Material Request ${ID} not found`);
    if (mr.status !== 'DRAFT') {
      return req.error(400, `Only DRAFT requests can be submitted. Current status: ${mr.status}`);
    }
    // Must have at least one item
    const items = await SELECT.from(this.entities.MaterialRequestItems).where({ request_ID: ID });
    if (!items || items.length === 0) {
      return req.error(400, 'Cannot submit a request with no items');
    }
    await UPDATE(this.entities.MaterialRequests)
      .set({ status: 'SUBMITTED' })
      .where({ ID });

    // Update BOQ requested quantities
    for (const item of items) {
      if (item.boqItem_ID) {
        const boq = await SELECT.one.from(this.entities.BOQItems)
          .where({ ID: item.boqItem_ID });
        if (boq) {
          await UPDATE(this.entities.BOQItems)
            .set({ requestedQty: (boq.requestedQty || 0) + item.requestedQty })
            .where({ ID: item.boqItem_ID });
        }
      }
    }
    return SELECT.one.from(this.entities.MaterialRequests).where({ ID });
  }

  async _approveRequest(req) {
    const { ID } = req.params[0];
    const { approvalRemarks } = req.data;
    const mr = await SELECT.one.from(this.entities.MaterialRequests).where({ ID });
    if (!mr) return req.error(404, `Material Request ${ID} not found`);
    if (mr.status !== 'SUBMITTED') {
      return req.error(400, `Only SUBMITTED requests can be approved. Current status: ${mr.status}`);
    }
    await UPDATE(this.entities.MaterialRequests)
      .set({
        status       : 'APPROVED',
        approvalDate : new Date().toISOString(),
        remarks      : approvalRemarks || mr.remarks,
        approvedBy_ID: req.user?.id || null
      })
      .where({ ID });
    return SELECT.one.from(this.entities.MaterialRequests).where({ ID });
  }

  async _rejectRequest(req) {
    const { ID } = req.params[0];
    const { rejectionReason } = req.data;
    if (!rejectionReason) {
      return req.error(400, 'Rejection reason is mandatory');
    }
    const mr = await SELECT.one.from(this.entities.MaterialRequests).where({ ID });
    if (!mr) return req.error(404, `Material Request ${ID} not found`);
    if (mr.status !== 'SUBMITTED') {
      return req.error(400, `Only SUBMITTED requests can be rejected. Current status: ${mr.status}`);
    }
    // Reverse BOQ requested quantities
    const items = await SELECT.from(this.entities.MaterialRequestItems).where({ request_ID: ID });
    for (const item of items) {
      if (item.boqItem_ID) {
        const boq = await SELECT.one.from(this.entities.BOQItems)
          .where({ ID: item.boqItem_ID });
        if (boq) {
          const newQty = Math.max(0, (boq.requestedQty || 0) - item.requestedQty);
          await UPDATE(this.entities.BOQItems)
            .set({ requestedQty: newQty })
            .where({ ID: item.boqItem_ID });
        }
      }
    }
    await UPDATE(this.entities.MaterialRequests)
      .set({ status: 'REJECTED', rejectionReason })
      .where({ ID });
    return SELECT.one.from(this.entities.MaterialRequests).where({ ID });
  }

  async _closeRequest(req) {
    const { ID } = req.params[0];
    const mr = await SELECT.one.from(this.entities.MaterialRequests).where({ ID });
    if (!mr) return req.error(404, `Material Request ${ID} not found`);
    if (!['APPROVED', 'ORDERED'].includes(mr.status)) {
      return req.error(400, `Cannot close request in status: ${mr.status}`);
    }
    await UPDATE(this.entities.MaterialRequests).set({ status: 'CLOSED' }).where({ ID });
    return SELECT.one.from(this.entities.MaterialRequests).where({ ID });
  }

  // ═══════════════════════════════════════════════════════════════
  // POST-READ ENRICHMENT
  // ═══════════════════════════════════════════════════════════════

  _enrichProjects(projects) {
    if (!projects) return;
    const list = Array.isArray(projects) ? projects : [projects];
    for (const p of list) {
      // Safely apply criticality only when the object exists
      if (p && typeof p === 'object') {
        // Use 0 as default if status is missing to prevent drill-down errors in FE cache
        p.criticality = p.status ? this._projectStatusCriticality(p.status) : 0;
      }
    }
  }

  _enrichRequests(requests) {
    if (!requests) return;
    const list = Array.isArray(requests) ? requests : [requests];
    for (const r of list) {
      if (r && typeof r === 'object') {
        r.criticality = r.status ? this._requestStatusCriticality(r.status) : 0;
      }
    }
  }

  _projectStatusCriticality(status) {
    const map = {
      DRAFT    : 0,  // Neutral
      ACTIVE   : 3,  // Positive
      ON_HOLD  : 2,  // Critical
      COMPLETED: 3,  // Positive
      CANCELLED: 1   // Negative
    };
    return map[status] ?? 0;
  }

  _requestStatusCriticality(status) {
    const map = {
      DRAFT    : 0,
      SUBMITTED: 2,
      APPROVED : 3,
      REJECTED : 1,
      ORDERED  : 3,
      CLOSED   : 0
    };
    return map[status] ?? 0;
  }
};
