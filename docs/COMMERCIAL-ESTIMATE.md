# Dar El Omouma Hospital — Commercial Estimate & Pricing Guidance

**Purpose:** to help you price the mobile application correctly, and to size the much larger Hospital Information System (HIS) engagement that follows it.
**Currency:** Egyptian Pounds (EGP) unless stated otherwise.
**Status:** These are **indicative market estimates**, not a quotation. They are based on the scope defined in `PROMPT.md` and on typical Egyptian software-market rates. Verify against your own team's cost base and current exchange rates before you send a number to the client.

---

## 1. The Headline Finding

You said you are asking **EGP 15,000** for the application.

**That price is roughly one order of magnitude below what this scope costs to build.** It is not a negotiating position — it is a number that, if accepted, would lose you money and would very likely end in an unfinished product and an unhappy hospital.

Here is why, in the client's own terms.

The deck you were given contains **11 screens**. But those 11 screens are not the product. Behind them sit:

- A backend with a patient master index, appointment engine, result pipeline and audit log.
- An **admin console** — without it the hospital cannot add a single clinic, price, result or offer. This is a second application, and it is not optional.
- Two store submissions, each with its own review process, health-data declarations and privacy paperwork.
- Medical data handling, which brings Law 151/2018 obligations, encryption, audit logging and a penetration test.

EGP 15,000 is, realistically, the price of **two to three days of one developer's time**. The scope in `PROMPT.md` is approximately **15–17 person-months**.

---

## 2. What EGP 15,000 Actually Buys

To be fair to the number rather than just dismissing it — here is what it can honestly deliver:

| Deliverable | Included at EGP 15,000? |
|---|---|
| A clickable UI prototype of the 11 deck screens (Figma) | Yes |
| A static mobile app with hard-coded demo content, not published to the stores | Marginally |
| Any backend, database or login | **No** |
| Admin console | **No** |
| Real bookings, results or patient data | **No** |
| App Store / Google Play publication | **No** |
| Security, encryption, audit, legal compliance | **No** |
| Maintenance | **No** |

If the hospital's budget is genuinely EGP 15,000, the correct response is not to build the app for that money. It is to sell a **paid discovery and prototype engagement** at that price, and use it to justify the real number. See Section 7.

---

## 3. Recommended Pricing — Mobile Application

### 3.1 Estimating Basis

| Input | Value |
|---|---|
| Phase 1 duration (`PROMPT.md` §17) | 21 weeks |
| Team | 1 PM/BA (50%), 1 designer (50%), 2 mobile engineers, 1.5 backend engineers, 1 QA (50%) |
| Effort | ≈ 15–17 person-months |
| Blended loaded cost per person-month (Egyptian market) | EGP 35,000 – 55,000 |
| Direct cost | ≈ EGP 550,000 – 900,000 |
| Target gross margin | 35 – 45% |

### 3.2 Three Tiers To Put In Front Of The Client

Always present **three** options. A single price invites a haggle; three prices invite a choice.

| | **Tier A — Essential** | **Tier B — Complete (recommended)** | **Tier C — Platform** |
|---|---|---|---|
| **Scope** | Reduced Phase 1: registration, clinics + booking, prices & schedules, offers, medical tips, complaints, contact. Results and medical file are **view-only PDF upload**. | Full Phase 1 exactly as specified in `PROMPT.md` | Phase 1 + selected Phase 2 modules (payments, dependants, pregnancy companion, insurance/corporate, queue) |
| **Admin console** | Basic | Full | Full + dashboards |
| **Platforms** | iOS + Android | iOS + Android | iOS + Android + tablet |
| **Duration** | 12–14 weeks | 20–22 weeks | 34–40 weeks |
| **Price** | **EGP 280,000 – 420,000** | **EGP 750,000 – 1,150,000** | **EGP 1,600,000 – 2,600,000** |

If the hospital insists on a single number, quote **Tier B at EGP 850,000** and hold it.

### 3.2b Tier S — Starter at EGP 200,000

If EGP 200,000 is the number you want to open with, it **can** work — but only for the
**mobile application with a hard-cut scope**, and only if the exclusions below are written
into the contract. It cannot buy a hospital information system (Section 4); at that price
an HIS engagement is a guaranteed loss, not a thin margin.

**What the number affords.** EGP 200,000 across a 14-week delivery is ≈ EGP 57,000 per
month for the entire team. That is approximately **one full-time engineer**. Plan the
scope for one person, not for a team, or the margin is gone before you start.

| | Tier S — Starter |
|---|---|
| **Price** | EGP 200,000 |
| **Duration** | 14 weeks |
| **Team** | 1 full-stack engineer + part-time design and QA |
| **Platforms** | iOS + Android (single React Native / Flutter codebase) |

**Included — the deck's public and transactional core:**

| Module | Reference |
|---|---|
| Splash, onboarding, login/register with OTP and National-ID validation | `PROMPT.md` §6.1–6.2 |
| Home screen with the client's four tiles | §6.3 |
| Clinics, doctors, schedules and appointment booking (pay at reception) | §6.7 |
| Radiology and laboratory **catalogues, prices and schedules** — browse and book only | §6.8–6.9 |
| Offers & events, medical tips — CMS-driven | §6.11–6.12 |
| Complaints with reference number and status | §6.5 |
| Contact & emergency call | §6.10 |
| Push notifications: booking confirmation and reminders | §12.3 |
| **Basic admin console** — content, catalogues, schedules, bookings, complaints inbox | §14, reduced |
| Store submission on both platforms | §17 M7 |

**Excluded — state each of these explicitly in the proposal:**

| Excluded | Sell later at |
|---|---|
| Lab/radiology **results delivery** and the critical-result gate (§6.9) | EGP 80,000 – 130,000 |
| **Medical file** with vitals, visit history and documents (§6.6) | EGP 55,000 – 90,000 |
| **Home care** request and dispatch workflow (§6.4) | EGP 60,000 – 95,000 |
| **Blood bank** (§6.9) | EGP 40,000 – 65,000 |
| In-app payment (§13) | EGP 90,000 – 160,000 |
| Full admin console, dashboards and role management (§14) | EGP 100,000 – 180,000 |
| Penetration test (§11.3) | EGP 45,000 – 90,000 |
| Any Phase 2 module (§7.1) | Per §3.3 |
| Dedicated tablet layouts, dark theme | EGP 40,000 – 70,000 |

**Conditions to attach to a EGP 200,000 price — non-negotiable:**

1. **Annual maintenance is a separate, signed line: EGP 45,000 – 60,000/year, starting at
   launch.** At this build price the retainer is where the engagement becomes profitable.
   Do not sign the build without it.
2. **Hosting, SMS, maps and store fees are billed to the hospital directly**, not absorbed.
   SMS in particular is usage-based and will grow with the user base.
3. **The exclusion table above is in the contract**, item by item, with its later price.
   Every excluded item is a booked future sale, not a gap.
4. **Two rounds of revision per screen.** Beyond that, billable.
5. The hospital's obligations in `PROMPT.md` §18.2 (catalogues, prices, brand assets, legal
   texts, developer accounts, SMS sender ID) are prerequisites with a billable delay clause.
6. **Results and clinical data are out**, so the app carries no protected health information
   in Tier S. Say this plainly — it is what makes the reduced compliance surface honest, and
   it is the strongest argument for funding the next phase.

**Why this is a defensible opening move.** Tier S is a real, shippable product in the
hospital's own brand, in both stores, with a working booking engine. It builds the patient
identity layer, which makes every later module naturally yours (§5). The exclusion table
turns the discount into a roadmap rather than a loss. What you must not do is quote
EGP 200,000 for **Tier B scope** — that is the same mistake as EGP 15,000, just less severe.

### 3.3 Modular Price List

Use this when the hospital wants to buy incrementally, or to price change requests. Prices assume the Tier B foundation already exists.

| Module | Reference | Price (EGP) |
|---|---|---|
| Discovery, requirements & UX research | §17 M0 | 45,000 – 80,000 |
| Full UI design system + all Phase 1 screens (AR + EN) | §17 M1 | 70,000 – 120,000 |
| Backend foundation, auth, OTP, infrastructure, CI/CD | §17 M2 | 110,000 – 180,000 |
| Registration + national-ID validation + patient master index | §6.2 | 45,000 – 70,000 |
| Clinics, doctors, schedules & booking engine | §6.7 | 90,000 – 150,000 |
| Radiology module | §6.8 | 55,000 – 90,000 |
| Laboratory module + result pipeline + critical-result gate | §6.9 | 80,000 – 130,000 |
| Blood bank | §6.9 | 40,000 – 65,000 |
| Medical file | §6.6 | 55,000 – 90,000 |
| Home care | §6.4 | 60,000 – 95,000 |
| Complaints with SLA tracking | §6.5 | 35,000 – 55,000 |
| Offers, events & medical tips (CMS-driven) | §6.11–6.12 | 45,000 – 70,000 |
| Push notification system + segmentation | §12.3 | 30,000 – 50,000 |
| Admin console (full) | §14 | 150,000 – 260,000 |
| QA, accessibility & Arabic RTL hardening | §16 | 60,000 – 100,000 |
| Penetration test + remediation | §11.3 | 45,000 – 90,000 |
| Store submission, launch & staff training | §17 M7 | 30,000 – 50,000 |
| **Phase 2 — Payments (Paymob/Fawry) + invoicing** | §13 | 90,000 – 160,000 |
| **Phase 2 — Teleconsultation (video)** | §7.1.2 | 130,000 – 240,000 |
| **Phase 2 — Pregnancy companion + newborn/vaccination record** | §7.1.8–7.1.9 | 110,000 – 190,000 |
| **Phase 2 — Insurance & corporate contracts** | §7.1.5 | 90,000 – 150,000 |
| **Phase 2 — Dependants & family accounts** | §7.1.1 | 45,000 – 75,000 |
| **Phase 2 — Queue & live waiting status** | §7.1.7 | 50,000 – 85,000 |
| **Phase 2 — Pharmacy & e-prescriptions** | §7.1.3–7.1.4 | 100,000 – 170,000 |
| **Phase 2 — DICOM viewer** | §7.1.10 | 70,000 – 130,000 |

### 3.4 Recurring Revenue — Do Not Leave This Out

| Item | Price |
|---|---|
| **Annual maintenance & support** | **18–22% of the build price per year.** For Tier B: EGP 150,000 – 250,000/year. Covers OS/SDK upgrades, store policy changes, bug fixes, security patches, and a defined support SLA. |
| Hosting & third-party services | EGP 60,000 – 180,000/year, billed at cost + 15% (servers, storage, SMS, maps, push, monitoring). SMS is usage-based and can grow quickly — price it per message. |
| Content operations (if you run it, not the hospital) | EGP 8,000 – 20,000/month |
| Enhancement retainer | EGP 40,000 – 90,000/month for a guaranteed engineering allocation |

**The recurring line is where this relationship becomes profitable.** A one-off build with no maintenance contract is the worst commercial outcome available to you.

### 3.5 Payment Terms To Insist On

- 30% on signature, 25% on design sign-off, 25% on staging delivery, 20% on store approval.
- Milestone sign-off in writing; work stops if a milestone is unsigned for more than 10 working days.
- Change requests priced separately against the modular list in §3.3 — nothing goes in "as a favour".
- The hospital's obligations in `PROMPT.md` §18.2 are contractual. Delay on their side moves your dates and is billable after an agreed grace period.
- Intellectual property transfers on final payment, not before.

---

## 4. Pricing The Full Hospital System (HIS)

You asked what to charge for "the whole hospital system". This is a fundamentally different class of engagement — the mobile app is one window into it.

### 4.1 What A Full HIS Actually Contains

| Domain | Modules |
|---|---|
| **Patient administration (ADT)** | Registration, master patient index, admission, discharge, transfer, bed management, appointment scheduling |
| **Clinical (EMR)** | Encounters, clinical notes, order entry (CPOE), problem lists, allergies, vitals, nursing charts, operating-theatre records, maternity & delivery records, NICU |
| **Laboratory (LIS)** | Test catalogue, order management, sample tracking, analyser interfacing, result validation, quality control |
| **Radiology (RIS/PACS)** | Modality scheduling, worklists, DICOM storage, reporting, image distribution |
| **Pharmacy** | Formulary, dispensing, inpatient medication administration, stock, expiry, purchase |
| **Inventory & supply chain** | Stores, requisitions, suppliers, purchase orders, consumables, medical gases |
| **Revenue cycle** | Pricing, cashiering, insurance contracts, claims, pre-authorisation, e-invoicing, receivables |
| **Finance** | General ledger, accounts payable/receivable, fixed assets, cost centres |
| **HR** | Employee records, rostering, shifts, attendance, payroll |
| **Quality & governance** | Incidents, infection control, accreditation evidence, KPIs, audit |
| **Management** | Executive dashboards, occupancy, case mix, profitability by service line |
| **Digital front door** | The patient mobile app + patient portal + staff app |
| **Integration layer** | HL7 v2 / FHIR R4 engine, DICOM, device interfacing, national-system reporting |

That is 12 domains. Each is comparable in size to, or larger than, the entire mobile application.

### 4.2 Two Routes — Price Them Differently

**Route A — Implement an existing HIS product** (recommended for a hospital of this size). You license a proven system and sell the implementation.

| Line | Price (EGP) |
|---|---|
| Software licence (regional/Egyptian HIS vendor, ~100-bed hospital) | 1,200,000 – 4,000,000 (or 250,000 – 800,000/year subscription) |
| Implementation, configuration & data migration | 800,000 – 2,000,000 |
| Integration (LIS/PACS analysers, devices, mobile app) | 300,000 – 800,000 |
| Training & go-live support | 150,000 – 400,000 |
| Annual support & maintenance | 18–22% of licence |
| **Your realistic revenue as implementation partner** | **EGP 1,200,000 – 3,000,000 on the project + recurring** |

**Route B — Build a custom HIS.** Higher revenue, dramatically higher risk. Only take this with a team of 10+, a 24–36 month horizon, and staged financing.

| Scope | Duration | Price (EGP) |
|---|---|---|
| Core only (ADT + scheduling + basic EMR + billing + the mobile app) | 12–15 months | **2,500,000 – 4,500,000** |
| Core + LIS + RIS + pharmacy + inventory | 20–26 months | **5,000,000 – 9,000,000** |
| Full suite including finance, HR, quality, dashboards, full integration layer | 30–40 months | **9,000,000 – 18,000,000** |
| Annual maintenance | — | 18–22% of build price per year |

### 4.3 The Number To Quote

If the hospital asks you today, *"and how much for the whole system?"*, the answer is:

> "The patient app is Phase 1 at EGP 850,000. A complete hospital information system is a separate programme — realistically **EGP 2.5 to 5 million for the core**, and up to **EGP 9 million** for the full suite, over 18 to 30 months. Before I can give you a firm figure I need a two-to-three week paid assessment of your current systems, bed count, departments and workflows. That assessment is EGP 60,000 – 120,000 and it is credited against the project if you proceed."

**Never quote an HIS without a paid assessment first.** The single largest cost driver — whether they already run an HIS, LIS or PACS, and whether it exposes an API (`PROMPT.md` §19, question 4) — is unknown to you right now. Quoting blind on that question is how software houses go bankrupt.

### 4.4 The EGP 200,000 Question — Answered Directly

**EGP 200,000 for a full hospital information system is not a low price. It is not a price
at all.** Quoting it would not win you a thin-margin project; it would commit you to
18–30 months of work funded at roughly 2–3% of its cost, and it would end in an
abandoned system, an unpaid balance, and a damaged reputation in a market where hospital
procurement runs almost entirely on reference calls.

The arithmetic, so you can see it rather than take it on faith:

| | Value |
|---|---|
| HIS core effort (ADT + scheduling + basic EMR + billing) | 80 – 120 person-months |
| What EGP 200,000 funds at Egyptian loaded cost | ≈ 4 person-months |
| Coverage | **≈ 3 – 5% of the core** |
| Cheapest single HIS module (§4.5) | EGP 250,000 |

EGP 200,000 does not buy the smallest module in the system. That is the whole answer.

**But the instinct behind the number is right.** You are trying to find an entry point you
can actually deliver and get paid for. That entry point exists — it is just not "the whole
system at a discount". It is **one module, sold at its real price**, with the rest booked as
a roadmap. Section 4.5 gives you the module prices to do exactly that.

**The three moves that work, in order:**

1. **Sell the paid assessment first — EGP 60,000 – 120,000, two to three weeks.** You cannot
   price an HIS before you know whether they already run one, how many beds and sites,
   which departments, and what has an API (`PROMPT.md` §19, question 4). Credit it against
   the project. This is the single highest-value thing you can sell this month.
2. **Sell the mobile app as the first module — Tier S at EGP 200,000 (§3.2b), or Tier B at
   EGP 850,000 if they have the budget.** It is real, shippable, and it builds the patient
   identity layer that makes every later module naturally yours.
3. **Then sell HIS modules one at a time, at the prices in §4.5**, each one funding the next.

If the hospital's total budget genuinely is EGP 200,000, they are not buying an HIS this
year and no vendor on earth will sell them one. Say so plainly and sell them move 1 and
move 2. That is an honest EGP 260,000 – 320,000 of work you can deliver well, and it puts
you in position for the real programme.

### 4.5 HIS Module Price List — Sell One Module At A Time

Custom-build prices. Use this to convert a small budget into a sequenced programme instead
of an impossible discount. Each module is independently deliverable and independently
useful to the hospital.

| # | Module | Price (EGP) | Typical order |
|---|---|---|---|
| 1 | Patient registration, master patient index & ADT | 350,000 – 600,000 | First — everything depends on it |
| 2 | Outpatient scheduling & clinic workflow | 300,000 – 500,000 | Second |
| 3 | Cashier, price lists, receipts & basic billing | 350,000 – 600,000 | Third — starts paying for itself |
| 4 | Insurance, corporate contracts, pre-authorisation & claims | 400,000 – 700,000 | Fourth |
| 5 | EMR core — encounters, notes, orders (CPOE), vitals, allergies | 700,000 – 1,200,000 | Fifth — the largest single module |
| 6 | Laboratory information system (LIS) + analyser interfacing | 600,000 – 1,000,000 | |
| 7 | Radiology (RIS) + PACS/DICOM integration | 500,000 – 900,000 | |
| 8 | Pharmacy, formulary & dispensing | 450,000 – 800,000 | |
| 9 | Inventory, stores & purchasing | 350,000 – 600,000 | |
| 10 | Inpatient, bed management, operating theatre, maternity & NICU records | 500,000 – 900,000 | |
| 11 | Finance — GL, AP, AR, fixed assets, cost centres | 500,000 – 900,000 | |
| 12 | HR, rostering, attendance & payroll | 450,000 – 800,000 | |
| 13 | Quality, incidents, infection control & accreditation evidence | 250,000 – 450,000 | Cheapest entry module |
| 14 | Management dashboards & BI | 250,000 – 500,000 | |
| 15 | Integration engine — HL7 v2 / FHIR R4 / DICOM | 400,000 – 800,000 | Required from module 6 onward |

Module sum: **EGP 6.35M – 11.25M**. The full-suite figure in §4.2 (EGP 9M – 18M) is higher
because it additionally carries programme management, data migration, training across all
departments, parallel-run support, and contingency — all of which are real and all of which
must be priced when the modules are bought as one programme rather than one at a time.

**Add to every module:** annual maintenance at 18–22% of that module's price, from the date
that module goes live. By module 5 the recurring line alone should exceed a junior
engineer's salary.

### 4.6 What Moves The HIS Price Most

| Driver | Effect |
|---|---|
| Bed count and number of sites | Near-linear on implementation and training |
| Existing systems and whether they must be integrated or replaced | ±40% |
| Whether historical data must be migrated | +10–25% |
| Insurance and Universal Health Insurance Authority reporting requirements | +15–30% |
| Number of departments and specialisms | Linear on configuration |
| Accreditation targets (GAHAR, JCI) | +10–20% for documentation and audit features |
| Analyser and medical-device interfacing | EGP 40,000 – 120,000 per device class |
| 24/7 support requirement | Doubles the support line |

---

## 5. Positioning The Mobile App As The Door To The HIS

Your strongest commercial move is **not** to win the app at a low price. It is to win the app at a fair price and position it as Phase 1 of the platform:

1. **Anchor on outcomes, not screens.** The hospital does not want 11 screens. It wants fewer phone calls, fewer no-shows, more home-care revenue, and a marketing channel it owns. Price against that value.
2. **Show the operational cost of *not* integrating.** In Phase 1, every lab result reaches a patient because a staff member uploads it. Quantify that manual load in staff-hours per month. It is the single most persuasive argument for the Phase 3 integration project — and it comes from the hospital's own numbers, not yours.
3. **Make the patient master index yours.** Once the app owns the patient identity layer, every subsequent module is naturally your work.
4. **Sell the assessment early.** A paid HIS assessment at EGP 60,000–120,000 is easy to approve, pays for itself, and effectively pre-qualifies you for the multi-million-pound programme.

---

## 6. Risk Register — Price These In Or Exclude Them In Writing

| Risk | Impact | Handling |
|---|---|---|
| Hospital cannot supply complete clinic/test/price catalogues on time | Blocks M3–M4 | Contractual prerequisite (`PROMPT.md` §18.2); billable delay clause |
| Apple rejects under Guideline 5.1.1 (health data) | 2–6 weeks | Budget two resubmission cycles; prepare the privacy paperwork at M2, not M7 |
| Scope creep from staff who did not attend discovery | Unbounded | Written change control against §3.3 |
| SMS sender-ID registration delay | Blocks OTP, blocks everything | Start registration in week 1 |
| No HIS API exists → permanent manual entry | Operational failure post-launch | Raise before contract; size the staffing cost with the hospital |
| Penetration test finds critical issues late | 2–4 weeks | Run the test at M6, not at launch |
| Client expects unlimited free changes after launch | Margin erosion | Warranty covers **defects only**, in writing; enhancements are billable |

---

## 7. If The Hospital's Budget Is Genuinely EGP 15,000

Do not build the app for it. Do this instead:

1. Sell **Discovery & Prototype** for EGP 15,000 – 45,000: requirement workshops, a clickable Figma prototype of all 11 screens in Arabic RTL, and this `PROMPT.md` document as the deliverable.
2. Present the prototype to hospital management. A working prototype in their own brand, on their own phone, changes the conversation entirely.
3. Present the three tiers from §3.2 alongside it.
4. Credit the EGP 15,000 against the build if they proceed within 60 days.

You lose nothing, you get paid for the work you have already effectively done, and you enter the real negotiation with the hospital's own decision-makers looking at their own product.

---

*These figures are market estimates prepared to support your pricing decision. Validate them against your actual team costs, your overhead, and current market conditions before quoting a client.*
