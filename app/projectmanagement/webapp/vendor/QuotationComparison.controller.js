sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/ui/core/Item"
], function (Controller, JSONModel, MessageToast, MessageBox, Item) {
    "use strict";

    // ── Helpers ───────────────────────────────────────────────────────────────

    function _statusState(status) {
        const map = {
            DRAFT            : "None",
            SUBMITTED        : "Warning",
            UNDER_EVALUATION : "Warning",
            SELECTED         : "Success",
            REJECTED         : "Error"
        };
        return map[status] || "None";
    }

    function _priceState(rank) {
        if (rank === 1) return "Success";
        if (rank === 2) return "Warning";
        return "Error";
    }

    function _leadDaysState(days, median) {
        if (days <= median * 0.9) return "Success";
        if (days >= median * 1.2) return "Error";
        return "None";
    }

    function _scoreState(score) {
        if (score >= 7.5) return "Success";
        if (score >= 5)   return "Warning";
        return "Error";
    }

    // ═════════════════════════════════════════════════════════════════════════
    return Controller.extend("solar.epc.projectmanagement.vendor.QuotationComparison", {

        onInit: function () {
            const oModel = new JSONModel({
                selectedMRId      : "",
                selectedMR        : {},
                hasQuotations     : false,
                quotations        : [],
                quotationCount    : 0,
                comparisonMessage : "",
                itemComparison    : [],
                sortBy            : "totalAmount",
                materialRequests  : []
            });
            this.getView().setModel(oModel, "qc");

            console.log("QuotationComparison onInit fired");
            this._loadMaterialRequests();
        },

        _loadMaterialRequests: function () {
            const oQCModel = this.getView().getModel("qc");

            const aMockRequests = [
                {
                    ID: "5435a2ce-e79b-4f94-93de-76aea6ba0d2b",
                    requestNumber: "MR-2025-001",
                    projectName: "Bhadla Solar Park Ph-III",
                    status: "APPROVED"
                },
                {
                    ID: "6b44c3f1-a12d-4e5f-b8c9-c5f7d9e2a1b3",
                    requestNumber: "MR-2025-002",
                    projectName: "Rewa Ultra Mega Solar",
                    status: "SUBMITTED"
                },
                {
                    ID: "7c55d4g2-b23e-5f6g-c9d0-d6g8e0f3b2c4",
                    requestNumber: "MR-2025-003",
                    projectName: "Kamuthi Solar Plant",
                    status: "APPROVED"
                }
            ];

            const oComponent = this.getOwnerComponent();
            const oMainModel = oComponent.getModel();

            if (!oMainModel) {
                console.warn("OData model not initialized yet, using test data");
                oQCModel.setProperty("/materialRequests", aMockRequests);
                return;
            }

            oMainModel.bindList("/MaterialRequests").requestContexts(0, 100)
                .then(function (aCtx) {
                    const aMRs = aCtx.map(function (ctx) {
                        const oObj = ctx.getObject();
                        return {
                            ID: oObj.ID,
                            requestNumber: oObj.requestNumber || oObj.ID,
                            projectName: "Unknown",
                            status: oObj.status || "DRAFT"
                        };
                    }).filter(function (mr) {
                        return mr.status === "APPROVED" || mr.status === "SUBMITTED";
                    });

                    if (aMRs.length > 0) {
                        oQCModel.setProperty("/materialRequests", aMRs);
                    } else {
                        // OData returned data but none matched APPROVED/SUBMITTED status filter
                        // Show all returned records so the dropdown is not empty
                        const aAll = aCtx.map(function (ctx) {
                            const oObj = ctx.getObject();
                            return {
                                ID: oObj.ID,
                                requestNumber: oObj.requestNumber || oObj.ID,
                                projectName: "Unknown",
                                status: oObj.status || "DRAFT"
                            };
                        });
                        oQCModel.setProperty("/materialRequests", aAll.length > 0 ? aAll : aMockRequests);
                    }
                }.bind(this))
                .catch(function (oErr) {
                    console.warn("OData load failed, using test data:", oErr.message);
                    oQCModel.setProperty("/materialRequests", aMockRequests);
                }.bind(this));
        },

        // ── Navigation ────────────────────────────────────────────────────────

        onNavBack: function () {
            const oRouter = this.getOwnerComponent().getRouter();
            oRouter.navTo("QuotationList");
        },

        onNavHome: function () {
            this.getOwnerComponent().getRouter().navTo("HomePage");
        },

        onNavQuotations: function () {
            this.getOwnerComponent().getRouter().navTo("QuotationList");
        },

        // ── Step 1: Load MR list ──────────────────────────────────────────────

        onMRSelectChange: function (oEvent) {
            const sKey = oEvent.getSource().getSelectedKey();
            const oModel = this.getView().getModel("qc");
            oModel.setProperty("/selectedMRId", sKey);
            oModel.setProperty("/hasQuotations", false);
            oModel.setProperty("/quotations", []);

            if (sKey) {
                this._loadMRDetails(sKey);
            }
        },

        _loadMRDetails: function (sMRId) {
            const oMainModel = this.getOwnerComponent().getModel();
            if (!oMainModel) { return; }

            oMainModel.bindContext(
                "/MaterialRequests(ID='" + sMRId + "',IsActiveEntity=true)", null, {
                $expand: "project"
            }).requestObject()
            .then(function (oMR) {
                const oModel = this.getView().getModel("qc");
                oModel.setProperty("/selectedMR", {
                    requestNumber: oMR.requestNumber,
                    project      : oMR.project ? (oMR.project.projectName || oMR.project.projectCode) : "",
                    requiredDate : oMR.requiredDate
                });
            }.bind(this))
            .catch(function () {});
        },

        // ── Step 2: Load Quotations ───────────────────────────────────────────

        onLoadQuotations: function () {
            const sKey = this.getView().getModel("qc").getProperty("/selectedMRId");
            if (!sKey) {
                MessageToast.show("Please select a Material Request first.");
                return;
            }
            this._fetchQuotations(sKey);
        },

        _fetchQuotations: function (sMRId) {
            const oVendorModel = this.getOwnerComponent().getModel("vendorService");
            if (!oVendorModel) {
                MessageToast.show("Vendor service not available.");
                return;
            }

            oVendorModel.bindList("/VendorQuotations", null, null, null, {
                $filter : "materialRequest_ID eq '" + sMRId + "'",
                $expand : "vendor,items($expand=material)"
            }).requestContexts(0, 50)
            .then(function (aCtx) {
                const aRaw = aCtx.map(function (ctx) { return ctx.getObject(); });
                this._processQuotations(aRaw, sMRId);
            }.bind(this))
            .catch(function () {
                // Fallback to all quotations if filter fails
                oVendorModel.bindList("/VendorQuotations", null, null, null, {
                    $expand: "vendor,items($expand=material)"
                }).requestContexts(0, 100)
                .then(function (aCtx) {
                    const aFiltered = aCtx
                        .map(function (ctx) { return ctx.getObject(); })
                        .filter(function (q) { return q.materialRequest_ID === sMRId; });
                    this._processQuotations(aFiltered, sMRId);
                }.bind(this))
                .catch(function () {
                    MessageToast.show("Error loading quotations. Please try again.");
                });
            }.bind(this));
        },

        _processQuotations: function (aRaw, sMRId) {
            const oModel = this.getView().getModel("qc");

            if (!aRaw || aRaw.length === 0) {
                oModel.setProperty("/hasQuotations", false);
                oModel.setProperty("/quotationCount", 0);
                MessageToast.show("No quotations found for this material request.");
                return;
            }

            // Sort by totalAmount ascending for ranking
            const aSorted = aRaw.slice().sort(function (a, b) {
                return (a.totalAmount || 0) - (b.totalAmount || 0);
            });

            const minTotal  = aSorted[0].totalAmount || 0;
            const maxTotal  = aSorted[aSorted.length - 1].totalAmount || 0;
            const leadTimes = aRaw.map(function (q) { return q.deliveryLeadDays || 0; });
            const medianLead = leadTimes.sort((a, b) => a - b)[Math.floor(leadTimes.length / 2)] || 7;

            const aQuotations = aRaw.map(function (q, idx) {
                // Price rank (1 = cheapest)
                const rank = aSorted.findIndex(function (s) { return s.ID === q.ID; }) + 1;

                return {
                    ID              : q.ID,
                    vendorName      : q.vendor ? q.vendor.vendorName : "Unknown Vendor",
                    vendorCode      : q.vendor ? q.vendor.vendorCode : "",
                    vendorScore     : q.vendor ? parseFloat((q.vendor.performanceScore || 0).toFixed(1)) : 0,
                    subtotal        : q.subtotal || 0,
                    taxAmount       : q.taxAmount || 0,
                    totalAmount     : q.totalAmount || 0,
                    deliveryLeadDays: q.deliveryLeadDays || 0,
                    paymentTerms    : q.paymentTerms || "-",
                    status          : q.status,
                    isSelected      : q.isSelected || false,
                    currency        : q.currency || "INR",
                    rank            : rank,
                    rankState       : _priceState(rank),
                    priceState      : _priceState(rank),
                    leadDaysState   : _leadDaysState(q.deliveryLeadDays, medianLead),
                    scoreState      : _scoreState(q.vendor ? q.vendor.performanceScore : 0),
                    statusState     : _statusState(q.status),
                    items           : q.items || []
                };
            });

            // Item-level comparison
            const aItemComparison = this._buildItemComparison(aRaw);

            const sSelected = aRaw.some(function (q) { return q.isSelected; })
                ? "A vendor has already been selected for this request."
                : "Compare vendor bids and click 'Select Vendor' to finalise the decision.";

            oModel.setProperty("/quotations",       aQuotations);
            oModel.setProperty("/itemComparison",   aItemComparison);
            oModel.setProperty("/quotationCount",   aQuotations.length);
            oModel.setProperty("/hasQuotations",    true);
            oModel.setProperty("/comparisonMessage", sSelected);
        },

        _buildItemComparison: function (aQuotations) {
            // Group items by material across all quotations
            const mByMaterial = {};

            aQuotations.forEach(function (q) {
                const sVendorName = q.vendor ? q.vendor.vendorName : "Unknown";
                (q.items || []).forEach(function (item) {
                    const sMat = item.material_ID || item.material;
                    if (!sMat) { return; }
                    if (!mByMaterial[sMat]) {
                        mByMaterial[sMat] = {
                            materialCode: item.material ? (item.material.materialCode || sMat) : sMat,
                            description : item.description || (item.material ? item.material.description : ""),
                            quotedQty   : item.quotedQty || 0,
                            uom         : item.uom || "",
                            prices      : []
                        };
                    }
                    mByMaterial[sMat].prices.push({
                        vendorName: sVendorName,
                        unitPrice : item.unitPrice || 0
                    });
                });
            });

            return Object.values(mByMaterial).map(function (m) {
                const prices = m.prices.map(function (p) { return p.unitPrice; });
                const bestPrice  = Math.min.apply(null, prices);
                const worstPrice = Math.max.apply(null, prices);
                const best = m.prices.find(function (p) { return p.unitPrice === bestPrice; });
                return {
                    materialCode: m.materialCode,
                    description : m.description,
                    quotedQty   : m.quotedQty,
                    uom         : m.uom,
                    bestPrice   : bestPrice,
                    worstPrice  : worstPrice,
                    variance    : parseFloat((worstPrice - bestPrice).toFixed(2)),
                    bestVendor  : best ? best.vendorName : "-"
                };
            });
        },

        // ── Sorting ───────────────────────────────────────────────────────────

        onSortChange: function (oEvent) {
            const sSortKey = oEvent.getSource().getSelectedKey();
            const oModel   = this.getView().getModel("qc");
            const aQ = oModel.getProperty("/quotations").slice();

            aQ.sort(function (a, b) {
                if (sSortKey === "totalAmount")     { return a.totalAmount - b.totalAmount; }
                if (sSortKey === "deliveryLeadDays"){ return a.deliveryLeadDays - b.deliveryLeadDays; }
                if (sSortKey === "vendorScore")      { return b.vendorScore - a.vendorScore; }
                return 0;
            });
            // Re-rank
            aQ.forEach(function (q, i) {
                q.rank       = i + 1;
                q.rankState  = _priceState(i + 1);
                q.priceState = _priceState(i + 1);
            });
            oModel.setProperty("/quotations", aQ);
        },

        // ── Quotation row press ───────────────────────────────────────────────

        onQuotationRowPress: function (oEvent) {
            const oCtx  = oEvent.getSource().getBindingContext("qc");
            const sName = oCtx.getProperty("vendorName");
            MessageToast.show("Viewing quotation details for " + sName + ".");
        },

        // ── Select vendor ─────────────────────────────────────────────────────

        onSelectVendorPress: function (oEvent) {
            const oButton = oEvent.getSource();
            const oCtx    = oButton.getBindingContext("qc");
            const sQuotId = oCtx.getProperty("ID");
            const sVendor = oCtx.getProperty("vendorName");

            MessageBox.confirm(
                "Select " + sVendor + " as the vendor for this material request?",
                {
                    title  : "Confirm Vendor Selection",
                    actions: [MessageBox.Action.YES, MessageBox.Action.NO],
                    onClose: function (sAction) {
                        if (sAction === MessageBox.Action.YES) {
                            this._callSelectVendor(sQuotId, sVendor);
                        }
                    }.bind(this)
                }
            );
        },

        _callSelectVendor: function (sQuotId, sVendorName) {
            const oVendorModel = this.getOwnerComponent().getModel("vendorService");
            if (!oVendorModel) {
                MessageToast.show("Vendor service not available.");
                return;
            }

            const oContext = oVendorModel.bindContext(
                "/VendorQuotations(ID='" + sQuotId + "',IsActiveEntity=true)/VendorService.selectVendor(...)"
            );
            oContext.setParameter("selectionReason", "Best price-quality ratio based on comparison.");

            oContext.execute()
            .then(function () {
                MessageBox.success(
                    sVendorName + " has been selected as the vendor.\n\nYou can now create a Purchase Order.",
                    { title: "Vendor Selected" }
                );
                // Refresh quotations
                const sMRId = this.getView().getModel("qc").getProperty("/selectedMRId");
                this._fetchQuotations(sMRId);
            }.bind(this))
            .catch(function (oErr) {
                MessageBox.error(
                    "Failed to select vendor: " + (oErr.message || oErr),
                    { title: "Error" }
                );
            });
        }
    });
});
