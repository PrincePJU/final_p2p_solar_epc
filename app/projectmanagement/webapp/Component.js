sap.ui.define([
    "sap/fe/core/AppComponent",
    "sap/ui/model/json/JSONModel",
    "solar/epc/projectmanagement/service/RoleService"
], function (AppComponent, JSONModel, RoleService) {
    "use strict";

    return AppComponent.extend("solar.epc.projectmanagement.Component", {
        metadata: {
            manifest: "json"
        },

        init: function () {
            AppComponent.prototype.init.apply(this, arguments);

            const sStoredRole = sessionStorage.getItem("currentRole") || RoleService.ROLES.MANAGEMENT;
            const bLoggedIn = sessionStorage.getItem("loggedIn") === "true";

            const oSessionModel = new JSONModel({
                currentRole: sStoredRole,
                userName: sessionStorage.getItem("userName") || "",
                loggedIn: bLoggedIn,
                unauthorized: false,
                lastDeniedRoute: ""
            });
            this.setModel(oSessionModel, "session");

            this.getRouter().attachBeforeRouteMatched(this._onBeforeRouteMatched, this);
        },

        _getDefaultRouteForRole: function (sRole) {
            switch (sRole) {
            case RoleService.ROLES.BDM:
                return "ProjectsList";
            case RoleService.ROLES.ENGINEER:
                return "EngineeringProjectsList";
            case RoleService.ROLES.PROJECT_MANAGER:
                return "MRApprovalDashboard";
            case RoleService.ROLES.PROCUREMENT_OFFICER:
                return "VendorList";
            default:
                return "HomePage";
            }
        },

        _onBeforeRouteMatched: function (oEvent) {
            const sRouteName = oEvent.getParameter("name");
            const oSessionModel = this.getModel("session");
            const bLoggedIn = oSessionModel.getProperty("/loggedIn");
            const sRole = oSessionModel.getProperty("/currentRole");

            if (sRouteName === "LoginPage") {
                oSessionModel.setProperty("/unauthorized", false);

                if (bLoggedIn) {
                    this.getRouter().navTo(this._getDefaultRouteForRole(sRole), {}, true);
                }
                return;
            }

            if (sRouteName === "QuotationComparison") {
                oSessionModel.setProperty("/unauthorized", false);
                return;
            }

            if (!bLoggedIn) {
                this.getRouter().navTo("LoginPage", {}, true);
                return;
            }

            if (!RoleService.canAccessRoute(sRole, sRouteName)) {
                oSessionModel.setProperty("/unauthorized", true);
                oSessionModel.setProperty("/lastDeniedRoute", sRouteName);
                this.getRouter().navTo("HomePage", {}, true);
            } else {
                oSessionModel.setProperty("/unauthorized", false);
            }
        }
    });
});
