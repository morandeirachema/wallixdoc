# Consulting Templates

Excel/spreadsheet templates for collecting and tracking client data
throughout a WALLIX Bastion PAM engagement.

All files are CSV — open directly in Excel, Google Sheets, or LibreOffice
Calc. Save a copy per client engagement; never edit the master template.

---

## Template Index

| File | Phase | Purpose |
|------|-------|---------|
| [01-client-discovery.csv](01-client-discovery.csv) | Phase 0–1 | Environment questionnaire — AD, network, users, OT, compliance |
| [02-asset-inventory.csv](02-asset-inventory.csv) | Phase 1 | Target system inventory — all devices to be onboarded to Bastion |
| [03-user-inventory.csv](03-user-inventory.csv) | Phase 1–2 | Privileged user register — roles, MFA type, training status |
| [04-risk-matrix.csv](04-risk-matrix.csv) | Phase 1 | Risk assessment — likelihood, impact, PAM mitigations |
| [05-compliance-gap.csv](05-compliance-gap.csv) | Phase 1–3 | Compliance gap analysis — IEC 62443, NIS2, PCI-DSS, GDPR |
| [06-token-distribution.csv](06-token-distribution.csv) | Phase 3 | FortiToken hardware distribution and activation log |
| [07-project-tracker.csv](07-project-tracker.csv) | All phases | Task and milestone tracker — owner, dates, status, blockers |
| [08-test-results.csv](08-test-results.csv) | Phase 2–3 | Integration and UAT test log — pass/fail with evidence |
| [09-roi-worksheet.csv](09-roi-worksheet.csv) | Phase 0 | ROI calculation — breach cost, fines, insurance, operational savings |
| [10-access-review.csv](10-access-review.csv) | Ongoing | Quarterly/annual privileged access review — users, vendors, RBAC, vault accounts |
| [11-change-request-log.csv](11-change-request-log.csv) | All phases | Change request tracker — scope, effort, cost, timeline impact, approval status |
| [12-weekly-status-report.csv](12-weekly-status-report.csv) | All phases | Weekly engagement status report — RAG status, progress, blockers, decisions, milestones |

---

## How to Use

1. Copy the relevant CSV(s) to a client folder: `clients/[CLIENT-NAME]/`
2. Open in Excel and save as `.xlsx` for the working copy
3. Keep the original CSV in this folder as the blank master
4. At engagement close, export the completed sheets back to CSV for archiving

---

## Naming Convention for Client Files

```
clients/
└── ACME-Corp-2026/
    ├── 01-client-discovery.xlsx
    ├── 02-asset-inventory.xlsx
    ├── 03-user-inventory.xlsx
    └── ...
```

---

*Source documents for field definitions and scoring criteria:*
- *[Discovery & Assessment](../consulting/01-discovery-assessment.md)*
- *[Business Case & ROI](../consulting/05-business-case-roi.md)*
- *[Scope & Proposal Template](../consulting/06-scope-proposal-template.md)*
- *[Training & Change Management](../consulting/07-training-change-mgmt.md)*
- *[PAM in OT Guide](../consulting/04-pam-ot-guide.md)*
