sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageBox",
    "solar/epc/projectmanagement/service/RoleService"
], function (Controller, JSONModel, MessageBox, RoleService) {
    "use strict";

    // Demo credentials — in production these are validated server-side via XSUAA
    const DEMO_USERS = {
        "bdm":         { password: "demo", role: RoleService.ROLES.BDM },
        "engineer":    { password: "demo", role: RoleService.ROLES.ENGINEER },
        "senior":      { password: "demo", role: RoleService.ROLES.PROJECT_MANAGER },
        "procurement": { password: "demo", role: RoleService.ROLES.PROCUREMENT_OFFICER },
        "site":        { password: "demo", role: RoleService.ROLES.SITE_ENGINEER },
        "finance":     { password: "demo", role: RoleService.ROLES.FINANCE_OFFICER },
        "admin":       { password: "demo", role: RoleService.ROLES.MANAGEMENT }
    };

    return Controller.extend("solar.epc.projectmanagement.login.LoginPage", {

        onInit: function () {
            const oModel = new JSONModel({
                username:     "",
                password:     "",
                selectedRole: RoleService.ROLES.MANAGEMENT
            });
            this.getView().setModel(oModel, "login");
        },

        onLoginPress: function () {
            const oModel    = this.getView().getModel("login");
            const sUsername = (oModel.getProperty("/username") || "").trim().toLowerCase();
            const sPassword = (oModel.getProperty("/password") || "").trim();
            const sRole     = oModel.getProperty("/selectedRole");

            // In demo mode any username + password "demo" works; role comes from selector
            // A known username overrides the role selector with their predefined role
            const oUser = DEMO_USERS[sUsername];

            if (sUsername === "") {
                MessageBox.warning("Please enter a username.", { title: "Login" });
                return;
            }

            // Accept any password in demo mode; known users get role from table
            const sResolvedRole = oUser ? oUser.role : sRole;
            const sDisplayName  = RoleService.getDisplayName(sResolvedRole);

            this._doLogin(sUsername, sResolvedRole, sDisplayName);
        },

        _doLogin: function (sUsername, sRole, sDisplayName) {
            const oComponent    = this.getOwnerComponent();
            const oSessionModel = oComponent.getModel("session");

            oSessionModel.setProperty("/currentRole", sRole);
            oSessionModel.setProperty("/userName",    sUsername);
            oSessionModel.setProperty("/loggedIn",    true);

            oComponent.getRouter().navTo("HomePage");
        }
    });
});
