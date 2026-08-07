# Source Coverage — What Was Received and Where It Landed

This document records exactly what was extracted from the client-supplied material,
so nothing is silently lost between the deck and `PROMPT.md`.

---

## 1. Design deck — `D.O.H_APP.pptx` — **fully processed**

11 slides, all Arabic text extracted, all 33 embedded media files extracted and
inspected. Brand identity read from the hospital signage and ambulance livery
images in the deck.

| Slide | Arabic content found | Mapped to |
|---|---|---|
| 1 | دار الأمومة فى بيتك · تسجيل دخول · إنشاء حساب | `PROMPT.md` §6.1 Splash & Welcome |
| 2 | سجل بياناتك · الاسم رباعى · الرقم القومى · رقم الهاتف · البريد الالكتروني · اسم الشركه ان وجد | §6.2 Registration — every field carried over, with validation rules and National-ID checksum added |
| 3 | الرعايه المنزليه · الشكاوي · نصائح طبيه · العروض | §6.3 Home Screen — the four tiles kept exactly as specified |
| 4 | الملف الطبي | §6.6 Medical File |
| 5 | العيادات · إختر عياده · عياده جراحه العظام · احجز الان | §6.7 Clinics — Orthopaedic Surgery treated as the worked example; full list flagged as an open question |
| 6 | الأشعه · اختر نوع الأشعة · أشعه تليفزيونيه · أشعه عاديه · أشعه مقطعيه · أسعار الأشعه · مواعيد الأشعه | §6.8 Radiology — all three modalities, prices and schedules carried over |
| 7 | التحاليل وبنك الدم · العروض · نتائج تحاليل · اسعار التحاليل · خدمات بنك الدم | §6.9 Laboratory & Blood Bank |
| 8 | اتصل · 01013009936 | §6.10 Contact & Emergency — number used verbatim |
| 9 | (images only, no text) | Interpreted as the home-care / ambulance visual; folded into §6.4 and §6.10 |
| 10 | العروض · EVENTS · اليوم العالمى للسرطان · اليوم العالمى للمرأة · اليوم العالمى للطفل | §6.11 Offers & Events — all three awareness days named |
| 11 | نصائح طبيه · عام · تغذيه · امومه · قلب · جلديه + 5 tips | §6.12 Medical Tips — all five categories and all five tips seeded verbatim as launch content |

**Brand identity extracted:** hospital name مستشفى دار الأمومة, tagline صحتك مسؤوليتنا,
mother-and-child crescent mark, navy `#0B2E5C` and pink `#E4327E` (sampled from the
signage photograph — approximate, see `PROMPT.md` §19 question 1).

---

## 2. Voice notes — **not processed**

Four WhatsApp voice notes were supplied:

| File | Recorded |
|---|---|
| `WhatsApp_Ptt_20260804_at_20.54.55.ogg` | 04 Aug 2026, 20:54 |
| `WhatsApp_Ptt_20260804_at_20.55.47.ogg` | 04 Aug 2026, 20:55 |
| `WhatsApp_Ptt_20260804_at_20.56.41.ogg` | 04 Aug 2026, 20:56 |
| `WhatsApp_Ptt_20260804_at_21.02.01.ogg` | 04 Aug 2026, 21:02 |

**These could not be transcribed.** Speech recognition requires downloading a model,
and every model host (`huggingface.co`, `openaipublic.azureedge.net`, `alphacephei.com`)
is blocked by this environment's network egress policy — the proxy returns HTTP 403,
which is an organisation policy denial, not a transient failure.

`PROMPT.md` therefore reflects **the design deck plus standard hospital-app practice
and the proposed extensions**. It does **not** reflect anything said in the four voice
notes.

### What is needed

Send the content of the voice notes as text (Arabic is fine) and the affected sections
of `PROMPT.md` will be revised. Anything in the recordings about the following would
change the document materially:

- Additional screens or features not in the deck
- The full clinic, doctor, laboratory-test or radiology-study lists
- Pricing, insurance or corporate-contract rules
- Whether the hospital already runs an HIS, LIS or PACS
- Number of branches
- Launch deadline
- Anything already listed in `PROMPT.md` §19 (Open Questions)
