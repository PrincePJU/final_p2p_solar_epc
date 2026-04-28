sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "solar/epc/projectmanagement/service/RoleService"
], function (Controller, JSONModel, MessageToast, MessageBox, RoleService) {
    "use strict";

    // Routes that have a live frontend target
    const LIVE_ROUTES = {
        "Engineering & Projects": "ProjectsList",
        "Procurement":            "ProjectsList",
        "Site Operations":        "ProjectsList",
        "Vendor Rebates":         "ProjectsList",
        "Finance Cockpit":        "ProjectsList",
        "MyHome":                 "HomePage"
    };

    return Controller.extend("solar.epc.projectmanagement.home.HomePage", {

        // ── Lifecycle ─────────────────────────────────────────────────────────

        onInit: function () {
            const oComponent    = this.getOwnerComponent();
            const oSessionModel = oComponent.getModel("session");
            const sRole         = oSessionModel.getProperty("/currentRole");

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
                oSessionModel.setProperty("/unauthorized",    false);
                oSessionModel.setProperty("/lastDeniedRoute", "");
            }
        },

        onExit: function () {
            this.getOwnerComponent().getModel("session")
                .detachPropertyChange(this._onSessionRoleChange, this);
        },

        // ── Initialisation helpers ────────────────────────────────────────────

        _initViewModel: function (sRole) {
            const hour        = new Date().getHours();
            const greeting    = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
            const todos       = RoleService.getTodos(sRole);
            const sUserName   = this.getOwnerComponent().getModel("session").getProperty("/userName") || "User";

            const oModel = new JSONModel({
                greeting:    greeting,
                userName:    sUserName,
                role:        RoleService.getDisplayName(sRole),
                systemName:  "SolarSage EPC",
                currentRole: sRole,
                todos:       todos,
                todosCount:  todos.length,
                access:      RoleService.getAccessModel(sRole),
                editMode:    false
            });
            this.getView().setModel(oModel, "view");
        },

        _applyRole: function (sRole) {
            const oModel = this.getView().getModel("view");
            const todos  = RoleService.getTodos(sRole);

            oModel.setProperty("/role",        RoleService.getDisplayName(sRole));
            oModel.setProperty("/currentRole", sRole);
            oModel.setProperty("/todos",       todos);
            oModel.setProperty("/todosCount",  todos.length);
            oModel.setProperty("/access",      RoleService.getAccessModel(sRole));

            // Sync session model so the route guard uses the new role
            this.getOwnerComponent().getModel("session")
                .setProperty("/currentRole", sRole);
        },

        // ── Event handlers ────────────────────────────────────────────────────

        onRoleChange: function (oEvent) {
            const sRole = oEvent.getSource().getSelectedKey();
            if (sRole) {
                this._applyRole(sRole);
            }
        },

        onTodoPress: function (oEvent) {
            const oCtx   = oEvent.getSource().getBindingContext("view");
            const sTask  = oCtx.getProperty("task");
            MessageToast.show("Opening: " + sTask);
        },

        onNavPress: function (oEvent) {
            const sHeader  = oEvent.getSource().getHeader();
            const sRoute   = LIVE_ROUTES[sHeader];
            const oRouter  = this.getOwnerComponent().getRouter();
            const sRole    = this.getView().getModel("view").getProperty("/currentRole");

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
            const oItem    = oEvent.getSource();
            const sAppKey  = oItem.data("appKey");
            const sLabel   = oItem.data("appLabel");
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
