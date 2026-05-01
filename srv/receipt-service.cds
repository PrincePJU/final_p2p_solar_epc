using solar.epc as epc from '../db/schema';

// ═══════════════════════════════════════════════════════════════
// RECEIPT SERVICE  — CAP OData V4  (simulates RAP pattern)
// Covers: Material Receipts (GRN), Damaged Material Claims
// Roles: Site Engineer, Procurement Officer
// ═══════════════════════════════════════════════════════════════

@requires: ['SiteEngineer','ProcurementOfficer','Management']
service ReceiptService @(path: '/receipt') {

  // ── READ-ONLY REFERENCES ──────────────────────────────────────
  @readonly
  entity MaterialMaster as projection on epc.MaterialMaster;

  @readonly
  entity VendorMaster as projection on epc.VendorMaster;

  @readonly
  entity PurchaseOrders as projection on epc.PurchaseOrders;

  @readonly
  entity PurchaseOrderItems as projection on epc.PurchaseOrderItems;

  @readonly
  entity Deliveries as projection on epc.Deliveries;

  @readonly
  entity DeliveryItems as projection on epc.DeliveryItems;

  @readonly
  entity Users as projection on epc.Users;

  // ── MATERIAL RECEIPTS ─────────────────────────────────────────
  @odata.draft.enabled
  entity MaterialReceipts as projection on epc.MaterialReceipts {
    *,
    delivery      : redirected to Deliveries,
    purchaseOrder : redirected to PurchaseOrders,
    receivedBy    : redirected to Users,
    verifiedBy    : redirected to Users,
    items         : redirected to MaterialReceiptItems,
    damagedItems  : redirected to DamagedMaterials
  } actions {
    action verifyReceipt(verificationRemarks: String(500)) returns MaterialReceipts;
    action rejectReceipt(rejectionReason: String(500))     returns MaterialReceipts;
  };

  entity MaterialReceiptItems as projection on epc.MaterialReceiptItems {
    *,
    receipt      : redirected to MaterialReceipts,
    deliveryItem : redirected to DeliveryItems,
    poItem       : redirected to PurchaseOrderItems,
    material     : redirected to MaterialMaster
  };

  // ── DAMAGED MATERIALS ─────────────────────────────────────────
  entity DamagedMaterials as projection on epc.DamagedMaterials {
    *,
    receipt     : redirected to MaterialReceipts,
    receiptItem : redirected to MaterialReceiptItems,
    material    : redirected to MaterialMaster
  } actions {
    action raiseClaim(claimAmount: Decimal(18,2)) returns DamagedMaterials;
    action settleClaim(settlementAmount: Decimal(18,2), response: String(500)) returns DamagedMaterials;
    action rejectClaim(reason: String(500))        returns DamagedMaterials;
  };
}

// ─── ANNOTATIONS: MATERIAL RECEIPTS ───────────────────────────

annotate ReceiptService.MaterialReceipts with @(
  UI.Identification: [
    { $Type: 'UI.DataFieldForAction', Action: 'ReceiptService.verifyReceipt', Label: 'Verify Receipt'  },
    { $Type: 'UI.DataFieldForAction', Action: 'ReceiptService.rejectReceipt', Label: 'Reject Receipt'  }
  ],
  UI.LineItem: [
    { Value: receiptNumber,   Label: 'GRN Number'      },
    { Value: delivery_ID,     Label: 'Delivery'        },
    { Value: purchaseOrder_ID,Label: 'PO Number'       },
    { Value: receiptDate,     Label: 'Receipt Date'    },
    { Value: receivedBy_ID,   Label: 'Received By'     },
    { Value: status,          Label: 'Status'          },
    { Value: verifiedBy_ID,   Label: 'Verified By'     },
    { Value: verificationDate,Label: 'Verified On'     }
  ],
  UI.SelectionFields: [ status, purchaseOrder_ID, receiptDate ],
  UI.HeaderInfo: {
    TypeName      : 'Material Receipt (GRN)',
    TypeNamePlural: 'Material Receipts',
    Title         : { Value: receiptNumber },
    Description   : { Value: status }
  },
  UI.Facets: [
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Receipt Header',
      Target: '@UI.FieldGroup#Header'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Received Items',
      Target: 'items/@UI.LineItem'
    },
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Damaged Materials',
      Target: 'damagedItems/@UI.LineItem'
    }
  ],
  UI.FieldGroup#Header: {
    Label: 'Receipt Header',
    Data : [
      { Value: receiptNumber    },
      { Value: delivery_ID      },
      { Value: purchaseOrder_ID },
      { Value: receiptDate      },
      { Value: receivedBy_ID    },
      { Value: status           },
      { Value: overallRemarks   },
      { Value: verifiedBy_ID    },
      { Value: verificationDate }
    ]
  }
);

annotate ReceiptService.MaterialReceiptItems with @(
  UI.LineItem: [
    { Value: lineNumber,   Label: 'Line'          },
    { Value: material_ID,  Label: 'Material'      },
    { Value: description,  Label: 'Description'   },
    { Value: dispatchedQty,Label: 'Dispatched Qty'},
    { Value: receivedQty,  Label: 'Received Qty'  },
    { Value: acceptedQty,  Label: 'Accepted Qty'  },
    { Value: rejectedQty,  Label: 'Rejected Qty'  },
    { Value: uom,          Label: 'UOM'           },
    { Value: condition,    Label: 'Condition'     },
    { Value: remarks,      Label: 'Remarks'       }
  ]
);

annotate ReceiptService.DamagedMaterials with @(
  UI.Identification: [
    { $Type: 'UI.DataFieldForAction', Action: 'ReceiptService.raiseClaim',  Label: 'Raise Claim'   },
    { $Type: 'UI.DataFieldForAction', Action: 'ReceiptService.settleClaim', Label: 'Settle Claim'  },
    { $Type: 'UI.DataFieldForAction', Action: 'ReceiptService.rejectClaim', Label: 'Reject Claim'  }
  ],
  UI.LineItem: [
    { Value: material_ID,   Label: 'Material'      },
    { Value: damagedQty,    Label: 'Damaged Qty'   },
    { Value: uom,           Label: 'UOM'           },
    { Value: damageType,    Label: 'Damage Type'   },
    { Value: description,   Label: 'Description'   },
    { Value: claimStatus,   Label: 'Claim Status'  },
    { Value: claimAmount,   Label: 'Claim Amount'  },
    { Value: resolvedDate,  Label: 'Resolved Date' }
  ],
  UI.Facets: [
    {
      $Type : 'UI.ReferenceFacet',
      Label : 'Damage Details',
      Target: '@UI.FieldGroup#Damage'
    }
  ],
  UI.FieldGroup#Damage: {
    Label: 'Damage Details',
    Data : [
      { Value: material_ID    },
      { Value: damagedQty     },
      { Value: uom            },
      { Value: damageType     },
      { Value: description    },
      { Value: photoReference },
      { Value: claimStatus    },
      { Value: claimAmount    },
      { Value: vendorResponse },
      { Value: resolvedDate   }
    ]
  }
);
