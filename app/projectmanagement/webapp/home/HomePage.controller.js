sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "solar/epc/projectmanagement/service/RoleService"
], function (Controller, JSONModel, MessageToast, MessageBox, RoleService) {
    "use strict";

    // Tile → route mapping per role.
    // BDM      → all projects (create/activate/hold/cancel)
    // Engineer → ACTIVE projects only, can create BOQ + MR
    // Senior   → ACTIVE projects only, can only approve/reject MR
    const ROUTE_BY_ROLE = {
        "BDM": { "Engineering & Projects": "ProjectsList", default: "ProjectsList" },
        "ENGINEER": { "Engineering & Projects": "EngineeringProjectsList", default: "EngineeringProjectsList" },
        "PROJECT_MANAGER": { "Engineering & Projects": "SeniorProjectsList", "Procurement": "VendorList", default: "SeniorProjectsList" },
        "PROCUREMENT_OFFICER": { "Engineering & Projects": "ProjectsList", "Procurement": "POList", default: "POList" },
        "SITE_ENGINEER": { "Engineering & Projects": "ProjectsList", "Site Operations": "GRNList", default: "GRNList" },
        "FINANCE_OFFICER": { "Engineering & Projects": "ProjectsList", "Finance Cockpit": "InvoiceList", default: "InvoiceList" },
        "MANAGEMENT": { "MyHome": "ManagementDashboard", "Engineering & Projects": "ProjectsList", "Procurement": "ProcurementMRList", "Site Operations": "DeliveryList", "Finance Cockpit": "InvoiceList", default: "ManagementDashboard" }
    };

    return Controller.extend("solar.epc.projectmanagement.home.HomePage", {

        // ── Lifecycle ─────────────────────────────────────────────────────────

        onInit: function () {
            const oComponent = this.getOwnerComponent();
            const oSessionModel = oComponent.getModel("session");
            const sRole = oSessionModel.getProperty("/currentRole");

            this._initViewModel(sRole);

            // Keep view model in sync when session role changes (e.g. from another view)
            oSessionModel.attachPropertyChange(this._onSessionRoleChange, this);

            // Show access-denied message if we were redirected here
            if (oSessionModel.getProperty("/unauthorized")) {
                const sDenied = oSessionModel.getProperty("/lastDeniedRoute");
                MessageBox.warning(
                    "You do not have permission to access '" + sDenied + "'.",
                    { title: "Access Denied" }
                );
                oSessionModel.setProperty("/unauthorized", false);
                oSessionModel.setProperty("/lastDeniedRoute", "");
            }
        },

        onExit: function () {
            this.getOwnerComponent().getModel("session")
                .detachPropertyChange(this._onSessionRoleChange, this);
        },

        // ── Initialisation helpers ────────────────────────────────────────────

        _initViewModel: function (sRole) {
            const hour = new Date().getHours();
            const greeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
            const todos = RoleService.getTodos(sRole);
            const sUserName = this.getOwnerComponent().getModel("session").getProperty("/userName") || "User";
            const oAccess = RoleService.getAccessModel(sRole);
            const oKPIs = this._getKPIData(sRole);

            const oModel = new JSONModel({
                greeting: greeting,
                userName: sUserName,
                role: RoleService.getDisplayName(sRole),
                systemName: "SolarSage EPC",
                currentRole: sRole,
                todos: todos,
                todosCount: todos.length,
                access: oAccess,
                todoRows: this.formatTodoRows(oAccess),
                kpis: oKPIs,
                editMode: false
            });
            this.getView().setModel(oModel, "view");
        },

        _applyRole: function (sRole) {
            const oModel = this.getView().getModel("view");
            const todos = RoleService.getTodos(sRole);
            const oAccess = RoleService.getAccessModel(sRole);
            const oKPIs = this._getKPIData(sRole);

            oModel.setProperty("/role", RoleService.getDisplayName(sRole));
            oModel.setProperty("/currentRole", sRole);
            oModel.setProperty("/todos", todos);
            oModel.setProperty("/todosCount", todos.length);
            oModel.setProperty("/access", oAccess);
            oModel.setProperty("/kpis", oKPIs);

            const iTodoRows = this.formatTodoRows(oAccess);
            oModel.setProperty("/todoRows", iTodoRows);

            // Force GridContainer to resize by explicitly setting layoutData and invalidating parent
            const oTodoCard = this.getView().byId("todoCard");
            if (oTodoCard) {
                const oLayoutData = oTodoCard.getLayoutData();
                if (oLayoutData) {
                    oLayoutData.setRows(iTodoRows);
                    const oGrid = this.getView().byId("mainGrid");
                    if (oGrid) {
                        oGrid.invalidate();
                    }
                }
            }

            // Sync session model so the route guard uses the new role
            this.getOwnerComponent().getModel("session")
                .setProperty("/currentRole", sRole);
        },

        // ── KPI Data Mock ─────────────────────────────────────────────────────

        _getKPIData: function (sRole) {
            // Mock KPI data based on role for authentic Fiori NumericHeader cards
            // Note: state expects sap.m.ValueColor: Good, Critical, Error, Neutral
            const oKPIs = {
                home: { value: "14", scale: "Tasks", trend: "None", state: "Neutral", details: "Across all modules" },
                engineering: { value: "0", scale: "Projects", trend: "None", state: "Neutral", details: "Active" },
                procurement: { value: "0", scale: "POs", trend: "None", state: "Neutral", details: "Pending" },
                siteOps: { value: "0", scale: "Deliveries", trend: "None", state: "Neutral", details: "Today" },
                vendorRebates: { value: "0", scale: "Contracts", trend: "None", state: "Neutral", details: "Under Review" },
                finance: { value: "0", scale: "Invoices", trend: "None", state: "Neutral", details: "To Validate" }
            };

            switch (sRole) {
                case "BDM":
                    oKPIs.engineering = { value: "24", scale: "Active", trend: "Up", state: "Good", details: "$4.2M Pipeline" };
                    break;
                case "ENGINEER":
                    oKPIs.engineering = { value: "8", scale: "BOQs", trend: "None", state: "Neutral", details: "In Progress" };
                    break;
                case "PROJECT_MANAGER":
                    oKPIs.engineering = { value: "12", scale: "Projects", trend: "Up", state: "Good", details: "On Track" };
                    oKPIs.procurement = { value: "5", scale: "Vendors", trend: "None", state: "Critical", details: "Pending Evaluation" };
                    break;
                case "PROCUREMENT_OFFICER":
                    oKPIs.procurement = { value: "15", scale: "Open POs", trend: "Up", state: "Critical", details: "Action Required" };
                    break;
                case "SITE_ENGINEER":
                    oKPIs.siteOps = { value: "4", scale: "Receipts", trend: "Down", state: "Neutral", details: "Pending Verification" };
                    break;
                case "FINANCE_OFFICER":
                    oKPIs.finance = { value: "9", scale: "Invoices", trend: "Up", state: "Error", details: "Awaiting Payment" };
                    break;
                case "MANAGEMENT":
                    oKPIs.engineering = { value: "45", scale: "Total", trend: "Up", state: "Good", details: "Projects Enterprise-wide" };
                    oKPIs.procurement = { value: "3.2", scale: "M", trend: "Down", state: "Good", details: "Spend vs Budget" };
                    oKPIs.siteOps = { value: "98", scale: "%", trend: "Up", state: "Good", details: "Safety Compliance" };
                    oKPIs.vendorRebates = { value: "120", scale: "k", trend: "Up", state: "Good", details: "Rebates Claimed" };
                    oKPIs.finance = { value: "12", scale: "%", trend: "Down", state: "Critical", details: "Margin Variance" };
                    break;
            }
            return oKPIs;
        },

        // ── Event handlers ────────────────────────────────────────────────────

        onRoleChange: function (oEvent) {
            const sRole = oEvent.getSource().getSelectedKey();
            if (sRole) {
                this._applyRole(sRole);
            }
        },

        onTodoPress: function (oEvent) {
            const oCtx = oEvent.getSource().getBindingContext("view");
            const sRole = oCtx.getProperty("role") || "";
            const oRouter = this.getOwnerComponent().getRouter();
            const sCurrentRole = this.getView().getModel("view").getProperty("/currentRole");

            // Route todo items to the relevant functional screen
            if (sRole.includes("Senior") || sCurrentRole === "PROJECT_MANAGER") {
                if (sRole.includes("Senior") || sRole.includes("Executive")) {
                    oRouter.navTo("MRApprovalDashboard");
                    return;
                }
            }
            if (sCurrentRole === "ENGINEER") {
                oRouter.navTo("EngineeringProjectsList");
                return;
            }
            if (sCurrentRole === "BDM") {
                oRouter.navTo("ProjectsList");
                return;
            }
            if (sCurrentRole === "PROCUREMENT_OFFICER") {
                oRouter.navTo("POList");
                return;
            }
            if (sCurrentRole === "SITE_ENGINEER") {
                oRouter.navTo("GRNList");
                return;
            }
            if (sCurrentRole === "FINANCE_OFFICER") {
                oRouter.navTo("InvoiceList");
                return;
            }
            // fallback
            const sTask = oCtx.getProperty("task");
            MessageToast.show("Opening: " + sTask);
        },

        onNavPress: function (oEvent) {
            const oSource = oEvent.getSource();
            const sHeader = oSource.getHeader ? oSource.getHeader() : oSource.getTitle();
            const oRouter = this.getOwnerComponent().getRouter();
            const sRole = this.getView().getModel("view").getProperty("/currentRole");

            // Determine route based on tile header and role.
            // MyHome routes to ManagementDashboard for MANAGEMENT, otherwise HomePage.
            const oRoleRoutes = ROUTE_BY_ROLE[sRole];
            let sRoute = oRoleRoutes && oRoleRoutes[sHeader]
                ? oRoleRoutes[sHeader]
                : sHeader === "MyHome" ? "HomePage" : oRoleRoutes?.default;

            if (!sRoute) {
                MessageToast.show("'" + sHeader + "' module is coming soon");
                return;
            }

            if (!RoleService.canAccessRoute(sRole, sRoute)) {
                MessageBox.error(
                    "Your role does not have access to '" + sHeader + "'.",
                    { title: "Access Denied" }
                );
                return;
            }

            oRouter.navTo(sRoute);
        },

        onAppPress: function (oEvent) {
            const oItem = oEvent.getSource();
            const sAppKey = oItem.data("appKey") || "";
            const sLabel = oItem.data("appLabel") || "";
            const sRole = this.getView().getModel("view").getProperty("/currentRole");
            const oRouter = this.getOwnerComponent().getRouter();

            const oNavMap = {
                "manageVendors":      "VendorList",
                "createMR":           "EngineeringProjectsList",
                "approveMR":          "MRApprovalDashboard",
                "compareQuotations":  "QuotationComparison",
                "approvedMRs":        "ProcurementMRList",
                "createPO":           "POList",
                "trackDeliveries":    "DeliveryList",
                "postGR":             "GRNList",
                "reportDamage":       "GRNList",
                "validateInvoice":    "InvoiceList"
            };

            if (oNavMap[sAppKey]) {
                if (sAppKey === "compareQuotations") {
                    MessageToast.show("Loading Compare Quotations...");
                }
                oRouter.navTo(oNavMap[sAppKey]);
                return;
            }

            // Partial matches
            if (sAppKey.toLowerCase().includes("compare") || sLabel.toLowerCase().includes("compare")) {
                MessageToast.show("Loading Compare Quotations...");
                oRouter.navTo("QuotationComparison");
                return;
            }

            MessageToast.show("Launching '" + sLabel + "' — screen coming soon");
        },

        onEditPress: function (oEvent) {
            const oModel = this.getView().getModel("view");
            const bEditMode = !oModel.getProperty("/editMode");
            oModel.setProperty("/editMode", bEditMode);
            MessageToast.show(bEditMode ? "Edit mode enabled. You can now drag and drop to rearrange tiles." : "Edit mode disabled.");
        },

        onDrop: function (oEvent) {
            const oDraggedItem = oEvent.getParameter("draggedControl");
            const oDroppedItem = oEvent.getParameter("droppedControl");
            const sDropPosition = oEvent.getParameter("dropPosition");

            const oParent = oDraggedItem.getParent();
            const iDragPosition = oParent.indexOfItem(oDraggedItem);
            let iDropPosition = oParent.indexOfItem(oDroppedItem);

            if (iDragPosition < iDropPosition && sDropPosition === "Before") {
                iDropPosition--;
            } else if (iDragPosition > iDropPosition && sDropPosition === "After") {
                iDropPosition++;
            }

            oParent.removeItem(oDraggedItem);
            oParent.insertItem(oDraggedItem, iDropPosition);
        },

        // ── Formatters ────────────────────────────────────────────────────────

        formatTodoRows: function (oAccess) {
            if (!oAccess) {
                return 4;
            }
            let iCount = 1; // MyHome is always visible
            if (oAccess.tile_engineeringProjects) iCount++;
            if (oAccess.tile_procurement) iCount++;
            if (oAccess.tile_siteOps) iCount++;
            if (oAccess.tile_vendorRebates) iCount++;
            if (oAccess.tile_finance) iCount++;

            // 2 tiles per row next to the todoCard, each tile is 2 rows high
            let iRows = Math.ceil(iCount / 2) * 2;

            // If there is only 1 row of workspaces (iRows === 2), 
            // reduce the Action Center height to half of the default max height (3 rows).
            if (iRows === 2) {
                return 2;
            }

            let iReduced = Math.floor(iRows * 0.75);
            return Math.max(3, iReduced);
        },

        // ── Private ───────────────────────────────────────────────────────────

        _onSessionRoleChange: function (oEvent) {
            const sPath = oEvent.getParameter("path");
            if (sPath === "/currentRole") {
                const sRole = oEvent.getSource().getProperty("/currentRole");
                // Only update view if this controller's model disagrees (avoid loop)
                if (this.getView().getModel("view").getProperty("/currentRole") !== sRole) {
                    this._applyRole(sRole);
                }
            }
        }
    });
});
