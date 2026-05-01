sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/ActionSheet",
    "sap/m/Button",
    "sap/ui/core/Theming"
], function (Controller, ActionSheet, Button, Theming) {
    "use strict";

    return Controller.extend("solar.epc.projectmanagement.App", {
        onInit: function () {
            // Apply default theme to ensure we are starting with the intended one
            Theming.setTheme("sap_horizon");
        },

        onProfilePress: function (oEvent) {
            const oButton = oEvent.getSource();

            if (!this._oThemeActionSheet) {
                this._oThemeActionSheet = new ActionSheet({
                    title: "Settings",
                    showCancelButton: true,
                    buttons: [
                        new Button({
                            text: "Theme: Horizon Light",
                            icon: "sap-icon://lightbulb",
                            press: this.onThemeChange.bind(this, "sap_horizon")
                        }),
                        new Button({
                            text: "Theme: Horizon Dark",
                            icon: "sap-icon://e-care",
                            press: this.onThemeChange.bind(this, "sap_horizon_dark")
                        }),
                        new Button({
                            text: "Theme: Quartz Light",
                            icon: "sap-icon://palette",
                            press: this.onThemeChange.bind(this, "sap_fiori_3")
                        }),
                        new Button({
                            text: "Theme: Quartz Dark",
                            icon: "sap-icon://background",
                            press: this.onThemeChange.bind(this, "sap_fiori_3_dark")
                        })
                    ]
                });
                this.getView().addDependent(this._oThemeActionSheet);
            }

            this._oThemeActionSheet.openBy(oButton);
        },

        onThemeChange: function (sTheme) {
            Theming.setTheme(sTheme);
        }
    });
});
