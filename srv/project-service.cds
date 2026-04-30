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
  // Route pattern "ActiveProjects:?query:" → FE binds /ActiveProjects
  // Not @readonly so FE ObjectPage allows Create on child tables (BOQ, MR).
  // Project header fields are annotated @Common.FieldControl: #ReadOnly.
  @readonly
  @restrict: [
    { grant: ['READ'], to: ['Engineer','ProjectManager','Management','ProcurementOfficer','BDM'] }
  ]
  entity ActiveProjects as projection on epc.Projects {
    *,
    projectManager   : redirected to Users,
    boqItems         : redirected to BOQItems,
    materialRequests : redirected to MaterialRequests,
    virtual criticality : Integer
  } where status = 'ACTIVE';

  // ── SENIOR ACTIVE PROJECTS — Senior Engineer view ─────────────
  // Separate entity so route pattern "SeniorActiveProjects:?query:"
  // resolves cleanly — same data, distinct FE binding path.
  @readonly
  @restrict: [
    { grant: ['READ'], to: ['Engineer','ProjectManager','Management','ProcurementOfficer','BDM'] }
  ]
  entity SeniorActiveProjects as projection on epc.Projects {
    *,
    projectManager   : redirected to Users,
    boqItems         : redirected to BOQItems,
    materialRequests : redirected to MaterialRequests,
    virtual criticality : Integer
  } where status = 'ACTIVE';

  // ── BOQ ITEMS ─────────────────────────────────────────────────
  // Junior Engineers define BOQ. Senior Engineers and BDM are read-only here.
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
    quotations          : redirected to VendorQuotations
  } actions {
    action submitRequest()             returns MaterialRequests;
    action approveRequest(approvalRemarks: String(500)) returns MaterialRequests;
    action rejectRequest(rejectionReason: String(500)) returns MaterialRequests;
    action closeRequest()              returns MaterialRequests;
  };

  entity MaterialRequestItems as projection on epc.MaterialRequestItems {
    *,
    request  : redirected to MaterialRequests,
    material : redirected to MaterialMaster,
    boqItem  : redirected to BOQItems
  };

  // ── VENDOR QUOTATIONS (read-only from project context) ────────
  @readonly
  entity VendorQuotations as projection on epc.VendorQuotations;
}

// UI annotations are maintained in app/projectmanagement/annotations.cds
