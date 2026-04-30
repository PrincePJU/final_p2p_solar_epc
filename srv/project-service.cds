using solar.epc as epc from '../db/schema';

// ═══════════════════════════════════════════════════════════════
// PROJECT SERVICE  — CAP OData V4
// Covers: Projects, BOQ, Material Requests, Approval workflow
// Roles: Engineer, Project Manager, Management
// ═══════════════════════════════════════════════════════════════

@requires: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer']
service ProjectService @(path: '/project') {

  // ── READ-ONLY REFERENCES ──────────────────────────────────────
  @readonly
  entity MaterialMaster as projection on epc.MaterialMaster
    where isActive = true;

  @readonly
  entity Users as projection on epc.Users
    where isActive = true;

  // ── PROJECTS ──────────────────────────────────────────────────
  // BDM owns the project lifecycle: create, activate, hold, cancel.
  // Engineers get read-only access so they can navigate to approved projects.
  @odata.draft.enabled
  @cds.redirection.target
  @restrict: [
    { grant: ['READ'],   to: ['BDM','Management','ProcurementOfficer'] },
    { grant: ['READ'],   to: ['Engineer','ProjectManager'], where: 'status = ''ACTIVE''' },
    { grant: ['CREATE','UPDATE','DELETE'], to: ['BDM','Management'] },
    { grant: ['UPDATE'], to: ['Engineer'], where: 'status = ''ACTIVE''' },
    { grant: ['activateProject','putOnHold','completeProject','cancelProject'], to: ['BDM','Management'] }
  ]
  entity Projects as projection on epc.Projects {
    *,
    projectManager   : redirected to Users,
    boqItems         : redirected to BOQItems,
    materialRequests : redirected to MaterialRequests,
    virtual criticality : Integer
  } actions {
    action activateProject()   returns Projects;
    action putOnHold(reason: String(500)) returns Projects;
    action completeProject()   returns Projects;
    action cancelProject(reason: String(500)) returns Projects;
  };

  // ── ACTIVE PROJECTS — Engineer view ──────────────────────────
  @odata.draft.enabled
  @restrict: [
    { grant: ['READ'], to: ['Engineer','ProjectManager','Management','ProcurementOfficer','BDM'] },
    { grant: ['UPDATE'], to: ['Engineer'] }
  ]
  entity ActiveProjects as projection on epc.Projects {
    *,
    projectManager   : redirected to Users,
    boqItems         : redirected to ActiveProjects_BOQItems,
    materialRequests : redirected to ActiveProjects_MaterialRequests,
    virtual criticality : Integer
  } where status = 'ACTIVE';

  @restrict: [
    { grant: ['READ'],                    to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE','DELETE'], to: ['Engineer','Management'] }
  ]
  entity ActiveProjects_BOQItems as projection on epc.BOQItems {
    *,
    project : redirected to ActiveProjects,
    material : redirected to MaterialMaster
  };

  @restrict: [
    { grant: ['READ'],                                          to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE'],                               to: ['Engineer','Management'] },
    { grant: ['submitRequest'],                                 to: ['Engineer','Management'] },
    { grant: ['approveRequest','rejectRequest','closeRequest'],  to: ['ProjectManager','Management'] }
  ]
  entity ActiveProjects_MaterialRequests as projection on epc.MaterialRequests {
    *,
    project : redirected to ActiveProjects,
    requestedBy : redirected to Users,
    approvedBy  : redirected to Users,
    items       : redirected to ActiveProjects_MaterialRequestItems,
    quotations  : redirected to ActiveProjects_VendorQuotations,
    virtual criticality : Integer
  } actions {
    action submitRequest()             returns ActiveProjects_MaterialRequests;
    action approveRequest(approvalRemarks: String(500)) returns ActiveProjects_MaterialRequests;
    action rejectRequest(rejectionReason: String(500)) returns ActiveProjects_MaterialRequests;
    action closeRequest()              returns ActiveProjects_MaterialRequests;
  };

  @restrict: [
    { grant: ['READ'],                    to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE','DELETE'], to: ['Engineer','Management'] }
  ]
  entity ActiveProjects_MaterialRequestItems as projection on epc.MaterialRequestItems {
    *,
    request : redirected to ActiveProjects_MaterialRequests,
    material : redirected to MaterialMaster,
    boqItem : redirected to ActiveProjects_BOQItems
  };

  @readonly
  entity ActiveProjects_VendorQuotations as projection on epc.VendorQuotations {
    *,
    materialRequest: redirected to ActiveProjects_MaterialRequests,
    items: redirected to ActiveProjects_VendorQuotationItems
  };

  @readonly
  @cds.redirection.target
  entity ActiveProjects_VendorQuotationItems as projection on epc.VendorQuotationItems {
    *,
    quotation: redirected to ActiveProjects_VendorQuotations,
    requestItem: redirected to ActiveProjects_MaterialRequestItems,
    material: redirected to MaterialMaster
  };

  // ── SENIOR ACTIVE PROJECTS — Senior Engineer view ─────────────
  @odata.draft.enabled
  @restrict: [
    { grant: ['READ'], to: ['Engineer','ProjectManager','Management','ProcurementOfficer','BDM'] },
    { grant: ['UPDATE'], to: ['Engineer','ProjectManager'] }
  ]
  entity SeniorActiveProjects as projection on epc.Projects {
    *,
    projectManager   : redirected to Users,
    boqItems         : redirected to SeniorActiveProjects_BOQItems,
    materialRequests : redirected to SeniorActiveProjects_MaterialRequests,
    virtual criticality : Integer
  } where status = 'ACTIVE';

  @restrict: [
    { grant: ['READ'],                    to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE','DELETE'], to: ['Engineer','Management'] }
  ]
  entity SeniorActiveProjects_BOQItems as projection on epc.BOQItems {
    *,
    project : redirected to SeniorActiveProjects,
    material : redirected to MaterialMaster
  };

  @restrict: [
    { grant: ['READ'],                                          to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE'],                               to: ['Engineer','Management'] },
    { grant: ['submitRequest'],                                 to: ['Engineer','Management'] },
    { grant: ['approveRequest','rejectRequest','closeRequest'],  to: ['ProjectManager','Management'] }
  ]
  entity SeniorActiveProjects_MaterialRequests as projection on epc.MaterialRequests {
    *,
    project : redirected to SeniorActiveProjects,
    requestedBy : redirected to Users,
    approvedBy  : redirected to Users,
    items       : redirected to SeniorActiveProjects_MaterialRequestItems,
    quotations  : redirected to SeniorActiveProjects_VendorQuotations,
    virtual criticality : Integer
  } actions {
    action submitRequest()             returns SeniorActiveProjects_MaterialRequests;
    action approveRequest(approvalRemarks: String(500)) returns SeniorActiveProjects_MaterialRequests;
    action rejectRequest(rejectionReason: String(500)) returns SeniorActiveProjects_MaterialRequests;
    action closeRequest()              returns SeniorActiveProjects_MaterialRequests;
  };
  
  @restrict: [
    { grant: ['READ'],                    to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE','DELETE'], to: ['Engineer','Management'] }
  ]
  entity SeniorActiveProjects_MaterialRequestItems as projection on epc.MaterialRequestItems {
    *,
    request : redirected to SeniorActiveProjects_MaterialRequests,
    material : redirected to MaterialMaster,
    boqItem : redirected to SeniorActiveProjects_BOQItems
  };

  @readonly
  entity SeniorActiveProjects_VendorQuotations as projection on epc.VendorQuotations {
    *,
    materialRequest: redirected to SeniorActiveProjects_MaterialRequests,
    items: redirected to SeniorActiveProjects_VendorQuotationItems
  };

  @readonly
  @cds.redirection.target
  entity SeniorActiveProjects_VendorQuotationItems as projection on epc.VendorQuotationItems {
    *,
    quotation: redirected to SeniorActiveProjects_VendorQuotations,
    requestItem: redirected to SeniorActiveProjects_MaterialRequestItems,
    material: redirected to MaterialMaster
  };

  // ── BOQ ITEMS ─────────────────────────────────────────────────
  // Junior Engineers define BOQ. Senior Engineers and BDM are read-only here.
  @cds.redirection.target
  @restrict: [
    { grant: ['READ'],                    to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE','DELETE'], to: ['Engineer','Management'] }
  ]
  entity BOQItems as projection on epc.BOQItems {
    *,
    project  : redirected to Projects,
    material : redirected to MaterialMaster
  };

  // ── MATERIAL REQUESTS ─────────────────────────────────────────
  // Junior Engineers create, fill items, and submit.
  // Senior Engineers (ProjectManager) can only approve or reject — no creation.
  @cds.redirection.target
  @restrict: [
    { grant: ['READ'],                                          to: ['BDM','Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE'],                               to: ['Engineer','Management'] },
    { grant: ['submitRequest'],                                 to: ['Engineer','Management'] },
    { grant: ['approveRequest','rejectRequest','closeRequest'],  to: ['ProjectManager','Management'] }
  ]
  entity MaterialRequests as projection on epc.MaterialRequests {
    *,
    project             : redirected to Projects,
    requestedBy         : redirected to Users,
    approvedBy          : redirected to Users,
    items               : redirected to MaterialRequestItems,
    quotations          : redirected to VendorQuotations,
    virtual criticality : Integer
  } actions {
    action submitRequest()             returns MaterialRequests;
    action approveRequest(approvalRemarks: String(500)) returns MaterialRequests;
    action rejectRequest(rejectionReason: String(500)) returns MaterialRequests;
    action closeRequest()              returns MaterialRequests;
  };

  @cds.redirection.target
  entity MaterialRequestItems as projection on epc.MaterialRequestItems {
    *,
    request  : redirected to MaterialRequests,
    material : redirected to MaterialMaster,
    boqItem  : redirected to BOQItems
  };

  // ── VENDOR QUOTATIONS (read-only from project context) ────────
  @readonly
  entity VendorQuotations as projection on epc.VendorQuotations {
    *,
    materialRequest: redirected to MaterialRequests,
    items: redirected to VendorQuotationItems
  };

  @readonly
  @cds.redirection.target
  entity VendorQuotationItems as projection on epc.VendorQuotationItems {
    *,
    quotation: redirected to VendorQuotations,
    requestItem: redirected to MaterialRequestItems,
    material: redirected to MaterialMaster
  };
}

// UI annotations are maintained in app/projectmanagement/annotations.cds
