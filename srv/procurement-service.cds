using solar.epc as epc from '../db/schema';

// ═══════════════════════════════════════════════════════════════
// PROCUREMENT SERVICE  — CAP OData V4
// Covers: Purchase Orders, Deliveries
// Roles: Procurement Officer, Project Manager, Site Engineer
// ═══════════════════════════════════════════════════════════════

@requires: ['ProcurementOfficer','Management','ProjectManager','SiteEngineer']
service ProcurementService @(path: '/procurement') {

  // ── READ-ONLY REFERENCES ──────────────────────────────────────
  @readonly
  entity MaterialMaster as projection on epc.MaterialMaster;

  @readonly
  entity VendorMaster as projection on epc.VendorMaster;

  @readonly
  entity Projects as projection on epc.Projects;

  @readonly
  entity MaterialRequests as projection on epc.MaterialRequests;

  @readonly
  entity VendorQuotations as projection on epc.VendorQuotations;

  // ── PURCHASE ORDERS ───────────────────────────────────────────
  @odata.draft.enabled
  entity PurchaseOrders as projection on epc.PurchaseOrders {
    *,
    project         : redirected to Projects,
    vendor          : redirected to VendorMaster,
    quotation       : redirected to VendorQuotations,
    materialRequest : redirected to MaterialRequests,
    approvedBy      : redirected to Users,
    items           : redirected to PurchaseOrderItems,
    deliveries      : redirected to Deliveries
  } actions {
    action confirmPO()                       returns PurchaseOrders;
    action cancelPO(reason: String(500))     returns PurchaseOrders;
    action closePO()                         returns PurchaseOrders;
  };

  entity PurchaseOrderItems as projection on epc.PurchaseOrderItems {
    *,
    purchaseOrder : redirected to PurchaseOrders,
    material      : redirected to MaterialMaster
  };

  // ── DELIVERIES ────────────────────────────────────────────────
  // Draft is inherited from the parent PurchaseOrders composition
  entity Deliveries as projection on epc.Deliveries {
    *,
    purchaseOrder : redirected to PurchaseOrders,
    vendor        : redirected to VendorMaster,
    items         : redirected to DeliveryItems
  } actions {
    action markInTransit()                       returns Deliveries;
    action markDelivered(actualDate: Date)       returns Deliveries;
    action markDelayed(reason: String(500), newDate: Date) returns Deliveries;
  };

  entity DeliveryItems as projection on epc.DeliveryItems {
    *,
    delivery : redirected to Deliveries,
    poItem   : redirected to PurchaseOrderItems,
    material : redirected to MaterialMaster
  };

  @readonly
  entity Users as projection on epc.Users;
}

// ─── ANNOTATIONS: PURCHASE ORDERS ────────────────────────────

annotate ProcurementService.PurchaseOrders with @(
  UI.LineItem: [
    { Value: poNumber,      Label: 'PO Number'    },
    { Value: project_ID,    Label: 'Project'      },
    { Value: vendor_ID,     Label: 'Vendor'       },
    { Value: poDate,        Label: 'PO Date'      },
    { Value: deliveryDate,  Label: 'Delivery Date'},
    { Value: grandTotal,    Label: 'Grand Total'  },
    { Value: currency,      Label: 'Currency'     },
    { Value: status,        Label: 'Status'       }
  ],
  UI.SelectionFields: [ status, project_ID, vendor_ID, poDate ],
  UI.HeaderInfo: {
    TypeName      : 'Purchase Order',
    TypeNamePlural: 'Purchase Orders',
    Title         : { Value: poNumber },
    Description   : { Value: vendor_ID }
  },
  UI.Facets: [
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'PO Header',
      Target: '@UI.FieldGroup#Header'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Financial Details',
      Target: '@UI.FieldGroup#Financials'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'PO Line Items',
      Target: 'items/@UI.LineItem'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Deliveries',
      Target: 'deliveries/@UI.LineItem'
    }
  ],
  UI.FieldGroup#Header: {
    Label: 'PO Header',
    Data : [
      { Value: poNumber        },
      { Value: project_ID      },
      { Value: vendor_ID       },
      { Value: materialRequest_ID },
      { Value: quotation_ID    },
      { Value: poDate          },
      { Value: deliveryDate    },
      { Value: paymentTerms    },
      { Value: deliveryAddress },
      { Value: status          },
      { Value: approvedBy_ID   },
      { Value: approvalDate    },
      { Value: remarks         }
    ]
  },
  UI.FieldGroup#Financials: {
    Label: 'Financials',
    Data : [
      { Value: currency   },
      { Value: subtotal   },
      { Value: taxAmount  },
      { Value: grandTotal }
    ]
  }
);

annotate ProcurementService.PurchaseOrderItems with @(
  UI.LineItem: [
    { Value: lineNumber,   Label: 'Line'         },
    { Value: material_ID,  Label: 'Material'     },
    { Value: description,  Label: 'Description'  },
    { Value: orderedQty,   Label: 'Ordered Qty'  },
    { Value: uom,          Label: 'UOM'          },
    { Value: unitPrice,    Label: 'Unit Price'   },
    { Value: taxPercent,   Label: 'Tax %'        },
    { Value: taxAmount,    Label: 'Tax Amount'   },
    { Value: totalAmount,  Label: 'Line Total'   },
    { Value: deliveredQty, Label: 'Delivered Qty'},
    { Value: pendingQty,   Label: 'Pending Qty'  }
  ]
);

// ─── ANNOTATIONS: DELIVERIES ──────────────────────────────────

annotate ProcurementService.Deliveries with @(
  UI.LineItem: [
    { Value: deliveryNumber,  Label: 'Delivery No.'  },
    { Value: purchaseOrder_ID,Label: 'PO Number'     },
    { Value: vendor_ID,       Label: 'Vendor'        },
    { Value: scheduledDate,   Label: 'Scheduled Date'},
    { Value: actualDate,      Label: 'Actual Date'   },
    { Value: status,          Label: 'Status'        },
    { Value: delayDays,       Label: 'Delay Days'    },
    { Value: vehicleNumber,   Label: 'Vehicle No.'   }
  ],
  UI.SelectionFields: [ status, purchaseOrder_ID, scheduledDate ],
  UI.HeaderInfo: {
    TypeName      : 'Delivery',
    TypeNamePlural: 'Deliveries',
    Title         : { Value: deliveryNumber },
    Description   : { Value: status }
  },
  UI.Facets: [
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Delivery Details',
      Target: '@UI.FieldGroup#Details'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Transport Details',
      Target: '@UI.FieldGroup#Transport'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Delivery Items',
      Target: 'items/@UI.LineItem'
    }
  ],
  UI.FieldGroup#Details: {
    Label: 'Delivery Details',
    Data : [
      { Value: deliveryNumber   },
      { Value: purchaseOrder_ID },
      { Value: vendor_ID        },
      { Value: scheduledDate    },
      { Value: actualDate       },
      { Value: status           },
      { Value: delayDays        },
      { Value: delayReason      },
      { Value: siteContact      },
      { Value: remarks          }
    ]
  },
  UI.FieldGroup#Transport: {
    Label: 'Transport Details',
    Data : [
      { Value: vehicleNumber    },
      { Value: driverName       },
      { Value: driverPhone      },
      { Value: eWayBillNumber   },
      { Value: invoiceReference }
    ]
  }
);

annotate ProcurementService.DeliveryItems with @(
  UI.LineItem: [
    { Value: lineNumber,    Label: 'Line'          },
    { Value: material_ID,   Label: 'Material'      },
    { Value: description,   Label: 'Description'   },
    { Value: dispatchedQty, Label: 'Dispatched Qty'},
    { Value: uom,           Label: 'UOM'           }
  ]
);
