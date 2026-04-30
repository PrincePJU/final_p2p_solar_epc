using ProjectService as service from '../../srv/project-service';

// ═══════════════════════════════════════════════════════════════
// PROJECT LIST REPORT — UI Annotations
// ═══════════════════════════════════════════════════════════════

// ── LIST PAGE ─────────────────────────────────────────────────

annotate service.Projects with @(

  UI.SelectionFields: [
    status,
    state,
    projectManager_ID,
    startDate,
    endDate
  ],

  UI.LineItem: [
    {
      $Type      : 'UI.DataField',
      Value      : projectCode,
      Label      : 'Project Code',
      ![@UI.Importance]: #High
    },
    {
      $Type      : 'UI.DataField',
      Value      : projectName,
      Label      : 'Project Name',
      ![@UI.Importance]: #High
    },
    {
      $Type      : 'UI.DataField',
      Value      : clientName,
      Label      : 'Client',
      ![@UI.Importance]: #Medium
    },
    {
      $Type      : 'UI.DataField',
      Value      : location,
      Label      : 'Location',
      ![@UI.Importance]: #Medium
    },
    {
      $Type      : 'UI.DataField',
      Value      : state,
      Label      : 'State',
      ![@UI.Importance]: #Low
    },
    {
      $Type      : 'UI.DataField',
      Value      : capacityKWp,
      Label      : 'Capacity (kWp)',
      ![@UI.Importance]: #Medium
    },
    {
      $Type      : 'UI.DataField',
      Value      : budget,
      Label      : 'Budget (INR)',
      ![@UI.Importance]: #High
    },
    {
      $Type      : 'UI.DataField',
      Value      : startDate,
      Label      : 'Start Date',
      ![@UI.Importance]: #Medium
    },
    {
      $Type             : 'UI.DataFieldForAnnotation',
      Target            : '@UI.DataPoint#BudgetProgress',
      Label             : 'Budget Utilization',
      ![@UI.Importance] : #High
    },
    {
      $Type            : 'UI.DataField',
      Value            : status,
      Label            : 'Status',
      ![@UI.Importance]: #High
    }
  ],

  // ── KPI HEADER DATA POINTS ────────────────────────────────────
  UI.DataPoint#Budget: {
    Value        : budget,
    Title        : 'Total Budget',
    ValueFormat  : { NumberOfFractionalDigits: 0 }
  },

  UI.DataPoint#Spent: {
    Value        : spentAmount,
    Title        : 'Spent Amount',
    ValueFormat  : { NumberOfFractionalDigits: 0 }
  },

  UI.DataPoint#Capacity: {
    Value  : capacityKWp,
    Title  : 'Capacity (kWp)'
  },

  UI.DataPoint#BudgetProgress: {
    Value       : spentAmount,
    Title       : 'Budget Used',
    TargetValue : budget,
    Visualization: #Progress,
    Criticality  : criticality
  }
);

// ═══════════════════════════════════════════════════════════════
// PROJECT OBJECT PAGE — UI Annotations
// ═══════════════════════════════════════════════════════════════

annotate service.Projects with @(

  UI.HeaderInfo: {
    TypeName       : 'Project',
    TypeNamePlural : 'Projects',
    Title          : {
      $Type : 'UI.DataField',
      Value : projectName
    },
    Description: {
      $Type : 'UI.DataField',
      Value : projectCode
    },
    ImageUrl: ''
  },

  UI.HeaderFacets: [
    {
      $Type  : 'UI.ReferenceFacet',
      Target : '@UI.DataPoint#Budget',
      Label  : 'Budget'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Target : '@UI.DataPoint#Spent',
      Label  : 'Spent'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Target : '@UI.DataPoint#Capacity',
      Label  : 'Capacity'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      Target : '@UI.DataPoint#BudgetProgress',
      Label  : 'Budget Utilization'
    }
  ],

  // ── OBJECT PAGE ACTIONS ──────────────────────────────────────
  UI.Identification: [
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.activateProject',
      Label  : 'Activate'
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.putOnHold',
      Label  : 'Put On Hold'
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.completeProject',
      Label  : 'Complete'
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.cancelProject',
      Label  : 'Cancel'
    }
  ],

  // ── OBJECT PAGE SECTIONS ──────────────────────────────────────
  // Navigation-property tables (boqItems, materialRequests) must be top-level
  // ReferenceFacets — CollectionFacet wrappers block their rendering in FE v4.
  UI.Facets: [
    {
      $Type  : 'UI.CollectionFacet',
      ID     : 'GeneralInfo',
      Label  : 'General Information',
      Facets : [
        {
          $Type  : 'UI.ReferenceFacet',
          Target : '@UI.FieldGroup#ProjectDetails',
          Label  : 'Project Details'
        },
        {
          $Type  : 'UI.ReferenceFacet',
          Target : '@UI.FieldGroup#DatesAndBudget',
          Label  : 'Dates and Budget'
        }
      ]
    },
    {
      $Type  : 'UI.ReferenceFacet',
      ID     : 'BOQSection',
      Target : 'boqItems/@UI.LineItem',
      Label  : 'Bill of Quantity'
    },
    {
      $Type  : 'UI.ReferenceFacet',
      ID     : 'MRSection',
      Target : 'materialRequests/@UI.LineItem',
      Label  : 'Material Requests'
    }
  ],

  UI.FieldGroup#ProjectDetails: {
    Label : 'Project Details',
    Data  : [
      { $Type: 'UI.DataField', Value: projectCode,    Label: 'Project Code'     },
      { $Type: 'UI.DataField', Value: projectName,    Label: 'Project Name'     },
      { $Type: 'UI.DataField', Value: clientName,     Label: 'Client'           },
      { $Type: 'UI.DataField', Value: location,       Label: 'Location'         },
      { $Type: 'UI.DataField', Value: state,          Label: 'State'            },
      { $Type: 'UI.DataField', Value: capacityKWp,    Label: 'Capacity (kWp)'   },
      { $Type: 'UI.DataField', Value: projectManager_ID, Label: 'Project Manager'},
      { $Type: 'UI.DataField', Value: status,       Label: 'Status'           },
      { $Type: 'UI.DataField', Value: description, Label: 'Description'      }
    ]
  },

  UI.FieldGroup#DatesAndBudget: {
    Label : 'Dates and Budget',
    Data  : [
      { $Type: 'UI.DataField', Value: startDate,    Label: 'Start Date'    },
      { $Type: 'UI.DataField', Value: endDate,       Label: 'End Date'      },
      { $Type: 'UI.DataField', Value: currency,      Label: 'Currency'      },
      { $Type: 'UI.DataField', Value: budget,        Label: 'Total Budget'  },
      { $Type: 'UI.DataField', Value: spentAmount,   Label: 'Spent Amount'  }
    ]
  }
);

// ── FIELD-LEVEL ANNOTATIONS ────────────────────────────────────

annotate service.Projects with {
  projectCode  @title: 'Project Code'    @Common.FieldControl: #ReadOnly;
  projectName  @title: 'Project Name'    @mandatory;
  clientName   @title: 'Client Name'     @mandatory;
  location     @title: 'Site Location'   @mandatory;
  state        @title: 'State'           @mandatory;
  capacityKWp  @title: 'Capacity (kWp)'  @Measures.Unit: 'kWp';
  startDate    @title: 'Start Date'      @mandatory;
  endDate      @title: 'End Date';
  budget       @title: 'Budget'          @Measures.ISOCurrency: currency;
  spentAmount  @title: 'Spent Amount'    @Common.FieldControl: #ReadOnly  @Measures.ISOCurrency: currency;
  currency     @title: 'Currency';
  status       @title: 'Status'          @Common.FieldControl: #ReadOnly;
  description  @title: 'Description'     @UI.MultiLineText: true;
  projectManager @title: 'Project Manager'
    @Common.Text          : projectManager.userName
    @Common.TextArrangement: #TextOnly
    @Common.ValueList: {
      CollectionPath : 'Users',
      Parameters     : [
        { $Type: 'Common.ValueListParameterOut',         LocalDataProperty: projectManager_ID, ValueListProperty: 'ID'       },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'userName'                                        },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'role'                                            }
      ]
    };
}

// ── ACTIVE PROJECTS — list + object page annotations ─────────
// Used by EngineeringProjectsList and SeniorProjectsList targets.
// Same columns as Projects but bound to the ActiveProjects entity.
annotate service.ActiveProjects with @(

  UI.SelectionFields: [ state, projectManager_ID, startDate, endDate ],

  UI.LineItem: [
    { $Type: 'UI.DataField', Value: projectCode,  Label: 'Project Code',    ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: projectName,  Label: 'Project Name',    ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: clientName,   Label: 'Client',          ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: location,     Label: 'Location',        ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: capacityKWp,  Label: 'Capacity (kWp)',  ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: budget,       Label: 'Budget (INR)',    ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: startDate,    Label: 'Start Date',      ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: status,       Label: 'Status',          ![@UI.Importance]: #High   }
  ],

  UI.HeaderInfo: {
    TypeName      : 'Project',
    TypeNamePlural: 'Projects',
    Title         : { $Type: 'UI.DataField', Value: projectName },
    Description   : { $Type: 'UI.DataField', Value: projectCode }
  },

  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#APBudget',   Label: 'Budget'            },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#APCapacity', Label: 'Capacity'          }
  ],

  UI.DataPoint#APBudget: {
    Value: budget,
    Title: 'Total Budget',
    ValueFormat: { NumberOfFractionalDigits: 0 }
  },

  UI.DataPoint#APCapacity: {
    Value: capacityKWp,
    Title: 'Capacity (kWp)'
  },

  UI.Facets: [
    {
      $Type : 'UI.CollectionFacet',
      ID    : 'GeneralInfo',
      Label : 'General Information',
      Facets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#APProjectDetails', Label: 'Project Details'  },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#APDatesAndBudget', Label: 'Dates and Budget' }
      ]
    },
    { $Type: 'UI.ReferenceFacet', ID: 'BOQSection', Target: 'boqItems/@UI.LineItem',         Label: 'Bill of Quantity'  },
    { $Type: 'UI.ReferenceFacet', ID: 'MRSection',  Target: 'materialRequests/@UI.LineItem', Label: 'Material Requests' }
  ],

  UI.FieldGroup#APProjectDetails: {
    Label: 'Project Details',
    Data : [
      { $Type: 'UI.DataField', Value: projectCode,        Label: 'Project Code'    },
      { $Type: 'UI.DataField', Value: projectName,        Label: 'Project Name'    },
      { $Type: 'UI.DataField', Value: clientName,         Label: 'Client'          },
      { $Type: 'UI.DataField', Value: location,           Label: 'Location'        },
      { $Type: 'UI.DataField', Value: state,              Label: 'State'           },
      { $Type: 'UI.DataField', Value: capacityKWp,        Label: 'Capacity (kWp)' },
      { $Type: 'UI.DataField', Value: projectManager_ID,  Label: 'Project Manager' },
      { $Type: 'UI.DataField', Value: status,             Label: 'Status'          },
      { $Type: 'UI.DataField', Value: description,        Label: 'Description'     }
    ]
  },

  UI.FieldGroup#APDatesAndBudget: {
    Label: 'Dates and Budget',
    Data : [
      { $Type: 'UI.DataField', Value: startDate,   Label: 'Start Date'   },
      { $Type: 'UI.DataField', Value: endDate,     Label: 'End Date'     },
      { $Type: 'UI.DataField', Value: currency,    Label: 'Currency'     },
      { $Type: 'UI.DataField', Value: budget,      Label: 'Total Budget' },
      { $Type: 'UI.DataField', Value: spentAmount, Label: 'Spent Amount' }
    ]
  }
);

// ── SENIOR ACTIVE PROJECTS — identical annotations ────────────
// Separate entity alias so SeniorProjectsList route pattern resolves.
annotate service.SeniorActiveProjects with @(

  UI.SelectionFields: [ state, projectManager_ID, startDate, endDate ],

  UI.LineItem: [
    { $Type: 'UI.DataField', Value: projectCode,  Label: 'Project Code',    ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: projectName,  Label: 'Project Name',    ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: clientName,   Label: 'Client',          ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: location,     Label: 'Location',        ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: capacityKWp,  Label: 'Capacity (kWp)',  ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: budget,       Label: 'Budget (INR)',    ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: startDate,    Label: 'Start Date',      ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: status,       Label: 'Status',          ![@UI.Importance]: #High   }
  ],

  UI.HeaderInfo: {
    TypeName      : 'Project',
    TypeNamePlural: 'Projects',
    Title         : { $Type: 'UI.DataField', Value: projectName },
    Description   : { $Type: 'UI.DataField', Value: projectCode }
  },

  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SAPBudget',   Label: 'Budget'   },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SAPCapacity', Label: 'Capacity' }
  ],

  UI.DataPoint#SAPBudget: {
    Value: budget,
    Title: 'Total Budget',
    ValueFormat: { NumberOfFractionalDigits: 0 }
  },

  UI.DataPoint#SAPCapacity: {
    Value: capacityKWp,
    Title: 'Capacity (kWp)'
  },

  UI.Facets: [
    {
      $Type : 'UI.CollectionFacet',
      ID    : 'GeneralInfo',
      Label : 'General Information',
      Facets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#SAPProjectDetails', Label: 'Project Details'  },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#SAPDatesAndBudget', Label: 'Dates and Budget' }
      ]
    },
    { $Type: 'UI.ReferenceFacet', ID: 'BOQSection', Target: 'boqItems/@UI.LineItem',         Label: 'Bill of Quantity'  },
    { $Type: 'UI.ReferenceFacet', ID: 'MRSection',  Target: 'materialRequests/@UI.LineItem', Label: 'Material Requests' }
  ],

  UI.FieldGroup#SAPProjectDetails: {
    Label: 'Project Details',
    Data : [
      { $Type: 'UI.DataField', Value: projectCode,       Label: 'Project Code'    },
      { $Type: 'UI.DataField', Value: projectName,       Label: 'Project Name'    },
      { $Type: 'UI.DataField', Value: clientName,        Label: 'Client'          },
      { $Type: 'UI.DataField', Value: location,          Label: 'Location'        },
      { $Type: 'UI.DataField', Value: state,             Label: 'State'           },
      { $Type: 'UI.DataField', Value: capacityKWp,       Label: 'Capacity (kWp)' },
      { $Type: 'UI.DataField', Value: projectManager_ID, Label: 'Project Manager' },
      { $Type: 'UI.DataField', Value: status,            Label: 'Status'          },
      { $Type: 'UI.DataField', Value: description,       Label: 'Description'     }
    ]
  },

  UI.FieldGroup#SAPDatesAndBudget: {
    Label: 'Dates and Budget',
    Data : [
      { $Type: 'UI.DataField', Value: startDate,   Label: 'Start Date'   },
      { $Type: 'UI.DataField', Value: endDate,     Label: 'End Date'     },
      { $Type: 'UI.DataField', Value: currency,    Label: 'Currency'     },
      { $Type: 'UI.DataField', Value: budget,      Label: 'Total Budget' },
      { $Type: 'UI.DataField', Value: spentAmount, Label: 'Spent Amount' }
    ]
  }
);

// ── ACTIVE PROJECTS — field-level read-only (header locked for engineers) ──
annotate service.ActiveProjects with {
  projectCode    @Common.FieldControl: #ReadOnly;
  projectName    @Common.FieldControl: #ReadOnly;
  clientName     @Common.FieldControl: #ReadOnly;
  location       @Common.FieldControl: #ReadOnly;
  state          @Common.FieldControl: #ReadOnly;
  capacityKWp    @Common.FieldControl: #ReadOnly;
  projectManager @Common.FieldControl: #ReadOnly;
  status         @Common.FieldControl: #ReadOnly;
  description    @Common.FieldControl: #ReadOnly;
  startDate      @Common.FieldControl: #ReadOnly;
  endDate        @Common.FieldControl: #ReadOnly;
  currency       @Common.FieldControl: #ReadOnly;
  budget         @Common.FieldControl: #ReadOnly;
  spentAmount    @Common.FieldControl: #ReadOnly;
}

annotate service.SeniorActiveProjects with {
  projectCode    @Common.FieldControl: #ReadOnly;
  projectName    @Common.FieldControl: #ReadOnly;
  clientName     @Common.FieldControl: #ReadOnly;
  location       @Common.FieldControl: #ReadOnly;
  state          @Common.FieldControl: #ReadOnly;
  capacityKWp    @Common.FieldControl: #ReadOnly;
  projectManager @Common.FieldControl: #ReadOnly;
  status         @Common.FieldControl: #ReadOnly;
  description    @Common.FieldControl: #ReadOnly;
  startDate      @Common.FieldControl: #ReadOnly;
  endDate        @Common.FieldControl: #ReadOnly;
  currency       @Common.FieldControl: #ReadOnly;
  budget         @Common.FieldControl: #ReadOnly;
  spentAmount    @Common.FieldControl: #ReadOnly;
}

// ── STATUS DROPDOWN VALUE LIST ────────────────────────────────

annotate service.Projects with {
  status @Common.ValueListWithFixedValues: true
         @Common.ValueList: {
           CollectionPath: 'Projects',
           Parameters: [
             { $Type: 'Common.ValueListParameterOut', LocalDataProperty: status, ValueListProperty: 'status' }
           ]
         };
}

// ═══════════════════════════════════════════════════════════════
// BOQ ITEMS — List annotations (shown in object page section)
// ═══════════════════════════════════════════════════════════════

annotate service.BOQItems with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: lineNumber,    Label: '#'                },
    {
      $Type : 'UI.DataField',
      Value : material_ID,
      Label : 'Material',
      ![@UI.Importance]: #High
    },
    { $Type: 'UI.DataField', Value: description,   Label: 'Description'      },
    { $Type: 'UI.DataField', Value: uom,           Label: 'UOM'              },
    { $Type: 'UI.DataField', Value: plannedQty,    Label: 'Planned Qty'      },
    { $Type: 'UI.DataField', Value: estimatedRate, Label: 'Est. Rate (INR)'  },
    { $Type: 'UI.DataField', Value: estimatedValue,Label: 'Est. Value (INR)' },
    { $Type: 'UI.DataField', Value: requestedQty,  Label: 'Requested'        },
    { $Type: 'UI.DataField', Value: orderedQty,    Label: 'Ordered'          },
    { $Type: 'UI.DataField', Value: receivedQty,   Label: 'Received'         }
  ]
);

annotate service.BOQItems with {
  material @title: 'Material'
    @Common.Text           : material.description
    @Common.TextArrangement: #TextFirst
    @Common.ValueList: {
      CollectionPath: 'MaterialMaster',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut',         LocalDataProperty: material_ID,  ValueListProperty: 'ID'          },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'materialCode'                                  },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'description'                                   },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'uom'                                           }
      ]
    };
  plannedQty    @title: 'Planned Qty';
  estimatedRate @title: 'Estimated Rate';
  estimatedValue @title: 'Estimated Value' @Common.FieldControl: #ReadOnly;
  requestedQty  @title: 'Requested Qty'   @Common.FieldControl: #ReadOnly;
  orderedQty    @title: 'Ordered Qty'     @Common.FieldControl: #ReadOnly;
  receivedQty   @title: 'Received Qty'    @Common.FieldControl: #ReadOnly;
}

// ═══════════════════════════════════════════════════════════════
// MATERIAL REQUESTS — List annotations (shown in object page)
// ═══════════════════════════════════════════════════════════════

annotate service.MaterialRequests with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: requestNumber, Label: 'Request No.',  ![@UI.Importance]: #High  },
    { $Type: 'UI.DataField', Value: requestDate,   Label: 'Raised On',   ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: requiredDate,  Label: 'Required By', ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: requestedBy_ID,Label: 'Raised By',   ![@UI.Importance]: #Medium },
    {
      $Type            : 'UI.DataField',
      Value            : status,
      Label            : 'Status',
      ![@UI.Importance]: #High
    },
    { $Type: 'UI.DataField', Value: remarks,        Label: 'Remarks',    ![@UI.Importance]: #Low    }
  ],

  UI.Identification: [
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.submitRequest',
      Label  : 'Submit'
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.approveRequest',
      Label  : 'Approve'
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.rejectRequest',
      Label  : 'Reject'
    }
  ]
);

annotate service.MaterialRequests with {
  requestNumber  @title: 'Request Number'   @Common.FieldControl: #ReadOnly;
  requestDate    @title: 'Request Date';
  requiredDate   @title: 'Required By'      @mandatory;
  status         @title: 'Status'           @Common.FieldControl: #ReadOnly;
  remarks        @title: 'Remarks'          @UI.MultiLineText: true;
  requestedBy    @title: 'Requested By'
    @Common.Text           : requestedBy.userName
    @Common.TextArrangement: #TextOnly;
  approvedBy     @title: 'Approved By'
    @Common.Text           : approvedBy.userName
    @Common.TextArrangement: #TextOnly;
}

// ═══════════════════════════════════════════════════════════════
// MATERIAL REQUEST ITEMS — inline table in MR detail
// ═══════════════════════════════════════════════════════════════

annotate service.MaterialRequestItems with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: lineNumber,   Label: '#'           },
    { $Type: 'UI.DataField', Value: material_ID,  Label: 'Material'    },
    { $Type: 'UI.DataField', Value: description,  Label: 'Description' },
    { $Type: 'UI.DataField', Value: requestedQty, Label: 'Qty'         },
    { $Type: 'UI.DataField', Value: uom,          Label: 'UOM'         },
    { $Type: 'UI.DataField', Value: remarks,      Label: 'Remarks'     }
  ]
);

annotate service.MaterialRequestItems with {
  material @title: 'Material'
    @Common.Text           : material.description
    @Common.TextArrangement: #TextFirst
    @Common.ValueList: {
      CollectionPath: 'MaterialMaster',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut',         LocalDataProperty: material_ID,  ValueListProperty: 'ID'          },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'materialCode'                                  },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'description'                                   },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'uom'                                           }
      ]
    };
  requestedQty @title: 'Requested Qty' @mandatory;
  uom          @title: 'UOM'           @mandatory;
}
