# Dar El Omouma Hospital — Mobile App

Documentation set for the Dar El Omouma Hospital (مستشفى دار الأمومة) patient mobile
application for iOS and Android.

| Document | Purpose |
|---|---|
| [`PROMPT.md`](PROMPT.md) | The formal product & engineering build prompt. Hand this to a development team, a vendor, or an AI coding agent. Covers brand, personas, screen-by-screen requirements, architecture, data model, API, security & compliance, QA and delivery plan. |
| [`docs/COMMERCIAL-ESTIMATE.md`](docs/COMMERCIAL-ESTIMATE.md) | Pricing guidance for the app and for the full Hospital Information System, with a modular price list, tiering strategy, payment terms and a risk register. |
| [`docs/SALES-PLAYBOOK.md`](docs/SALES-PLAYBOOK.md) | How to price and sell the full hospital system: the headline number and how to adjust it, the ROI business case built from the hospital's own figures, meeting structure, stakeholder map, stage-funded payment plan, and objection handling. |
| [`docs/SOURCE-COVERAGE.md`](docs/SOURCE-COVERAGE.md) | A screen-by-screen trace of what was extracted from the client's design deck and how it maps into `PROMPT.md`, plus what could not be processed. |

## Scope at a glance

**Phase 1** (from the client deck): registration with Egyptian National ID validation,
medical file, clinics & appointment booking, radiology, laboratory & blood bank,
home care, complaints, offers & events, medical tips, contact & emergency.

**Phase 1 — added scope:** operating-theatre management with an admin-managed
classification system (صغرى / متوسطة / كبرى / ذات مهارة), a live availability grid,
**direct booking by doctors with no approval step**, patient surgery requests routed
through an approval inbox with SLA escalation and WhatsApp alerts, a surgical safety
pack (digital consent, WHO checklist, pre-op bundle, blood reservation, implant
traceability, family status notifications), the **Dar El Omouma Surgery Centre** as the
first instance of a generic specialty-centre framework (neurosurgery, urology,
orthopaedics), the **visiting-experts programme**, a configurable permission model, and
a full report catalogue.

**Phase 2/3** (proposed extensions): payments, teleconsultation, e-prescriptions,
pharmacy, insurance & corporate contracts, dependants, live queue, pregnancy
companion, newborn & vaccination records, DICOM viewer, staff app, and HIS/LIS/PACS
integration over HL7 FHIR and DICOM.

## Brand

| Token | Value |
|---|---|
| Primary (navy) | `#0B2E5C` |
| Accent (pink) | `#E4327E` |
| Tagline | صحتك مسؤوليتنا |
| Emergency line | 01013009936 |

Colour values are derived from the hospital's signage and vehicle livery in the
supplied deck and **must be confirmed against the official vector logo** before
development begins.
