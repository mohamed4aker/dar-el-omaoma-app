# Selling The Hospital System — Price & Persuasion Playbook

**Companion to:** `docs/COMMERCIAL-ESTIMATE.md` (what to charge) and `PROMPT.md` (what to build)
**Purpose:** the number to put on the page for Dar El Omouma's full hospital system, and the argument that makes a seven-figure number easier to approve than a six-figure one.

> **All financial figures in Sections 3 and 4 are illustrative placeholders.** They exist to show you the *shape* of the argument. Before any of this reaches the hospital, every number must be replaced with the hospital's own actuals, gathered in the paid assessment (Section 6). A business case built on invented numbers collapses the moment a finance director tests one of them — and it takes your credibility with it.

---

## 1. The Number

### 1.1 Recommended Headline Quote

For a hospital of Dar El Omouma's apparent profile — a specialist maternity hospital, single or few sites, currently running on paper or on disconnected point systems:

> **EGP 4,200,000 for the core hospital system programme, delivered over 18 months in five funded stages, plus EGP 850,000 for the patient mobile application.**
>
> **Total programme: EGP 5,050,000.**

This is the number you say out loud. Not "around four million". Not "it depends". A specific figure, said calmly, without apologising for it.

### 1.2 How To Adjust It

Adjust the headline once the assessment gives you facts:

| Factor | Adjustment |
|---|---|
| Under 50 beds, single site | −25% → ≈ EGP 3.2M |
| 50–120 beds, single site | Baseline → EGP 4.2M |
| 120–250 beds, or 2–3 sites | +35% → ≈ EGP 5.7M |
| They already run a HIS that must be integrated, not replaced | −20% on scope, +15% on integration |
| They already run a HIS with **no** API | +25% — manual interfacing is expensive and thankless |
| Historical data migration required | +10–25% |
| Insurance / UHIA reporting in scope | +15–30% |
| GAHAR or JCI accreditation target | +10–20% |
| 24/7 support required | Doubles the recurring line, not the build |

### 1.3 What The EGP 4.2M Covers

Modules 1, 2, 3, 4, 5 and 15 from `COMMERCIAL-ESTIMATE.md` §4.5 — registration and master patient index, outpatient scheduling, cashier and billing, insurance and contracts, EMR core, and the integration engine. Plus programme management, migration, training and parallel-run support.

LIS, RIS/PACS, pharmacy, inventory, inpatient, finance, HR, quality and BI are **Programme 2**, quoted separately at EGP 3.5M – 6M. Do not fold them into the headline. You want the second programme to be a decision they make after you have already succeeded, not a line item they cut today.

---

## 2. Why A Big Number Sells Better Than A Small One

This is counter-intuitive and it is the most important idea in this document.

A hospital owner has seen cheap software before. It arrived, it half-worked, the vendor disappeared, and they went back to paper. **A low price does not read as "good value" to them — it reads as "this one will fail too."**

| A low number signals | A high number signals |
|---|---|
| A freelancer who will vanish | A firm that will still exist in year three |
| Scope they will have to fight for later | Scope that was thought through |
| No support after launch | A team, a process, a contract |
| They are a small account | They are an important client |

There is a second effect. Hospital capital decisions above roughly EGP 1M go to the owner or the board. Below that, they get delegated to an administrator whose incentive is to spend as little as possible. **A large number reaches the person who can actually say yes; a small number reaches the person whose job is to say no.**

So: do not shrink the number to make it easier. Make the *argument* strong enough that the number stops being the subject of the conversation.

---

## 3. The Argument — Build It From Their Money, Not Your Costs

The hospital does not care that it takes you 18 months and eight engineers. That is your problem. They care about one thing: **does this make or save more than it costs?**

Every persuasive hospital-system sale rests on the same four leaks. All four are real, all four are measurable, and the hospital is almost certainly not measuring them today.

### 3.1 The Four Leaks

| # | Leak | Typical range in an unautomated hospital | What the system does |
|---|---|---|---|
| 1 | **Billing leakage** — services delivered but never charged: consumables, extra investigations, unrecorded procedures, cash not reconciled | 3–8% of gross revenue | Order entry links every clinical action to a charge automatically |
| 2 | **Insurance claim rejection** — claims denied for missing pre-authorisation, wrong coding, missing documentation, late submission | 10–20% of insured revenue | Pre-auth workflow, coded orders, complete documentation, deadline tracking |
| 3 | **Pharmacy & stores shrinkage** — expiry, loss, over-ordering, no consumption visibility | 5–15% of pharmacy and consumables spend | Stock control, batch and expiry tracking, consumption-based reordering |
| 4 | **Capacity waste** — no-shows, idle clinic slots, slow bed turnover, patients lost to queues | 15–25% no-show rate is common | Reminders, online booking, live occupancy, discharge planning |

### 3.2 The Worksheet — Fill This In With Them, In The Room

Do not present your estimate of their leakage. **Ask them for the inputs and do the arithmetic in front of them.** A number the owner helped calculate is a number the owner defends.

| Input — ask them | Their answer |
|---|---|
| A. Annual gross revenue | ________ |
| B. Share of revenue from insurance and corporate contracts | ____ % |
| C. Rejected or written-off claims last year | ________ |
| D. Annual pharmacy + consumables spend | ________ |
| E. Outpatient appointments per month | ________ |
| F. Estimated no-show rate | ____ % |
| G. Average outpatient visit value | ________ |
| H. Staff doing manual paperwork, registration, filing, claim preparation | ____ people |

Then, live:

```
Billing leakage recovered        = A × 4%   × 50% capture
Claim rejections recovered       = C        × 40% capture
Pharmacy waste recovered         = D × 6%   × 50% capture
No-show revenue recovered        = E × 12 × G × (F × 40% reduction)
Staff hours redeployed           = H × annual cost × 25%
--------------------------------------------------------------
ANNUAL BENEFIT                   = ________
PROGRAMME COST                   = EGP 5,050,000 over 18 months
PAYBACK                          = ________ months
```

The capture percentages above are deliberately conservative. **Argue against yourself in public** — say out loud "I have assumed we only recover half of this, because no system recovers all of it." That single sentence does more for your credibility than any slide.

### 3.3 Worked Illustration

Purely to show the shape. **These are not Dar El Omouma's numbers.**

Assume a hospital with EGP 120M annual revenue, 40% insured, EGP 7M in rejected claims, EGP 15M pharmacy spend, 3,000 outpatient visits a month at EGP 400, a 20% no-show rate, and 12 staff on manual administration.

| Line | Annual benefit (EGP) |
|---|---|
| Billing leakage: 120M × 4% × 50% | 2,400,000 |
| Claim rejections: 7M × 40% | 2,800,000 |
| Pharmacy waste: 15M × 6% × 50% | 450,000 |
| No-shows: 3,000 × 12 × 400 × (20% × 40%) | 1,152,000 |
| Staff redeployment: 12 × 90,000 × 25% | 270,000 |
| **Total annual benefit** | **≈ 7,072,000** |

Against EGP 5.05M spent over 18 months, with benefits beginning as each stage goes live: **payback in roughly 11–14 months from the first billing module going live, and approximately EGP 7M per year recurring thereafter.**

That is the entire sale. Not features. Not screens. **This table.**

### 3.4 The Cost Of Doing Nothing

Then say the sentence that closes more hospital deals than any other:

> "Whether or not you work with me, this leak is running. At these numbers it is costing you around **EGP 590,000 every month**. Eighteen months of deciding costs more than the system does."

Compute it as annual benefit ÷ 12. Put it on one slide, alone, in large type.

---

## 4. What Else Justifies The Number — Beyond Money

Money opens the door. These close it.

| Driver | The argument |
|---|---|
| **Accreditation** | GAHAR and JCI both require traceable clinical documentation, incident tracking and audit trails. Paper cannot produce them. Accreditation raises the prices the hospital can charge and the contracts it can win. |
| **Insurance & UHIA readiness** | As Egypt's Universal Health Insurance system expands, contracts increasingly require electronic claims and structured reporting. A hospital that cannot submit electronically loses the contract. This is existential, not optional. |
| **Medico-legal protection** | In a maternity hospital specifically, an obstetric complication that reaches court is defended on documentation. An immutable, timestamped, audited record is legal protection that paper cannot provide. Say this once, seriously, and stop. |
| **Owner visibility** | Today the owner learns last month's profitability three weeks late, from a spreadsheet someone assembled by hand. Offer them yesterday's occupancy, revenue by service line and doctor productivity, on their phone. For an owner-operated hospital this is often the single most compelling feature in the whole system. |
| **Competition** | Name the competing hospitals in their governorate that already have booking apps and digital results. Patients — especially the young mothers who are this hospital's core market — choose on convenience. |
| **Valuation** | A hospital with clean, structured, three-year historical data sells for materially more than one with boxes of files. If the owner ever intends to bring in an investor or sell, this is an asset, not a cost. |

---

## 5. How To Present It — The Sequence

### 5.1 Never Present One Number

Present three, largest first. The first number sets the anchor; the middle number becomes "reasonable" by comparison; the third exists to be refused.

| | Option 1 — Complete | Option 2 — Core *(recommend this)* | Option 3 — Entry |
|---|---|---|---|
| Scope | Full suite, all 15 modules + mobile app | Core HIS (6 modules) + mobile app | Mobile app + registration & scheduling only |
| Duration | 30–36 months | 18 months | 6 months |
| Price | **EGP 9,800,000** | **EGP 5,050,000** | **EGP 1,400,000** |
| Annual benefit | Full leak closed | ≈ 75% of the leak closed | ≈ 20% |

Present Option 1 first and fully. Then say: *"I do not recommend this for you this year."* Volunteering against your own largest number buys you more trust than anything else you will do in the meeting — and it makes Option 2 read as your honest professional judgement rather than your sales target.

### 5.2 The Three-Meeting Structure

Never try to sell a seven-figure system in one meeting. It cannot be done and attempting it marks you as inexperienced.

**Meeting 1 — Diagnosis (45 minutes). Sell nothing.**
Ask, do not pitch. Walk the registration desk, the cashier, the lab reception, the medical records room. Ask to see how a claim is prepared. Count the paper. Ask every question in the §3.2 worksheet. Leave with data and no proposal. Close with: *"Give me three weeks and I will come back and tell you exactly what this is costing you."*

**Meeting 2 — The business case (60 minutes). Sell the assessment, not the system.**
Present the findings and the filled-in worksheet. Present the three options. Then ask for a small commitment: **the paid assessment at EGP 60,000 – 120,000**, credited against the programme. An owner who says yes to EGP 80,000 has already said yes in principle to the programme; the rest is scheduling.

**Meeting 3 — The proposal (90 minutes). Sell the plan.**
Deliver the assessment report — current-state findings, quantified leaks, target architecture, stage plan, risk register, and the fixed price. By now the number is the least surprising thing in the room.

### 5.3 Who You Are Actually Selling To

| Person | What they care about | What to show them |
|---|---|---|
| **Owner / Chairman** | Profit, control, visibility, valuation, reputation | §3.3 ROI table, §3.4 cost of delay, the owner's phone dashboard |
| **Medical Director** | Patient safety, clinical workflow, doctors not being slowed down | Critical-result workflow, medico-legal documentation, "the doctors will use it because it is faster than paper" |
| **Finance Manager** | Cash flow, budget cycle, claim rejections | Stage payments, the claims module, the reconciliation reports |
| **IT Manager (if any)** | Not being blamed, not being replaced | Architecture, backup and DR, training *them* to own it, support SLA — make them the hero of the project, never the obstacle |
| **Head Nurse / Reception supervisor** | "Is this more work for me?" | Show, on a phone, the paperwork disappearing. They are the quiet veto in every hospital sale — win them in Meeting 1. |

**Rule:** the owner signs, but any of the other four can kill it. Do not sell only to the person with the pen.

---

## 6. Making A Big Number Payable

Most hospitals cannot release EGP 5M at once, and that is a cash-flow problem — not a pricing problem. Do not solve it by cutting the price. Solve it with structure.

### 6.1 Stage The Programme So It Self-Funds

| Stage | Contents | Duration | Payment |
|---|---|---|---|
| **Stage 0** | Paid assessment | 3 weeks | EGP 90,000 — credited |
| **Stage 1** | Registration, master patient index, ADT, outpatient scheduling | 4 months | EGP 850,000 |
| **Stage 2** | Cashier, price lists, billing, reconciliation | 3 months | EGP 750,000 ← **first savings appear here** |
| **Stage 3** | Insurance, contracts, pre-authorisation, claims | 3 months | EGP 900,000 ← **largest single return** |
| **Stage 4** | EMR core, CPOE, clinical documentation | 5 months | EGP 1,300,000 |
| **Stage 5** | Integration engine, migration, training, parallel run, go-live | 3 months | EGP 400,000 |
| **Mobile app** | Runs in parallel from month 2 | 5 months | EGP 850,000 |
| **Recurring** | Support & maintenance, from each stage's go-live | ongoing | 18–22%/year |

The sentence that makes this land:

> "You are not paying five million. You are paying eight hundred and fifty thousand to start. By stage three the system is returning more per month than the next stage costs. **The programme pays for itself from stage two onward.**"

### 6.2 Other Structures That Unlock Budget

- **Instalments across two fiscal years** — many private hospitals approve capital by budget year; splitting the programme across two makes an impossible number possible.
- **Subscription model** — EGP 180,000 – 300,000 per month over 24 months instead of a capital purchase. Total is higher; approval is far easier. Offer it when you hear "we do not have the capital."
- **Retain the recurring line no matter what.** Discount the build if you must; never discount the maintenance. That contract is the business.
- **Never discount for nothing.** Every reduction is exchanged: a faster payment schedule, a reference-site agreement, a case study, an introduction to another hospital, or removed scope. A discount given for free teaches them the first number was dishonest.

---

## 7. Objection Handling

Rehearse these until they are automatic. Arabic lines are given because that is the language the meeting will be in.

**"This is too expensive."**
> "Compared to what? Let us put it against what the current situation costs. By your own numbers the leak is around EGP 590,000 a month. The system costs less than nine months of that leak, and then it keeps paying every year."
>
> *"غالي مقارنة بإيه؟ خلينا نحطه جنب تكلفة الوضع الحالي. بأرقام حضرتك، اللي بيضيع حوالي ٥٩٠ ألف في الشهر. السيستم تكلفته أقل من تسع شهور من الضياع ده، وبعدين بيفضل يرجّع كل سنة."*

**"There is a company offering it for 300,000."**
> "There is, and it is a real offer for a real product. Ask them three questions: does the price include configuring your departments and migrating your data, or only the licence? What is the annual support cost from year two? And can I speak to a hospital of my size that they took live — not one that bought it, one that is running on it? The cheap number is almost always the licence with the implementation removed. Implementation is where hospital systems succeed or fail."
>
> *"اسألهم تلات أسئلة: السعر شامل التركيب وتهجير البيانات ولا اللايسنس بس؟ الدعم السنوي من السنة التانية بكام؟ وأقدر أكلم مستشفى بحجمي شغّالة عندهم فعلاً — مش اشترت، شغّالة؟"*

**"We will start small and expand later."**
> "That is exactly what I am proposing — but the order matters. Start with registration and billing, not with a module that has nothing underneath it. Otherwise you pay twice: once to build it, and once to rebuild it when the foundation arrives."

**"Our doctors will not use it."**
> "They will not, if it is slower than paper. That is why the clinical module is stage four, not stage one — I want six months of your staff succeeding with the easy parts before I go anywhere near a consultant's workflow. And I will build the doctor's screen with three of your doctors in the room, not for them."

**"Send me a proposal and we will study it."**
> "I will — but a proposal written before I have seen your registration desk and your claims file would be guesswork, and you would be right to reject it. Give me one morning in the hospital first. Then the proposal will have your numbers in it, not my assumptions."

*(This is the most common brush-off in the market. Never accept it. A proposal sent cold is a proposal read as a price list and filed.)*

**"How do I know you can deliver this? You are a small team."**
> Answer honestly and specifically: name the stage plan, the fact that they pay per stage and can stop at any stage boundary, the source-code escrow or repository ownership, and the documentation and training that means they are never hostage to you. **"You own the code and the data from day one"** is a stronger answer than any claim about company size.

**"Can you do the whole thing for 200,000?"**
> "No. And I would rather tell you that now than take the money and fail. For 200,000 I can build you the patient mobile application with a defined scope — a real product, in both app stores, in your brand. The hospital system is a different programme and it starts with an assessment. Let us do the app first, and you can judge me on it before you commit to anything larger."

*(This is the single most valuable answer in this document. Refusing an undeliverable price, in the room, out loud, is the strongest credibility signal available to a small vendor.)*

---

## 7b. Competing Against Established HIS Vendors

The hospital will almost certainly be comparing you with an established Egyptian HIS product vendor. The best known in this segment is **CodeZone** (`codezone-eg.com`), whose hospital product is **MYELIN**, sold in editions segmented by facility size:

| Edition | Positioning (per the vendor's own material) |
|---|---|
| **MYELIN Basic** | New or small hospitals — front-office workflow and patient billing |
| **MYELIN Grow** | Medical centres of limited capacity — patient records, appointment scheduling, service tracking |
| **MYELIN Pro** | Medium-sized hospitals — billing, claims, HR, purchasing and inventory |

Stated core components include the hospital management base, patient records and diagnosis, CRM, SMS, and BI/decision support. Named public references include Dawi Clinics and I-Care Hospital.

**CodeZone does not publish prices.** Neither does any comparable vendor in this market — HIS pricing is quotation-based and varies by bed count, sites, concurrent users, modules and implementation scope. Treat any specific annual figure you hear second-hand as unverified until you see the quotation.

### How to find out what they actually charge

In order of usefulness:

1. **Ask the hospital.** If they are evaluating vendors, they already hold the quotation. "Have you had a quote from anyone else? Can I see the scope so I compare like for like?" is a normal, professional question and it is the fastest route to the number. It also tells you what stage the decision is at.
2. **Ask peers.** Administrators at hospitals of similar size talk to each other. One phone call to a friendly hospital that has been through a HIS purchase is worth more than any amount of searching.
3. **Approach CodeZone as an implementation partner, not a competitor.** Product vendors need local partners for configuration, integration, training and support. This is a legitimate and often better business than building a custom HIS: you sell the licence, keep the implementation and support revenue, and carry none of the product risk. Worth one email before you commit to building your own.

Do not request a quotation while posing as a hospital. You would get a number and lose the ability to ever partner with them, in a market where the vendors all know each other.

### The comparison trap — and how to break it

A product licence quote and a custom-build quote are not comparable, and the hospital will compare them anyway. Break it by insisting on a like-for-like scope table:

| Line | Product vendor | Custom build |
|---|---|---|
| Software licence or subscription | ✔ quoted | n/a — you own it |
| Implementation, configuration, department setup | **often quoted separately** | included |
| Data migration | usually extra | quoted |
| Integration with labs, analysers, PACS, the mobile app | usually extra | quoted |
| Customisation to the hospital's own workflow | limited, billed per change | included by definition |
| Training and go-live support | often extra | included |
| **Annual support, from year two** | **18–22%, recurring forever** | 18–22% |
| Ownership of code and data | licensed — stops when you stop paying | owned outright |
| Total cost over five years | **the only fair comparison** | **the only fair comparison** |

**The question that reframes the whole conversation:**

> *"السعر ده شامل التركيب وتهجير البيانات والربط والتدريب — ولا اللايسنس بس؟ وإيه تكلفة الدعم السنوي من السنة التانية؟ خلينا نقارن التكلفة على خمس سنين، مش سعر اليوم."*
>
> "Does that price include implementation, migration, integration and training — or just the licence? And what is annual support from year two? Let us compare five-year total cost, not day-one price."

Your honest advantages against a product: workflow fits the hospital instead of the reverse, they own the code and data, the mobile app is native to the system rather than a bolt-on, and you are local and responsive. Your honest disadvantages: a proven product carries less delivery risk, has existing reference sites, and is available sooner. **Say both.** A vendor who names the competitor's genuine strengths is believed about everything else.

## 8. What Kills These Deals

| Mistake | Do instead |
|---|---|
| Quoting before the assessment | Diagnose first, always |
| Leading with features and screenshots | Lead with the four leaks and their money |
| Selling only to the owner | Win the head nurse and the IT manager first |
| Discounting when challenged | Exchange, never concede |
| Promising a date you cannot hold | Stage boundaries with exit rights |
| Hiding the manual-entry burden of an unintegrated Phase 1 | Quantify it openly — it funds Phase 3 |
| Skipping the maintenance contract to close faster | The maintenance contract *is* the business |
| Accepting "send me a proposal" | Trade it for one morning on site |

---

## 9. Your Next Three Actions

1. **Book Meeting 1 this week.** Ask for one morning to walk the hospital. Take no proposal, no laptop, no price. Take the §3.2 worksheet and fill it in.
2. **Come back with their numbers in the §3.3 table, and sell only the assessment** at EGP 60,000 – 120,000.
3. **In parallel, close the mobile app at EGP 200,000 (Tier S) or EGP 850,000 (Tier B).** Ship it well. A working app in their brand, in both stores, is worth more than every slide in this document when the seven-figure conversation begins.

---

*Prepared as internal sales guidance. Replace all illustrative figures with hospital-supplied actuals before use with the client.*
