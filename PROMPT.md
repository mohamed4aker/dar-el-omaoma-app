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

### 2.5 Developer Attribution

The application shall carry a discreet credit to the development company. The objective is durable, professional attribution that neither intrudes on the patient experience nor embarrasses the hospital.

**Where attribution appears:**

| Placement | Treatment |
|---|---|
| **More → About** (patient app) | A dedicated block: *"Developed by <Company>"* with the company logo, website and a contact action. This is the primary placement. |
| **Login screen footer** (patient app) | A single muted line at 11 pt in `neutral/muted`: *"Developed by <Company>"*, tappable to the About block. Nothing more. |
| **Admin console footer** (every page) | *"<Company> — support: <phone> / <email>"*. Staff use this daily and it is the channel through which support requests arrive; here it is useful rather than decorative. |
| **Generated PDF reports** (admin console exports) | A one-line footer alongside the page number. |

**Where attribution shall never appear:**

- The splash screen — it delays the patient and reads as an advertisement.
- The home screen, or any clinical screen: results, medical file, booking flows, emergency actions.
- Push notifications, SMS or WhatsApp messages.
- Any modal, banner, interstitial or toast.

**Contractual note.** The placements above shall be written into the contract as an agreed, permanent part of the product, so that neither party can unilaterally remove or expand them later. If the hospital requires a fully white-labelled product with no attribution, that is a legitimate request and shall be priced as a separate licence option — not conceded for free.

**App store listings.** Where the applications are published under the hospital's developer account (as required by §18.2), the publisher shown by Apple and Google is the hospital. The in-app attribution above is therefore the only durable credit, which is precisely why its placement is specified here rather than left to implementation.

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
| `doctor` | A credentialed practitioner. Sees own schedule and patient list, **books operating-theatre sessions directly without approval** (§6.13), books clinic patients, and initiates visiting-expert cases (§6.15). |
| `staff_*` | Back-office roles in the admin console: `staff_reception`, `staff_lab`, `staff_radiology`, `staff_homecare`, `staff_marketing`, `staff_complaints`, `staff_finance`, `staff_or_scheduler`. |
| `surgery_approver` | Approves or rejects **patient-initiated** surgery requests (§6.13.6). Held by the medical director, department heads, and any staff member the admin grants it to. Multiple holders; any one may act. |
| `center_manager` | Manages a specialty centre (§6.14): its procedures, clinics, doctors, pricing and content. Scoped to one centre only. |
| `visiting_program_coordinator` | Creates and runs visiting-expert campaigns (§6.15). |
| `admin` | Full administrative control, including user management, permission assignment and audit-log review. |

### 3.3 Permission Model

Roles are **containers for permissions, not hard-coded behaviour.** The admin console shall allow an administrator to create custom roles and assign individual permissions to them. Shipping with fixed, non-editable roles is not acceptable — the hospital's org chart will not match the vendor's assumptions.

| Permission | `patient` | `doctor` | `staff_or_scheduler` | `surgery_approver` | `center_manager` | `admin` |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| View theatre availability | summary only | ✔ full | ✔ full | ✔ full | ✔ own centre | ✔ |
| **Book a theatre session directly (no approval)** | ✖ | **✔** | ✔ | ✔ | ✔ own centre | ✔ |
| Request a surgery (requires approval) | ✔ | — | — | — | — | — |
| Approve / reject a patient surgery request | ✖ | ✖ | ✖ | **✔** | ✔ own centre | ✔ |
| Override a booking conflict (with mandatory reason) | ✖ | ✖ | ✔ | ✔ | ✖ | ✔ |
| Cancel / postpone another user's booking | own only | own only | ✔ | ✔ | ✔ own centre | ✔ |
| Book a clinic appointment for a patient | own only | ✔ | ✔ | ✔ | ✔ own centre | ✔ |
| Manage operation classifications | ✖ | ✖ | ✖ | ✖ | ✖ | **✔** |
| Manage centre catalogue, clinics & pricing | ✖ | ✖ | ✖ | ✖ | ✔ own centre | ✔ |
| Create / run a visiting-expert campaign | ✖ | propose | ✖ | ✔ | ✔ own centre | ✔ |
| View clinical reports | own data | own patients | operational only | ✔ | ✔ own centre | ✔ |
| View financial reports | own invoices | own revenue | ✖ | ✖ | ✔ own centre | ✔ |
| Manage users, roles & permissions | ✖ | ✖ | ✖ | ✖ | ✖ | ✔ |
| View audit log | own access history | ✖ | ✖ | ✖ | ✖ | ✔ |

**Rules that apply to the whole permission model:**

1. Every permission is enforced **server-side on every request**. The matrix above describes the UI; it does not implement security.
2. Permission changes are themselves audited: who granted what, to whom, when.
3. **Every approval permission shall have at least two holders and a named escalation target.** A single approver who is on leave must never be able to stall patient requests — see the escalation rule in §6.13.6.
4. `center_manager` and any centre-scoped role are constrained by **row-level** authorisation, not by hiding menu items.
5. A user may hold several roles; permissions are the union, and the most permissive scope wins.

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
                │   ├── Blood Bank ── Services ── Donate / Request
                │   ├── Surgery ── Procedure catalogue ── Estimate ── Request ── Status
                │   ├── Centres ── Surgery Centre ── Specialties ── Clinics / Procedures
                │   └── Visiting Experts ── Campaign ── Expert profile ── Screening booking
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

**Doctor mode.** A user who signs in with the `doctor` role sees an additional tab — **My Practice** — containing the theatre availability grid (§6.13.4), direct theatre booking, their own clinic schedule and patient list, their visiting-expert cohorts (§6.15), and their pending items. This is the same binary as the patient app, not a separate application; the tab is revealed by the server-issued role and never by a client-side flag.

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

### 6.13 Operating Theatre & Surgery Booking (حجز العمليات) **[P1]**

This is the largest module in the system and the one with the greatest operational and clinical risk. It is specified in full.

#### 6.13.1 Operating Theatres

The admin console maintains the theatre register: code, display name, type (general, obstetric, minor-procedures, endoscopy), floor and location, fixed equipment, default turnover time, and an active/inactive state. Theatres may be taken out of service for maintenance for a defined window; a theatre out of service shall not be bookable and any existing booking inside that window shall be surfaced for rescheduling rather than silently invalidated.

#### 6.13.2 Operation Classifications (التصنيفات) — Admin-Managed

Classifications are **data, not code.** The system ships seeded with the client's four:

| Code | Arabic | English |
|---|---|---|
| `minor` | صغرى | Minor |
| `intermediate` | متوسطة | Intermediate |
| `major` | كبرى | Major |
| `specialised` | ذات مهارة | Specialised / high-skill |

The administrator shall be able to **create, rename, reorder, deactivate and recolour classifications at any time, without a code change or an app release.** Each classification carries configurable defaults that pre-fill a booking and reduce scheduling error:

| Attribute | Purpose |
|---|---|
| Default duration | Pre-fills the theatre slot length |
| Default turnover time | Cleaning and preparation before the next case |
| Price band (min–max) | Drives the patient-facing estimate in §6.13.7 |
| Required surgeon seniority | Warns when the booked surgeon is below it |
| Default anaesthesia type | General, spinal, local, sedation |
| Blood units to reserve by default | Triggers the blood-bank hold in §6.13.9 |
| Default pre-operative investigation set | Auto-orders labs and radiology in §6.13.9 |
| Colour | Used consistently in the availability grid and all reports |

Deactivating a classification shall never alter historical bookings. Records keep the classification they were created with.

#### 6.13.3 Procedure Catalogue

Each procedure: Arabic and English name, internal code, **classification**, owning department or centre, typical duration, required theatre type, required equipment and instrument sets, required team composition, default surgeon list, cash price or price range, and whether it is available to patients for request in the app.

#### 6.13.4 Theatre Availability View (الفاضي والمحجوز)

The core screen of the module, available to doctors in the mobile app and to schedulers in the admin console.

- A **grid: theatres down one axis, time across the other**, with day and week views, honouring RTL.
- Each block is colour-coded by state — `available`, `booked`, `provisional` (awaiting approval), `turnover`, `blocked` (maintenance), `emergency reserve` — and by operation classification, using the colours in §6.13.2. Colour shall never be the only signal: every block carries a text label and, where applicable, an icon (§12.2).
- Filters: theatre, date range, surgeon, department, centre, classification, status.
- A booked block shows the procedure, the surgeon and the classification. **It shall not show the patient's name to a doctor who is not part of that case's team** — this is a privacy boundary, not a UI preference.
- Available capacity per theatre per day shall be shown as a summary figure so a surgeon can find a free day at a glance without scanning the grid.
- The grid shall update in near-real time (server-sent events or polling ≤ 30 s). Two surgeons viewing the same slot must not both believe it is free.

#### 6.13.5 Doctor-Initiated Booking — Direct, No Approval

**A credentialed doctor books a theatre session directly. The booking is confirmed immediately. No approval step, no waiting for anyone.** This is an explicit client requirement and shall not be diluted into a "fast-track approval".

Flow: open availability → select theatre and slot → select procedure (classification and duration pre-fill from §6.13.2) → select or search the patient → set anaesthesia type, team, required equipment, and blood reservation → add notes → confirm.

**"No approval" does not mean "no rules."** The server shall reject, and the client shall prevent, any booking that:

| Conflict | Behaviour |
|---|---|
| Theatre already booked, or inside another case's turnover window | **Hard block** |
| The surgeon is already booked elsewhere at that time — including in a clinic | **Hard block** |
| The patient is already scheduled for another procedure or appointment at that time | **Hard block** |
| Required equipment or instrument set is committed to another case | **Hard block** |
| Theatre is blocked for maintenance | **Hard block** |
| The procedure's required theatre type does not match | Warning, may proceed with a reason |
| Surgeon seniority is below the classification's requirement | Warning, may proceed with a reason; notifies the department head |
| The booking is outside the theatre's normal operating hours | Warning, may proceed with a reason |

Hard blocks are overridable **only** by a user holding the override permission (§3.3), and only with a mandatory free-text reason that is written to the audit log and notified to the medical director. Every override is a report line (§14.1).

Concurrency: slot booking shall be enforced with a database-level constraint or a transactional lock, not an application-level check. Two doctors tapping "confirm" on the same slot within the same second is an expected event, not an edge case; exactly one shall succeed and the other shall receive a clear, immediate "this slot was just taken" message with the refreshed grid.

#### 6.13.6 Patient-Initiated Request — Approval Required

A patient may **request** a surgery from the app. The request is never a confirmed booking.

Flow: select procedure from the patient-visible catalogue → preferred surgeon (optional) → preferred date range → upload supporting documents and prior reports → see the price estimate (§6.13.7) → acknowledge that this is a request subject to medical review → submit.

- Status lifecycle: `submitted` → `under_review` → `approved` → `scheduled` → … , or `rejected` / `more_info_required` / `cancelled_by_patient`.
- On submission the system **immediately notifies every holder of the `surgery_approver` permission** by push, by WhatsApp (§12.4), and in the admin console inbox.
- **Escalation is mandatory.** If no approver acts within a configurable window (default 4 working hours), the request escalates to the medical director and the escalation is recorded. If it is still unactioned after a second window (default 24 hours), it appears on the daily management report. Patient requests shall never be able to sit unanswered.
- The approver sees the patient's medical file, the uploaded documents, the requested procedure and its classification, and theatre availability — in one screen, with **approve**, **approve and schedule now**, **request more information**, and **reject with reason** as the available actions.
- A rejection requires a reason from an admin-managed list plus free text. The patient sees a courteous message and a route to book a consultation clinic instead. **A rejected surgery request shall never be a dead end.**
- Once approved and scheduled, the case joins the same theatre schedule as a doctor-initiated booking and is indistinguishable from it thereafter.

**Clinic appointments remain immediate for patients** (§6.7) — no approval, live availability. Only theatre bookings require approval. The app shall make this distinction obvious so that a patient is never confused about what they have and have not secured.

#### 6.13.7 Price Estimate

Before submitting a request, the patient sees an estimate: the procedure's price or the classification's price band, plus the expected additions (theatre, anaesthesia, stay, implants where applicable), the contracted price and co-payment if an insurance or corporate contract applies **[P2]**, and a clear, prominent statement that the figure is an estimate subject to clinical assessment. The estimate as shown shall be stored with the request so that any later dispute can be resolved against what the patient actually saw.

#### 6.13.8 Case Lifecycle & Theatre Day

`scheduled` → `pre_op_ready` → `patient_in_theatre` → `procedure_started` → `procedure_finished` → `in_recovery` → `completed`, with `postponed` and `cancelled` available at any point before completion.

- **Cancellation and postponement require a coded reason** from an admin-managed list (patient unfit, patient did not attend, equipment unavailable, surgeon unavailable, emergency case took priority, theatre overrun, financial, other). This list is the single most valuable data source the module produces — it is what §14.1 turns into an improvement programme.
- **Cancellation waiting list:** when a slot is released, the system shall automatically identify waiting patients who match the theatre type, classification and surgeon, and notify them of the opening in priority order.
- **Emergency bumping:** an emergency case may displace a scheduled elective case. The displaced patient and surgeon shall be notified immediately, automatically, with an apology and a rescheduling action — never left to discover it on arrival.
- **Actual versus estimated duration** shall be captured on every case. The system shall surface, per procedure and per surgeon, where the estimate is consistently wrong, so that scheduling improves over time.

#### 6.13.9 Clinical Safety & Integration — Added By The Vendor

These are not in the client's brief. They are what separates a booking calendar from a theatre system, and they are strongly recommended for Phase 1.

| Capability | Description |
|---|---|
| **Digital informed consent** | Procedure-specific consent text in Arabic, captured with an on-screen signature from the patient (and guardian where applicable), timestamped, versioned, and stored in the medical file. In a surgical hospital this is the single highest-value medico-legal artefact the system can produce. |
| **WHO Surgical Safety Checklist** | The three-phase checklist — sign in, time out, sign out — completed in the theatre and stored against the case. It is an international standard and a requirement for GAHAR and JCI accreditation. |
| **Pre-operative bundle** | On booking, automatically raise the classification's default investigation set (§6.13.2) as laboratory and radiology orders (§6.8, §6.9), and show the case as `pre_op_ready` only when all results are back. Missing pre-op investigations are a leading cause of same-day cancellation. |
| **Anaesthesia assessment** | An assessment appointment booked automatically for classifications that require it, with ASA grading recorded against the case. |
| **Blood reservation** | The classification's default blood units automatically raise a cross-match and hold request in the blood bank (§6.9). A case requiring blood shall not reach `pre_op_ready` until the hold is confirmed. This makes the existing blood-bank module operationally essential rather than informational. |
| **Equipment & instrument-set reservation** | Sets are reserved with the theatre slot and released on cancellation. Double-committed equipment is a hard block (§6.13.5). |
| **Implant & prosthesis traceability** | For orthopaedic and neurosurgical cases: manufacturer, model, lot and serial recorded against the patient. Required for recall response and for accreditation. |
| **Theatre team roster** | Anaesthetist, scrub nurse, circulating nurse and technician assigned per case, with their own availability conflicts checked. |
| **Family status notifications** | With the patient's explicit consent, one nominated family member receives *"in theatre"* and *"out of theatre, in recovery"* notifications. **No clinical detail whatsoever.** For families waiting outside, this is the most appreciated feature in the entire application, and it costs almost nothing to build. |
| **Operative note** | The surgeon records findings, procedure performed, implants used and post-operative instructions; it is filed to the medical file and drives the follow-up appointment. |
| **Automatic follow-up** | A post-operative follow-up appointment is created on completion, per the procedure's configured interval, and offered to the patient for confirmation. |

---

### 6.14 Specialty Centres — Programme-Within-A-Programme **[P1]**

The client requires the **Dar El Omouma Surgery Centre** (مركز جراحات دار الأمومة) to exist as a distinct programme inside the same application. The correct implementation is **not** a hard-coded second app. It is a generic, admin-configurable **Specialty Centre** entity of which the Surgery Centre is the first instance — so that the hospital can launch a second, third and fourth centre later without any development work.

#### 6.14.1 The Centre Entity

Each centre is created in the admin console and carries: name (AR/EN), slug, hero image and logo, description, optional accent colour within the hospital's palette, its own **specialties**, **procedure catalogue**, **clinics**, **doctors**, **price list**, **offers**, **medical tips**, **operating-theatre allocation**, and its own `center_manager`.

In the patient app a centre appears as a distinct destination with its own landing screen and its own booking flows, while remaining unmistakably part of Dar El Omouma. It shall be **deep-linkable** so the centre can be marketed on its own.

#### 6.14.2 Dar El Omouma Surgery Centre — The First Instance

Seeded with the specialties the client named:

| Specialty | Arabic |
|---|---|
| Neurosurgery | جراحة المخ والأعصاب |
| Urology | جراحة المسالك البولية |
| Orthopaedic surgery | جراحة العظام |

The administrator adds the centre's procedures and clinics. Doctors book the centre's theatre sessions directly under exactly the rules in §6.13.5 — the booking engine is shared, not duplicated. Patients request the centre's surgeries under §6.13.6 and book its clinics immediately under §6.7.

**Theatre allocation.** A centre may be granted dedicated theatre sessions (for example, "Theatre 2, Tuesdays 08:00–14:00, Surgery Centre"). Within its own allocation the centre's doctors book freely; outside it they compete with the rest of the hospital on the shared grid. Allocation is configured by the administrator and is visible in the availability view.

**Reporting.** Every report in §14.1 shall be filterable by centre, and each centre shall have its own contribution view — cases, case mix by classification, theatre utilisation, revenue. An owner who can see a centre's performance in isolation will fund the next one.

---

### 6.15 Visiting Experts Programme (برنامج الخبراء الزائرين) **[P1]**

A visiting consultant — typically from outside Egypt — attends for a defined window and operates on a cohort of patients assembled in advance by a host doctor at Dar El Omouma. This is a recurring, high-value, logistically demanding business line, and it is currently run on phone calls and notebooks.

#### 6.15.1 The Campaign

A `visiting_program_coordinator`, a `center_manager` or an admin creates a **campaign**:

- **Expert:** name, photo, country, institution, specialty and sub-specialty, qualifications, languages, biography. Both Arabic and English.
- **Host doctor:** the Dar El Omouma consultant who screens patients and assists.
- **Window:** arrival and departure dates; the screening period that precedes them.
- **Scope:** which procedures the expert will perform, and their classification.
- **Capacity:** maximum number of cases, and theatre sessions reserved for the visit.
- **Minimum viable cohort:** the number of confirmed cases below which the visit does not proceed. This is a real commercial constraint of these programmes and the system shall track it explicitly, showing the coordinator a live count against the threshold and flagging the campaign when the decision date approaches.
- **Pricing:** package price per procedure, deposit amount and deposit policy.
- **Publication window:** when the campaign becomes visible in the app.

#### 6.15.2 Patient Journey

`interest_registered` → `screening_booked` → `screened` → `shortlisted` → `deposit_paid` → `surgery_scheduled` → `completed`, with `not_eligible`, `waitlisted` and `withdrawn` as terminal or holding states.

- A patient discovers the campaign in the app (or via a shared deep link), reads the expert's profile, and **registers interest or books a screening clinic slot with the host doctor directly** — no approval needed for the screening clinic.
- **The host doctor may also register and book patients directly**, exactly as the client described: the doctor gathers a cohort from their own practice. Doctor-added patients enter the same pipeline at the same stage; there is one list, not two.
- The host doctor screens each patient and marks them shortlisted, not eligible, or waitlisted with a reason.
- Shortlisted patients are notified, shown the package price and deposit, and confirmed onto a surgery date inside the expert's window. Confirmation creates a normal theatre booking (§6.13) against the campaign's reserved sessions, so the visiting cases appear on the same availability grid as everything else.
- Every stage transition notifies the patient and the coordinator (§12.3).
- **Waitlist promotion is automatic**: when a shortlisted patient withdraws, the next waitlisted patient is offered the place.

#### 6.15.3 Coordinator View

A single pipeline board for each campaign — counts and patients at every stage, the live cohort count against the minimum viable threshold, the theatre sessions reserved and consumed, deposits collected against deposits due, and days remaining before the decision date and before arrival. Conversion from registered interest to completed surgery is the campaign's headline metric and shall be visible without running a report.

#### 6.15.4 Compliance — Raise This Before Building

**A visiting foreign practitioner requires authorisation to practise in Egypt.** Temporary licensing or permission via the Egyptian Medical Syndicate and the Ministry of Health is a legal precondition, and the requirements and lead times must be confirmed with the hospital's legal adviser before the first campaign runs. The system shall support this operationally: each expert profile holds their credential documents, licence or permission reference, and its validity dates, and **a campaign shall not be publishable to patients while the expert's authorisation is missing or expired.** Building the feature without this gate would let the hospital advertise a surgeon who is not cleared to operate. Flagged as open question 19.14.

Deposits taken for a visit that is subsequently cancelled — because the expert cannot travel or the minimum cohort is not reached — require a written refund policy, shown to the patient before payment and enforced by the system.

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

SpecialtyCentre (slug, name_ar, name_en, logo, hero, description, accent_colour,
                 manager_user_id, is_published)
  ├─< CentreSpecialty (name_ar, name_en)
  └─< TheatreAllocation (centre_id, theatre_id, weekday, start, end, valid_from, valid_to)

OperationClassification (code, name_ar, name_en, sort_order, colour, is_active,
                         default_duration_min, default_turnover_min,
                         price_min, price_max, required_seniority,
                         default_anaesthesia, default_blood_units,
                         default_preop_investigation_set_id)

OperatingTheatre (code, name, type, floor, fixed_equipment[], default_turnover_min,
                  is_active)
  └─< TheatreBlock (theatre_id, start_at, end_at, reason)      -- maintenance

Procedure (code, name_ar, name_en, classification_id, department_id?, centre_id?,
           typical_duration_min, required_theatre_type, required_equipment[],
           required_team[], price, price_is_range, patient_requestable,
           followup_interval_days)

SurgeryCase (patient_id, procedure_id, classification_id, theatre_id,
             start_at, end_at, turnover_end_at,
             surgeon_id, anaesthetist_id, team[], centre_id?, campaign_id?,
             origin: doctor_direct | patient_request | staff,
             status, anaesthesia_type, blood_units_reserved,
             estimated_price_snapshot, actual_duration_min,
             cancel_reason_code?, cancel_reason_text?,
             created_by, created_at)
  ├─< SurgeryApproval (case_id, requested_at, approver_user_id?, decision,
  │                    reason_code?, reason_text?, decided_at,
  │                    escalated_at?, escalated_to?)
  ├─< BookingOverride (case_id, conflict_type, reason_text, overridden_by, at)
  ├─< ConsentRecord (case_id, template_version, signature_image, signed_by,
  │                  relationship, signed_at)
  ├─< SafetyChecklist (case_id, phase: sign_in|time_out|sign_out, items[],
  │                    completed_by, completed_at)
  ├─< ImplantRecord (case_id, manufacturer, model, lot_no, serial_no, site)
  ├─< OperativeNote (case_id, findings, procedure_performed, instructions, author_id)
  └─< FamilyStatusSubscription (case_id, contact_phone, consent_id)

EquipmentSet (name, items[], quantity_available)
  └─< EquipmentReservation (set_id, case_id, from_at, to_at)

VisitingCampaign (centre_id?, expert_id, host_doctor_id, arrival_at, departure_at,
                  screening_from, screening_to, procedures[], capacity,
                  min_viable_cohort, decision_date, package_price, deposit_amount,
                  refund_policy_text, publish_from, publish_to, status)
  ├─< VisitingExpert (name_ar, name_en, photo, country, institution, specialty,
  │                   qualifications, languages[], bio,
  │                   licence_reference, licence_valid_from, licence_valid_to,
  │                   credential_documents[])          -- publication gate: §6.15.4
  └─< CampaignPatient (campaign_id, patient_id, stage, added_by, added_by_role,
                       screening_appointment_id?, eligibility_note?,
                       deposit_payment_id?, surgery_case_id?, waitlist_rank?)

Role (code, name, is_system)
  └─< RolePermission (role_id, permission_code, scope: global|centre|own)
UserRole (user_id, role_id, centre_id?, valid_from, valid_to)

NotificationLog (recipient_user_id?, recipient_phone?, channel, template_code,
                 entity, entity_id, sent_at, provider_ref, status, failure_reason)

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
5. **Theatre slot exclusivity shall be enforced by a database constraint** — an exclusion constraint over `(theatre_id, tstzrange(start_at, turnover_end_at))` in PostgreSQL, or an equivalent — not by an application-level availability check. The same applies to surgeon, patient and equipment overlap. An application check under concurrency is a double-booked theatre waiting to happen (§6.13.5).
6. `OperationClassification` and every reason-code list are **seeded data that the administrator owns**, not enumerations in code. A classification may be deactivated but never deleted, and historical records retain the classification they were created with.
7. `SurgeryCase.estimated_price_snapshot` stores the estimate exactly as the patient saw it at request time, and is immutable thereafter.

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

Indicative endpoint groups: `/auth`, `/patients/me`, `/dependants`, `/departments`, `/clinics`, `/doctors`, `/slots`, `/appointments`, `/orders`, `/results`, `/home-care`, `/complaints`, `/offers`, `/tips`, `/blood-bank`, `/invoices`, `/payments`, `/devices`, `/content`, `/theatres`, `/theatres/availability`, `/classifications`, `/procedures`, `/surgery-cases`, `/surgery-requests`, `/surgery-requests/{id}/decision`, `/centres`, `/visiting-campaigns`, `/visiting-campaigns/{id}/patients`, `/roles`, `/permissions`, `/reports`.

**Two contract requirements specific to theatre booking:**

- `POST /surgery-cases` shall be **idempotent** and shall return `409 Conflict` with a machine-readable `code` naming the exact clash (`theatre_busy`, `surgeon_busy`, `patient_busy`, `equipment_busy`, `theatre_blocked`) and the conflicting window. The client renders a specific message and a refreshed grid from that response — never a generic failure.
- `GET /theatres/availability` shall support a real-time subscription (SSE or WebSocket). Polling is the documented fallback, not the design.

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
| **Surgery request submitted** | Patient submits (§6.13.6) | **To every `surgery_approver` — push + WhatsApp + console inbox** |
| **Surgery request unactioned** | Approval SLA breached | To the medical director; then to the daily management report |
| Surgery request decided | Approver acts | To the patient (transactional) |
| Surgery scheduled / rescheduled / cancelled | Case status change | To patient, surgeon and theatre team (transactional) |
| Theatre booking conflict override | Override used (§6.13.5) | To the medical director |
| Emergency bumping | Elective case displaced | To the displaced patient and surgeon, immediately |
| Cancellation slot available | Slot released, waiting list matched | To matched patients in priority order |
| Pre-operative step outstanding | T-48 h with investigations or consent missing | To patient and surgeon |
| **Family theatre status** | `patient_in_theatre` / `in_recovery` | To the nominated contact, with consent, **no clinical detail** |
| Visiting-expert campaign published | Campaign goes live | To opted-in patients matching the specialty |
| Visiting-expert stage change | Pipeline transition (§6.15.2) | To patient and coordinator |
| Visiting-expert cohort at risk | Below minimum viable cohort near the decision date | To the coordinator and host doctor |

- Notification payloads shall contain **no clinical detail** — "Your laboratory result is ready" is acceptable; the analyte and value are not. This applies with particular force to family theatre-status messages and to every WhatsApp message.
- Transactional notifications (marked above) are not disableable, but shall still be delivered courteously and never duplicated across channels within a short window.
- Universal Links (iOS) and App Links (Android) shall be configured for every shareable entity: offer, tip, clinic, doctor, appointment, result, **surgery request, centre, and visiting-expert campaign**.
- Every send shall be written to `NotificationLog` with its channel, template, provider reference and delivery status, so that "the doctor says he was never told" is an answerable question.

### 12.4 WhatsApp Notifications To Staff **[P1 for staff, P2 for patients]**

The client requires that a patient's surgery request reach the approvers on WhatsApp. This is achievable, with constraints that shape the design and must be understood before it is promised.

**Implementation:** WhatsApp Business Cloud API (Meta), with a verified business account and a registered sender number.

**The constraint that governs everything:** outside a 24-hour window opened by the recipient's own message, WhatsApp permits only **pre-approved message templates**. A staff alert is by definition unsolicited, so **every staff notification must be a template submitted to Meta and approved in advance.** Templates take days to approve and cannot be composed at runtime; only their variables change. Template drafting is therefore an M2 activity, not an M5 one, and the approved template set is a project deliverable.

**Required templates (Arabic, with variables):**

| Template | Variables |
|---|---|
| New surgery request awaiting approval | patient reference, procedure, classification, requested date range, deep link |
| Surgery request escalated — SLA breached | request reference, hours elapsed, deep link |
| Theatre booking cancelled or postponed | case reference, theatre, date, reason code |
| Emergency case displaced an elective booking | case reference, new proposed date, deep link |
| Visiting-expert cohort below threshold | campaign name, current count, threshold, decision date |

**Rules:**

1. **No protected health information in any WhatsApp message.** Send a patient reference number and a deep link — never a name, a diagnosis, a result or a clinical note. WhatsApp is a consumer messaging platform on a personal device; treat it as an alerting channel that says *"something needs you, open the app"*, never as a channel that carries the content itself. This rule is not negotiable and shall be stated in the Data Protection Impact Assessment.
2. **WhatsApp is never the only channel.** The delivery chain for any approval alert is: in-app push → WhatsApp → SMS after a configurable delay if still unactioned → escalation per §6.13.6. A patient's surgery request must not depend on one messaging platform being up.
3. Staff opt in to WhatsApp alerts individually, with their consent recorded, and may switch to SMS.
4. Message costs are per-conversation and are billed to the hospital. Volume shall be estimated during discovery and the recurring cost stated in the proposal (see `docs/COMMERCIAL-ESTIMATE.md` §3.4).
5. **Patient-facing WhatsApp** (booking confirmations, result-ready alerts) is Phase 2 and requires its own opt-in, its own templates, and a marketing-consent boundary that transactional templates must not cross.

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

**Additional modules required by §6.13–6.15:**

- **Operating theatres** — theatre register, maintenance blocks, turnover defaults, centre allocations.
- **Operation classifications** — create, rename, reorder, recolour, deactivate, and edit every default in §6.13.2. **No code change, no app release.**
- **Procedure catalogue** — including which procedures patients may request.
- **Theatre schedule** — the availability grid with drag-to-reschedule, conflict warnings, override with mandatory reason, and the day-of-surgery board.
- **Surgery approvals inbox** — patient requests with SLA timers, the approver's one-screen decision view (§6.13.6), escalation state, and a decided-requests archive.
- **Cancellation & postponement reason codes** — admin-managed list, and the cancellation waiting list.
- **Specialty centres** — create and configure centres, their specialties, catalogues, clinics, doctors, pricing, content and theatre allocations; assign `center_manager`.
- **Visiting-expert campaigns** — expert profiles with credential documents and the **licence-validity publication gate** (§6.15.4), campaign setup, the pipeline board, cohort tracking against the minimum viable threshold, waitlist management, and deposit reconciliation.
- **Consent templates** — versioned, procedure-specific consent text; superseding a template shall never alter consents already signed.
- **Safety checklist templates**, equipment and instrument sets, theatre team roster.
- **WhatsApp template registry** — the approved Meta templates, their variables, and their delivery statistics.
- **Reports** — §14.1.

Every destructive or clinical action in the console shall require a confirmation step and shall be recorded in the audit log with the acting user.

### 14.1 Reports

Every report shall be filterable by date range, department, **centre**, doctor, **classification** and status; viewable on screen; exportable to CSV, XLSX and PDF; and schedulable for automatic email delivery to a named recipient list. Report access obeys the permission matrix in §3.3 — a `center_manager` sees their own centre and nothing else, and financial reports are separately permissioned from clinical ones.

**Operating theatre**

| Report | Why it matters |
|---|---|
| Theatre utilisation — booked, used and idle hours per theatre per day, week and month | The hospital's most expensive asset; utilisation is the number the owner will ask for first |
| Case mix by classification (صغرى / متوسطة / كبرى / ذات مهارة) | Drives staffing, pricing and capacity planning |
| Surgeon volume and case mix, by classification and centre | Doctor productivity and credentialing evidence |
| First-case on-time start rate | The single best predictor of whether a theatre day will overrun |
| Turnover time — actual against configured | Recovers hidden capacity without buying a theatre |
| **Cancellations and postponements by reason code** | The improvement programme writes itself from this one report |
| Estimated against actual duration, by procedure and by surgeon | Feeds back into §6.13.2 defaults and makes scheduling progressively more accurate |
| Same-day cancellations attributable to missing pre-op investigations or consent | Directly actionable; usually the largest single cause |
| Conflict overrides — who, what, why | Governance; a rising count is an early warning |
| Emergency bumping — frequency and displaced cases | Justifies reserving emergency capacity |
| Implant and prosthesis register by lot and serial | Recall response and accreditation |

**Surgery demand & approvals**

| Report | Why it matters |
|---|---|
| Patient request funnel — submitted → reviewed → approved → scheduled → performed | Shows where surgical demand is being lost |
| Approval turnaround and SLA breaches, by approver | Makes the escalation rule in §6.13.6 enforceable |
| Rejection reasons | Distinguishes clinical from operational and financial rejection |
| Request-to-surgery lead time | The waiting time the hospital actually offers |

**Specialty centres**

Cases, case mix, theatre utilisation, clinic volume, revenue and contribution per centre, with centre-against-centre comparison and period-on-period trend.

**Visiting experts**

Per campaign: interest registered → screened → shortlisted → deposit paid → operated, with conversion at each stage; cohort against minimum viable threshold; theatre sessions reserved against consumed; deposits collected, refunded and outstanding; cost against revenue. Across campaigns: which experts, specialties and seasons convert best — this is the report that decides which visit to run next year.

**Clinical & operational**

Clinic volume and no-show rate by clinic and doctor · appointment lead time · laboratory turnaround against target · radiology report turnaround · **critical results and time to clinician acknowledgement** (§6.9) · home-care requests by service, status and coverage area · complaint volume and SLA compliance by category and department · blood-bank stock movement, requests and donor conversion.

**Financial [P2 where payments are in scope]**

Revenue by service line, centre, doctor and payer · cash against insurance against corporate · estimate against final invoice variance · outstanding balances · deposits held · refunds · daily settlement reconciliation.

**Engagement & product**

Registration funnel · active users · booking completion rate by channel · result-view rate · offer click-through · push, WhatsApp and SMS delivery and failure rates by template · app crash rate and API latency (§15).

**Management dashboard.** A single screen for the owner and medical director: today's theatre schedule and utilisation, cases in progress, surgery requests awaiting approval with the oldest highlighted, today's clinic load, revenue month-to-date against last month, complaints breaching SLA, and any active visiting campaign at risk. It shall be readable on a phone.

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
9. **As a doctor, book a theatre slot directly** — confirmed immediately, with no approval step — and confirm it appears on the availability grid for every other user within 30 seconds.
10. **Attempt a double-booking under concurrency**: two clients confirm the same theatre slot simultaneously; exactly one succeeds and the other receives a clear message and a refreshed grid. Repeat for surgeon overlap, patient overlap and equipment overlap.
11. **As a patient, request a surgery**; confirm every `surgery_approver` receives the push and the WhatsApp template within 60 seconds; approve it; confirm it becomes a scheduled case indistinguishable from a doctor-booked one.
12. **Leave a surgery request unactioned past the SLA** and confirm it escalates to the medical director and appears on the management report.
13. **As an administrator, create a new operation classification**, set its defaults, and confirm it is immediately selectable in booking and appears in the reports — with no app release.
14. Open the Surgery Centre, browse its three specialties, book one of its clinics immediately as a patient, and request one of its procedures.
15. Run a visiting-expert campaign end to end: publish it, register interest as a patient, have the host doctor add a second patient directly, screen and shortlist both, schedule the surgeries into the reserved sessions, and confirm the cohort count tracks against the minimum viable threshold.
16. Confirm a campaign **cannot be published** while the expert's licence reference is missing or expired.
17. Cancel a scheduled case with a reason code and confirm the waiting list is notified and the reason reaches the cancellation report.
18. Verify that **no WhatsApp, SMS or push message anywhere in the system contains a patient name, diagnosis or clinical value.**

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
| **M5 — Engagement** | Home care, complaints, offers, medical tips, notifications, WhatsApp templates submitted for Meta approval | 3 weeks |
| **M5a — Operating theatre** | Theatres, admin-managed classifications, procedure catalogue, availability grid, **direct doctor booking with concurrency-safe conflict enforcement**, patient request and approval workflow with escalation, cancellation reasons and waiting list, day-of-surgery board | 5 weeks |
| **M5b — Surgical safety & integration** | Digital consent, WHO safety checklist, pre-operative bundle auto-ordering, blood reservation, equipment reservation, implant traceability, operative note, family status notifications | 3 weeks |
| **M5c — Centres & visiting experts** | Specialty-centre framework, Surgery Centre instance, theatre allocation, visiting-expert campaigns with the licence publication gate, pipeline board, waitlist and deposits | 4 weeks |
| **M5d — Permissions & reports** | Configurable roles and permissions, centre-scoped authorisation, the full report catalogue (§14.1), scheduled exports, management dashboard | 3 weeks |
| **M6 — Hardening** | QA, accessibility, localisation review, penetration test and remediation, performance tuning, **theatre concurrency load testing** | 4 weeks |
| **M7 — Launch** | Store submission, pilot with a limited patient group, production monitoring, staff training | 2 weeks |

**Indicative total with §6.13–6.15 included: 36 weeks**, assuming the hospital meets its obligations in Section 18.2 on schedule.

> **Scope note.** The operating-theatre, specialty-centre and visiting-expert modules are not an increment on the original brief — they are roughly **70% again on top of it**, and they carry the programme's highest clinical and concurrency risk. M2 (Foundation) must be extended by one week to accommodate the permission framework and the WhatsApp template submission, both of which have external lead times. Do not fold this scope into the original schedule or the original price; see `docs/COMMERCIAL-ESTIMATE.md` §3.3a.

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
14. **Visiting-expert licensing (§6.15.4):** what authorisation does a visiting foreign practitioner require from the Egyptian Medical Syndicate and the Ministry of Health, what is the lead time, and who at the hospital is accountable for holding it? **A campaign cannot be published without this answer.**
15. **Theatres:** how many operating theatres, of what types, with what operating hours, and how much emergency capacity is held back?
16. **Doctor credentialing:** who is authorised to book a theatre directly, and how is that list maintained as doctors join and leave? What defines "seniority" for the classification requirement in §6.13.2?
17. **Override authority:** who may override a hard booking conflict (§6.13.5), and who must be notified when they do?
18. **Approval coverage:** who holds `surgery_approver`, who covers them on leave and at night, and are the default 4-hour and 24-hour escalation windows correct?
19. **Anaesthesia and theatre staffing:** are anaesthetists and theatre nurses to be scheduled by this system, or by an existing roster the system must respect?
20. **Surgery pricing:** is surgical pricing per procedure, per classification band, or a package including theatre, anaesthesia and stay? Are implants billed separately?
21. **Deposits and refunds:** what is the deposit and refund policy for visiting-expert campaigns, and who signs it off?
22. **Centres:** is the Surgery Centre a separate legal entity, with separate pricing, invoicing or tax registration — or a service line within the hospital?
23. **WhatsApp:** does the hospital hold a WhatsApp Business account and a verified business profile? If not, verification is on the critical path (§12.4).
24. **Developer attribution (§2.5):** are the specified placements agreed, and is a white-label option required?

---

## 20. Explicitly Out Of Scope (Phase 1)

Clinical decision support; ICD-10 or CPT coding; **inpatient admission, ward and bed management** (the theatre module in §6.13 schedules and records the operation itself — it does not admit, ward or discharge the patient); pharmacy stock and inventory; **hospital-wide staff rostering** (§6.13.9 assigns a theatre team to a case against their availability; it does not build the hospital's shift roster); HR, payroll; general accounting and the general ledger; medical-equipment maintenance scheduling (theatres may be blocked for maintenance, but the maintenance programme itself is out); a public marketing website; any migration of historical paper records.

---

*End of document.*
