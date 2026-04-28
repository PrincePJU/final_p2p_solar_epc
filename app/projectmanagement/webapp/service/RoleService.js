sap.ui.define([], function () {
    "use strict";

    // ── Role constants ──────────────────────────────────────────────────────────
    // PROJECT_MANAGER is the backend CDS role; it displays as "Senior Engineer"
    const ROLES = {
        ENGINEER:            "ENGINEER",
        PROJECT_MANAGER:     "PROJECT_MANAGER",
        PROCUREMENT_OFFICER: "PROCUREMENT_OFFICER",
        SITE_ENGINEER:       "SITE_ENGINEER",
        FINANCE_OFFICER:     "FINANCE_OFFICER",
        MANAGEMENT:          "MANAGEMENT"
    };

    const ROLE_DISPLAY = {
        ENGINEER:            "Engineer",
        PROJECT_MANAGER:     "Senior Engineer",
        PROCUREMENT_OFFICER: "Procurement Officer",
        SITE_ENGINEER:       "Site Engineer",
        FINANCE_OFFICER:     "Finance Officer",
        MANAGEMENT:          "Management"
    };

    // ── Route-level permissions ─────────────────────────────────────────────────
    // Maps every manifest route name to the roles allowed to load it
    const ROUTE_PERMISSIONS = {
        LoginPage: [
            "ENGINEER", "PROJECT_MANAGER", "PROCUREMENT_OFFICER",
            "SITE_ENGINEER", "FINANCE_OFFICER", "MANAGEMENT"
        ],
        HomePage: [
            "ENGINEER", "PROJECT_MANAGER", "PROCUREMENT_OFFICER",
            "SITE_ENGINEER", "FINANCE_OFFICER", "MANAGEMENT"
        ],
        ProjectsList: [
            "ENGINEER", "PROJECT_MANAGER", "PROCUREMENT_OFFICER", "MANAGEMENT"
        ],
        ProjectsObjectPage: [
            "ENGINEER", "PROJECT_MANAGER", "PROCUREMENT_OFFICER", "MANAGEMENT"
        ]
    };

    // ── Per-role dashboard access ───────────────────────────────────────────────
    // tiles:    workspace tile visibility
    // features: miscellaneous feature flags
    // apps:     app launcher visibility
    const ROLE_ACCESS = {
        ENGINEER: {
            tiles: {
                engineeringProjects: true,
                procurement:         false,
                siteOps:             false,
                vendorRebates:       false,
                finance:             false
            },
            features: { insightCard: false },
            apps: {
                createMR:          true,
                approveMR:         false,
                manageVendors:     false,
                compareQuotations: false,
                createPO:          false,
                trackDeliveries:   false,
                postGR:            false,
                reportDamage:      false,
                validateInvoice:   false,
                projectHealth:     false
            }
        },
        PROJECT_MANAGER: {
            tiles: {
                engineeringProjects: true,
                procurement:         true,
                siteOps:             false,
                vendorRebates:       false,
                finance:             false
            },
            features: { insightCard: true },
            apps: {
                createMR:          true,
                approveMR:         true,
                manageVendors:     false,
                compareQuotations: true,
                createPO:          false,
                trackDeliveries:   true,
                postGR:            false,
                reportDamage:      false,
                validateInvoice:   false,
                projectHealth:     true
            }
        },
        PROCUREMENT_OFFICER: {
            tiles: {
                engineeringProjects: true,
                procurement:         true,
                siteOps:             true,
                vendorRebates:       true,
                finance:             false
            },
            features: { insightCard: true },
            apps: {
                createMR:          false,
                approveMR:         false,
                manageVendors:     true,
                compareQuotations: true,
                createPO:          true,
                trackDeliveries:   true,
                postGR:            true,
                reportDamage:      true,
                validateInvoice:   false,
                projectHealth:     true
            }
        },
        SITE_ENGINEER: {
            tiles: {
                engineeringProjects: false,
                procurement:         false,
                siteOps:             true,
                vendorRebates:       false,
                finance:             false
            },
            features: { insightCard: false },
            apps: {
                createMR:          false,
                approveMR:         false,
                manageVendors:     false,
                compareQuotations: false,
                createPO:          false,
                trackDeliveries:   true,
                postGR:            true,
                reportDamage:      true,
                validateInvoice:   false,
                projectHealth:     false
            }
        },
        FINANCE_OFFICER: {
            tiles: {
                engineeringProjects: false,
                procurement:         false,
                siteOps:             false,
                vendorRebates:       false,
                finance:             true
            },
            features: { insightCard: true },
            apps: {
                createMR:          false,
                approveMR:         false,
                manageVendors:     false,
                compareQuotations: false,
                createPO:          false,
                trackDeliveries:   false,
                postGR:            false,
                reportDamage:      false,
                validateInvoice:   true,
                projectHealth:     true
            }
        },
        MANAGEMENT: {
            tiles: {
                engineeringProjects: true,
                procurement:         true,
                siteOps:             true,
                vendorRebates:       true,
                finance:             true
            },
            features: { insightCard: true },
            apps: {
                createMR:          true,
                approveMR:         true,
                manageVendors:     true,
                compareQuotations: true,
                createPO:          true,
                trackDeliveries:   true,
                postGR:            true,
                reportDamage:      true,
                validateInvoice:   true,
                projectHealth:     true
            }
        }
    };

    // ── Role-specific todo items ────────────────────────────────────────────────
    const ROLE_TODOS = {
        ENGINEER: [
            {
                task: "Review BOQ for Bhadla Solar Park Ph-III",
                project: "Bhadla Solar Park Ph-III", role: "Engineer Action",
                icon: "sap-icon://create-form", status: "In Progress", state: "None"
            },
            {
                task: "Create Material Request for Solar Panels",
                project: "Rewa Ultra Mega Solar", role: "Engineer Action",
                icon: "sap-icon://approvals", status: "Pending", state: "Warning"
            }
        ],
        PROJECT_MANAGER: [
            {
                task: "Approve Material Request #MR-1024",
                project: "Bhadla Solar Park Ph-III", role: "Senior Engineer Action",
                icon: "sap-icon://approvals", status: "High Priority", state: "Error"
            },
            {
                task: "Review Project Health — Rewa Solar",
                project: "Rewa Ultra Mega Solar", role: "Senior Engineer Action",
                icon: "sap-icon://line-chart-time-axis", status: "Budget at 75%", state: "Warning"
            },
            {
                task: "Evaluate Inverter Quotations",
                project: "Rewa Ultra Mega Solar", role: "Senior Engineer Action",
                icon: "sap-icon://compare", status: "Pending Bid Review", state: "Warning"
            }
        ],
        PROCUREMENT_OFFICER: [
            {
                task: "Evaluate Vendor Quotations (RFQ #Q-2024-001)",
                project: "Kurnool Operations", role: "Procurement Action",
                icon: "sap-icon://compare", status: "Requires Review", state: "Warning"
            },
            {
                task: "Verify Goods Receipt — Delivery #DL-883",
                project: "Kamuthi Solar Plant", role: "Procurement Action",
                icon: "sap-icon://shipping-status", status: "In Transit", state: "None"
            },
            {
                task: "Approve Purchase Order #PO-992",
                project: "Bhadla Solar Park Ph-III", role: "Procurement Action",
                icon: "sap-icon://approvals", status: "Pending", state: "Warning"
            }
        ],
        SITE_ENGINEER: [
            {
                task: "Verify Damaged Solar Panels (Delivery #DL-883)",
                project: "Kurnool Operations", role: "Site Action",
                icon: "sap-icon://quality-issue", status: "Requires Inspection", state: "Warning"
            },
            {
                task: "Post Goods Receipt for Materials",
                project: "Kamuthi Solar Plant", role: "Site Action",
                icon: "sap-icon://receipt", status: "Pending Verification", state: "None"
            }
        ],
        FINANCE_OFFICER: [
            {
                task: "Validate Invoice #INV-551 against PO #PO-992",
                project: "Kamuthi Solar Plant", role: "Finance Action",
                icon: "sap-icon://my-sales-order", status: "Ready for Payment", state: "Success"
            },
            {
                task: "Review Project Budget Status — Bhadla Ph-III",
                project: "Bhadla Solar Park Ph-III", role: "Finance Action",
                icon: "sap-icon://money-bills", status: "High Spend", state: "Warning"
            }
        ],
        MANAGEMENT: [
            {
                task: "Approve Material Request #MR-1024",
                project: "Bhadla Solar Park Ph-III", role: "Executive Action",
                icon: "sap-icon://approvals", status: "High Priority", state: "Error"
            },
            {
                task: "Evaluate Inverter Quotations",
                project: "Rewa Ultra Mega Solar", role: "Executive Action",
                icon: "sap-icon://compare", status: "Pending Bid Review", state: "Warning"
            },
            {
                task: "Review All Project Health Metrics",
                project: "Multi-Project", role: "Executive Action",
                icon: "sap-icon://line-chart-time-axis", status: "Dashboard Update", state: "None"
            },
            {
                task: "Approve Invoice #INV-551",
                project: "Kamuthi Solar Plant", role: "Executive Action",
                icon: "sap-icon://my-sales-order", status: "Ready for Payment", state: "Success"
            }
        ]
    };

    // ── Public API ──────────────────────────────────────────────────────────────
    return {
        ROLES: ROLES,

        getDisplayName: function (sRole) {
            return ROLE_DISPLAY[sRole] || sRole;
        },

        canAccessRoute: function (sRole, sRouteName) {
            const aAllowed = ROUTE_PERMISSIONS[sRouteName];
            if (!aAllowed) return true; // unknown routes are open by default
            return aAllowed.indexOf(sRole) !== -1;
        },

        // Returns a flat object for JSONModel binding:
        //   tile_engineeringProjects, tile_procurement, ...
        //   insightCard
        //   app_createMR, app_approveMR, ...
        getAccessModel: function (sRole) {
            const oConfig = ROLE_ACCESS[sRole];
            if (!oConfig) return {};

            const oFlat = {
                displayName: ROLE_DISPLAY[sRole] || sRole
            };
            Object.keys(oConfig.tiles).forEach(function (k) {
                oFlat["tile_" + k] = oConfig.tiles[k];
            });
            Object.keys(oConfig.features).forEach(function (k) {
                oFlat[k] = oConfig.features[k];
            });
            Object.keys(oConfig.apps).forEach(function (k) {
                oFlat["app_" + k] = oConfig.apps[k];
            });
            return oFlat;
        },

        getTodos: function (sRole) {
            return (ROLE_TODOS[sRole] || []).slice();
        }
    };
});
