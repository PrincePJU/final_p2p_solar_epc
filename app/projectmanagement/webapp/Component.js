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

            // Session model is the single source of truth for the active role.
            // In production this would be populated from the XSUAA JWT token.
            const oSessionModel = new JSONModel({
                currentRole:     RoleService.ROLES.MANAGEMENT,
                userName:        "",
                loggedIn:        false,
                unauthorized:    false,
                lastDeniedRoute: ""
            });
            this.setModel(oSessionModel, "session");

            // Route guard — fires before any route target is displayed
            this.getRouter().attachBeforeRouteMatched(this._onBeforeRouteMatched, this);
        },

        // ── Route guard ───────────────────────────────────────────────────────
        _onBeforeRouteMatched: function (oEvent) {
            const sRouteName    = oEvent.getParameter("name");
            const oSessionModel = this.getModel("session");
            const bLoggedIn     = oSessionModel.getProperty("/loggedIn");
            const sRole         = oSessionModel.getProperty("/currentRole");

            // Always allow LoginPage and our new QuotationComparison route
            if (sRouteName === "LoginPage" || sRouteName === "QuotationComparison") {
                oSessionModel.setProperty("/unauthorized", false);
                return;
            }

            // Not logged in — send to login
            if (!bLoggedIn) {
                this.getRouter().navTo("LoginPage", {}, /*replace*/ true);
                return;
            }

            // Logged in but role lacks permission
            if (!RoleService.canAccessRoute(sRole, sRouteName)) {
                oSessionModel.setProperty("/unauthorized",    true);
                oSessionModel.setProperty("/lastDeniedRoute", sRouteName);
                this.getRouter().navTo("HomePage", {}, /*replace*/ true);
            } else {
                oSessionModel.setProperty("/unauthorized", false);
            }
        }
    });
});
