# Dar El Omouma — Flutter application

Patient and doctor mobile application for Dar El Omouma Hospital, built against
[`../PROMPT.md`](../PROMPT.md). Arabic-first (RTL), with English as a fully
supported secondary language.

```bash
flutter pub get
flutter run              # Android / iOS
flutter test             # 85 tests
flutter analyze          # clean
```

## Layout

```
lib/
  core/
    l10n/          Arabic + English strings, compile-checked (no codegen step)
    routing/       go_router route table; paths map 1:1 to deep links
    theme/         brand palette, 8pt spacing grid, light + dark themes
    utils/         date, time, duration and money formatting
    validation/    Egyptian National ID, phone, name, email
    widgets/       shared cards, chips, tiles, notes
  domain/
    models/        catalog, booking, patient, content, TimeRange
    scheduling/    booking_conflicts.dart — theatre conflict engine
  data/
    seed_data.dart in-memory catalogues (deck content marked as such)
    app_state.dart stands in for the API described in PROMPT.md §9
  features/        one folder per screen area
    admin/         the admin console — catalogue and content maintenance
test/              national ID + theatre scheduling
```

## What is implemented

| Area | Screens |
|---|---|
| Onboarding | Welcome (deck slide 1), phone + OTP login, registration with National-ID derivation (slide 2) |
| Home | Four client tiles — home care, complaints, tips, offers (slide 3) — plus next appointment and quick services |
| Services | Clinics + booking (slide 5), radiology with preparation acknowledgement (slide 6), laboratory, results and blood bank (slide 7) |
| Medical file | Identity, allergies, visits, and the maternity view (slide 4) |
| **Theatre** | Availability grid, direct doctor booking with conflict enforcement and audited override |
| **Surgery** | Patient request with price snapshot, approval status, escalation indicator |
| **Centres** | Generic specialty-centre framework; Surgery Centre is its first instance |
| **Visiting experts** | Campaign list gated on the expert's practising licence |
| Content | Offers and awareness events (slide 10), medical tips (slide 11), complaints, home care |
| **Approvals** | Approver inbox with the SLA clock, approve / reject with a coded reason / request more information, and manual escalation |
| **Notifications** | Outbound log tagged by channel (push, WhatsApp, SMS) with the template code, showing that external messages carry no clinical detail |
| Home care | Service catalogue, request with address and time window, and the status ladder to completion |
| Blood bank | Unit request and donor registration with eligibility calculation and appeal opt-in |
| **Admin console** | Same app, same codebase, revealed by the `admin` role. Manage operation classifications, procedures, clinics, doctors, theatres, offers and medical tips. Adaptive layout: one column on a phone, a four-column grid in a desktop browser |
| More | Language, theme, contact, and the About screen carrying developer attribution |

## Notes for the next developer

- **`AppState` is the API boundary.** Every method on it maps to an endpoint in
  `PROMPT.md` §9. When the backend lands, only that class changes.
- **`TheatreScheduler` is a UX aid, not the enforcement point.** The
  authoritative check is a database exclusion constraint on the server
  (`PROMPT.md` §8, rule 5). The client runs it first so a surgeon sees a clash
  before tapping confirm, and must still handle the server's `409`.
- **Operation classifications are data, not an enum.** Nothing in the UI
  switches on a classification code — the admin console owns that list.
- **Set `DeveloperInfo` in `features/auth/welcome_screen.dart`** to the real
  company details. Attribution placement is specified in `PROMPT.md` §2.5;
  do not add placements beyond those.
- **Fonts.** The build uses system fonts. Production must bundle IBM Plex Sans
  Arabic and Inter per `PROMPT.md` §2.3 rather than relying on the device.
- **The brand palette is approximate**, sampled from photographs in the deck.
  Confirm against the official vector logo before release (`PROMPT.md` §19.1).
- **National-ID checksum is opt-in and off by default.** See the library comment
  in `core/validation/national_id.dart` for why, and validate the algorithm
  against real IDs before enabling `strictChecksum`.
- The doctor and approver roles are selectable on the login screen **for
  demonstration only**. In production the role arrives in the server-issued
  session token.
- **`AppNotification.staffAlert` is the only way to build an external message**,
  and it composes the body from a reference plus a short context — never a
  patient name. `workflow_test.dart` asserts this against every WhatsApp and
  SMS message the app produces; keep that test green.
- **The admin console ships inside this app**, gated by role, and is built for
  a wide screen because in practice it is used in a browser on a desk. Building
  it as a separate web deployment (`flutter build web -t lib/main_admin.dart`
  against a second entry point) would keep admin code out of the patient binary
  and decouple its release cadence from store review — worth revisiting before
  launch.
- **Catalogue entries are deactivated, never deleted**, so a past case keeps the
  classification, price and procedure it was created with.
- **WhatsApp templates must be approved by Meta before launch** and cannot be
  composed at runtime (`PROMPT.md` §12.4). The `templateCode` on each
  notification is the registry key; submit that set during M2, not M5.
