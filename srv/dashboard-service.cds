using solar.epc as epc from '../db/schema';

// ═══════════════════════════════════════════════════════════════
// DASHBOARD SERVICE  — CAP OData V4
// Covers: Analytics, KPIs, Charts, Management Summary
// Roles: Management, Project Manager, Procurement Officer, Finance Officer
// ═══════════════════════════════════════════════════════════════

@requires: ['Management','ProjectManager','FinanceOfficer','ProcurementOfficer']
service DashboardService @(path: '/dashboard') {

  // ── PROJECT SUMMARY VIEW ──────────────────────────────────────
  @readonly
  view ProjectSummary as select from epc.Projects {
    key ID,
    projectCode,
    projectName,
    clientName,
    location,
    state,
    capacityKWp,
    budget,
    spentAmount,
    currency,
    status,
    startDate,
    endDate,
    (budget - spentAmount)       as remainingBudget : Decimal(18,2),
    case when budget > 0
      then round((spentAmount / budget) * 100, 2)
      else 0
    end                          as budgetUtilizationPct : Decimal(5,2)
  };

  // ── PROCUREMENT KPI VIEW ──────────────────────────────────────
  @readonly
  view ProcurementKPI as select from epc.PurchaseOrders {
    key project.ID             as projectId,
        project.projectCode    as projectCode,
        project.projectName    as projectName,
        count(ID)              as totalPOs       : Integer,
        sum(grandTotal)        as totalPOValue   : Decimal(18,2),
        count(case when status = 'CONFIRMED'         then 1 end) as confirmedPOs  : Integer,
        count(case when status = 'FULLY_DELIVERED'   then 1 end) as deliveredPOs  : Integer,
        count(case when status = 'CANCELLED'         then 1 end) as cancelledPOs  : Integer
  } group by project.ID, project.projectCode, project.projectName;

  // ── DELIVERY PERFORMANCE VIEW ─────────────────────────────────
  @readonly
  view DeliveryPerformance as select from epc.Deliveries {
    key purchaseOrder.vendor.ID       as vendorId,
        purchaseOrder.vendor.vendorName as vendorName,
        count(ID)                     as totalDeliveries  : Integer,
        count(case when status = 'DELIVERED' and delayDays = 0 then 1 end) as onTime : Integer,
        count(case when delayDays > 0 then 1 end)         as delayed   : Integer,
        avg(delayDays)                as avgDelayDays     : Decimal(5,2),
        max(delayDays)                as maxDelayDays     : Integer
  } group by purchaseOrder.vendor.ID, purchaseOrder.vendor.vendorName;

  // ── RECEIPT QUALITY VIEW ──────────────────────────────────────
  @readonly
  view ReceiptQuality as select from epc.MaterialReceiptItems {
    key receipt.purchaseOrder.project.ID   as projectId,
        receipt.purchaseOrder.project.projectCode as projectCode,
        sum(dispatchedQty)  as totalDispatched : Decimal(13,3),
        sum(acceptedQty)    as totalAccepted   : Decimal(13,3),
        sum(rejectedQty)    as totalRejected   : Decimal(13,3),
        case when sum(dispatchedQty) > 0
          then round((sum(rejectedQty) / sum(dispatchedQty)) * 100, 2)
          else 0
        end                 as rejectionRate  : Decimal(5,2)
  } group by receipt.purchaseOrder.project.ID, receipt.purchaseOrder.project.projectCode;

  // ── INVOICE MATCHING STATUS VIEW ─────────────────────────────
  @readonly
  view InvoiceMatchingSummary as select from epc.Invoices {
    key vendor.ID                       as vendorId,
        vendor.vendorName               as vendorName,
        count(ID)                       as totalInvoices : Integer,
        sum(totalAmount)                as totalValue    : Decimal(18,2),
        count(case when status = 'MATCHED'  then 1 end) as matched     : Integer,
        count(case when status = 'MISMATCH' then 1 end) as mismatched  : Integer,
        count(case when status = 'PAID'     then 1 end) as paid        : Integer,
        count(case when status = 'APPROVED' then 1 end) as approved    : Integer
  } group by vendor.ID, vendor.vendorName;

  // ── VENDOR PERFORMANCE SUMMARY VIEW ──────────────────────────
  @readonly
  view VendorPerformanceSummary as select from epc.VendorMaster {
    key ID,
    vendorCode,
    vendorName,
    performanceScore,
    totalOrders,
    onTimeDeliveries,
    qualityScore,
    isActive,
    case when totalOrders > 0
      then round((onTimeDeliveries / totalOrders) * 100, 2)
      else 0
    end as onTimeDeliveryPct : Decimal(5,2)
  } where isActive = true;

  // ── MATERIAL CONSUMPTION VIEW ─────────────────────────────────
  @readonly
  view MaterialConsumption as select from epc.BOQItems {
    key ID,
        project.projectCode as projectCode,
        material.materialCode as materialCode,
        material.description  as materialDescription,
        material.category     as category,
        uom,
        plannedQty,
        requestedQty,
        orderedQty,
        receivedQty,
        (plannedQty - receivedQty) as pendingQty       : Decimal(13,3),
        case when plannedQty > 0
          then round((receivedQty / plannedQty) * 100, 2)
          else 0
        end                        as completionPct    : Decimal(5,2)
  };

  // ── THREE-WAY MATCH SUMMARY ───────────────────────────────────
  @readonly
  view ThreeWayMatchSummary as select from epc.ThreeWayMatchResults {
    key invoice.purchaseOrder.project.ID       as projectId,
        invoice.purchaseOrder.project.projectCode as projectCode,
        count(ID)                              as totalLines    : Integer,
        count(case when overallStatus = 'MATCHED'           then 1 end) as matched       : Integer,
        count(case when overallStatus = 'QUANTITY_MISMATCH' then 1 end) as qtyMismatch   : Integer,
        count(case when overallStatus = 'PRICE_MISMATCH'    then 1 end) as priceMismatch : Integer,
        count(case when overallStatus = 'BOTH_MISMATCH'     then 1 end) as bothMismatch  : Integer,
        sum(abs(valueVariance))                as totalVariance : Decimal(18,2)
  } group by invoice.purchaseOrder.project.ID, invoice.purchaseOrder.project.projectCode;

  // ── KPI FUNCTION: OVERALL PROJECT HEALTH ─────────────────────
  function getProjectHealth(projectId: UUID) returns {
    projectCode       : String(20);
    budgetUtilization : Decimal(5,2);
    procurementStatus : String(50);
    deliveryStatus    : String(50);
    invoiceStatus     : String(50);
    overallHealth     : String(20);
  };
}

// ─── ANNOTATIONS: DASHBOARD VIEWS ────────────────────────────

annotate DashboardService.ProjectSummary with @(
  UI.LineItem: [
    { Value: projectCode,          Label: 'Project Code'        },
    { Value: projectName,          Label: 'Project Name'        },
    { Value: status,               Label: 'Status'              },
    { Value: capacityKWp,          Label: 'Capacity (kWp)'      },
    { Value: budget,               Label: 'Budget'              },
    { Value: spentAmount,          Label: 'Spent'               },
    { Value: remainingBudget,      Label: 'Remaining'           },
    { Value: budgetUtilizationPct, Label: 'Budget Used %'       }
  ]
);

annotate DashboardService.VendorPerformanceSummary with @(
  UI.LineItem: [
    { Value: vendorCode,        Label: 'Vendor Code'       },
    { Value: vendorName,        Label: 'Vendor Name'       },
    { Value: totalOrders,       Label: 'Total Orders'      },
    { Value: onTimeDeliveries,  Label: 'On-Time'           },
    { Value: onTimeDeliveryPct, Label: 'OTD %'             },
    { Value: qualityScore,      Label: 'Quality Score'     },
    { Value: performanceScore,  Label: 'Overall Score'     }
  ]
);
