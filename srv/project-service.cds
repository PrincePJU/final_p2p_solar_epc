using solar.epc as epc from '../db/schema';

// ═══════════════════════════════════════════════════════════════
// PROJECT SERVICE  — CAP OData V4
// Covers: Projects, BOQ, Material Requests, Approval workflow
// Roles: Engineer, Project Manager, Management
// ═══════════════════════════════════════════════════════════════

@requires: ['Engineer','ProjectManager','Management','ProcurementOfficer']
service ProjectService @(path: '/project') {

  // ── READ-ONLY REFERENCES ──────────────────────────────────────
  @readonly
  entity MaterialMaster as projection on epc.MaterialMaster
    where isActive = true;

  @readonly
  entity Users as projection on epc.Users
    where isActive = true;

  // ── PROJECTS ──────────────────────────────────────────────────
  @odata.draft.enabled
  @restrict: [
    { grant: ['READ'],                          to: ['Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE'],               to: ['Engineer','ProjectManager','Management'] },
    { grant: ['DELETE'],                        to: ['Management'] },
    { grant: ['activateProject','putOnHold','completeProject','cancelProject'], to: ['ProjectManager','Management'] }
  ]
  entity Projects as projection on epc.Projects {
    *,
    projectManager   : redirected to Users,
    boqItems         : redirected to BOQItems,
    materialRequests : redirected to MaterialRequests,
    // Criticality: 0=Neutral, 1=Negative, 2=Critical, 3=Positive
    virtual criticality : Integer
  } actions {
    action activateProject()   returns Projects;
    action putOnHold(reason: String(500)) returns Projects;
    action completeProject()   returns Projects;
    action cancelProject(reason: String(500)) returns Projects;
  };

  // ── BOQ ITEMS ─────────────────────────────────────────────────
  entity BOQItems as projection on epc.BOQItems {
    *,
    project  : redirected to Projects,
    material : redirected to MaterialMaster
  };

  // ── MATERIAL REQUESTS ─────────────────────────────────────────
  // Draft is inherited from the parent Projects composition
  @restrict: [
    { grant: ['READ'],                                        to: ['Engineer','ProjectManager','Management','ProcurementOfficer'] },
    { grant: ['CREATE','UPDATE'],                             to: ['Engineer','ProjectManager'] },
    { grant: ['submitRequest'],                               to: ['Engineer','ProjectManager'] },
    { grant: ['approveRequest','rejectRequest','closeRequest'], to: ['ProjectManager','Management'] }
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

// ─── ANNOTATIONS: PROJECTS ────────────────────────────────────

annotate ProjectService.Projects with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: projectCode,    Label: 'Project Code'    },
    { $Type: 'UI.DataField', Value: projectName,    Label: 'Project Name'    },
    { $Type: 'UI.DataField', Value: clientName,     Label: 'Client'          },
    { $Type: 'UI.DataField', Value: location,       Label: 'Location'        },
    { $Type: 'UI.DataField', Value: capacityKWp,    Label: 'Capacity (kWp)'  },
    { $Type: 'UI.DataField', Value: status,         Label: 'Status',
      Criticality: criticality                                                },
    { $Type: 'UI.DataField', Value: startDate,      Label: 'Start Date'      },
    { $Type: 'UI.DataField', Value: budget,         Label: 'Budget (INR)'    }
  ],
  UI.SelectionFields: [ status, projectManager_ID, state ],
  UI.HeaderInfo: {
    TypeName      : 'Project',
    TypeNamePlural: 'Projects',
    Title         : { Value: projectName },
    Description   : { Value: projectCode }
  },
  UI.Identification: [
    { Value: projectCode },
    { Value: projectName },
    { Value: status      }
  ],
  UI.Facets: [
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'General Information',
      Target: '@UI.FieldGroup#General'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Project Dates & Budget',
      Target: '@UI.FieldGroup#DatesAndBudget'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Bill of Quantity',
      Target: 'boqItems/@UI.LineItem'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Material Requests',
      Target: 'materialRequests/@UI.LineItem'
    }
  ],
  UI.FieldGroup#General: {
    Label: 'General Information',
    Data : [
      { Value: projectCode    },
      { Value: projectName    },
      { Value: clientName     },
      { Value: location       },
      { Value: state          },
      { Value: capacityKWp    },
      { Value: projectManager_ID },
      { Value: status         },
      { Value: description    }
    ]
  },
  UI.FieldGroup#DatesAndBudget: {
    Label: 'Dates & Budget',
    Data : [
      { Value: startDate     },
      { Value: endDate       },
      { Value: budget        },
      { Value: spentAmount   },
      { Value: currency      }
    ]
  }
);

annotate ProjectService.Projects with {
  projectCode    @title: 'Project Code'    @mandatory;
  projectName    @title: 'Project Name'   @mandatory;
  clientName     @title: 'Client Name';
  location       @title: 'Site Location';
  state          @title: 'State';
  capacityKWp    @title: 'Capacity (kWp)';
  startDate      @title: 'Start Date';
  endDate        @title: 'End Date';
  budget         @title: 'Budget';
  spentAmount    @title: 'Spent Amount'   @readonly;
  currency       @title: 'Currency';
  status         @title: 'Status'         @readonly;
  description    @title: 'Description';
  projectManager @title: 'Project Manager'
    @Common.ValueList: {
      CollectionPath: 'Users',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut', LocalDataProperty: projectManager_ID, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'userName' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'role'     }
      ]
    };
}

// ─── ANNOTATIONS: BOQ ITEMS ───────────────────────────────────

annotate ProjectService.BOQItems with @(
  UI.LineItem: [
    { Value: lineNumber,     Label: 'Line'             },
    { Value: material_ID,    Label: 'Material'         },
    { Value: description,    Label: 'Description'      },
    { Value: uom,            Label: 'UOM'              },
    { Value: plannedQty,     Label: 'Planned Qty'      },
    { Value: estimatedRate,  Label: 'Est. Rate'        },
    { Value: estimatedValue, Label: 'Est. Value'       },
    { Value: requestedQty,   Label: 'Requested Qty'    },
    { Value: orderedQty,     Label: 'Ordered Qty'      },
    { Value: receivedQty,    Label: 'Received Qty'     }
  ]
);

annotate ProjectService.BOQItems with {
  material @title: 'Material'
    @Common.ValueList: {
      CollectionPath: 'MaterialMaster',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut',         LocalDataProperty: material_ID,  ValueListProperty: 'ID'           },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'materialCode'                                  },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'description'                                   },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'uom'                                           }
      ]
    };
}

// ─── ANNOTATIONS: MATERIAL REQUESTS ──────────────────────────

annotate ProjectService.MaterialRequests with @(
  UI.LineItem: [
    { Value: requestNumber, Label: 'Request No.'    },
    { Value: project_ID,    Label: 'Project'        },
    { Value: requestDate,   Label: 'Request Date'   },
    { Value: requiredDate,  Label: 'Required Date'  },
    { Value: requestedBy_ID,Label: 'Requested By'   },
    { Value: status,        Label: 'Status'         }
  ],
  UI.SelectionFields: [ status, project_ID, requestedBy_ID ],
  UI.HeaderInfo: {
    TypeName      : 'Material Request',
    TypeNamePlural: 'Material Requests',
    Title         : { Value: requestNumber },
    Description   : { Value: status }
  },
  UI.Facets: [
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Request Details',
      Target: '@UI.FieldGroup#Header'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Request Items',
      Target: 'items/@UI.LineItem'
    }
  ],
  UI.FieldGroup#Header: {
    Label: 'Request Details',
    Data : [
      { Value: requestNumber  },
      { Value: project_ID     },
      { Value: requestDate    },
      { Value: requiredDate   },
      { Value: requestedBy_ID },
      { Value: status         },
      { Value: remarks        },
      { Value: approvedBy_ID  },
      { Value: approvalDate   },
      { Value: rejectionReason}
    ]
  }
);

annotate ProjectService.MaterialRequestItems with @(
  UI.LineItem: [
    { Value: lineNumber,   Label: 'Line'         },
    { Value: material_ID,  Label: 'Material'     },
    { Value: description,  Label: 'Description'  },
    { Value: requestedQty, Label: 'Qty'          },
    { Value: uom,          Label: 'UOM'          },
    { Value: remarks,      Label: 'Remarks'      }
  ]
);
