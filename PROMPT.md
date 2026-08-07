# Dar El Omouma Hospital — Mobile Application (iOS & Android)
## Formal Product & Engineering Build Prompt

**Client:** Dar El Omouma Hospital (مستشفى دار الأمومة)
**Tagline:** "صحتك مسؤوليتنا" — *Your health is our responsibility*
**Product name (working):** Dar El Omouma App — "دار الأمومة في بيتك" (*Maternity Home, at your home*)
**Document version:** 1.0
**Document status:** Ready for estimation and development kick-off
**Source of truth:** Client-supplied design deck `D.O.H_APP.pptx` (11 screens) plus the extensions defined in Section 7 of this document.

---

## 0. How To Use This Document

This document is a complete build prompt. It is written so that it can be handed, without modification, to any of the following and produce the same product:

- An internal or outsourced mobile development team.
- An AI coding agent instructed to scaffold and implement the application.
- A vendor being asked to submit a fixed-price proposal.

Every requirement is stated in the imperative ("The app **shall**…"). Requirements marked **[P1]** are Phase 1 and are derived directly from the client's design deck. Requirements marked **[P2]** and **[P3]** are recommended extensions proposed by the vendor; they are scoped, priced and scheduled separately and are not required for the Phase 1 launch.

Anything the implementer cannot resolve from this document must be raised against Section 19 (Open Questions) before implementation, not assumed.

---

## 1. Product Summary

### 1.1 Purpose

Dar El Omouma Hospital requires a patient-facing mobile application for iOS and Android that allows patients and their families to interact with the hospital's clinical and administrative services without attending in person. The application is the hospital's primary digital front door.

### 1.2 Business Objectives

| # | Objective | Success measure |
|---|---|---|
| 1 | Reduce phone-based booking load on the reception and call centre | ≥ 40% of outpatient appointments booked in-app within 6 months of launch |
| 2 | Deliver laboratory and radiology results digitally | ≥ 60% of results collected in-app rather than at the counter |
| 3 | Grow the home-care service line | ≥ 200 home-care requests per month by month 6 |
| 4 | Create a direct marketing channel for offers, campaigns and health-awareness days | ≥ 50% opt-in rate for push notifications |
| 5 | Formalise patient complaints and feedback into a tracked, auditable workflow | 100% of complaints acknowledged within 24 hours |
| 6 | Establish the data foundation for a future full Hospital Information System (HIS) | Patient master index in place and API-addressable |

### 1.3 Product Principles

1. **Arabic-first.** Egyptian Arabic is the primary language and right-to-left (RTL) is the primary layout direction. English is a fully supported secondary language, not an afterthought.
2. **Low-friction.** A patient must be able to book an appointment in no more than four taps from the home screen.
3. **Trustworthy.** The application handles medical data. Security, privacy and correctness take precedence over feature velocity.
4. **Works on modest hardware and networks.** The target user may be on an entry-level Android device on a 3G connection.
5. **The hospital never loses the patient.** Every digital dead end must offer a phone number, a WhatsApp handover, or a callback request.

---

## 2. Brand & Visual Identity

### 2.1 Colour Palette

Colours below are derived from the hospital's existing signage and vehicle livery supplied in the design deck. **The implementer shall confirm exact values against the official brand guideline or vector logo file before development begins** (see Section 19).

| Token | Approx. hex | Usage |
|---|---|---|
| `brand/navy` | `#0B2E5C` | Primary. Headers, primary text, navigation, primary buttons |
| `brand/pink` | `#E4327E` | Secondary/accent. Calls to action, active states, highlights, maternity-line branding |
| `brand/navy-tint` | `#E8EEF6` | Section backgrounds, cards, selected rows |
| `brand/pink-tint` | `#FDE9F2` | Badges, promotional surfaces |
| `neutral/surface` | `#FFFFFF` | Cards, sheets |
| `neutral/background` | `#F6F7F9` | Screen background (light theme) |
| `neutral/text` | `#111827` | Body text |
| `neutral/muted` | `#6B7280` | Secondary text, captions |
| `semantic/success` | `#0E9F6E` | Confirmed bookings, ready results |
| `semantic/warning` | `#D97706` | Pending, awaiting payment |
| `semantic/danger` | `#DC2626` | Cancellations, critical result flags, emergency |

A dark theme shall be produced by re-mapping these tokens, not by inverting colours algorithmically.

### 2.2 Logo & Iconography

- The application shall use the official Dar El Omouma mark (mother-and-child crescent) as supplied in vector format (SVG or AI). Raster extraction from the presentation deck is **not** acceptable for production.
- App icon, splash screen and in-app header shall all use the same mark, at the appropriate optical sizes for iOS and Android.
- Iconography shall be a single consistent set (recommended: Phosphor or Material Symbols, rounded weight). Mixed icon sets are not acceptable.

### 2.3 Typography

| Element | Arabic | English | Size |
|---|---|---|---|
| Screen title | IBM Plex Sans Arabic — Bold | Inter — Bold | 24 sp/pt |
| Section header | IBM Plex Sans Arabic — SemiBold | Inter — SemiBold | 18 |
| Body | IBM Plex Sans Arabic — Regular | Inter — Regular | 16 |
| Caption / helper | IBM Plex Sans Arabic — Regular | Inter — Regular | 13 |
| Button label | IBM Plex Sans Arabic — SemiBold | Inter — SemiBold | 16 |

Arabic numerals: the app shall render Western Arabic numerals (0–9) by default with a user preference to switch to Eastern Arabic numerals (٠–٩). Dates shall follow the Gregorian calendar with an optional Hijri display.

### 2.4 Layout System

- 8 pt spacing grid. Permitted spacing values: 4, 8, 12, 16, 24, 32, 48.
- Corner radius: 12 pt for cards, 999 pt (pill) for primary buttons, 8 pt for inputs.
- Minimum touch target: 44 × 44 pt.
- Minimum contrast ratio: 4.5:1 for body text, 3:1 for large text and UI components (WCAG 2.2 AA).

---

## 3. Users, Roles & Permissions

### 3.1 Personas

| Persona | Description | Primary needs |
|---|---|---|
| **Expectant mother** | Core audience given the hospital's maternity specialism | Antenatal appointments, ultrasound scans, lab results, pregnancy guidance, delivery-package pricing |
| **Family member / caregiver** | Books and manages care on behalf of a parent, spouse or child | Dependant profiles, home-care requests, results access, transport |
| **Corporate / insured patient** | Employee covered by a company contract with the hospital | Eligibility, approval status, co-payment amount, corporate price list |
| **Walk-in / general outpatient** | Adult patient using clinics, labs and radiology | Prices, schedules, booking, results |
| **Hospital staff (back-office)** | Reception, lab, radiology, home-care coordinator, marketing, complaints officer | Managing everything the patient sees, via the admin console (Section 14) |

### 3.2 Roles

| Role | Scope |
|---|---|
| `guest` | Browse public content only: clinics list, prices, schedules, offers, medical tips, contact. Cannot book or view any medical data. |
| `patient` | All `guest` rights, plus own medical file, bookings, results, invoices, complaints, home-care requests. |
| `dependant_manager` | A `patient` who additionally manages linked dependant profiles (children, spouse, parents) under explicit consent. **[P2]** |
| `staff_*` | Back-office roles in the admin console: `staff_reception`, `staff_lab`, `staff_radiology`, `staff_homecare`, `staff_marketing`, `staff_complaints`, `staff_finance`. |
| `admin` | Full administrative control, including user management and audit-log review. |

**Rule:** Authorisation shall be enforced server-side on every request. Client-side role checks are for user experience only and shall never be the sole gate on any medical or financial data.

---

## 4. Platform & Technical Requirements

### 4.1 Target Platforms

| Platform | Minimum version | Notes |
|---|---|---|
| iOS | 15.0 | iPhone only for Phase 1; iPad layout is **[P2]** |
| Android | 8.0 (API 26) | Phone only for Phase 1 |

Both platforms shall support portrait orientation as the primary layout. Landscape is required only for the DICOM/image viewer **[P2]**.

### 4.2 Recommended Stack

The implementer may propose an alternative, but must justify it against the criteria below.

| Layer | Recommendation | Rationale |
|---|---|---|
| Mobile client | **React Native (Expo, TypeScript)** or **Flutter (Dart)** | Single codebase for both stores; mature RTL support; large Egyptian talent pool for maintenance |
| State management | TanStack Query + Zustand (RN) / Riverpod (Flutter) | Server-state caching is the dominant concern in this app |
| Navigation | React Navigation / go_router | Deep-link support required (Section 12.3) |
| Backend | **Node.js (NestJS, TypeScript)** or **.NET 8** | Strong typing, mature health-integration ecosystem |
| Database | **PostgreSQL 15+** | Relational integrity is required for clinical and billing data |
| Object storage | S3-compatible (AWS S3 or self-hosted MinIO) | Result PDFs, images, marketing media |
| Cache / queue | Redis | Sessions, rate limiting, OTP, background jobs |
| Push | Firebase Cloud Messaging (Android) + APNs (iOS) | Standard |
| Auth | OAuth 2.0 / OIDC with phone-OTP as primary factor | Section 11 |
| Observability | Sentry (crash + errors) + structured server logs + uptime monitoring | Section 16 |
| CI/CD | GitHub Actions → TestFlight + Google Play Internal Testing | Section 17 |

### 4.3 Environments

Three isolated environments shall be provisioned: `development`, `staging` (with anonymised data only), and `production`. **Production patient data shall never be copied into a lower environment.**

### 4.4 Performance Budget

| Metric | Target |
|---|---|
| Cold start to interactive home screen | ≤ 2.5 s on a mid-tier Android device |
| Any list screen first paint | ≤ 1.0 s from cache, ≤ 2.5 s from network |
| API p95 response time | ≤ 400 ms |
| App download size | ≤ 60 MB (Android App Bundle), ≤ 80 MB (iOS) |
| Crash-free session rate | ≥ 99.5% |

---

## 5. Information Architecture

```
Splash
└── Onboarding (first launch only)
    └── Auth
        ├── Login (phone + OTP, or email + password)
        ├── Register
        └── Continue as guest
            └── HOME (tab bar)
                ├── Home
                │   ├── Home Care
                │   ├── Complaints
                │   ├── Medical Tips
                │   └── Offers & Events
                ├── Services
                │   ├── Clinics ── Clinic detail ── Doctor ── Booking ── Confirmation
                │   ├── Radiology ── Type ── Prices / Schedules ── Booking
                │   ├── Laboratory ── Tests / Prices / Offers ── Booking ── Results
                │   └── Blood Bank ── Services ── Donate / Request
                ├── Medical File
                │   ├── Profile & vitals
                │   ├── Visits & appointments
                │   ├── Lab results
                │   ├── Radiology reports
                │   ├── Prescriptions            [P2]
                │   └── Documents & invoices
                ├── Bookings
                └── More
                    ├── Contact & Emergency (call 01013009936)
                    ├── Branches & directions
                    ├── Dependants                [P2]
                    ├── Insurance & corporate      [P2]
                    ├── Language & appearance
                    ├── Notification settings
                    ├── Privacy & consent
                    └── About / Terms
```

A persistent, always-reachable **emergency action** (call `01013009936` / request ambulance) shall be available from the home screen header on every screen of the Home tab.

---

## 6. Phase 1 — Functional Requirements (Derived From The Client Deck)

Each subsection maps to a screen in `D.O.H_APP.pptx`.

### 6.1 Splash & Welcome — *deck slide 1* **[P1]**

- Display the hospital logo, the name "دار الأمومة في بيتك", and the tagline.
- Present two primary actions: **تسجيل دخول** (Log in) and **إنشاء حساب** (Create account).
- Provide a tertiary action: **الدخول كزائر** (Continue as guest) with access limited to the `guest` role.
- Splash shall not exceed 1.5 s of artificial delay; if a session token is valid, skip straight to Home.

### 6.2 Registration — *deck slide 2* **[P1]**

Collect and validate the following fields:

| Field | Arabic label | Validation | Required |
|---|---|---|---|
| Full four-part name | الاسم رباعي | Arabic or Latin letters and spaces; minimum four tokens; 6–120 chars | Yes |
| National ID | الرقم القومي | Exactly 14 digits; **checksum and structural validation of the Egyptian National ID** (century digit, embedded birth date, governorate code) | Yes |
| Mobile number | رقم الهاتف | Egyptian mobile format `01[0125]\d{8}`; normalised to E.164 (`+20…`) for storage | Yes |
| Email | البريد الإلكتروني | RFC 5322; unique | Optional |
| Company name | اسم الشركة إن وجد | Free text or selection from the hospital's registered corporate-contract list | Optional |

Additional Phase 1 requirements:

- Date of birth and gender shall be **derived automatically** from the National ID and shown to the user for confirmation; the user may correct them, which raises a verification flag for reception.
- Registration completes only after **phone verification by 6-digit OTP** (SMS), valid for 5 minutes, maximum 5 attempts, rate-limited to 3 sends per phone number per hour.
- The user shall explicitly accept the Terms of Use and the Privacy Notice via unticked checkboxes. Pre-ticked consent is not acceptable.
- A separate, independently revocable opt-in shall be collected for marketing communications.
- Duplicate detection: if the National ID or phone number already exists, the app shall route the user to login/account-recovery rather than creating a second medical record.
- On success the server creates or links a **Medical Record Number (MRN)** in the patient master index.

### 6.3 Home Screen — *deck slide 3* **[P1]**

Four primary entry tiles, exactly as specified by the client:

1. **الرعاية المنزلية** — Home Care
2. **الشكاوى** — Complaints
3. **نصائح طبية** — Medical Tips
4. **العروض** — Offers

Plus, added for usability:

- A greeting row with the patient's first name and MRN.
- A **"Next appointment"** card when one exists, with a one-tap route to directions or cancellation.
- A **"Results ready"** badge when unread lab or radiology results exist.
- A quick-access row to Clinics, Radiology, Laboratory and Blood Bank (the services from slides 5–7).
- The persistent emergency call action described in Section 5.

### 6.4 Home Care (الرعاية المنزلية) **[P1]**

- Present the catalogue of home-care services offered by the hospital (nursing visit, physiotherapy, home sample collection, post-natal mother-and-baby care, elderly care, wound care, home medical equipment).
- Each service shows: description, price or price range, duration, and coverage area.
- Request flow: select service → select patient (self or dependant) → address (saved addresses plus map pin) → preferred date/time window → notes → confirm.
- The request produces a tracked ticket with statuses: `submitted` → `scheduled` → `en_route` → `in_progress` → `completed` / `cancelled`.
- The patient receives push notifications on every status change and may cancel free of charge until the `en_route` status.

### 6.5 Complaints (الشكاوى) **[P1]**

- Categories: appointment, clinical care, nursing, cleanliness, billing, staff conduct, facilities, other.
- Fields: category, related department, related visit (optional, selected from the patient's own visit history), free-text description, up to five attachments (image or PDF, ≤ 10 MB each).
- Submission returns a **reference number**. Status lifecycle: `received` → `under_review` → `resolved` / `escalated`, each with a timestamp and, where present, an official response visible to the patient.
- **Service-level target:** acknowledgement within 24 hours, first substantive response within 72 hours. The admin console shall surface breaches of this target.
- An anonymous submission option shall be offered; anonymous complaints cannot be status-tracked and the UI shall state this clearly before submission.

### 6.6 Medical File (الملف الطبي) — *deck slide 4* **[P1]**

The patient's own record, read-only from the app in Phase 1:

- **Identity & MRN**, blood group, allergies, chronic conditions, current medications.
- **Vitals history** (weight, blood pressure, blood glucose) with simple trend charts; patient-entered values shall be visually distinguished from clinician-recorded values.
- **Visit history**: date, clinic, doctor, diagnosis summary, attached documents.
- **Lab results** (Section 6.9) and **radiology reports** (Section 6.8), each downloadable as PDF.
- **Invoices and receipts**.
- **Export**: the patient may export the full file as a single PDF, and may share individual documents through the OS share sheet.
- **Maternity view [P1 for maternity patients]**: gestational age, expected delivery date, antenatal visit schedule with the next due visit highlighted, and the ultrasound scan history.

### 6.7 Clinics (العيادات) — *deck slide 5* **[P1]**

- Searchable, filterable list of clinics. The deck names **عيادة جراحة العظام** (Orthopaedic Surgery) as the worked example; the full clinic list shall be supplied by the hospital and shall be **server-driven, not hard-coded**.
- Clinic detail: description, consultant list, consultation fee, follow-up fee and follow-up window, working days and hours, location within the hospital.
- Doctor detail: photo, name, title, specialty and sub-specialty, qualifications, languages, available slots.
- **احجز الآن** (Book Now) flow:
  1. Select clinic → doctor (or "first available") → date → time slot.
  2. Select patient (self or dependant).
  3. Choose payment: pay at reception, or pay now (Section 13).
  4. Confirm. The patient receives an in-app confirmation, a push notification, and an SMS.
- Booking rules: slot capacity and overbooking policy are configured per clinic in the admin console; double-booking of the same patient in the same slot shall be rejected server-side; cancellation is permitted up to a configurable cut-off (default 4 hours before the appointment).
- **Add to device calendar** shall be offered on confirmation.
- Reminders: push at 24 hours and 2 hours before the appointment.

### 6.8 Radiology (الأشعة) — *deck slide 6* **[P1]**

- Modality selection exactly as specified in the deck:
  - **أشعة تليفزيونية** — Ultrasound / sonar
  - **أشعة عادية** — Plain X-ray
  - **أشعة مقطعية** — CT
  - (MRI and mammography shall be supported by the data model and enabled when the hospital confirms availability.)
- **أسعار الأشعة** — a price list per study, showing cash price and, where the patient has an active corporate or insurance contract, the contracted price and co-payment **[P2 for contract pricing]**.
- **مواعيد الأشعة** — the department's working hours and bookable slots per modality.
- Booking flow as per clinics, with the addition of **preparation instructions** (e.g. fasting, full bladder, contrast allergy screening) that the patient must acknowledge before confirmation.
- **Report delivery**: when the radiologist's report is finalised, the patient is notified and can read and download the PDF report in the Medical File. Image (DICOM) viewing is **[P2]**.

### 6.9 Laboratory & Blood Bank (التحاليل وبنك الدم) — *deck slide 7* **[P1]**

**Laboratory:**
- **أسعار التحاليل** — searchable test catalogue with price, sample type, turnaround time and preparation instructions. Profiles/panels shall be supported as a first-class entity.
- **العروض** — laboratory promotional packages (see Section 6.11).
- **نتائج التحاليل** — results, with:
  - Status per order: `ordered` → `sample_collected` → `in_progress` → `ready`.
  - Result view showing analyte, value, unit, reference range, and an out-of-range indicator.
  - PDF download and share.
  - **Critical-result rule:** results flagged critical by the laboratory shall **not** be released silently to the app. They shall be withheld from patient view until a clinician acknowledges them in the admin console, at which point the patient sees the result together with an instruction to contact the hospital. This behaviour is mandatory and non-negotiable.
- Home sample collection shall link into the Home Care module (Section 6.4).

**Blood Bank (خدمات بنك الدم):**
- Request blood units: component type, blood group, number of units, required date, requesting department or external hospital, attached request form.
- Register as a donor: donor profile, blood group, last donation date, eligibility self-screening questionnaire, and a next-eligible-date calculation.
- Donation appointment booking.
- Urgent appeals: the hospital may broadcast a targeted push notification to matching, eligible, opted-in donors. Targeting shall be by blood group and eligibility only; no other patient attribute may be used.

### 6.10 Contact & Emergency — *deck slide 8* **[P1]**

- One-tap dial to **01013009936**, presented prominently.
- Additional channels: WhatsApp, email, and a callback request form.
- Branch addresses with an "Open in Maps" action and live "open now / closed" status derived from working hours.
- **Ambulance request**: a distinct, unmistakable action that places the call and simultaneously submits the patient's location and MRN to the dispatcher. The UI shall make clear that the phone call is the authoritative channel and that the in-app request is supplementary.

### 6.11 Offers & Events (العروض) — *deck slide 10* **[P1]**

- Promotional offers with: title, hero image, description, price before and after, validity window, applicable services, terms, and a direct booking action.
- **Health-awareness events**, as named in the deck: World Cancer Day, International Women's Day, World Children's Day — plus a hospital-managed calendar for others.
- Offers shall be authored and scheduled entirely from the admin console. **No offer content shall require an app release.**
- Offers may be targeted by gender, age band and language. Targeting on any clinical attribute is prohibited.

### 6.12 Medical Tips (نصائح طبية) — *deck slide 11* **[P1]**

Content categories exactly as specified by the client — **عام** (General), **تغذية** (Nutrition), **أمومة** (Maternity), **قلب** (Cardiac), **جلدية** (Dermatology) — extensible from the admin console.

The five tips supplied in the deck shall be seeded as launch content:

| Category | Tip (Arabic, as supplied) |
|---|---|
| عام | المضادات الحيوية تعالج العدوى البكتيرية وليس الفيروسية، لذلك لا تعالج الأنفلونزا لأنها عدوى فيروسية |
| تغذية | سمك السلمون يحتوي على كمية عالية من أوميجا 3 |
| أمومة | الكالسيوم يلعب دورًا هامًا في نمو العظام وتجلط الدم |
| قلب | التدخين من الأسباب الرئيسية لأمراض القلب |
| جلدية | لا تستخدم الماء الساخن لغسيل الوجه |

Requirements:
- Card feed with category filter, search, save-for-later, and share.
- Every item shall carry a **medical reviewer name and review date**. Unreviewed content shall not be publishable.
- Every item shall display a standing disclaimer: this content is general health information and is not a substitute for medical consultation.
- Content shall be authored in both Arabic and English; if an English translation is absent, the Arabic is shown with a language indicator.

---

## 7. Phase 2 & Phase 3 — Recommended Extensions

These are the vendor's additions. They are not in the client's deck. They are listed with a recommended phase and are individually priced in the accompanying commercial estimate.

### 7.1 Phase 2 — Depth

| # | Module | Description |
|---|---|---|
| 7.1.1 | **Dependants & family accounts** | Manage children, spouse and parents under one login, with consent records, and an automatic transition of a minor to an independent account at 18. |
| 7.1.2 | **Teleconsultation** | Scheduled video consultations (WebRTC), in-consultation chat, file exchange, automatic session recording policy, and a post-consultation summary. |
| 7.1.3 | **E-prescriptions** | Digital prescriptions in the Medical File, with a QR code for pharmacy dispensing and a refill-reminder engine. |
| 7.1.4 | **Pharmacy** | Hospital pharmacy catalogue, prescription upload, price check, home delivery, and order tracking. |
| 7.1.5 | **Insurance & corporate contracts** | Eligibility check, pre-approval submission and status, contracted price display, co-payment calculation, and approval-letter storage. Directly supports the "اسم الشركة" field already present in the deck's registration screen. |
| 7.1.6 | **Payments & wallet** | Full in-app payment (Section 13), invoice history, refunds, instalments and a stored-credit wallet. |
| 7.1.7 | **Queue & live waiting status** | Ticket number, live position in the queue, estimated call time, and a "leave the waiting room, we will notify you" mode. |
| 7.1.8 | **Pregnancy companion** | Week-by-week pregnancy tracking, kick counter, contraction timer, antenatal checklist, birth-plan document, and a hospital-bag checklist. This is the highest-value differentiator for a maternity hospital and is strongly recommended. |
| 7.1.9 | **Newborn & vaccination record** | Baby profile linked to the mother, growth charts (WHO percentiles), Egyptian national immunisation schedule with due-date reminders, and vaccination certificates. |
| 7.1.10 | **DICOM image viewer** | In-app viewing of radiology images with pan, zoom, window/level and series navigation. |
| 7.1.11 | **Ratings & NPS** | Post-visit rating of the doctor, department and overall experience, with an NPS dashboard for management. |
| 7.1.12 | **Loyalty & referrals** | Points on completed visits, redemption against services, and a referral scheme. |
| 7.1.13 | **iPad / tablet layouts** | Adaptive two-pane layouts. |

### 7.2 Phase 3 — Platform

| # | Module | Description |
|---|---|---|
| 7.2.1 | **Staff companion app** | Doctor schedule, patient list, result acknowledgement (including the critical-result workflow in Section 6.9), and home-care visit check-in/check-out with geolocation. |
| 7.2.2 | **HIS / LIS / RIS-PACS integration** | Replace manual admin entry with live integration to the hospital's core systems over **HL7 v2** and/or **HL7 FHIR R4**, and **DICOM** for imaging. See Section 10. |
| 7.2.3 | **Bed & admission management surface** | Inpatient admission status, room, estimated discharge, and running bill visible to the family. |
| 7.2.4 | **Analytics & management dashboards** | Bookings, no-show rate, revenue by service line, complaint SLA compliance, campaign performance. |
| 7.2.5 | **Wearable & home-device integration** | Apple HealthKit and Google Health Connect for weight, blood pressure and glucose. |
| 7.2.6 | **Arabic voice search & accessibility mode** | Voice-driven navigation and a simplified high-contrast, large-type mode for elderly users. |

---

## 8. Data Model (Core Entities)

The implementer shall produce a full ERD. At minimum, the following entities and relationships are required.

```
Patient (MRN, national_id_hash, name, dob, gender, phone_e164, email,
         blood_group, allergies[], chronic_conditions[], corporate_id?, created_at)
  ├─< PatientConsent (type, granted_at, revoked_at, version, ip, device)
  ├─< Dependant (relationship, linked_patient_mrn, consent_id)          [P2]
  ├─< Address (label, governorate, city, street, lat, lng, is_default)
  ├─< Device (push_token, platform, app_version, last_seen_at)
  └─< AuditLogEntry (actor, action, entity, entity_id, at, ip)

Department (code, name_ar, name_en, type: clinic|radiology|lab|blood_bank|home_care)
  └─< Clinic (department_id, consultation_fee, followup_fee, followup_window_days)
        └─< Doctor (name, title, specialty, sub_specialty, languages[], photo)
              └─< ScheduleTemplate ──< Slot (start_at, end_at, capacity, booked_count)

Appointment (patient_id, slot_id, type: clinic|radiology|lab|homecare, status,
             payment_status, price, created_at, cancelled_at, cancel_reason)

Order (patient_id, type: lab|radiology, items[], status, ordered_by, ordered_at)
  └─< ResultDocument (order_id, kind, pdf_url, released_at, is_critical,
                      acknowledged_by, acknowledged_at)
        └─< ResultAnalyte (code, name, value, unit, ref_low, ref_high, flag)

HomeCareRequest (patient_id, service_id, address_id, window_start, window_end,
                 status, assigned_staff_id, notes)

Complaint (patient_id?, is_anonymous, category, department_id?, visit_id?, body,
           attachments[], status, reference_no, response_body, sla_due_at)

Offer (title_ar, title_en, body, media, price_before, price_after,
       valid_from, valid_to, target_rules, services[])

MedicalTip (category, body_ar, body_en, media, reviewer_name, reviewed_at, published_at)

BloodBankRequest / DonorProfile / DonationAppointment

Invoice (patient_id, lines[], subtotal, discount, tax, total, status)
  └─< Payment (provider, provider_ref, amount, status, paid_at)          [P2]

CorporateContract (company_name, tax_id, price_list_id, active_from, active_to) [P2]
```

**Mandatory data rules:**

1. The national ID shall be stored **hashed** (salted, per-record) for duplicate detection, with the plaintext value held encrypted at rest and readable only by roles with an explicit business need. It shall never be returned in an API response to the mobile client after registration.
2. All timestamps shall be stored in UTC and rendered in `Africa/Cairo`.
3. Clinical records shall be **append-only**. Corrections create a new version; nothing is destructively updated.
4. Every read of another person's medical data (staff or dependant manager) shall write an audit-log entry.

---

## 9. API Requirements

- **Style:** REST over HTTPS, JSON, versioned at the path root (`/api/v1/…`). GraphQL is acceptable if the vendor justifies it.
- **Specification:** an **OpenAPI 3.1** document shall be maintained in the repository and shall be the contract of record. The mobile client's API types shall be generated from it, not hand-written.
- **Auth:** `Authorization: Bearer <access_token>`; 15-minute access tokens; 30-day refresh tokens with rotation and reuse detection.
- **Errors:** a single error envelope with a stable machine-readable `code`, an Arabic message, an English message, and an optional `field` for validation failures. HTTP status codes shall be used correctly.
- **Pagination:** cursor-based on all collections. Offset pagination is not acceptable for lists that grow.
- **Idempotency:** all booking, payment and request-creation endpoints shall accept an `Idempotency-Key` header and shall be safe to retry.
- **Rate limiting:** per IP and per account, with stricter limits on OTP, login and search endpoints.
- **Localisation:** the client shall send `Accept-Language: ar-EG` or `en`; the server returns localised content and error messages accordingly.

Indicative endpoint groups: `/auth`, `/patients/me`, `/dependants`, `/departments`, `/clinics`, `/doctors`, `/slots`, `/appointments`, `/orders`, `/results`, `/home-care`, `/complaints`, `/offers`, `/tips`, `/blood-bank`, `/invoices`, `/payments`, `/devices`, `/content`.

---

## 10. Integrations

| System | Protocol | Phase | Notes |
|---|---|---|---|
| SMS gateway (OTP + transactional) | Provider REST API | P1 | Egyptian provider with a registered alphanumeric sender ID; the vendor shall confirm the sender-ID registration lead time |
| Push notification | FCM + APNs | P1 | |
| Maps & geocoding | Google Maps SDK / Mapbox | P1 | Branch locations, home-care addresses |
| WhatsApp Business | Cloud API | P2 | Booking confirmations and complaint responses |
| Payment gateway | **Paymob** and/or **Fawry**, plus Meeza/InstaPay | P2 | Section 13 |
| HIS / EMR | HL7 v2 (ADT, ORM, ORU) or FHIR R4 | P3 | Patient identity, visits, orders, results |
| LIS | HL7 ORU / vendor API | P3 | Automated result release |
| RIS / PACS | HL7 + DICOMweb (WADO-RS, QIDO-RS) | P3 | Reports and images |
| Health platforms | HealthKit / Health Connect | P3 | Vitals |

**Until Phase 3 integration is delivered, all clinical content (results, reports, visit records) reaches the app through the admin console (Section 14).** This is an explicit, accepted operational cost of Phase 1 and shall be sized with the hospital before launch.

---

## 11. Security, Privacy & Compliance

### 11.1 Non-Negotiable Controls

1. **Transport:** TLS 1.2+ everywhere. Certificate pinning on the mobile clients, with a documented rotation procedure and a remote kill-switch so that a certificate change cannot brick installed apps.
2. **At rest:** database encryption at rest; column-level encryption for national ID, and for clinical free-text fields.
3. **Authentication:** phone + OTP as the primary factor. Optional biometric unlock (Face ID / Touch ID / Android BiometricPrompt) gating access to the Medical File on every foreground entry.
4. **Session:** automatic logout after 15 minutes of inactivity while the Medical File is open. Screenshot blocking on result screens (Android `FLAG_SECURE`; iOS screen-recording detection and content masking).
5. **Authorisation:** enforced server-side per request; object-level checks on every record access. No endpoint may return another patient's data on the basis of a client-supplied identifier alone.
6. **Audit:** immutable audit log of every access to medical data, retained for a minimum of 5 years.
7. **Secrets:** no API keys, tokens or endpoints hard-coded in the mobile binary. Secrets live in a managed secret store.
8. **Storage:** no protected health information in device logs, in crash-report payloads, in analytics events, or in unencrypted local storage. Sensitive tokens live in Keychain / Android Keystore.
9. **Data residency:** patient data shall be hosted in a jurisdiction agreed in writing with the hospital, with a documented backup and restore procedure and a tested disaster-recovery plan (target RPO ≤ 1 hour, RTO ≤ 4 hours).

### 11.2 Regulatory

- The system shall be built to comply with **Egyptian Personal Data Protection Law No. 151 of 2018** and its executive regulations, including lawful basis, explicit consent for sensitive (health) data, data-subject rights (access, correction, erasure, portability), breach notification, and appointment of a data protection officer where required.
- The application shall comply with **Apple App Store Review Guideline 5.1.1** (health and medical data) and **Google Play's Health Apps and Sensitive Data policies**, including the Data Safety declaration.
- A **Records of Processing Activities** register and a **Data Protection Impact Assessment** shall be delivered with the system.
- Where the hospital is subject to Egyptian Ministry of Health or Universal Health Insurance Authority requirements for electronic medical records, the vendor shall document the gap and the remediation path.
- The app shall carry a clear statement that it does not provide diagnosis and is not for emergency use, with the emergency number presented alongside.

### 11.3 Testing

A third-party penetration test and an OWASP MASVS Level 1 (minimum) assessment shall be completed before production launch, with all high and critical findings remediated and retested.

---

## 12. Localisation, Accessibility & Notifications

### 12.1 Localisation

- Languages: **Arabic (ar-EG)** — default; **English (en)**.
- Full RTL layout mirroring: navigation, icons with direction, sliders, progress, charts, back gestures.
- Language switchable in-app without restart; the choice persists and is sent to the server for content and notification localisation.
- No string may be hard-coded in a component. All copy lives in translation files and is reviewed by a native Arabic medical copy editor.
- Number, date, currency (EGP) and name formatting shall follow locale conventions.

### 12.2 Accessibility

- WCAG 2.2 AA as the target.
- Full VoiceOver and TalkBack labelling, including Arabic labels.
- Dynamic type support up to 200% without truncation or overlap.
- No information conveyed by colour alone; out-of-range lab values shall carry an icon and text, not just a red colour.
- Reduce-motion support.

### 12.3 Notifications & Deep Links

Notification types (each independently toggleable by the patient):

| Type | Trigger | Default |
|---|---|---|
| Appointment confirmed | Booking success | On (transactional, not disableable) |
| Appointment reminder | T-24 h and T-2 h | On |
| Appointment changed / cancelled | Staff action | On (transactional) |
| Result ready | Result released | On |
| Home-care status change | Status transition | On |
| Complaint response | Staff response | On |
| Offers & campaigns | Marketing schedule | **Off — explicit opt-in required** |
| Blood-bank urgent appeal | Targeted broadcast | Off — donor opt-in required |

- Notification payloads shall contain **no clinical detail** — "Your laboratory result is ready" is acceptable; the analyte and value are not.
- Universal Links (iOS) and App Links (Android) shall be configured for every shareable entity: offer, tip, clinic, doctor, appointment, result.

---

## 13. Payments **[P2, with Phase 1 hooks]**

- Phase 1 shall record a `payment_status` of `pay_at_reception` on every booking, so that the Phase 2 payment module can be added without a data migration.
- Phase 2 shall integrate **Paymob** and/or **Fawry**, supporting card, Meeza, mobile wallets, InstaPay and Fawry reference-code payment.
- **PCI DSS scope shall be minimised** — card data shall never touch the hospital's servers or the mobile binary. Hosted fields or the provider SDK only.
- Requirements: 3-D Secure, webhook-driven reconciliation (never client-reported success), idempotent capture, full and partial refunds, VAT-compliant electronic invoicing aligned with Egyptian Tax Authority e-invoice requirements, and a daily settlement report for finance.

---

## 14. Admin Console (Back-Office)

A responsive web application, delivered as part of the same programme. Without it the mobile app has no content and no operational workflow — **it is not optional and it is not a Phase 2 item.**

Modules: patients & MRN search · departments, clinics, doctors, schedules & slots · appointments (create, reschedule, cancel, no-show marking) · lab test catalogue & pricing · lab orders and **result upload with the critical-result acknowledgement gate** · radiology catalogue, schedules, report upload · home-care service catalogue, request queue, staff assignment · complaints inbox with SLA timers and response composer · offers & events authoring with scheduling and targeting · medical tips authoring with the medical-review gate · blood-bank requests, donor registry and appeal broadcasting · push-notification composer with audience segments and a mandatory test-send step · corporate contracts and price lists **[P2]** · invoices and payments **[P2]** · user, role and permission management · audit-log viewer · dashboards.

Every destructive or clinical action in the console shall require a confirmation step and shall be recorded in the audit log with the acting user.

---

## 15. Analytics

- Product analytics (recommended: PostHog self-hosted, or Firebase Analytics) with an agreed event taxonomy defined **before** implementation.
- **No protected health information in any analytics event.** Events carry a pseudonymous identifier, screen name, and non-clinical properties only.
- Required funnels: registration completion, booking completion, result-view rate, home-care request completion, offer click-through.
- Crash and performance monitoring via Sentry, with source maps / dSYMs uploaded on every release.
- Analytics shall be disabled until the user's consent choice is captured on first launch.

---

## 16. Quality Assurance & Acceptance

### 16.1 Test Coverage

| Layer | Requirement |
|---|---|
| Unit | ≥ 70% line coverage on business logic; 100% on national-ID validation, slot-availability, pricing, and result-release rules |
| Integration | All API endpoints, against a seeded test database |
| End-to-end | The eight critical journeys listed in 16.2, automated (Detox / Maestro / Patrol) and run in CI |
| Manual | A device matrix agreed with the hospital, to include at least two low-end Android devices (≤ 3 GB RAM) and the oldest supported iPhone |
| Accessibility | Screen-reader pass in both Arabic and English on every Phase 1 screen |
| Security | Section 11.3 |
| Localisation | Full RTL visual review of every screen; no clipped, mirrored-incorrectly, or untranslated strings |

### 16.2 Critical Journeys (must pass to accept Phase 1)

1. Register with a valid Egyptian National ID and verify by OTP.
2. Log in, log out, and recover access on a new device.
3. Book, receive confirmation for, and cancel a clinic appointment.
4. Book a radiology study and acknowledge its preparation instructions.
5. View, download and share a released laboratory result — and confirm that a result flagged critical is **not** visible before clinician acknowledgement.
6. Submit a home-care request and follow it to `completed`.
7. Submit a complaint and receive a reference number and a response.
8. Switch language to English and back, and complete journey 3 in each direction.

### 16.3 Acceptance Criteria

Phase 1 is accepted when: all Section 16.2 journeys pass on both platforms; the performance budget in Section 4.4 is met; all high and critical penetration-test findings are closed; both store submissions are approved; the admin console supports every workflow in Section 14; and the handover package in Section 18 is delivered in full.

---

## 17. Delivery Plan

| Milestone | Contents | Indicative duration |
|---|---|---|
| **M0 — Discovery & sign-off** | Requirement workshops, open questions closed, brand assets received, final clinic/test/service catalogues received, API contract agreed | 2 weeks |
| **M1 — Design** | Full UI kit, all Phase 1 screens in Arabic RTL and English LTR, clickable prototype, client sign-off | 3 weeks |
| **M2 — Foundation** | Backend scaffold, database, auth + OTP, admin console shell, CI/CD, environments | 3 weeks |
| **M3 — Core patient app** | Registration, home, clinics, booking, medical file | 4 weeks |
| **M4 — Clinical services** | Radiology, laboratory, results, blood bank | 3 weeks |
| **M5 — Engagement** | Home care, complaints, offers, medical tips, notifications | 3 weeks |
| **M6 — Hardening** | QA, accessibility, localisation review, penetration test and remediation, performance tuning | 3 weeks |
| **M7 — Launch** | Store submission, pilot with a limited patient group, production monitoring, staff training | 2 weeks |

**Indicative Phase 1 total: 21 weeks**, assuming the hospital meets its obligations in Section 18.2 on schedule.

---

## 18. Deliverables & Responsibilities

### 18.1 Vendor Deliverables

1. iOS application, published to the App Store under the hospital's developer account.
2. Android application, published to Google Play under the hospital's developer account.
3. Backend API and admin console, deployed to the agreed infrastructure.
4. Full source code in the hospital's Git repository, with commit history.
5. OpenAPI specification, ERD, and architecture documentation.
6. Design files (Figma) with a complete component library.
7. Deployment runbook, environment configuration guide, and disaster-recovery procedure.
8. Admin console user manual in Arabic, plus two training sessions for hospital staff.
9. Penetration-test report and remediation evidence.
10. Data Protection Impact Assessment and processing register.
11. Warranty: defect remediation at no charge for the agreed warranty period after launch.

### 18.2 Hospital Responsibilities

The following are prerequisites and are on the hospital's critical path:

- Official brand assets: vector logo, colour specification, approved photography.
- Complete catalogues: clinics, doctors and schedules; laboratory tests with prices; radiology studies with prices; home-care services with prices.
- Legally reviewed Terms of Use, Privacy Notice, and medical disclaimer.
- Apple Developer Program and Google Play Console accounts, under the hospital's legal entity.
- SMS gateway account and registered sender ID.
- Named clinical reviewer for medical-tip content.
- Named operational owners for: complaints SLA, result release, home-care dispatch, and offer publishing.
- Decision on hosting jurisdiction and provider.
- Access to HIS/LIS/RIS vendors and their integration documentation (Phase 3).

---

## 19. Open Questions — To Be Closed Before Development

These are the points this document could not resolve from the supplied material. Each requires a written answer from the hospital.

1. **Brand:** exact hex values and the vector logo file. The palette in Section 2.1 is derived from photographs and is approximate.
2. **Catalogues:** the deck names only one clinic (Orthopaedic Surgery) and three radiology modalities. The full clinic, doctor, test and service lists are required.
3. **Corporate contracts:** the registration screen collects "اسم الشركة". Is corporate/insurance pricing in scope for Phase 1, or Phase 2 as proposed here?
4. **Existing systems:** does the hospital already run an HIS, LIS or PACS? Which vendor, which version, and does it expose an API? This single answer materially changes the Phase 3 estimate.
5. **Branches:** one site or several? Branch-level booking changes the slot model.
6. **Payments:** is in-app payment required at launch, or is pay-at-reception acceptable for Phase 1 as proposed?
7. **Result release policy:** who is clinically accountable for releasing results to patients, and what is the maximum acceptable delay?
8. **Home care coverage:** which governorates and districts, and what is the pricing model (flat, distance-based, or per service)?
9. **Complaint SLA:** are the 24 h / 72 h targets in Section 6.5 acceptable to the hospital, and who owns the escalation path?
10. **Blood bank:** does the hospital operate a licensed blood bank directly, and what regulatory constraints apply to donor data and appeals?
11. **Content ownership:** who authors and clinically approves medical tips on an ongoing basis?
12. **Hosting:** cloud provider, region, and whether data must remain within Egypt.
13. **Support model:** required post-launch support hours, response times, and whether the vendor or the hospital operates the admin console day to day.

---

## 20. Explicitly Out Of Scope (Phase 1)

Clinical decision support; ICD-10 or CPT coding; inpatient/ward management; pharmacy stock and inventory; HR, payroll and rostering; general accounting and the general ledger; medical-equipment maintenance; a public marketing website; any migration of historical paper records.

---

*End of document.*
