sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageBox",
    "sap/m/MessageToast",
    "solar/epc/projectmanagement/service/RoleService"
], function (Controller, JSONModel, MessageBox, MessageToast, RoleService) {
    "use strict";

    return Controller.extend("solar.epc.projectmanagement.login.LoginPage", {

        onInit: function () {
            this.getView().setModel(new JSONModel({
                username: "",
                password: "",
                selectedRole: RoleService.ROLES.MANAGEMENT
            }), "login");
        },

        onLoginPress: function () {
            const oModel = this.getView().getModel("login");
            const sUsername = (oModel.getProperty("/username") || "").trim();
            const sPassword = oModel.getProperty("/password") || "";

            if (!sUsername && !sPassword) {
                MessageToast.show("Checking XSUAA session...");
                this.getOwnerComponent()._loadSession().catch(function () {
                    MessageBox.error("No active XSUAA session was found. For local testing, enter a mocked username and password.");
                });
                return;
            }

            if (!sUsername || !sPassword) {
                MessageBox.warning("Enter both username and password.", { title: "Login" });
                return;
            }

            this.getOwnerComponent()
                .loginWithCredentials(sUsername, sPassword)
                .catch(function () {
                    MessageBox.error("Invalid username or password.", { title: "Login Failed" });
                });
        }
    });
});
