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

  Capabilities: {
    UpdateRestrictions: { Updatable: true }
  },

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
  
  boqItems @(
    Capabilities.InsertRestrictions: { Insertable: true },
    Capabilities.DeleteRestrictions: { Deletable: true },
    Capabilities.UpdateRestrictions: { Updatable: true }
  );
  materialRequests @(
    Capabilities.InsertRestrictions: { Insertable: true },
    Capabilities.DeleteRestrictions: { Deletable: true },
    Capabilities.UpdateRestrictions: { Updatable: true }
  );
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

  materialRequests @(
    Capabilities.InsertRestrictions: { Insertable: false },
    Capabilities.DeleteRestrictions: { Deletable: false },
    Capabilities.UpdateRestrictions: { Updatable: true }
  );
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

annotate service.ActiveProjects_BOQItems with @(
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

annotate service.SeniorActiveProjects_BOQItems with @(
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
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: material_ID,  ValueListProperty: 'ID'          },
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

annotate service.ActiveProjects_BOQItems with {
  material @title: 'Material'
    @Common.Text           : material.description
    @Common.TextArrangement: #TextFirst
    @Common.ValueList: {
      CollectionPath: 'MaterialMaster',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: material_ID,  ValueListProperty: 'ID'          },
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

annotate service.SeniorActiveProjects_BOQItems with {
  material @title: 'Material'
    @Common.Text           : material.description
    @Common.TextArrangement: #TextFirst
    @Common.ValueList: {
      CollectionPath: 'MaterialMaster',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: material_ID,  ValueListProperty: 'ID'          },
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

  UI.SelectionFields: [ status, project_ID, requestedBy_ID ],

  UI.SelectionVariant#PendingApproval: {
    Text          : 'Pending Approval',
    SelectOptions : [{
      PropertyName : status,
      Ranges       : [{ Sign: #I, Option: #EQ, Low: 'SUBMITTED' }]
    }]
  },

  UI.LineItem: [
    { $Type: 'UI.DataField', Value: requestNumber, Label: 'Request No.',  ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: project_ID,    Label: 'Project',      ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: requestDate,   Label: 'Raised On',    ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: requiredDate,  Label: 'Required By',  ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: requestedBy_ID,Label: 'Raised By',    ![@UI.Importance]: #Medium },
    {
      $Type            : 'UI.DataFieldWithCriticality',
      Value            : status,
      Criticality      : criticality,
      Label            : 'Status',
      ![@UI.Importance]: #High
    },
    { $Type: 'UI.DataField', Value: remarks,        Label: 'Remarks',     ![@UI.Importance]: #Low    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.approveRequest',
      Label  : 'Approve',
      ![@UI.Importance]: #High
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.rejectRequest',
      Label  : 'Reject',
      ![@UI.Importance]: #High
    }
  ],

  UI.Identification: [
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.approveRequest',
      Label  : 'Approve',
      Criticality: #Positive
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.rejectRequest',
      Label  : 'Reject',
      Criticality: #Negative
    },
    {
      $Type  : 'UI.DataFieldForAction',
      Action : 'ProjectService.submitRequest',
      Label  : 'Submit for Approval'
    }
  ],

  UI.HeaderInfo: {
    TypeName      : 'Material Request',
    TypeNamePlural: 'Material Requests',
    Title         : { $Type: 'UI.DataField', Value: requestNumber },
    Description   : { $Type: 'UI.DataField', Value: project_ID   }
  },

  UI.DataPoint#MRStatus: {
    Value       : status,
    Title       : 'Status',
    Criticality : criticality
  },

  UI.DataPoint#RequiredBy: {
    Value : requiredDate,
    Title : 'Required By'
  },

  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#MRStatus',   Label: 'Status'      },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#RequiredBy', Label: 'Required By' }
  ],

  UI.Facets: [
    {
      $Type : 'UI.CollectionFacet',
      ID    : 'MRGeneralInfo',
      Label : 'Request Details',
      Facets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#MRRequestInfo', Label: 'Request Info'   },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#MRApprovalInfo', Label: 'Approval Info' }
      ]
    },
    {
      $Type  : 'UI.ReferenceFacet',
      ID     : 'MRItemsSection',
      Target : 'items/@UI.LineItem',
      Label  : 'Requested Materials'
    }
  ],

  UI.FieldGroup#MRRequestInfo: {
    Label: 'Request Information',
    Data : [
      { $Type: 'UI.DataField', Value: requestNumber,  Label: 'Request No.'            },
      { $Type: 'UI.DataField', Value: project_ID,     Label: 'Project'                },
      { $Type: 'UI.DataField', Value: requestDate,    Label: 'Request Date'           },
      { $Type: 'UI.DataField', Value: requiredDate,   Label: 'Required By'            },
      { $Type: 'UI.DataField', Value: priority,       Label: 'Priority'               },
      { $Type: 'UI.DataField', Value: requestedBy_ID, Label: 'Raised By'              },
      { $Type: 'UI.DataField', Value: siteLocation,   Label: 'Site / Work Area'       },
      { $Type: 'UI.DataField', Value: purpose,        Label: 'Purpose / Justification'},
      { $Type: 'UI.DataField', Value: remarks,        Label: 'Remarks'                }
    ]
  },

  UI.FieldGroup#MRApprovalInfo: {
    Label: 'Approval Details',
    Data : [
      { $Type: 'UI.DataField', Value: status,           Label: 'Status'            },
      { $Type: 'UI.DataField', Value: approvedBy_ID,    Label: 'Approved / Rejected By' },
      { $Type: 'UI.DataField', Value: approvalDate,     Label: 'Approval Date'     },
      { $Type: 'UI.DataField', Value: rejectionReason,  Label: 'Rejection Reason'  }
    ]
  }
);

annotate service.ActiveProjects_MaterialRequests with @(
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
    }
  ],

  Capabilities.UpdateRestrictions: { Updatable: true }
);

annotate service.SeniorActiveProjects_MaterialRequests with @(
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
      $Type       : 'UI.DataFieldForAction',
      Action      : 'ProjectService.approveRequest',
      Label       : 'Approve',
      Criticality : #Positive
    },
    {
      $Type       : 'UI.DataFieldForAction',
      Action      : 'ProjectService.rejectRequest',
      Label       : 'Reject',
      Criticality : #Negative
    }
  ],

  Capabilities.UpdateRestrictions: { Updatable: true }
);

annotate service.MaterialRequests with {
  requestNumber  @title: 'Request Number'           @Common.FieldControl: #ReadOnly;
  requestDate    @title: 'Request Date'             @Common.FieldControl: #ReadOnly;
  requiredDate   @title: 'Required By'              @mandatory;
  priority       @title: 'Priority'
    @Common.ValueListWithFixedValues: true
    @Common.ValueList: {
      CollectionPath: 'MaterialRequests',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut', LocalDataProperty: priority, ValueListProperty: 'priority' }
      ]
    };
  purpose        @title: 'Purpose / Justification'  @UI.MultiLineText: true;
  siteLocation   @title: 'Site / Work Area';
  status         @title: 'Status'                   @Common.FieldControl: #ReadOnly;
  remarks        @title: 'Remarks'                  @UI.MultiLineText: true;
  approvalDate   @title: 'Approval Date'            @Common.FieldControl: #ReadOnly;
  rejectionReason @title: 'Rejection Reason'        @UI.MultiLineText: true  @Common.FieldControl: #ReadOnly;
  requestedBy    @title: 'Requested By'             @Common.FieldControl: #ReadOnly;
  project @title: 'Project'
    @Common.Text           : project.projectName
    @Common.TextArrangement: #TextOnly
    @Common.ValueList: {
      CollectionPath : 'Projects',
      Parameters     : [
        { $Type: 'Common.ValueListParameterOut',         LocalDataProperty: project_ID, ValueListProperty: 'ID'          },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'projectName'                                 },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'projectCode'                                 }
      ]
    };
  requestedBy    @title: 'Requested By'
    @Common.Text           : requestedBy.userName
    @Common.TextArrangement: #TextOnly;
  approvedBy     @title: 'Approved / Rejected By'
    @Common.Text           : approvedBy.userName
    @Common.TextArrangement: #TextOnly;
}

annotate service.ActiveProjects_MaterialRequests with {
  requestNumber   @title: 'Request Number'    @Common.FieldControl: #ReadOnly;
  requestDate     @title: 'Request Date'      @Common.FieldControl: #ReadOnly;
  requiredDate    @title: 'Required By'       @mandatory;
  priority        @title: 'Priority'
    @Common.ValueListWithFixedValues: true
    @Common.ValueList: {
      CollectionPath: 'ActiveProjects_MaterialRequests',
      Parameters: [
        { $Type: 'Common.ValueListParameterOut', LocalDataProperty: priority, ValueListProperty: 'priority' }
      ]
    };
  purpose         @title: 'Purpose / Justification'  @UI.MultiLineText: true;
  siteLocation    @title: 'Site / Work Area';
  status          @title: 'Status'            @Common.FieldControl: #ReadOnly;
  remarks         @title: 'Remarks'           @UI.MultiLineText: true;
  approvalDate    @title: 'Approval Date'     @Common.FieldControl: #ReadOnly;
  rejectionReason @title: 'Rejection Reason'  @Common.FieldControl: #ReadOnly  @UI.MultiLineText: true;
  requestedBy @title: 'Requested By'
    @Common.FieldControl: #ReadOnly
    @Common.Text           : requestedBy.userName
    @Common.TextArrangement: #TextOnly;
  approvedBy  @title: 'Reviewed By'
    @Common.FieldControl: #ReadOnly
    @Common.Text           : approvedBy.userName
    @Common.TextArrangement: #TextOnly;
}

annotate service.ActiveProjects_MaterialRequests with @(
  UI.HeaderInfo: {
    TypeName      : 'Material Request',
    TypeNamePlural: 'Material Requests',
    Title         : { $Type: 'UI.DataField', Value: requestNumber },
    Description   : { $Type: 'UI.DataField', Value: status        }
  },

  UI.DataPoint#APMRStatus: {
    Value       : status,
    Title       : 'Status',
    Criticality : criticality
  },

  UI.DataPoint#APMRRequired: {
    Value : requiredDate,
    Title : 'Required By'
  },

  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#APMRStatus',   Label: 'Status'      },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#APMRRequired', Label: 'Required By' }
  ],

  UI.Facets: [
    {
      $Type : 'UI.CollectionFacet',
      ID    : 'APMRGeneralInfo',
      Label : 'Request Details',
      Facets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#APMRRequestInfo', Label: 'Request Info'   },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#APMRApproval',    Label: 'Approval Info'  }
      ]
    },
    {
      $Type  : 'UI.ReferenceFacet',
      ID     : 'APMRItemsSection',
      Target : 'items/@UI.LineItem',
      Label  : 'Requested Materials'
    }
  ],

  UI.FieldGroup#APMRRequestInfo: {
    Label: 'Request Information',
    Data : [
      { $Type: 'UI.DataField', Value: requestNumber,  Label: 'Request No.'           },
      { $Type: 'UI.DataField', Value: requestDate,    Label: 'Raised On'             },
      { $Type: 'UI.DataField', Value: requiredDate,   Label: 'Required By'           },
      { $Type: 'UI.DataField', Value: priority,       Label: 'Priority'              },
      { $Type: 'UI.DataField', Value: requestedBy_ID, Label: 'Raised By'             },
      { $Type: 'UI.DataField', Value: siteLocation,   Label: 'Site / Work Area'      },
      { $Type: 'UI.DataField', Value: purpose,        Label: 'Purpose / Justification'},
      { $Type: 'UI.DataField', Value: remarks,        Label: 'Remarks'               }
    ]
  },

  UI.FieldGroup#APMRApproval: {
    Label: 'Approval Details',
    Data : [
      { $Type: 'UI.DataField', Value: status,           Label: 'Status'           },
      { $Type: 'UI.DataField', Value: approvedBy_ID,    Label: 'Reviewed By'      },
      { $Type: 'UI.DataField', Value: approvalDate,     Label: 'Approval Date'    },
      { $Type: 'UI.DataField', Value: rejectionReason,  Label: 'Rejection Reason' }
    ]
  }
);

annotate service.SeniorActiveProjects_MaterialRequests with {
  requestNumber   @title: 'Request Number'    @Common.FieldControl: #ReadOnly;
  requestDate     @title: 'Request Date'      @Common.FieldControl: #ReadOnly;
  requiredDate    @title: 'Required By'       @mandatory;
  priority        @title: 'Priority';
  purpose         @title: 'Purpose / Justification'  @UI.MultiLineText: true;
  siteLocation    @title: 'Site / Work Area';
  status          @title: 'Status'            @Common.FieldControl: #ReadOnly;
  remarks         @title: 'Remarks'           @UI.MultiLineText: true;
  approvalDate    @title: 'Approval Date'     @Common.FieldControl: #ReadOnly;
  rejectionReason @title: 'Rejection Reason'  @Common.FieldControl: #ReadOnly  @UI.MultiLineText: true;
  requestedBy @title: 'Requested By'
    @Common.FieldControl: #ReadOnly
    @Common.Text           : requestedBy.userName
    @Common.TextArrangement: #TextOnly;
  approvedBy  @title: 'Reviewed By'
    @Common.FieldControl: #ReadOnly
    @Common.Text           : approvedBy.userName
    @Common.TextArrangement: #TextOnly;
}

annotate service.SeniorActiveProjects_MaterialRequests with @(
  UI.HeaderInfo: {
    TypeName      : 'Material Request',
    TypeNamePlural: 'Material Requests',
    Title         : { $Type: 'UI.DataField', Value: requestNumber },
    Description   : { $Type: 'UI.DataField', Value: status        }
  },

  UI.DataPoint#SAPMRStatus: {
    Value       : status,
    Title       : 'Status',
    Criticality : criticality
  },

  UI.DataPoint#SAPMRRequired: {
    Value : requiredDate,
    Title : 'Required By'
  },

  UI.HeaderFacets: [
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SAPMRStatus',   Label: 'Status'      },
    { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SAPMRRequired', Label: 'Required By' }
  ],

  UI.Facets: [
    {
      $Type : 'UI.CollectionFacet',
      ID    : 'SAPMRGeneralInfo',
      Label : 'Request Details',
      Facets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#SAPMRRequestInfo', Label: 'Request Info'   },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#SAPMRApproval',    Label: 'Approval Info'  }
      ]
    },
    {
      $Type  : 'UI.ReferenceFacet',
      ID     : 'SAPMRItemsSection',
      Target : 'items/@UI.LineItem',
      Label  : 'Requested Materials'
    }
  ],

  UI.FieldGroup#SAPMRRequestInfo: {
    Label: 'Request Information',
    Data : [
      { $Type: 'UI.DataField', Value: requestNumber,  Label: 'Request No.'            },
      { $Type: 'UI.DataField', Value: requestDate,    Label: 'Raised On'              },
      { $Type: 'UI.DataField', Value: requiredDate,   Label: 'Required By'            },
      { $Type: 'UI.DataField', Value: priority,       Label: 'Priority'               },
      { $Type: 'UI.DataField', Value: requestedBy_ID, Label: 'Raised By'              },
      { $Type: 'UI.DataField', Value: siteLocation,   Label: 'Site / Work Area'       },
      { $Type: 'UI.DataField', Value: purpose,        Label: 'Purpose / Justification'},
      { $Type: 'UI.DataField', Value: remarks,        Label: 'Remarks'                }
    ]
  },

  UI.FieldGroup#SAPMRApproval: {
    Label: 'Approval Details',
    Data : [
      { $Type: 'UI.DataField', Value: status,           Label: 'Status'           },
      { $Type: 'UI.DataField', Value: approvedBy_ID,    Label: 'Reviewed By'      },
      { $Type: 'UI.DataField', Value: approvalDate,     Label: 'Approval Date'    },
      { $Type: 'UI.DataField', Value: rejectionReason,  Label: 'Rejection Reason' }
    ]
  }
);

// ═══════════════════════════════════════════════════════════════
// MATERIAL REQUEST ITEMS — inline table in MR detail
// ═══════════════════════════════════════════════════════════════

annotate service.MaterialRequestItems with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: lineNumber,    Label: '#',               ![@UI.Importance]: #Low    },
    { $Type: 'UI.DataField', Value: material_ID,   Label: 'Material',        ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: description,   Label: 'Description',     ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: requestedQty,  Label: 'Qty',             ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: uom,           Label: 'UOM',             ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: estimatedRate, Label: 'Unit Rate (INR)', ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: estimatedValue,Label: 'Est. Value (INR)',![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: remarks,       Label: 'Remarks',         ![@UI.Importance]: #Low    }
  ]
);

annotate service.ActiveProjects_MaterialRequestItems with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: lineNumber,    Label: '#',               ![@UI.Importance]: #Low    },
    { $Type: 'UI.DataField', Value: material_ID,   Label: 'Material',        ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: description,   Label: 'Description',     ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: requestedQty,  Label: 'Qty',             ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: uom,           Label: 'UOM',             ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: estimatedRate, Label: 'Unit Rate (INR)', ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: estimatedValue,Label: 'Est. Value (INR)',![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: remarks,       Label: 'Remarks',         ![@UI.Importance]: #Low    }
  ]
);

annotate service.SeniorActiveProjects_MaterialRequestItems with @(
  UI.LineItem: [
    { $Type: 'UI.DataField', Value: lineNumber,    Label: '#',               ![@UI.Importance]: #Low    },
    { $Type: 'UI.DataField', Value: material_ID,   Label: 'Material',        ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: description,   Label: 'Description',     ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: requestedQty,  Label: 'Qty',             ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: uom,           Label: 'UOM',             ![@UI.Importance]: #High   },
    { $Type: 'UI.DataField', Value: estimatedRate, Label: 'Unit Rate (INR)', ![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: estimatedValue,Label: 'Est. Value (INR)',![@UI.Importance]: #Medium },
    { $Type: 'UI.DataField', Value: remarks,       Label: 'Remarks',         ![@UI.Importance]: #Low    }
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
  requestedQty   @title: 'Requested Qty'      @mandatory;
  uom            @title: 'UOM'                @mandatory;
  estimatedRate  @title: 'Unit Rate (INR)';
  estimatedValue @title: 'Est. Value (INR)'   @Common.FieldControl: #ReadOnly;
  lineNumber     @title: '#'                  @Common.FieldControl: #ReadOnly;
}

annotate service.ActiveProjects_MaterialRequestItems with {
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
  requestedQty   @title: 'Requested Qty'    @mandatory;
  uom            @title: 'UOM'              @mandatory;
  estimatedRate  @title: 'Unit Rate (INR)';
  estimatedValue @title: 'Est. Value (INR)' @Common.FieldControl: #ReadOnly;
  lineNumber     @title: '#'               @Common.FieldControl: #ReadOnly;
}

annotate service.SeniorActiveProjects_MaterialRequestItems with {
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
  requestedQty   @title: 'Requested Qty'    @mandatory;
  uom            @title: 'UOM'              @mandatory;
  estimatedRate  @title: 'Unit Rate (INR)';
  estimatedValue @title: 'Est. Value (INR)' @Common.FieldControl: #ReadOnly;
  lineNumber     @title: '#'               @Common.FieldControl: #ReadOnly;
}
