# RenoVision

Samsung listing preparation now includes public copy, reviewer notes and an
offline 32-second sample promo/screenshot pack. See the
[existing release guide](docs/GOOGLE_PLAY_RELEASE.md#samsung-listing-pack---28-november).
The final replacement name is still undecided; no app branding or APK changed.

Latest source work, **28 November 2026**: Samsung-first launch preparation and
software-access foundations. Signed, installation-bound trial/Standard grants,
expiry/refresh checks and Settings > App access are implemented and tested with
synthetic receipts. Private builds retain existing unrestricted software access.
Samsung checkout, hosted verification, trial eligibility and device transfer are
**not live**. APK 1.0.20 below is unchanged; no new APK was requested.
Current private Chrome source is **`c58ff6c0f1`**, at http://localhost:7357/;
older source IDs below refer to earlier batches.
All **491 tests pass**; static analysis, Android Kotlin compilation and the
release web build pass. The separate deprecated Chrome test runner stalled at
startup; it is not counted as passed browser licence acceptance.
See the [Samsung release checklist](docs/GOOGLE_PLAY_RELEASE.md#samsung-first-release-preparation---28-november)
and [launch drafts](docs/PRODUCT_NOTES.md#samsung-launch-and-advertising-drafts---28-november).

Current test release, **25 November 2026**: **1.0.20+21**, shared source
**`454c2f8dcf`**. [Download APK 1.0.20](output/mobile-test/renovision-test-1.0.20.apk)
and install over the existing app. App identity, signing certificate, icon and data
paths are preserved. Older dated package/source-only notes below are historical.

Includes the latest Gemini transport/diagnostics, pinned sending, draggable image
divider, conditional thumbnail strip, original/generated mode switching and
disabled empty Partial/Precise edits without a brief override checkbox. New design
retains its brief percentage. Existing project work and keys are retained.
All **468 tests pass**, static analysis is clean, Chrome/release APK builds and
signature/assets/private-file/16KB alignment checks pass. Emulator update retains
sample work and verifies disabled edit reviews, restart and navigation. Same
Chrome source is served at http://localhost:7357/. Real phone/model acceptance
remains separate.

See [mobile test steps](docs/TESTING_GUIDE.md#requested-apk-1020-acceptance) and the
[current outstanding-request audit](CODEX_NEXT_STEPS.md#current-outstanding-request-audit--after-1020-packaging).

Latest readiness change: Brief % applies to New design. Partial/Precise show
change readiness, with sending disabled until a real change is supplied and no
Proceed-anyway checkbox. Source photos remain required; New design can leave
optional style/goal choices to AI. Included in APK 1.0.20 above.
Current Chrome: **`454c2f8dcf`** at http://localhost:7357/, superseding older IDs
below. **468 tests pass**; analysis and web build pass.

Latest fix: original-photo entry returns to New design; generated designs retain
their Partial default. Original and other photo angles share the same selection
path, and stale request warnings clear. Both Send to AI and Brief → Proceed use
the current source. Existing photos/briefs/designs remain saved. APK unchanged.
Current Chrome: **`9ee802e36f`** at http://localhost:7357/, superseding older IDs
below. 83 relevant checks pass; analysis and web build pass.

Latest workspace follow-up: keep the normal single-image size; show the thumbnail
strip when more than one room photo/design exists. Include original/photos/designs
and bring the selected thumbnail into view. Double-tap the divider for the updated
automatic view if a compact size is already saved. APK 1.0.19 is unchanged.
Current Chrome: **`82ff9af022`** at http://localhost:7357/, superseding older IDs
below. 47 relevant checks pass; static analysis is clean.

Workspace follow-up, **25 November**: drag the divider up/down on phones or
left/right on wide screens to resize the image and controls. Double-tap to reset;
the device remembers portrait/wide layouts. The owner confirmed Gemini Nano
Banana 2.1 / 2K generation in Chrome. APK 1.0.19 remains unchanged and still needs
the new Gemini source in a future requested build.
Current Chrome build: **`1035df3de0`**, superseding the IDs below. **449 tests pass**;
analysis and isolated browser checks pass. Wrong-key connection validation stays
out of diagnostics. Refresh the same http://localhost:7357/ tab to test.

Source / Chrome follow-up, **25 November 2026**: saved design selection opens
Partial; **Send to AI** stays on every workspace tab; 100% briefs need no extra
proceed tick. Gemini uses documented generateContent requests. **Settings → AI
diagnostics** keeps safe local model/status/timing logs. Live account access still
needs an owner test. The APK below is unchanged.
Chrome build **`6c6c28f662`** is served at **http://localhost:7357/**. Full suite
442 tests and final 30 targeted checks pass; analysis and actual Chrome checks pass.
See [current acceptance steps](docs/TESTING_GUIDE.md#gemini-and-workspace-follow-up-25-november-2026).

Latest test APK: **1.0.19+20**, source **`61e0807e2e`**.
[Download APK 1.0.19](output/mobile-test/renovision-test-1.0.19.apk) and install over
the existing app. Package, signing certificate, icon and data paths are unchanged.
**435 tests pass**, analysis clean, APK signature/assets/private-file/16KB checks
pass. Chrome serves the matching source at localhost:7357.

Includes all completed post-1.0.18 changes and **Settings → Storage cleanup**.
Choose an archive, save an offline backup or explicitly skip, then type its name
to permanently remove its local data. Browser downloads require confirmation that
the file is saved. Active projects, shared images, keys/settings and external files
are kept. Development folder cleanup removed 19 disposable folders (~0.83 GB).
See [APK 1.0.19 acceptance](docs/TESTING_GUIDE.md#requested-apk-1019-acceptance).
Older source-only/unchanged-APK statements below are historical and superseded.

Earlier Home source **`62350daf12`** adds a visible Home icon in the project rooms
list, four-step setup and workspace. It returns directly to Projects after saving
pending work, and stays visible beside Save/setup/Settings on phones. Workspace
remains available at every setup step; unfinished rooms show their saved step in
the rooms list. Adding another photo never restarts setup. Refresh restores the
saved page. **39 related tests pass**, analysis is clean and all seven help recordings
are refreshed. The APK below remains unchanged. Keep RenoVision for testing; the
public name/logo check remains on the release list.

Previous source follow-up **`e48ca6290f`**: Back leaves the current screen without
cycling workspace tabs. Setup's bottom Back changes steps; its top arrow saves
and leaves setup. More tools offers Rooms & spaces and Projects home. Also adds
room-name suggestions, photo/space wording, one pinned generation action,
persistent paint controls with Undo/Redo, compact Auto + information, per-result
AI cost details and a saved-look summary in Style. Analysis and generation remain
separate confirmed requests. **414 tests pass**, analysis is clean, and all seven
help recordings are refreshed and validated. This is not in the unchanged APK below.

Source follow-up after APK 1.0.18: the workspace Room tab now has a labelled
**4-step room setup** button. Guided room setup is also available inside setup,
with a chooser for all four steps that saves existing choices. Older/completed/
Live rooms retain their work. Source `7f94718c8f`: 22 related tests pass, analysis
is clean, web build and actual phone-sized Chrome navigation/reload checks pass.
Same http://localhost:7357/. This follow-up is not yet in the unchanged APK below.

Previous Android test build: **1.0.18+19**, source **`e0ef2fa1ee`**.
[Download the APK](output/mobile-test/renovision-test-1.0.18.apk) and install over
the existing RenoVision app, keeping its data. The olive-and-cream icon and signing
identity are unchanged. **401 tests pass**, static analysis is clean and the release
APK passes signature, public-asset/private-file and 16KB alignment checks.
The physical S21 acceptance steps are in the
[testing guide](docs/TESTING_GUIDE.md#requested-apk-1018-acceptance).

This packages all completed post-1.0.17 changes: saved keys, visible Autosave,
simpler Save/Save as, selected-design refinement, improved tile/grout controls,
corrected AI polish inputs and review, navigation restoration and updated help.
English remains the app language; full translations are deferred. Chrome uses
the same application source at http://localhost:7357/. The dated notes below
record earlier source-only verification; their old APK statements are superseded.

Refresh/review update: source **`e0ef2fa1ee`** remembers the main tab,
project, workspace tab/mode and selected image, Settings and workspace editing
tools. Refresh rebuilds Back navigation and does not replay AI sends. Navigation
preferences stay on this device and out of project files. The bottom **Review
and send AI polish** action first prepares Refine; **Polish with AI** shows the exact
prompt before confirmation. **Review & generate change** creates a new AI version
from your next specific request; it does not approve or overwrite your design.
Label follow-up: **33 paint/AI workflow tests pass**, clean analysis and updated
paint help. Prior navigation regression: **401 tests pass**, release web build and refreshed help
clips. Actual desktop/phone-size Chrome refresh, Settings Back and finish-review
checks pass. Same localhost:7357; now packaged in test APK 1.0.18+19.

Latest finish-polish correction, **23 November**: the owner confirms the tiled
pictures were saved **Local finishes** previews. An AI attempt failed and left the
preview selected; this is not a completed AI polish result.
**Review and send AI polish** is pinned in the finish editor; reopened local versions
also offer **Review and send AI polish** in Refine. Confirmation sends the
clean same-view design first and rough finish guide second, with physical
splashback boundaries and protected window/tap/cupboards. Only confirmed generation
saves **AI finish polish**. Independent grout adds White/Black and custom colour.
Save/restore retains both image references; originals and earlier versions remain.

Current Chrome source **`7821f8aa18`**, same localhost:7357: **396 full-suite tests
pass**, final analysis clean, release web build and updated paint-help clip/full
decode pass. No paid AI call or APK build. Provider appearance/boundary acceptance
is still required; local selections are not automatic semantic masks.

Latest saving/refinement corrections, **23 November**:

- Normal project-file actions are Save project and Save project as. The duplicate
  plain backup button is removed. Advanced encrypted export protects its exported
  copy only; it does not encrypt local data or existing plain files.
- Selecting a saved/generated image defaults to Precision and shows only Update
  this design. Full/Partial are explicit wider renovations; their original brief
  stays saved and is not reapplied to a focused update.
- Use another room's look reuses saved style/palette, preferring an approved result,
  without an AI call, model training or copying geometry/photo observations.
- Tile controls distinguish opacity from area. Grow left/right/up/down/all sides;
  Outline full splashback fills its four-corner area across grout gaps. Tile settings
  remain open through slider changes. Different wall planes need separate surfaces.
- Owner confirms key saving. Real disk save/autosave/Save as/reopen/restore/failure
  and encrypted-copy checks passed in isolated Windows and OneDrive Renos folders.
  Existing files are preserved; cloud sync and native phone choosers are separate.

Verified Chrome source **`2643765277`**, same localhost:7357: **394 full-suite tests
passed**, followed by **28 targeted paint/refinement checks** for the stable progress
slot. Final analysis clean (27.2s); web build 63.3s. Actual desktop/phone-sized
single-field refinement, project look reuse, complete Save as and advanced-export
explanation pass, with inspected screenshots. Seven refreshed help recordings and
full MP4 decodes pass. No paid AI request, new APK, data reset or old file deletion.

Previous small follow-up: the Projects list now uses a visible delete icon, with
typed confirmation, backup and recoverable archive/delete unchanged. Chrome
source `c9a6649c1e`: five project tests, clean analysis and web build passed.
Published APK stays 1.0.17+18. The remaining order is actual save/AI acceptance,
then a requested S21 package and launch preparation; see the active checklist.

Current follow-up, **23 November**: keys now survive browser reload in a separate
encrypted browser vault, without an app login. Enter a key once after this update;
it remains scoped to this browser profile and address. Clearing site data removes
it. Android continues to use its secure device store. Project files exclude keys.

Autosave is a visible switch below the title, not a menu-only action. Selected
designs have **Update this design** and **Apply focused update**. Local finishes
have **Review and send AI polish**, which prepares only the finish correction, clean design and
rough guide, rather than the original whole-room brief. Sending still needs
confirmation. Originals, approved baselines and prior versions are preserved.

Projects now offer confirmed, recoverable archive/delete, unique new names,
distinguishable legacy duplicates, and additive **Import rooms from project**.
Import adds separate room copies; it does not reconcile edits to an existing room.
Temporary notices dismiss/expire. Whole room stays visible above collapsed detail.
Multiple kitchen concepts receive different cabinetry, hood and material schemes
within the chosen palette; actual visual distinctness needs paid-provider testing.

Settings adds regional English wording and image usage/budget estimates. Optional
sourced design research is a separate, explicitly confirmed OpenAI request.
Tile previews can import a material sample and use a reviewed four-corner plane;
they are not automatic wall recognition or measured installation plans.

**Save/Open meanings:** Autosave keeps local room edits; photos and completed
designs save when added. A connected reusable browser working file is also updated
while linked. Save project writes the full project. Save as chooses another file.
Use Save as for a separate fixed copy with the same project contents.
Open resumes the matching project with conflict choices; Restore copy adds a
separate project. Android currently exports through its chooser; it does not
continuously overwrite a persistently linked external document URI.

No hosting or support destination exists yet. Hosted tester credits, delivered
feedback/privacy hosting and store/iOS setup remain release prerequisites. This
batch updates source/Chrome only; **published APK 1.0.17 is unchanged**.
Use [the active checklist](CODEX_NEXT_STEPS.md) and
[the follow-up acceptance pass](docs/TESTING_GUIDE.md#follow-up-acceptance--23-november).
The older dated notes below record previous builds and superseded behaviour.

Verified Chrome source **`ac96247b07`**, same localhost:7357: full suite **388 tests
passed**, plus **24 related tests** after the final archive visibility correction;
clean final analysis (17.7s), release web build 48.2s. Actual desktop/phone-sized tab navigation, selected-image
update field, Autosave reload and typed archive/restore passed in isolated Chrome.
Browser key reload/removal passed with synthetic secrets. Seven refreshed help
recordings passed capture and full MP4 decode checks. Real AI quality, owner key/
OneDrive chooser and S21 acceptance remain; no new APK or paid AI request.

Previous regroup, **22 November**: projects/rooms, multiple photos, AI analysis and
generation, styles/palettes, history, comparison, local finishes, camera/Live,
project files and image export/share are implemented. Use the current checklist in
[CODEX_NEXT_STEPS.md](CODEX_NEXT_STEPS.md) before the older dated notes below.

**Autosave** keeps local work and updates a connected writable working file.
**Save project** writes every room, photo, design and choice to that file.
**Export backup snapshot** writes a separate fixed copy of the same contents;
**Duplicate project** creates another project inside the app. Restore adds a copy
without overwriting. Additive room import and persistent browser keys were added
in the 23 November follow-up. API credentials remain excluded from project files.

The latest OneDrive kitchen export was confirmed empty. New browser code verifies
saved size and offers a download fallback; an actual destination save/reopen still
needs acceptance. Existing data and APKs are preserved. This batch refreshes Chrome
only: **published APK 1.0.17 is unchanged**.

Recent source fixes include New/Partial/Precise modes, smaller palettes, editable
Keep exceptions, clearer AI plans/manual handoff, useful empty Ideas, stronger
fitting prompts, smaller splashback patterns and optional selection-edge extension.
Local tiles remain previews. Real-provider image comparison and provider invoice/
balance integration remain unfinished; the follow-up adds optional research,
material perspective and image-only estimates.

Verified current source `68527c827a`: **374 tests pass**, clean analysis (13.5s),
release web build (46.9s). Browser bridge checks pass for a 16 MB complete read-back
and rejecting a zero-byte false success; the actual app Open/Save path writes a
nonempty complete kitchen fixture and retains it after reload in an isolated
profile. Deeper workspace browser automation stalled; its controls are covered
by native tests and still need manual Chrome acceptance. OneDrive acceptance
and paid quality comparison remain. Use the fresh-test steps in the testing guide.

Prompt enhancement after APK 1.0.17, **22 November**: room analysis now asks for a
decisive, room-specific design proposal with coordinated materials, main/task
lighting, fittings, restrained styling and explicit retained features. A newly
analysed, current proposal is enabled automatically for normal designs and remains
editable/optional. Changed photos or choices exclude the old proposal; matching
photo observations still inform current choices without requiring another analysis.
Precise correction never inherits the broader proposal. Setup, workspace and Live
share this rule. Multiple ideas may reinterpret suggested materials/detailing
within the user's scope rather than repeat the same AI proposal.

This changes prompts and defaults, not the provider API workflow or saved history.
No extra automatic AI call, model/quality change or new APK. The installed 1.0.17
does not include this follow-up; the Chrome preview is current at localhost:7357.

Verified source `71336f78f2`: **368 tests pass** (86s), clean analysis (15.5s),
release web build (101.5s). Detailed three-option kitchen briefs fit by omitting
repeated generic guidance and, when necessary, using a labelled excerpt of AI
observations. Written requirements, edited proposals and full saved analyses stay
intact. Existing prompt-length checks still reject overly long written briefs
before a paid request. Logs are under `output/prompt-enhancement-*`.
Actual 390×844 Chrome smoke passes for sample replay/practice import and Room /
New design controls. Request composition and prepared-preview behaviour are
verified in Flutter tests; browser automation did not complete the deeper preview
scroll/reveal. No real provider request was made.

Requested test release **1.0.17+18**: all recent shared-source changes, the
owner-authorised kitchen offline replay/practice project, invitation-based trial
access preparation, and visible branding cleanup. Help > Sample walkthroughs >
Try the kitchen sample flow needs no AI key. The separate practice copy lets
testers use real tools and saves without spending AI credits.

See [Google Play release guide](docs/GOOGLE_PLAY_RELEASE.md) for launch gates,
website/email choices, testing tasks, pricing and the optional test service.
About $1/tester is a proposed budget; currency/hosting/funding remain pending.
The service enforces request quotas, not a dollar balance, and is not deployed.

Verified **1.0.17+18**, source `d19f2fd3d2`: **363 tests pass**, clean analysis
(16.9s), release web build (48.1s) and Android build (70.3s). Actual 390×844 Chrome
and Android API 37 emulator checks pass for sample stages, saved brief, comparison,
practice import/reopen and tester settings, without a key or provider request.
The APK is `output/mobile-test/renovision-test-1.0.17.apk`, 84,941,239 bytes;
SHA256 `9E4AE423009A1F6040203ACAD591A91B857381D6468D154FEDFD9D1DBC39E0E6`.
Install over the existing app; do not uninstall or clear data. Its package and
certificate match 1.0.16. All published older APKs remain intact. Physical S21
acceptance and actual 16KB-runtime testing remain open. Earlier dated source-only
notes below are historical; their completed shared changes are now in 1.0.17.

Release priority confirmed **22 November**: first reach an accepted Android
release candidate on the owner's Samsung S21, then bring iPhone to the same
functional standard so friends can test through TestFlight. Feed their usability
and design-quality findings back into the shared Flutter app. Google Play remains
the primary launch target; its Android closed test is separate from iPhone beta
feedback. Keep Chrome current; native desktop packaging follows later. iOS parity
is planned, with file/save/share, persistent keys and real-device testing still open.

Photo-first design and local finishes follow-up, **22 November**: analysis now
asks for a fuller visible room inventory and a specific, coordinated scheme even
with few comments. Matching photo observations automatically inform New design
requests; the optional AI-written prompt still needs review. Changing style or
palette can reuse those observations without another analysis charge. A different
working image/view set and Precise correction do not inherit those facts.

Use **Colours & tiles without AI** on the image toolbar. Select a surface once,
choose Wall / Floor / Splashback and paint, square, rectangular or brick tiles in
**2 Finish**, then try colours, grout, scale and angle locally. Tile layouts are
approximate 2D previews, not measured products or reconstructed room planes.
**Finish with AI** saves the preview and prepares one precise polish of its
selected surfaces together. Review and explicitly confirm generation separately.
Source/desktop follow-up only; the published APK 1.0.16 is unchanged.

Source `b95048b5fc`: **350 tests pass**, clean analysis (11.4s), release web build
(55.5s). Existing projects/settings and the same localhost:7357 origin are retained.
An actual 390×844 Chrome check saved and reopened a local tile preview with its
surface/pattern intact, using a public sample in a disposable profile and no key.

Wall tile shortcuts: **2 Finish** now exposes **Wall tiles**, kitchen **Splashback
tiles**, and **Bathroom wall tiles / Shower wall tiles** where appropriate. Select
the area first; each shortcut reuses it and your colour. Add a separate surface
layer to retain independent wall and floor finishes. Patterns, grout and final
AI polish use the same save system; these source changes await a requested APK.
Shortcut source `74d73a34cf`: **354 tests pass**, clean analysis (10.0s), and release
web build (48.1s). The desktop preview uses the same localhost:7357 address.
An actual 390×844 Chrome kitchen check applies the splashback shortcut and
restores the tile pattern after save/reopen; public sample, no key or AI request.

Brief review follow-up, source `56814171d1`: the checklist has a pinned **Proceed
with the current brief** checkbox. Ticking it changes Refine brief to Proceed,
including below 75%. Proceed uses the normal connection/required-input/send path
and avoids repeating readiness guidance for that attempt. It does not send an
image or save a review acknowledgement until the normal send is confirmed.

Brief readiness follow-up, **22 November**, source `65936b5efb`: a live Brief %
indicator is pinned above Generate on every workspace tab. The existing send
confirmation includes missing-direction suggestions and Refine brief, with no
extra preflight dialog. A valid basic brief can still proceed. After proceeding
at 75% or more, that room/mode reminder stays hidden unless coverage drops below
75%; the normal paid-request confirmation remains. Precise correction has its own
short checklist. This is local input coverage, not an image-quality prediction;
extra photos, paid analysis and a connected key do not add points. Device-only
reminder preferences persist separately from project files. No new APK or paid AI.

Lighting/terminology follow-up, **22 November**, source `50196e8c85`: Update
lighting now explicitly requests replacing visible unprotected main fittings;
adding strip/under-vanity lights alone is insufficient. Full-room briefs include
the same direction. Ceiling geometry, Keep choices and task-light-only corrections
remain protected. Analysis identifies main fittings separately from accent lights.
Analysis/generation also clarify regional English terms and basin versus vanity
scope. The interface remains English-only; a Language & Region selector and
translated interfaces are proposed work, not implemented controls. Real generated
image adherence still needs user/provider testing. No new APK or paid AI request.

Main navigation follow-up, **22 November**, source `75ffe41898`: Projects is the
first/default tab, followed by Explore and Library. Settings opens from the
top-right cog as a separate page; Back returns to the same main tab. Its redundant
bottom destination is removed. This is source/desktop work after APK 1.0.16.

Workspace follow-up, **22 November 2026**, source `c2d523f4c0` after APK 1.0.16:
Generate is pinned across Room / Style / Refine / Ideas. Autosave stays in More
tools; only pending/failed save status uses the footer. Palettes are smaller with
a two-column full chooser; styles show ten curated common choices, then paged
alternatives, retaining cross-page selections. Style now has **Full room (all)** /
**Partial** scope. Full room includes normal finishes/fittings updates, while
protected items and explicit Keep choices still win; its included-item controls
are read-only. Partial exposes individual changes. Layout preservation stays on
by default, separately from renovation extent. Precise correction remains a
focused edit of the working image. Prompt/analysis details start closed; manual
copy/import is under Refine, while Ideas reviews generated versions. **332 tests
pass**; no paid AI, customer-data changes or new APK in this follow-up.

Launch review, **21 November 2026**: suitable for controlled beta preparation;
Google Play production still needs the focused
[launch gates](CODEX_NEXT_STEPS.md#public-launch-review--21-november-2026).
The user has no Play Console account yet. No store publication was made.

Requested test update, **21 November 2026 — 1.0.16+17**: all completed room,
paint, Live naming and recorded-help changes below are now packaged. All **327
tests pass**, analysis is clean, and the release APK is built from source
`aba3ee136c`. The confirmed olive/cream A icon, app ID and signing identity stay
the same. Install over the existing app; do not uninstall or clear its data.
Android checks caught incompatible help-video timestamps, now corrected with
standard H.264 MP4s. The updated APK installs/launches on an isolated API 37
emulator; playback, pause, actual near-end seek, fullscreen and written fallback
pass. Chrome is current at the same address. Physical S21 acceptance and
real-provider comparisons remain.

Source follow-up, **21 November 2026**, after APK 1.0.15: Help opens recorded app
workflows with playback/seek/full-screen controls and optional written steps.
Rooms have typed-name deletion and a persistent **Deleted rooms** recovery list.
Live room types save immediately and legacy type labels are normalized for
automatic names such as **Kitchen (Live)**. **Paint walls without AI** starts
with tap-to-select and colour; individual/all wall layers can be deleted after
reopening. Recolour the same layer without selecting again; **Finish with AI**
saves a rough preview and prepares a correction for review before generation.
Feedback explicitly says when its draft has not been sent.
These changes are included in the requested 1.0.16 APK.
Verification results and remaining work are in the linked status/next-steps files.
**327 tests pass**, analysis is clean, Chrome release and Android Kotlin/plugin
compilation pass. Source `aba3ee136c`; physical-phone acceptance remains.
The desktop browser preview is current at **http://localhost:7357**; its release
server supports reliable seeking through the new help videos.

Previous test update: **1.0.15+16** applies the user's confirmed **A** icon for now:
olive green with a cream room outline and sparkle. Launcher assets, app header,
startup mark and web icons match. **315 tests pass**, icon export passes, analysis is clean, and Chrome/Android release builds pass (138.1/155.1 seconds). Source `ce6b2da600`.
The previous 1.0.14 package remains unchanged for rollback.

21 November 2026 update: the requested **1.0.14+15** test package adds local
wall-paint previews without an AI key, saved editable paint layers, regional
style choices and the feedback tools. **315 tests pass**, analysis is clean, and Chrome/Android release builds pass (111.2/234.8 seconds).
The owner's support address/form URL is still needed to activate feedback delivery.
That package retained the previous icon; A was subsequently confirmed for 1.0.15.

Android-first Flutter renovation app, developed on Windows with Chrome as the
preview target. One shared Dart codebase builds platform-specific apps; the web
preview and Android APK are not separate products. iOS folders exist but that
platform has not been verified.

The working private beta supports saved projects/rooms, multiple photos,
AI photo analysis and editable prompt drafting, one/two/three renovation concepts,
selection/refinement, approved baselines, favourites, recoverable design deletion,
zoom/crop/annotation and before/after comparison. A personal OpenAI or Gemini API key can
connect directly over HTTPS on the phone, without a laptop. An optional relay and
manual copy/import workflow remain available.

The chosen Focus Canvas interface, phone camera/gallery and same-view camera
overlay are implemented. This is not tracked, moving-camera AR. Precision prompts
and marked references do not yet enforce masks or pixel preservation.

## Current position

Full source/conversation/design audit: **19 November 2026**, followed by verified
updates on **20–21 November**. The app is suitable for continued private testing.
AI precise-edit enforcement, persistent Android project-file linkage and measured
larger-project reliability remain unfinished. No public backend, payment system
or store-ready release is included.

The latest source adds prominent expandable AI settings, visible recoverable
design deletion, New design / Precise correction with separate 1/2/3 output
choices, stronger creative briefs, OpenAI/Gemini model presets, eight offline
guides with seven short recorded workflows and a fixed-brief model comparison aid. Automatic Live room names
use the actual type, such as Bedroom (Live), while preserving custom names.

Open project now resumes unchanged matching work; conflicting file/local
revisions offer Keep local or Open file as copy. New AI versions retain their
own settings, analysis and model/quality with Saved settings / Use these settings /
Refine this design actions. Startup shows loading and a non-destructive Retry.
Older versions remain readable without inventing missing historical settings.

Latest test package: **1.0.16+17**, source `aba3ee136c`, at
`output/mobile-test/renovision-test-1.0.16.apk` (also `renovision-test.apk`).
APK identity, matching 1.0.15 signing certificate, ARM64,
optional camera, restricted share paths, public-only assets and native ELF/ZIP
16KB alignment were checked. Size: 83,668,388 bytes; SHA256
`F70B4277E1259501EB76D09EB2316E9364B9913E83FC6576A87411840F1245FF`.
Install over the existing app without uninstalling. Older APKs remain for rollback.
Physical S21 acceptance and live Gemini comparisons remain. No paid AI calls or
user-data reset were performed.
Build further APKs only when requested.

In the Design workspace, choose **Colours & tiles without AI**. Tap a clear part of a
surface, check the highlighted boundary, then choose a finish, swatch or custom hex colour.
Adjust sensitivity if needed; outline/brush/erase remain optional fallbacks. Drafts
save locally; **Save finish version** creates a lossless PNG and editable layers,
leaving the source and approved baseline intact. Undo/Redo and Compare before
are available. Layer chips and Delete selected surface / Delete all surfaces remain
available after reopening. Tap selection uses local colour/edge connectivity,
not semantic recognition: similarly coloured adjacent objects may need correction.
Colour/shading and tile patterns are approximate, with no AI call; imported wallpaper remains later work. Local editing
preserves unselected pixels; that does not establish the same guarantee for AI edits.

Choose another colour on the same wall layer to replace it, without selecting
again. **Finish with AI** saves the local preview and opens Precise correction
with its paint/tile choices and one output. Review and explicitly generate when ready; this uses your
AI connection and may alter details because hard AI edit masks remain unfinished.

**Style > Regional influences** now includes Japanese, Italian, Moroccan and
Indian, alongside Scandinavian, Japandi, Mediterranean and French provincial.
Combine these with a base style; the app now has 23 styles and 12 palettes.

## Project documents

Keep four root documents and two supporting guides; update these rather than
creating another Markdown file per idea.

- [Product brief](RENOVISION_PROJECT_BRIEF.md): original requirements, unchanged.
- [Feature status](FEATURE_STATUS.md): what is implemented, incomplete and verified.
- [Next steps](CODEX_NEXT_STEPS.md): ordered backlog and conversation coverage.
- [Testing and storage](docs/TESTING_GUIDE.md): safe run/save/AI/device instructions.
- [Product and research notes](docs/PRODUCT_NOTES.md): design audit and dated research.

The next work should strengthen the existing product, not replace it with a template.

## Run the Windows preview

```powershell
cd C:\Dev\renovision_ai
flutter doctor
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1 -Release
```

Open **http://localhost:7357** in the same normal Chrome profile each time.
Bookmark it. Different ports, profiles and Incognito have separate saved stores.
Do not clear site data to fix missing projects. The launcher keeps browser ownership
with Chrome rather than creating a disposable Flutter Chrome profile.
The launcher resolves packages for the web target and avoids unnecessary desktop
plugin symlinks without changing global Flutter settings. `-Release` runs the
desktop browser app with production compilation; omit it for development debugging.
The current desktop build is `71336f78f2`, including all completed source features
listed above. A packaged native Windows companion remains a separate future stage.
Settings > App build and saved data shows the build/address/counts and offers
Check local saving. That confirms a read/write, not survival of a later crash.
See [recovered projects](docs/TESTING_GUIDE.md#recovered-projects) if an old test
appears missing. Source copies under `.local_backups/` do not back up app data.

## Test AI independently on Android

Settings > AI connection and models → disconnect a laptop relay if necessary →
Internet API → choose OpenAI or Gemini → privately enter that provider's developer
API key → Connect over internet. Recommended design models are browsable without
a key. Choose available image model/quality (Gemini uses 1K/2K/4K resolution).
Connecting checks listed model metadata, not paid image access;
analysis and generation are separate confirmed requests.

Android saves the key encrypted using Keystore, separately from projects. Chrome
direct mode keeps the key in session memory and needs re-entry after reload.
A subscription login is not an API key. Do not paste keys into chat or source.
The providers keep separate keys and model choices. Use saved provider key switches
back without re-entry on Android. OpenAI defaults to available 2.6 Sunburst/medium;
Gemini to Nano Banana 2.1/2K. Nano Banana Pro is the detailed Gemini preset.
Manually copied prompts remain provider-neutral. Claude is not an image renderer.
See [AI test setup](docs/TESTING_GUIDE.md#ai-test-setup).

## In-app help

For guided examples, open the app's information/Help icon and choose **Sample
walkthroughs**. Camera & photos groups Choose photos, Take a photo and Live view;
other guides cover Design & refine, Image tools & compare and Save & reopen.
**Compare AI models** is also available from Settings → Recommended design models
→ How to compare models. Keep the same original photo and brief for every test;
recommendations are a starting shortlist, with ranking left to actual results.
Enable **Use fixed brief for model tests** and select one result to skip the
normal rotating creative direction. This test switch resets off after restart;
it never starts a generation by itself or changes saved room output counts.
Help now defaults to recordings of real app widgets and transactions, with tap
highlights, captions, play/pause, seeking and full screen. Seven short bundled
MP4s cover photos/design, capture, Live, paint, library/recovery, Save/Open and models;
eight guides retain **Read steps** as an alternative. Fictional photos, simulated
AI/camera/file selection and disposable storage keep demonstrations separate from
your work. Viewing them needs no key and makes no project or provider requests.
The recordings replace the text-first examples in source after APK 1.0.15.

Help > Feedback and Settings > Feedback and ideas open the same saved local
draft. No photo/project/AI settings are attached; optional build/platform details
are shown in Review report. Email/form handoff needs a configured public contact.
Opening another app is not a delivery confirmation. Keep/copy the draft until
you have actually submitted it. See [feedback setup](docs/TESTING_GUIDE.md#feedback-setup).

## Save and resume

Open any photo/design full screen for **Save image** and **Share creation**.
On Android 10+, saving writes a PNG copy to Gallery under Pictures/RenoVision;
older Android uses the system file chooser. Chrome downloads the image or uses
browser file sharing when supported. Export strips embedded metadata and leaves
the stored original untouched. Sharing sends only the selected image; use Save
project to transfer editable rooms, choices and history. No account is required.

Local autosave retains room drafts and new images. Its shortcut is in More tools;
normal navigation flushes pending work. Keep a portable project backup as well.
Toolbar Save project/Save as and Settings exports include rooms, originals,
designs, prompts/history and current room choices; AI credentials stay separate.

Plain projects use `.renovision.json`. Optional password-protected backups use
`.renovision`; keep their password separately because it is not recoverable.
Encryption protects that export, not the current local photo/metadata database.

Open preserves portable project IDs and resumes an unchanged matching local
project. If file and local contents differ, choose Keep local or Open file as
copy; neither silently replaces the other. Restore copy deliberately creates an
independent project. Chrome can overwrite a linked plain file during its running
session; reopen it after restarting to reconnect. Android Save currently opens
the system destination chooser; persistent URI overwrite remains unfinished.
Local autosave and portable backups are separate. See
[saving and storage](docs/TESTING_GUIDE.md#saving-and-storage).

## Launch plan

Start with Standard using users' own developer API keys, with provider usage
billed separately. Included subscription AI credits and managed Pro services
come later, after adoption and cost testing. Accounts/billing are not implemented.
An optional paid Windows companion is a future option for phone capture followed
by large-screen refinement; Chrome already provides a desktop workspace. Transfer
project files manually today; automatic cross-device sync is future work.

## Developer validation

```powershell
flutter test
flutter analyze
flutter test --platform chrome test/workflow_test.dart test/editor_test.dart
flutter build web
```

An Android emulator is optional for private testing: start one in Android Studio
Device Manager, use `flutter devices`, then `flutter run -d <device-id>`.
Chrome does not validate Android camera/file/lifecycle behaviour. Install only a
requested new test APK over the old app with its matching signature; preserve data.

## Workspace privacy

Source, fictional bundled sample assets and synthetic tests belong in Git.
Local configuration, `.vscode/`, credentials/signing keys, browser profiles,
local databases, `.renovision.json` / `.renovision` exports, `output/`, recovered
projects and `.local_backups/` are ignored. Ignore rules do not erase Git history:
two private kitchen outputs remain in old commit `f94fe9b` despite being untracked
now. Review that history separately before making the repository public.

Retained private artifacts include APKs under `output/mobile-test/`, design boards
under `output/design-review/`, audit renders under `output/design-audit/` and
validated recovery files under `recovered_projects/`. Preserve the existing
`.dart_tool/chrome-device/` data and normal test profile. Do not delete uncertain
user files during cleanup. No remote push is part of the normal local workflow.

## Workspace cleanup — 19 November 2026

Removed approximately **2.02 GB (1.89 GiB)** of reproducible Android/test/tool
build caches, superseded test logs and APKs 1.0.8/1.0.9. Kept current APK 1.0.11,
its convenience filename and rollback APK 1.0.10 with their verification records.
The latest web build, application source/assets/tests, platform folders, SDK
configuration, browser profiles, recovered projects and all private images remain.

Consolidated 107 old source copies and one-off tools into one ignored archive
under `.local_backups/archives/`, verifying every archived file by SHA256 before
removing loose copies. Original documentation and browser/recovery archives stay
separate. The private cleanup manifest is
`.local_backups/cleanup-2026-11-19-refresh.json`; all 14 retained-file checksum
checks passed. The latest application test/analyser/web-build logs were kept.
No application code or stored user data changed and no new APK was built.
The next build/test will recreate the removed caches and may take longer once.
