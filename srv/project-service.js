'use strict';

const cds = require('@sap/cds');

module.exports = class ProjectService extends cds.ApplicationService {

  async init() {
    const {
      Projects,
      ActiveProjects,
      SeniorActiveProjects,
      MaterialRequests,
      MaterialRequestItems,
      BOQItems
    } = this.entities;

    // ── AUTO-NUMBERING ────────────────────────────────────────────
    this.before('CREATE', Projects,         this._generateProjectCode.bind(this));
    this.before('CREATE', MaterialRequests, this._generateRequestNumber.bind(this));

    // ── DERIVED FIELD CALCULATION ────────────────────────────────
    this.before('CREATE', MaterialRequestItems, this._validateRequestItem.bind(this));
    this.before('SAVE',   BOQItems,             this._calculateBOQValue.bind(this));

    // ── BUSINESS GATING ──────────────────────────────────────────
    this.before(['CREATE', 'UPDATE', 'DELETE'], BOQItems,         this._checkProjectActiveGate.bind(this));
    this.before(['CREATE', 'UPDATE', 'DELETE'], MaterialRequests, this._checkProjectActiveGate.bind(this));
    this.before('UPDATE', Projects,                               this._preventHeaderUpdateByEngineer.bind(this));

    // ── PROJECT ACTIONS ───────────────────────────────────────────
    this.on('activateProject',  Projects, this._activateProject.bind(this));
    this.on('putOnHold',        Projects, this._putProjectOnHold.bind(this));
    this.on('completeProject',  Projects, this._completeProject.bind(this));
    this.on('cancelProject',    Projects, this._cancelProject.bind(this));

    // ── MATERIAL REQUEST ACTIONS ──────────────────────────────────
    this.on('submitRequest',  MaterialRequests, this._submitRequest.bind(this));
    this.on('approveRequest', MaterialRequests, this._approveRequest.bind(this));
    this.on('rejectRequest',  MaterialRequests, this._rejectRequest.bind(this));
    this.on('closeRequest',   MaterialRequests, this._closeRequest.bind(this));

    // ── POST-READ ENRICHMENT ──────────────────────────────────────
    this.after('READ', Projects,             this._enrichProjects.bind(this));
    this.after('READ', ActiveProjects,       this._enrichProjects.bind(this));
    this.after('READ', SeniorActiveProjects, this._enrichProjects.bind(this));
    this.after('READ', MaterialRequests,     this._enrichRequests.bind(this));

    await super.init();
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
    // Prevent engineers from modifying project header fields when creating BOQ/MRs in Draft mode
    if (req.user && (req.user.is('ENGINEER') || req.user.is('Engineer'))) {
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
        status      : 'APPROVED',
        approvalDate: new Date().toISOString(),
        remarks     : approvalRemarks || mr.remarks
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
    const list = Array.isArray(projects) ? projects : [projects];
    for (const p of list) {
      p.criticality = this._projectStatusCriticality(p.status);
    }
  }

  _enrichRequests(requests) {
    const list = Array.isArray(requests) ? requests : [requests];
    for (const r of list) {
      r.criticality = this._requestStatusCriticality(r.status);
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
