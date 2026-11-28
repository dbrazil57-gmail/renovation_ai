# RenoImagineAI - store release guide

## Samsung individual-publisher eligibility - 28 November

The detailed Seller Portal guide resolves the earlier private/corporate ambiguity:
for the owner's Australian Android-app situation, registration requires a
**Corporate Commercial Seller Request**, including D-U-N-S verification on the
normal path. The guide for private commercial sellers explicitly redirects a
personal seller wanting to sell an Android app to the corporate request guide.
A personal Samsung Developer profile, or entering one's name in its company field,
does not provide Android distribution approval.
[Samsung corporate commercial request](https://seller.samsungapps.com/getSellerGuide.as#/0301010000),
[Samsung private commercial request](https://seller.samsungapps.com/getSellerGuide.as#/0301020000).

Verified by reading the public Markdown used by Samsung's JavaScript guide:
[corporate instructions](https://d2nup21dbv379f.cloudfront.net/seller-user-guide/0301010000.md),
[private instructions](https://d2nup21dbv379f.cloudfront.net/seller-user-guide/0301020000.md).
The standard browser extractor only shows the guide shell; anonymous source access
was required. No sign-in, application or account data was involved.

This portal category does not establish that Australia requires an incorporated
company. Acceptance of an Australian individual/sole trader using their legal
name and any alternate business documents is **not confirmed**. Samsung's broader
[preparation guide](https://developer.samsung.com/galaxy-store/prepare.html) mentions
asking support about alternative verification when D-U-N-S is unavailable; that
is not evidence of an exemption for this Android app.

Before further store-specific investment, the owner should ask Seller Portal
Help > Contact Us: "I am an Australian individual developer without an incorporated
company. Can I publish an Android app as a sole trader under my legal name? What
business documentation and D-U-N-S verification do you require?" No message has
been sent. Samsung-first remains conditional on eligibility; its lack of a
publishing fee does not mean personal-profile registration alone is sufficient.

Owner selected **RenoImagineAI** and the numbered **06 camera/house** logo concept,
with **Snap. Imagine. Renovate.** and **Australian designed. Globally inspired.**
as the approved brand text. This supersedes the rejected
RenoCue suggestion. Name approval does not establish trade-mark/domain clearance
or Samsung eligibility. Keep the app identity/storage compatible during rebranding.

## Samsung listing pack - 28 November

Prepare a store listing and promotional material separately from the in-app Help
walkthroughs. The confirmed name is **RenoImagineAI**, with the 06 camera/home
identity. The listing, installed app name/icon and final screenshots must match.
Retire pre-name drafts from submission; new sample drafts remain subject to final
phone capture/release acceptance before upload.
[Samsung self-check](https://developer.samsung.com/galaxy-store/self-check-list-galaxy.html?lang=en).

Latest branded local draft: `output/samsung-listing-draft/draft-1795857598547053/`,
including `renoimagineai-samsung-draft.zip`. It contains the title, public copy,
reviewer notes, camera/home icon, five sample UI screenshots, a 32-second silent
trailer and provenance. The older pre-name draft remains available locally but
must not be used for submission. This pack is a review draft, not an upload.
The closing scene includes both approved brand lines; the previous branded draft
is retained locally as history.

Samsung registration assets, checked against the
[Content Publish reference](https://developer.samsung.com/galaxy-store/galaxy-store-developer-api/content-publish-api/reference.html):

| Item | Preparation |
| --- | --- |
| App title | Final confirmed name, up to 100 UTF-8 bytes. |
| Short description | One sentence, up to 40 UTF-8 bytes. Draft below is 33 bytes. |
| Full description | Up to 4,000 UTF-8 bytes; draft below describes existing features. |
| App icon | PNG, 512 x 512 pixels, at most 1,024 KB; use final approved icon. |
| Screenshots | 4-8 PNG/JPG images, dimensions 320-3,840 pixels, at most 2:1 ratio. Prepare five. |
| Optional listing video | YouTube URL; Samsung places its thumbnail/link first in the screenshot area. |
| Review comments | Up to 4,000 bytes; private validation steps/access, separate from public copy. |

Also prepare the production-signed Android binary, category/age-rating answers,
country/language choices, support contact, working privacy-policy URL, accurate
data/permission disclosures and any purchase/trial terms. Privacy requirements
apply because selected photos/briefs are transmitted to the AI provider after
confirmation. The screenshots/description must show actual features and disclose
purchases appropriately. A promotional video does not establish working AI or
replace reviewer access.
[Samsung distribution rules](https://developer.samsung.com/galaxy-store/distribution-guide.html?lang=en),
[registration/review tabs](https://developer.samsung.com/galaxy-store/launch.html).

The owner's provided screenshot is **Samsung Developer personal/profile setup**
(occupation, job level, technology interests), not the commercial Seller Portal
verification page. Do not confuse its company field with legal publisher approval.
Leave it empty if allowed; if required, use a truthful independent-developer
description rather than an invented business. Formal seller eligibility is still
unresolved and must be checked before committing to Samsung distribution. No
personal account details from the screenshot are included in release materials.

### Public listing copy - draft

Approve final pricing/disclosures and release details before submission. English
is the current app language. The app's technical support URLs/legal owner remain
separate pending fields, never fabricated in public copy.

<!-- samsung-public-copy:start -->
APP TITLE
RenoImagineAI

SHORT DESCRIPTION
AI home design with your own key.

FULL DESCRIPTION
See renovation possibilities in your own space.

Start with photos from your gallery or camera. Choose a room or outdoor space,
explore styles and colour palettes, and create visual ideas using your own
OpenAI or Google Gemini developer API key.

DESIGN FROM YOUR PHOTOS
Use a primary photo and add other views for context. Review the AI's observations
and design proposal, then choose what to update and what to keep.

EXPLORE AND REFINE
Generate up to three design options, compare them with the original and select
a favourite. Describe a focused change to refine an existing design while keeping
each version available in your project.

TRY FINISHES AND KEEP YOUR WORK
Preview wall colours and tiles, organise rooms and saved designs, save a portable
project file, and export or share your favourite images. Local finish previews
can be sent for a separate AI polish after review and confirmation.

TRY THE OFFLINE EXAMPLE
Explore the included kitchen sample and Help walkthroughs before connecting AI.
Sample replay uses saved example results and does not make a live AI request.

BRING YOUR OWN AI
A supported developer API key and internet access are required for live AI
analysis and image generation. AI usage is charged separately by your provider.
A consumer chatbot subscription is not the same as developer API credit.

Projects are stored on your device. Selected photos and instructions are sent
to your chosen AI service after confirmation. Keep a project file for a portable
copy. English interface.

AI images are visual inspiration, not measured building plans. Results vary;
review important details before making renovation or purchasing decisions.
<!-- samsung-public-copy:end -->

### Private reviewer notes - draft

These are preparation notes, not a claim that a production submission exists.
Do not submit until the access/AI review instructions can actually be followed.

<!-- samsung-review-copy:start -->
DRAFT - COMPLETE BEFORE SUBMISSION
App name: RenoImagineAI.
Release version/package and legal publisher: [confirm final values].
Support and privacy URL: [provide working public destinations].

Offline demonstration:
1. Launch the app and open Help / Sample walkthroughs.
2. Select Try the kitchen sample flow.
3. Review the original, saved concept and later example ideas. Replay is offline;
   the historical result was imported from an external AI session. Its provider
   model is unknown. No live API call or generation speed is demonstrated.

Actual app workflow:
1. Create a project; choose a room and gallery photos or camera capture.
2. Follow Room photos, Design direction, Analyse and review, and Finalise and
   generate. Analysis and generation have separate confirmations.
3. Review a generated design, compare the original and request a focused update.
4. Save/Open a project file and export/share an image using the device chooser.
5. Allow camera access only when testing camera features.

Live AI review access: [provide a tested, limited review-access method privately].
Do not ask reviewers to create/pay for an AI provider account simply to validate
the core feature. Do not place an owner API key in the APK, screenshots or public
description. Confirm how Samsung will test BYO AI before submission.

Software access/purchases: [complete Samsung sandbox and restore/expiry checks,
then provide actual reviewer steps and approved terms]. No real purchase flow
or hosted activation is live in the current private test build.

Camera preview is a captured still/design overlay; it is not continuous live
AI video or spatially tracked AR. Local paint/tile previews are approximate.
The sample videos simulate camera/AI/file-picker responses in real app widgets.
Replace draft footage with final-device footage after branding/release acceptance.
<!-- samsung-review-copy:end -->

### Demo and screenshot preparation

`tool/prepare_samsung_listing.dart` creates a **draft-only** local pack under
`output/samsung-listing-draft/`: copy extracted from this guide, five sample-frame
screenshots, the current approved 512-pixel icon, a silent 32-second MP4 and its
storyboard/provenance. It uses existing authorised kitchen examples and recorded
Help UI, with explicit sample/draft labels. No live AI, user project/vault, upload,
APK, store account or advertising spend is involved. FFmpeg/ffprobe are development
tools already available locally, not app dependencies. Generated media stays
ignored by Git; the reproducible recipe is tracked.

Five final screenshot targets: room photos/setup; style/palette selection; a
selected design and focused update; before/after comparison; saved project/file
controls. The draft uses historical Help recordings. Capture final phone images
after the name/icon are agreed and the production build is accepted. Do not crop
away simulation disclosures and then present those recordings as live generation.

The promotional MP4 is for review before a final recording/YouTube upload. An
optional longer private reviewer video should show the complete real workflow,
including BYO connection/access, generation, refinement and save/restore. It must
not expose keys, account details, personal project names or phone notifications.
No publication or upload is authorised by creating this draft pack.

## Samsung-first release preparation - 28 November

Samsung is now the first store target; the existing Play/iOS material below is
retained for later channels. Owner has not registered in Samsung Seller Portal.
No account, product, paid checkout, listing or deployment was created here.

1. Owner register and establish commercial-seller eligibility in
   [Samsung Seller Portal](https://seller.samsungapps.com/) using the
   [official preparation guide](https://developer.samsung.com/galaxy-store/prepare.html).
   Decide production package/signing and an update/data-migration path before
   changing the current private `com.example.renovision_ai` package or certificate.
2. Agree the trial duration/limits and Standard terms. Owner prefers one active
   device and is considering monthly expiry; automatic renewal and price are not
   approved. A subscription and a manually renewed pass need different product
   behaviour/disclosures. Both can use one installed app.
3. Obtain the official Samsung IAP SDK through Samsung login, register the app/
   product IDs and implement the native method-channel contract. Show the actual
   local product price, renewal/trial terms and cancellation before checkout.
   [SDK integration](https://developer.samsung.com/iap/programming-guide/integrate-iap-helper-into-your-app.html).
4. Implement and host the HTTPS access authority. Verify receipts/current
   subscription state and keep a durable one-active-device/trial-eligibility
   ledger. Use verified recovery/transfer, authenticated webhooks or reconciliation,
   revocation/refund handling and private server signing keys.
   [Samsung verification](https://developer.samsung.com/iap/programming-guide/samsung-iap-server-api.html).
5. Test Samsung no-charge purchase/cancel/restore/acknowledgement, expiry, renewal,
   refund, offline lease and authenticated new-phone transfer. Retain viewing/
   export of existing work and distinguish app access from BYO provider charges.
6. Finish support/privacy/reporting destinations, accurate screenshot/demo rights,
   reviewer AI access and production signing, then submit for Samsung review.
   Drafts are in [product notes](PRODUCT_NOTES.md#samsung-launch-and-advertising-drafts---28-november).

Client implementation in this batch:

- `lib/app_access.dart`: pinned Ed25519 grants, installation request proof,
  expiry/high-water clock check and bounded offline lease, fail-closed licensed
  configuration, trial/refresh/verified-Samsung-receipt endpoints.
- `lib/samsung_access.dart`: SDK adapter **contract only**, purchase/owned-item
  filtering and service verification. Native SDK implementation is still absent;
  missing adapter means unavailable, never a fabricated successful purchase.
- Settings > App access: compact real state, pending setup, refresh/restore when
  configured. No Buy action until SDK, authority and price/terms review are ready.
- Existing private builds stay unrestricted. Store builds must explicitly use
  `RENOVISION_ACCESS_MODE=licensed`, HTTPS `RENOVISION_ACCESS_URL` and
  `RENOVISION_ACCESS_PUBLIC_KEYS` (JSON key-ID to base64url 32-byte public key).
  Optional `RENOVISION_SAMSUNG_STANDARD_PRODUCT` identifies the real portal SKU.
  These definitions contain public configuration only; no signing/API private key.
  Changing keys requires trusted app/key rotation, never trusting keys in a token.

Authority protocol to implement (not a running service):

- POST `<base>/v1/access/trial`, `/refresh` or `/samsung`, no redirects. Body is
  `{payload, signature}`; payload is base64url JSON containing version 1, operation,
  audience, SHA256 installation public-key ID, public key, UTC epoch-second time
  and random 24-byte nonce. Samsung also includes `purchaseId`. Verify Ed25519
  over UTF8 `RVREQ1.<payload>`, bind route/audience/key, enforce clock skew and
  nonce replay protection. A signed request proves key possession, not payment or
  unique trial eligibility. Add verified onboarding/invitation proof before public
  trial deployment; do not grant one new trial for every new installation key.
- 200 response `{grant: "RV1.<payload>.<signature>"}`. Signed payload fields:
  `v=1`, pinned `kid`, `iss=renovision-access`, `aud=renovision`, opaque `licence`,
  `device`, `plan=trial|standard`, integer UTC `iat`, `nbf`, `exp`, `refreshBy`.
  Sign UTF8 `RV1.<payload>` with the private Ed25519 key. Refresh must preserve
  original entitlement expiry unless a real renewal has been verified. Lease
  cannot exceed expiry or 48 hours from issue. New responses must be freshly
  issued; cached grants can be used locally until their lease ends.
- 401/403/410 revoke local access; 409 indicates a device/ownership conflict.
  Only use these statuses for authoritative access outcomes, not maintenance/
  rate limiting. Network/service failures retain existing cached local access
  until lease expiry, but stop new paid AI calls until online verification works.
  Never log requests, purchase IDs, licences, signing material or user room data.

The authority, actual SDK, account recovery, cumulative trial quotas, transfer
workflow and production end-to-end acceptance are outstanding. This foundation
must not be described as a finished billing system or reinstall-proof trial.
No new APK was built for this source batch; 1.0.20 remains the last private APK.

Latest requested test package, **25 November 2026**: **1.0.20+21**, source
**`454c2f8dcf`**. Includes Gemini request compatibility/diagnostics, the pinned
send action, draggable divider/conditional image strip, original/generated mode
selection and required-change readiness without a Partial/Precise brief override.
468 tests, analysis and APK signature/assets/private-file/16KB checks pass; native
emulator update from 1.0.19 retains sample work and verifies disabled empty edits.
Physical S21/real-provider acceptance is next. See [APK 1.0.20 tests](TESTING_GUIDE.md#requested-apk-1020-acceptance)
and the [current request audit](../CODEX_NEXT_STEPS.md#current-outstanding-request-audit--after-1020-packaging).
This supersedes older package/source-only statements below. Public release gates,
hosting/support, production identity/signing, store testing and iOS parity remain.

Updated 23 November 2026, Australia/Sydney. This is the requested release plan,
not evidence of store approval. Google Play/Android is the first public target.
Accept the app on the owner's Samsung S21, then finish iPhone parity so friends
can provide TestFlight feedback. Keep Chrome current; native desktop follows later.
The original project brief and existing test installations remain intact.

Follow-up **23 November**: source/Chrome now includes remembered browser keys,
visible Autosave, selected-design updates, paint-only AI polish, recoverable
project management/additive room import, regional wording, image-usage estimates,
optional sourced OpenAI research and improved local material previews. These are
now included in the requested **1.0.18+19 test APK**, source `e0ef2fa1ee`, together
with corrected/reviewed finish polish and remembered working screens. Final owner
S21 acceptance is next. Help recordings use real app widgets with
simulated camera/AI; genuine Android launch footage remains a later step.

Owner confirms **no hosting or support address yet**. Live tester funding/hosting,
support and AI-output report delivery, privacy hosting, production identity/signing,
store account/testing and iOS parity remain release gates. No deployment or spending
has been activated. Browser tester invitations now use a separate encrypted local
vault too; this does not create a hosted allowance or provider balance.

## Current position

- Latest shared-source corrections simplify normal saving to Save/Save as; move
  exported-copy-only password protection into Advanced; default selected results
  to focused updates; add optional project look reuse and better tile-area controls.
  Actual OneDrive-folder disk round trips passed with generated fixtures. Physical
  chooser/cloud-sync acceptance remains distinct. Requested APK 1.0.18 includes
  these completed changes; English stays the current app language.
- Working Android/Chrome app: projects, room photos/camera, multiple views,
  analysis, style/palette/scope, concepts, refinement, history/comparison, local
  paint/tile previews, save/share, portable/protected project files and Help.
- The requested 1.0.18 test APK includes all completed post-1.0.17 changes, kitchen
  sample replay/practice copy, existing branding and optional invitation-based test
  access. **401 tests pass**, analysis is clean and the release Android build and
  signature/assets/private-file/16KB alignment checks pass. Physical S21 and actual
  16KB-runtime acceptance remain; see [test evidence](TESTING_GUIDE.md#requested-apk-1018-acceptance).
- A read-only API 37 emulator update from 1.0.17 retained its sample work; selected
  image and Style tab survived restart, and the native finish editor opened.
  These checks do not replace physical phone or real-provider acceptance.
- Current Android test package/signature stays unchanged for update/data continuity.
  It is not yet a signed production Play bundle.
- Sample replay is offline and clearly labelled. It uses owner-authorised kitchen
  before/after images and a saved historical prompt; the later idea board uses a
  different viewpoint and a reconstructed example brief. No fabricated AI job,
  analysis, provider model or request ID is recorded.
- Initial tester-access client and a single-process gateway are prepared. They
  are not a deployed/funded service, payment system or production credit platform.

## Copyright, licences and name clearance — 23 November

This is a preliminary release check, not legal clearance. Google Play requires
publishers to respect copyright, trade marks, patents and other IP; approval is
not a substitute for checking rights to the app and its store-listing content.
[Google Play IP policy](https://support.google.com/googleplay/android-developer/answer/9888072?hl=en).

In Australia, qualifying original work receives copyright automatically; a ©
notice is optional. A suitable About notice can identify the actual owner and
year, for example `© 2026 [confirmed legal owner/publisher]`, with third-party
notices separate. The legal owner/publisher has not been confirmed, so no ownership
claim, root software licence or public copyright statement was invented. Copyright
protects expression such as source code and artwork, rather than the general idea
of renovation software or a before/after slider.
[Australian government copyright guidance](https://www.business.qld.gov.au/running-business/risk/ip/ip-kit/browse-ip-topics/copyright-works).

Repository findings:

- Six inspiration pictures have generation prompts/provenance in
  `assets/inspiration/provenance.json`; the record states no competitor or private
  room photos were used. The kitchen demo has the owner's recorded permission in
  `assets/demo/flow.json`. Retain these records and review rights to all inputs and
  provider terms before public use; AI generation alone is not IP clearance.
- The direct installed Dart-package licence files inspected use BSD-style, MIT or
  Apache terms. The web build already contains Flutter's bundled NOTICES asset.
  No visible About/Licences entry was found in Settings. Add access to those notices
  and audit transitive/native dependencies, icons/fonts, images and store artwork
  before release. This initial check is not a complete licence compliance audit.
  [Flutter licence-page support](https://api.flutter.dev/flutter/material/showLicensePage.html).
- Planner 5D, HOMLY and Forma were recorded as workflow/styling references, not
  licensed source/templates. Retain independently implemented code and artwork;
  public screenshots or design inspiration do not grant redistribution rights.

**Name finding:** a public service called [RenoVisions](https://renovisions.ai/)
advertises photo-based AI renovation visualisation and uses RenoVision wording.
This is a relevant similar-name use, not proof of a registered trade mark or of
infringement by either party. A completed trade-mark-register search and assessment
of confusing similarity in target countries have not been performed. Do not market
the name as cleared. Keep existing test installations/data while checking it.

Use IP Australia's [Australian trade mark search and TM Checker](https://www.ipaustralia.gov.au/trade-marks/search-existing-trade-marks),
including similar spellings and the proposed icon. Check app stores and ordinary
business use too. Search target countries if distributing overseas. Given the
related service name, consider a trade mark professional's clearance assessment
before investing in public branding. No registration, payment, rename or contact
with another business was made.

- [ ] Confirm the publishing entity and rights to original/human-authored material.
- [ ] Complete name/logo clearance; resolve the RenoVisions similarity before launch.
- [ ] Add About/Legal and accessible third-party licence notices; complete the
  asset/dependency audit and retain permissions/licence texts.
- [ ] Finalise terms covering user-upload rights, AI concepts/limitations and actual
  service behaviour, alongside the separate privacy policy. Do not claim exclusive
  ownership of all generated outputs or apply an open-source licence to the entire
  app without an explicit owner decision.

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
  secret stores are excluded from cloud/device-transfer backup. Chrome now retains
  the invitation in its separate encrypted browser/profile/address vault. Project
  files contain neither invitations nor API keys.
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
- [ ] Complete copyright/licence and name/logo clearance above, including the
  similar RenoVisions renovation service. Store acceptance is not legal clearance.
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
