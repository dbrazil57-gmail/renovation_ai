# RenoVision — Google Play release guide

Updated 22 November 2026, Australia/Sydney. This is the requested release plan,
not evidence of store approval. Google Play/Android is the first public target.
Accept the app on the owner's Samsung S21, then finish iPhone parity so friends
can provide TestFlight feedback. Keep Chrome current; native desktop follows later.
The original project brief and existing test installations remain intact.

## Current position

- Working Android/Chrome app: projects, room photos/camera, multiple views,
  analysis, style/palette/scope, concepts, refinement, history/comparison, local
  paint/tile previews, save/share, portable/protected project files and Help.
- The requested 1.0.17 test APK includes the recent source changes, kitchen sample
  replay/practice copy, branding cleanup and optional invitation-based test access.
  Final checks: 363 tests, clean analysis, release web/Android builds and actual
  Chrome/API 37 emulator sample/practice/restart checks pass. Physical S21 and
  actual 16KB-runtime acceptance remain; see [test evidence](TESTING_GUIDE.md#requested-apk-1017-acceptance).
- Current Android test package/signature stays unchanged for update/data continuity.
  It is not yet a signed production Play bundle.
- Sample replay is offline and clearly labelled. It uses owner-authorised kitchen
  before/after images and a saved historical prompt; the later idea board uses a
  different viewpoint and a reconstructed example brief. No fabricated AI job,
  analysis, provider model or request ID is recorded.
- Initial tester-access client and a single-process gateway are prepared. They
  are not a deployed/funded service, payment system or production credit platform.

## Website, email and privacy

A custom domain and full marketing website are optional for this first stage.
Google requires an operational support email; listing contact information is
visible to users. A separate free support mailbox or forwarding alias is suitable
to consider. A personal mailbox can be used, but expect that public address to be
visible. Do not put a supposedly encrypted personal address plus its decryption
key inside the app and describe it as hidden. A private forwarding destination
can live on a server, with a separate public support address.
[Google listing/contact requirements](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en).

Provide an app-specific, publicly accessible privacy-policy web page, linked in
the app and listing. It can be on hosted pages without buying a domain. Explain
photos/prompts sent to AI providers, BYO keys, optional trial-service processing,
reports, local storage, OS backups, exports and deletion. Reconcile this with Data
safety and actual SDK/network behaviour; a placeholder policy is not sufficient.
[Google User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en).

Still needed: choose the public support address and policy host, implement real
report delivery, and decide report/photo retention. The current email/form
handoff is not the required in-app AI-output reporting mechanism. Do not
automatically send a private room photo or credentials with feedback.
[Google AI-generated-content policy](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en).

## Initial AI allowances for testers

Owner suggestion: approximately **$1 per tester**, about $12 for 12 people.
Currency, funding, hosting and actual model/request cost still need confirmation.
The observed low personal test cost is useful evidence, not a guaranteed cost for
every input, model, quality or retry. No spending or deployment is activated here.

Use the offline sample for most usability tests. Offer a small, owner-funded live
allowance for genuine analysis/generation tests without asking every tester to
create a developer account. The owner provider key belongs only on the server.
The phone receives a separate, revocable invitation. BYO OpenAI/Gemini remains
available and their keys are not overwritten by trial access.

Implemented preparation:

- Settings > AI connection and models > Tester credits: HTTPS address, private
  invitation, remaining analysis/design attempts, expiry, refresh and disconnect.
- Android encrypts invitations in a separate Keystore-backed preference store;
  secret stores are excluded from cloud/device-transfer backup. Chrome keeps the
  invitation in memory. Project files contain neither invitations nor API keys.
- Each confirmed analysis consumes one analysis allowance; each generated image
  consumes one design allowance. Multiple concepts consume one per image.
- The gateway authenticates invitations, pins model/low quality, limits input
  sizes, allows one upstream request at a time, and enforces global/per-invitation
  counts and expiry. A durable reservation is written before forwarding.
- Repeated request IDs cannot create another upstream request. Interrupted or
  rejected attempts can consume an allowance; no automatic retry/refund is made.
  After an uncertain client failure, refresh the balance before proceeding.
- These are **request-attempt allowances, not dollar-denominated credits**.
  They do not enforce a $1 currency cap. Set counts from measured cost, validate
  provider access and establish an owner-approved spending control before funding.

### Preparing the small trial service

1. Run `dart run tool/create_tester_invites.dart` only when ready to create private
   files. It writes ignored `output/private-tester-service/` files and will not
   overwrite existing invitations. The example is 12 invitations, two analyses
   and three designs each, with 30-day expiry; review/change counts before use.
2. Choose a server with persistent storage and an HTTPS reverse proxy. This
   gateway is designed for **one process** with a durable JSON ledger. Do not
   deploy several instances or use an ephemeral filesystem. Multi-instance
   production needs a transactional database and additional operational work.
3. Supply `OPENAI_API_KEY` through the host's secret manager, and set
   `RENOVISION_TESTER_LEDGER` to the private ledger path. Optionally choose
   `RENOVISION_TESTER_MODEL`; the initial quality is fixed at low.
4. Review the quota/cost/expiry and enable explicitly with
   `RENOVISION_ENABLE_TESTER_SERVICE=1`; run `dart run tool/tester_gateway.dart`.
   It binds to loopback port 8788 (`RENOVISION_TESTER_PORT` can override it).
5. Configure the HTTPS proxy to reach only that loopback listener and replace
   `X-Forwarded-Proto` with `https`. Keep the internal provider relay private.
   Native Android needs no CORS entry. Browser testing requires explicit origins
   in `RENOVISION_TESTER_ORIGINS`, comma-separated; no wildcard is enabled.
6. Test expiration/revocation, exhaustion, simultaneous requests, ledger write
   failure, network interruption and server restart before giving out invitations.
   Each tester receives only their own invitation and the HTTPS address.
7. Retain the ledger securely, stop the service to revoke/change invitations,
   then restart after the deliberate edit. Removing a phone invitation does not
   revoke a copied server invitation; revoke it in the ledger. Stop the service
   for an immediate global stop. Do not log prompts, room images or credentials.

The gateway does not save request images/prompts or AI result images; the ledger
contains invitation hashes, counts, expiry and attempted request IDs. Configure
proxy logs, server backups, provider retention and cleanup deliberately. A lost
response is not replayed from a result cache. Trial billing/top-ups, automated
refunds, identity recovery, abuse monitoring and a dollar ledger remain future work.

## Android release checklist

- [ ] Accept the latest APK on S21: install over the existing app, retain projects,
  settings and keys, restart/reopen, and verify the build number.
- [ ] Check first-design appeal with little typing on several room/space types;
  compare real OpenAI/Gemini results and record cost, time and requested changes.
- [ ] Test camera/gallery, Live still overlay, multi-view analysis, one/two/three
  concepts, refinement, local finishes, comparison, deletion/recovery, Help videos,
  offline replay/practice copy, Gallery/share and plain/protected Save/Open.
- [ ] Check larger projects, interrupted/background requests, offline/denied
  permissions, low storage and restart. Resolve blocking defects and repeat fixes.
- [ ] Add actual in-app AI-output reporting with receipt/delivery and owner review.
- [ ] Publish/link the privacy policy, complete Data safety, clarify permanent
  local deletion/trash retention and Android OS backup behaviour.
- [ ] Finish production identity/signing with an explicit data-migration plan.
  A changed package/signature will not inherit the test app's private data/keys.
  Preserve test installations until portable projects are restored and checked.
- [ ] Build/verify a properly signed Android App Bundle, current target API/native
  16KB support, final permissions, version code and device compatibility.
- [ ] Complete Play Console identity/device verification when authorised; use a
  genuine personal/organisation account and final package identity.
- [ ] Prepare store icon A, feature graphic, real screenshots, clear descriptions,
  audience/content rating, support contact and licenses. Label Live accurately:
  a generated still overlay, not instant moving-view VR or a measured room scan.
- [ ] Give reviewers valid private instructions/access to test AI. Do not require
  them to establish/fund a provider account or hide review-only behaviour.
- [ ] Choose pricing and configure payment/payout arrangements if charging.
- [ ] Complete applicable internal/closed tests, apply for production access,
  resolve findings and submit for review. Approval is not automatic at day 14.

## Recruiting and running the closed test

For new personal accounts, at least 12 testers must stay opted in continuously
for 14 days before the production-access application. Friends/family are suitable;
they need compatible Android access and the Google account enrolled in the test.
Use Play's opt-in/install route: an APK shared privately does not replace this
track. Record engagement, feedback and resulting fixes. There is no published
fixed daily-minutes quota; an installed but unused app is weak testing evidence.
[Google testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

Suggested workload, not a Google minimum: first session 10–15 minutes creating/
opening a project, a short mid-test session trying tools/save/share, and a final
session checking an update and prior issues. Add a small live-AI allowance for a
deliberate end-to-end test. Collect phone/OS/app version, steps, expected versus
actual result, and an optional screenshot. Keep a short record of fixes.

Paid-download closed testers normally need to purchase the app; internal testers
can install a paid app free. Decide this before inviting people. Internal testing
does not replace the qualifying closed test; ensure testers join the correct track.
[Google test-track setup](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en).

## Income and later platforms

Validate willingness to pay for Standard with BYO AI, with separate provider
charges explained before purchase. A modest one-time purchase/unlock is the first
experiment; funded subscriptions/credits need ongoing delivery/support controls.
A published free app cannot simply become a paid download with the same package.
[Google app pricing](https://support.google.com/googleplay/android-developer/answer/6334373?hl=en).
Digital unlocks normally use Play Billing, subject to its applicable exceptions.
[Google payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en).

iPhone is the next platform milestone after Android acceptance: native file
Save/Open/restore, image save/share, Keychain, feedback/reporting, permissions,
branding and actual Mac/Xcode/iPhone verification remain. Use TestFlight for
friends; this feedback improves shared features but does not count toward Google's
Android closed test. Public Apple release is separate. Native desktop packaging,
cloud sync and a managed paid-AI platform follow demonstrated demand.

## Not authorised or completed by this guide

No account registration, domain/email purchase, hosting deployment, membership,
paid AI request, tester invitation, key disclosure, Play upload or production
signing change is performed by writing this guide or building the test APK.
Owner decisions pending: support mailbox/policy URL, hosting, trial currency and
funding, final quota/model, monetisation and production identity/migration.
