# Renovision feature status

## Refresh and review workflow — 23 November

Current source **`e0ef2fa1ee`** adds local navigation restoration for Projects /
Explore / Library, project rooms, workspace tab/mode and selected design/photo,
Settings and Back navigation. Colours & tiles reopens at Select/Finish with saved
layers; workspace viewer/comparison/crop/markup reopens from the same stored image.
Invalid or archived/deleted targets fall back safely. This preference is excluded
from portable projects. Dialogs, pending paid requests and transient camera capture
are not replayed. Tool pages reopen; unsaved crop strokes, viewer zoom and camera
frames are not a saved navigation state. Project photos/versions remain unchanged.

The first button, **Review and send AI polish**, stays at the bottom. It saves a preview
and opens Refine for reading/editing first. The second button, **Polish with AI**, opens the
confirmation with the exact prompt at the top, clean-source/guide roles and a
separate Send action. **Review & generate change** replaces the ambiguous Apply
update action: it creates another AI version from the selected image and update,
not approval or an overwrite. The original room brief remains separate.

Four page/tool restoration tests and a mocked refresh-during-confirmation test
pass. Shared source applies to Chrome and Android; physical S21 acceptance follows
the next requested APK. The earlier polish fix is locally committed as `e9b5f35`.
Label correction: **33 paint/AI workflow tests pass**, clean analysis (37s) and
updated paint-help capture/full decode. Web build (49.7s), actual desktop/phone
button-order checks and inspected phone layout pass. Earlier navigation verification:
**401 tests pass** (97s), clean analysis (49s), release web
build (104.9s), seven refreshed help recordings/full decodes. Actual isolated
desktop and phone Chrome refresh, Settings Back, Finish restoration and pre-send
Refine review pass; screenshots inspected. No paid request, APK or user-data reset.

## Finish-polish follow-up — 23 November

Owner confirms the supplied tile results are **Local finishes / local preview**;
an AI attempt failed, leaving that preview selected. It is not a completed AI
finish-polish result. Saving local finishes does not send a provider request.
The local mask cannot identify and exclude windows, taps or cupboards automatically.

- Polish now sends the **clean same-view design first**, rough finish guide second.
  Surface boundaries and objects in the clean design take priority over guide spill.
  Splashback instructions require separate wall-plane perspective and preserve
  window glass/frame/view, sink/tap, worktop, cupboards, outlets and appliances.
- Polish roles survive reopening a saved local version/current or legacy draft;
  Refine also offers **Polish saved finishes with AI**. A missing clean source
  blocks sending. No broad renovation brief, old room angles or palette is reapplied.
- **Polish with AI** stays pinned in Select/Finish, including expanded grout
  controls. Confirmation labels clean design and rough guide. Only confirmation
  sends one paid request; its separate result is labelled **AI finish polish**.
- Independent grout colour offers White, Black, Grey, Warm, Light and Dark plus
  custom hex. Choosing grout leaves tile colour unchanged; both values persist.
- Portable projects now accept/remap supporting same-room design images, retaining
  the guide parent and clean source through Save/Open/restore. Missing, unrelated,
  duplicate and self-referencing supporting IDs remain invalid.

Source **`7821f8aa18`**: **396 tests pass**, plus 46 related checks after excluding
finish polish from the broad-renovation warning; clean analysis, release web build,
and updated paint help capture/MP4 validation pass. Same localhost:7357; APK stays
1.0.17+18. All AI tests use mocks. Real-provider boundary/appearance acceptance is
still required; the local outline is not a semantic mask or enforced AI boundary.
Actual isolated desktop and phone-sized finish/grout checks pass; screenshots
inspected. Owner reports the next real polish worked well. Further surface cases
remain acceptance work. Refresh restoration and action placement are the next batch.

The earlier verification sections below describe their stated builds.

## Saving, selected-image updates and splashback corrections — 23 November

This section supersedes the earlier duplicate-backup and selected-image defaults.

Full regression: **394 tests pass** (86s), clean analysis, seven refreshed offline
help recordings and full MP4 decode verification. Final progress-slot stability
follow-up: **28 related paint/refinement tests pass**. Actual Chrome single-field
refinement, project-look reuse, complete Save as and encrypted-export explanation
pass in disposable profiles. Actual OneDrive-folder tests pass; existing user files
are unchanged. Final Chrome source **`2643765277`**, same localhost:7357; clean
final analysis 27.2s, web build 63.3s. Desktop and phone-sized checks pass, with
inspected screenshots. Published APK stays 1.0.17+18.

| Area | Current behaviour and verification |
| --- | --- |
| Normal saving | Save project maintains the working file; Save project as chooses another file/copy. Removed duplicate plaintext backup snapshot actions. Restore as a separate copy retains its independent-project meaning. |
| Encrypted export | Collapsed Advanced export encrypts only its exported copy; local records/photos and existing plain files remain readable. No claim of whole-project/device encryption. Restore of older protected/plain files remains supported. |
| Agent save acceptance | Two real filesystem tests pass in the actual OneDrive Renos folder, in new uniquely named fixture folders, plus workspace disk tests: complete bytes/photos/choices, autosave, Save as independence, failed-write recovery, reopen/restore, encryption/wrong-password rejection and preserved readable source. No existing file changes. Not evidence of cloud sync/native system chooser behaviour. |
| Credentials | Owner confirms API-key retention works. Browser/device vault implementation unchanged in this pass. |
| Selected result | Defaults to Precision, shows only the next-update field and excludes the broad brief/style/analysis. Completed correction text clears on its new result; historical recipe is retained. Full/Partial remain explicit choices. |
| Modes | Visible scope explanations. Full permits coordinated usual updates; Partial uses selected items/written scope; Precision is one focused update. Partial shows a compact selected-items summary. Selecting all items can make its scope similar to Full. |
| Project memory | Optional reuse of another room's style/palette, preferring approved saved recipe choices. Tested with zero AI calls and no transfer of room facts/instructions/Keep/geometry. Same-room matching observations already remain reusable; new rooms still need their own photos/analysis. No model training. |
| Tile area | Four-corner full-splashback outline replaces a fragmented selection and fits perspective; directional/all-side mask growth and Undo; opacity label states strength rather than area. Stable expansion keys and scroll controllers keep controls open during changes. Separate surface layers for different wall planes; local preview is still approximate. |

## Follow-up implementation — 23 November 2026

Project list follow-up: the ellipsis is replaced with a visible delete icon.
It opens the existing typed-name confirmation, backup and recoverable delete/archive
choices. Five project-management tests and static analysis passed for this change.
Previous small-follow-up Chrome source: `c9a6649c1e`; web rebuilt (63.6s).
The published APK remains unchanged at 1.0.17+18.
Isolated Chrome bin/confirmation/cancel check passed; list screenshot inspected.

This is the current source position. The 22 November audit below is historical
where superseded here. No new APK, real paid AI request, deployment or user-data
reset was performed for this follow-up.

Prior full-batch source **`ac96247b07`**, localhost:7357. Full suite: **388 passed**; final
archive visibility follow-up: **24 related tests passed**. Final analysis clean
(17.7s); release web: 48.2s.
Actual desktop/phone-sized tab navigation and inspected screenshots pass. Actual
selected-update field, Autosave after reload and typed archive/restore pass in
disposable Chrome profiles. Synthetic vault reload/separate removal passes; seven
help captures and full MP4 decodes pass. No real provider or physical-phone test.

| Request | Implemented behaviour | Remaining acceptance / limitation |
| --- | --- | --- |
| Remember keys (T09) | Separate encrypted IndexedDB/WebCrypto vault survives reload, scoped by browser profile/address. No login. Per-provider removal; no project export includes secrets. | Real reload/removal passed with synthetic fixtures; owner enters an existing key once after updating. Site-data clearing removes it; same-origin app code can use it. Android vault remains unchanged. |
| Visible Autosave (T03/T11) | Compact switch under the title in project, room setup and workspace. Saved setting, save errors retained. | Confirm placement on the physical phone after a requested APK. Local autosave is distinct from a reusable external file link. |
| Save/Open/import and project management (T10/T11) | Full portable project; optional snapshot; duplicate; typed archive/delete with backup suggestion; restore archived/deleted work; unique new names and numbered legacy labels. Import room copies adds all images/history with fresh IDs. | Original OneDrive incident cause remains unproven; system-picker destination save/reopen still required. Additive import does not reconcile same-room edits. Android durable linked URI overwriting remains open. |
| Narrow refinement | Selected result opens Refine with Update this design and Apply focused update; original broad brief/Keep fields remain separate. Typing an update also switches the footer to focused correction. | Mocked confirmation/cancellation, parent/version and brief preservation pass. Real-image adherence is not guaranteed. |
| Paint-only AI polish (T12) | Pinned Polish with AI sends the clean design first and rough guide second; saved local versions can resume in Refine. Excludes broad brief, old corrections, palette/analysis/research and unrelated angles. | Local preview is not a completed AI result. Automatic colour selection can miss edges; actual owner-image boundary acceptance remains. |
| Tile material/perspective (T12) | Bounded, metadata-stripped material import, editable colour/scale/grout and reviewed four-corner perspective; portable saved layers. | Approximate projection and lighting; no semantic segmentation, measured scale or verified product catalogue. |
| Three different concepts (T07) | Kitchen schemes explicitly vary cabinetry/front detail, hood, focal materials and main light within palette/Keep constraints. Other rooms retain distinct design directions. | Real two/three-result appeal and distinctness need an owner-confirmed paid test. No automatic similarity critique or paid retry. |
| Notice obstruction | Main workspace notices push content, replace old messages and expire after six seconds. Other snackbars explicitly expire, with close controls. Completed AI progress expires after ten seconds; failed-save recovery remains available. | Check real phone touch and enlarged text; active progress/save recovery must stay usable. |
| Region (T16) | Saved AU/NZ/UK/US English terminology setting, prompt guidance and mapped room-item labels. | Regional wording, not translation of the entire interface. |
| Image cost (T17) | Provider-returned image token usage stored with results; dated known-rate USD estimates, room totals, unpriced count and optional manually entered image budget. | Excludes analysis, research, failed requests, tax/FX and unknown pricing; not invoice, wallet or provider balance. Gemini usage is retained but unpriced. |
| Current references (T18) | Optional direct-OpenAI sourced text research, separate confirmation, fixed HTTPS host, one search call, reviewed opt-in inclusion only in new concepts. Portable dated notes/links. | No automatic browsing during image generation. No deployed product catalogue; other providers use their image models without this research tool. |
| Help (T14) | Updated step text and recordings of current app widgets using disposable sample storage and simulated AI/camera. Owner-authorised kitchen replay remains separate and offline. | Real Android launch footage and physical playback acceptance follow the release interface. |
| External release (T15/T19) | Existing tester-service/client preparation and release guide retained. | Owner confirms no hosting/support address. Funding, support/report delivery, privacy hosting, production signing/accounts, store testing and iOS parity remain open. |

## Request audit — 22 November 2026

This is the previous audit of 11 committed batches and the requests in the
conversation. Older dated notes below record history; an old unchecked packaging
item is not evidence that a feature is absent from the current app.

**Chrome:** source `68527c827a`, local commit `70ebf05`, localhost:7357.
**Latest APK:** 1.0.17+18, source `d19f2fd3d2`. Its bundled sample, trial-access
preparation and earlier 22 November changes are included. The last two commits
(`e0ca6bc`, `70ebf05`) are Chrome/source only, pending an explicitly requested APK.

Audit verification: the existing **374 passing tests**, clean analysis and web
build still match this unchanged app source. Fresh actual Chrome checks at
1280×900 and 390×844 pass Room/Style/Refine/Ideas navigation. Screenshots were
inspected for compact palettes, mode controls, collapsed tools and empty Ideas.
Evidence: `output/today-audit-browser.log`, `today-audit-phone-browser.log` and
matching screenshots. A first phone-driver attempt clicked before resize settled;
waiting for layout resolved it. The older workspace automation stall did not
reproduce. No real provider call or physical-phone verification occurred.

| ID | Today's request / issue | Code position and evidence | Acceptance still needed |
| --- | --- | --- | --- |
| T01 | Compact palettes; ten styles at a time | Implemented. Ten common styles, further pages, retained cross-page choices, smaller palette cards. Workspace/palette tests; current desktop/phone-sized Chrome screenshots inspected. | Physical-phone comfort with long labels and enlarged text. |
| T02 | Whole-room default; selectable individual items; New/Partial/Precise | Implemented. Whole-room switch can be turned off; Keep exceptions stay editable. Normal entry starts New design; explicit Refine starts precise. Separate briefs/choices retained. | Try kitchen and bathroom choices manually; actual returned-image scope. |
| T03 | Generate on all tabs; less text; manual AI tools in a sensible place | Implemented. Pinned Generate/Brief %, Autosave in More tools, collapsed details, manual copy/import in Refine, empty Ideas offers inspiration. Current desktop/phone-sized tab navigation/screenshots pass. | Physical-phone touch/scroll and a live request from the chosen tab. |
| T04 | Brief percentage and ability to proceed below 75% | Implemented advisory checklist, Proceed checkbox, remembered >=75% review; required inputs/paid confirmation remain. Automated tests and earlier Chrome interaction pass. | User check that low-brief flow feels clear. |
| T05 | Projects first; Settings via cog | Implemented and checked by navigation tests and earlier actual Chrome checks. | Physical-phone acceptance. |
| T06 | Multiple photos analysed; facts plus AI-written design plan | Implemented shared setup/workspace/Live composition. Exact selected views are listed for consent. Matching facts are reused; stale plans are excluded without forced paid reanalysis. Tests verify composed requests. | Real multi-view analysis and generated-room consistency. |
| T07 | Better concepts with little prompting; contemporary fittings, extractor and main light | Richer coordinated positive plans and fitting/main-light instructions implemented. Showcase concept explicitly chooses High; existing quality is not silently changed. Multiple concepts receive distinct directions. | Controlled paid comparison; visual appeal/distinctness and lighting replacement are not proven by mocked tests. |
| T08 | Analysis/plan checkbox wording; other views; manual AI label; useful Ideas | Implemented explanations and labels; Ideas applies confirmed inspiration style/palette to the existing room. Widget tests and inspected desktop screens pass. | Review a real returned plan and copy/import flow. |
| T09 | Browser API key seems lost | Tab/settings navigation retains it in tests. Reload/close deliberately clears the browser session key; explanatory status added. Android has separate persistent vault storage. | Real browser tab/reload and S21 restart acceptance; no browser key persistence added. |
| T10 | Save reported success but file empty | Actual empty owner file confirmed. Added post-write size check and download fallback. Real Chrome bridge 16 MB read-back/empty rejection and actual app Open/Save/reload pass. | Real Windows chooser + OneDrive save/reopen. Root cause of the original incident remains unproven. |
| T11 | Autosave / Save / backup / restore confusion | Clearer help and snapshot/duplicate names. Save includes rooms/photos/designs/choices; backup is fixed; restore adds a separate project. Tests cover contents/conflicts/autosave. | Check real chosen file updates; merge is not implemented. |
| T12 | Wall paint misses edges; splashback looks cartoonish | Added explicit undoable edge extension, smaller splashback pattern, thinner grout and selection-overlay hiding on finish change. Tests verify masks, undo, saved recipes and unaffected pixels. | Visual check of the owner's actual surfaces. Real tile textures/perspective are unfinished. |
| T13 | Outdoor spaces and fencing | Present: garden, exterior, balcony, patio/alfresco, deck, verandah, pool and room-specific fence/gate/balustrade choices. Prompts retain boundaries/positions. | Real outdoor concept and safety-sensitive boundary review; no survey/engineering verification. |
| T14 | Offline sample, before/after, saved prompt, testing without paid AI | Implemented in 1.0.17 Help: authorised kitchen stages/replay, historical prompt, compare and separate practice copy. Sample tests and prior Chrome/emulator checks pass. | Test playback on S21; later-stage prompt is explicitly illustrative. Older help clips still need rerecording for the accepted UI. |
| T15 | Small live AI allowance for testers | Client and capped HTTPS gateway prepared; separate encrypted invitations, counts/expiry/durable reservations tested. | Hosting, funding, measured quota and owner-approved spend control. Not deployed; counts are not a $1 balance. |
| T16 | Language/region choices | Regional English meanings are included in prompts. | Actual AU/NZ/UK/US selector and translated interface are not implemented. |
| T17 | Cost per image/room and money remaining | Not implemented; recorded as proposed work. | Usage collection, dated pricing and an explicit budget model. No provider-balance integration. |
| T18 | Search current designs/products; reproduce the HTML ChatGPT workflow | Current app uses model knowledge and attached photos/analysis, not web search. Actual exported image inspected; full web-session transcript not found locally. | Optional sourced research and controlled comparison. No claim that the historical session searched online. |
| T19 | Branding and Android then Apple release | Visible branding/sample and existing icon preserved; Google Play guide added. One shared Flutter codebase; Chrome current. | Production release gates, physical S21 acceptance, then iOS file/share/Keychain parity and real iPhone tests. |

No new APK, paid provider call, hosting deployment, project reset or credential
export was made during this audit. The next acceptance steps are in the testing
guide under **Today's acceptance pass**.

## Current position — 22 November

| Area | Current position |
| --- | --- |
| Core app | Projects/rooms, multiple photos, analysis, in-app generation, manual import, styles/palettes, history, approval, compare, crop/sketch, local finishes, camera/Live and image export/share are implemented. |
| Current batch | New/Partial/Precise, smaller palettes, editable whole-room Keep exceptions, clearer analysis/plan/manual handoff, first-design inspiration and stronger fitting prompts. Verification recorded below. |
| Saving | Local storage and project files exist. Latest owner OneDrive export was empty. Added size verification and download fallback; real destination acceptance remains open. |
| Save meanings | Autosave: local edits plus connected working file; Save project: working file; backup: fixed snapshot; duplicate: separate in-app project; restore: separate copy. No merge. Keys are excluded. |
| Paint/tiles | Persistent selections/layers, recolour, delete/undo and optional AI polish. New edge extension and smaller tile/grout defaults. Perspective remains approximate. |
| AI quality | Photo facts and the optional current plan feed generation. Richer prompting is implemented; paid comparison is still required. No online search or current product catalogue. |
| Platforms | One shared Flutter app. Chrome is the development preview; published APK stays 1.0.17. S21 acceptance, iPhone parity and native desktop packaging remain separate. |
| Launch | No public release. Tester hosting/funding, privacy/report delivery and store testing/account gates remain open. |

Current source `68527c827a`: **374 tests pass**, clean analysis (13.5s), release web
build (46.9s). Production browser bridge: real 16 MB write/every-byte read-back and
false-success empty-file rejection pass. Actual app Open/Save writes a complete
372 KB kitchen fixture and retains it after app reload in an isolated profile.
Deeper workspace browser automation stalled; native tests cover its controls.
Real OneDrive-provider acceptance
and a controlled paid design comparison are still outstanding.

**Prompt enhancement after 1.0.17, 22 November:** analysis prepares a specific
design proposal with material assignments, main/task lighting, fittings, staging
and retained features. Newly returned current proposals are enabled for normal
designs, editable and opt-out. The shared builder includes one only when source,
supporting views and current choices match; otherwise it uses current choices
and matching photo facts without blocking generation or paying to analyse again.
Precise correction excludes both broad proposals and observation context. Live
uses the same builder. Multiple ideas can reinterpret AI suggestions, with explicit
user materials, palette/style, Keep and scope still authoritative. Existing saved
prompts/recipes stay intact. This is source/Chrome work; the published 1.0.17 APK
remains unchanged. Image-quality gains need a controlled real-provider comparison.

Source `71336f78f2`: **368 tests pass**, clean analysis (15.5s), release web build
(101.5s). Detailed three-concept briefs retain all written instructions and the
complete proposal, shorten repeated generic guidance and excerpt optional photo
facts only as needed; full saved analysis is unchanged. Very long written briefs
still stop at the existing preflight limit. No paid provider call or new APK.

**Requested 1.0.17 source batch:** Help now contains an offline kitchen sample
replay with authorised actual images, a historical saved brief and a separate
practice-project copy. The later idea board is explicitly another viewpoint and
its follow-up brief is illustrative; no fake analysis/provider jobs are recorded.
Tester access is prepared as an invitation-only HTTPS client and single-process
quota gateway, with Android vault storage and backup exclusion. It requires an
owner-deployed/funded service; request allowances are not a $1 currency cap.
BYO provider keys, originals, package ID and signing identity remain unchanged.
Visible iOS/desktop/helper display labels are cleaned; those native platforms
still need their own build/runtime acceptance. Public launch gates remain open.

**Verified package 1.0.17+18**, source `d19f2fd3d2`: **363 tests pass**, clean
analysis and release web/Android builds. Actual Chrome and API 37 Android emulator
sample/practice/restart checks pass without paid AI. Tester uploads strip metadata
and resize working copies; personal provider preferences survive trial restore.
The emulator uses 4KB pages; physical S21 and 16KB-runtime acceptance remain open.
All completed shared changes in the earlier source-only notes are now packaged;
those dated notes record their original checks, not the latest APK position.

**Release order confirmed, 22 November:** Android/S21 release acceptance first;
iPhone functional parity and a friends' TestFlight beta are the next platform
milestone. Google Play remains the primary public target. The shared Flutter code
and Chrome preview continue together; native desktop packaging follows later.
This is an agreed priority, not completed iOS support: file export/restore,
save/share, persistent keys, remaining branding and iPhone testing are unfinished.
The 363 automated passes do not establish physical-phone or image-quality acceptance.

**Photo-first design and local finish follow-up, 22 November:** analysis requests
a fuller inventory of visible surfaces, fittings, lighting, clutter and spatial
relationships, then a concrete scheme within Full/Partial/Precise scope. Matching
photo observations now automatically inform New design; the optional AI-written
brief remains opt-in and context-checked. Preference changes reuse photo facts;
different working images/view sets and precision polishing do not inherit them.
No automatic paid analysis or measured geometry is implied.

**Colours & tiles without AI** extends saved local layers to walls, floors and
splashbacks, with square/rectangular/brick patterns, colour, grout, scale and angle.
The same selection is reused; versions and drafts retain settings through plain
and protected project copies. Tile previews are approximate 2D patterns, not a
product catalogue, semantic plane detection or perspective-correct installation.
Finish with AI prepares one reviewable correction from the saved composite;
confirmed paid generation remains separate. Published APK 1.0.16 is unchanged.

Source `b95048b5fc`: **350 tests pass**, clean analysis (11.4s), and release web
compilation (55.5s). Automated coverage includes automatic facts reuse, mismatched
photo/precision exclusion, legacy/tile recipe bounds, unselected pixels/alpha,
protected/plain copy restoration and zero-request final-polish preparation.
Actual 390×844 Chrome save/reopen restores the floor/pattern selection. Public
sample and isolated profile only; phone latency and real provider results remain.

Wall tile follow-up: room-aware shortcuts now expose Wall tiles, kitchen/pantry/
laundry Splashback tiles, bathroom wall tiles and bathroom/ensuite Shower wall
tiles. Powder rooms/toilets omit the shower shortcut. The chosen mask and colour
are reused; existing names are preserved except generated surface names. No new
geometry detection, storage format or AI request is introduced.
Source `74d73a34cf` passes **354 tests** and clean analysis (10.0s), including
kitchen/bathroom/ensuite/powder-room shortcut save/reopen, retained regions/colours,
zero-request polish handoff and enlarged-text phone/landscape layouts.
The release web build passes (48.1s), at the same localhost:7357 origin. Published
APK 1.0.16, its data, app icon and settings are unchanged.

**Checklist Proceed follow-up — source `56814171d1`:** a pinned checkbox changes
Refine brief to Proceed at any coverage percentage. It opens the normal generation
path (connection and required inputs still apply), suppressing duplicate guidance
for that attempt while retaining paid confirmation. Close/cancel sends nothing;
the checkbox resets on reopen. Published APK 1.0.16 remains unchanged.

**Brief readiness, 22 November — source `65936b5efb`:** live local coverage appears
beside Generate across all workspace tabs. The existing confirmation adds missing
inputs and Refine brief; users can proceed with a valid basic concept. A confirmed
75%+ review is remembered per room and new-design/precise mode on this device;
below 75% it reminds again. Cancel/Refine sends no request or review acknowledgement.
Paid confirmation and required photo/correction/scope guards stay intact. Precise
corrections do not require style/palette extras. Setup and Live share the guidance
and return to their relevant controls. This is coverage, not output confidence;
paid analysis, provider choice and extra photos earn no points. Source/desktop
only; published APK 1.0.16 remains unchanged.
All **342 tests pass**, analysis is clean (11.1s), and Chrome release compilation
passes (61.9s). Mock requests verify the guidance/consent/save paths without paid AI.

**Lighting and terminology, 22 November — source `50196e8c85`:** selected lighting
updates and full-room briefs explicitly replace visible unprotected main fittings;
supplementary strip/under-vanity lighting alone is insufficient. Keep/protected
fittings and requests limited to accent lighting take priority; unseen fittings
are not invented. Analysis separates main fittings/locations from accent lighting.
Shared analysis/generation guidance explains regional English synonyms without
equating the basin bowl with the whole vanity unit or rewriting user instructions.
This is prompt clarification, not verified output compliance. UI remains English-only,
without a locale selector or translated string bundles. Published APK 1.0.16 is unchanged.
All **335 tests pass**, analysis is clean (12.7s), and Chrome release build passes
(56.0s). These verify prompt scope, not generated-image adherence.

**Main navigation follow-up, 22 November — source `75ffe41898`:** bottom tabs are
Projects / Explore / Library, with Projects selected first. Settings uses the
top-right cog and its own page; returning preserves the previously selected main
tab. Contextual help and Explore's project shortcut follow the new order.
Published APK 1.0.16 remains unchanged; these changes are in source/desktop.

**Workspace follow-up, 22 November — source `c2d523f4c0` after APK 1.0.16:**
Generate stays pinned in all four tabs using one mounted, confirmed generation
session. Autosave is in More tools; pending/failed save states remain visible.
Compact palettes and ten-at-a-time style pages reduce scrolling without dropping
selections. Full room / Partial scope is saved in rooms, backups and generation
recipes. Full room supplies ordinary surface/fitting updates; saved Keep choices
and protections win, and its included-item controls are disabled. Partial requests
only selected/written changes; precise correction is independent. Fixed layout is
still the default. Analysis/prompt details start closed. Manual copy/import is
under Refine; completed batches open Ideas for review. **332 tests pass**. The
published APK remains 1.0.16, with its original checksum; this follow-up needs a
future requested package for phone acceptance. No paid generation or data reset.
Clean analysis (9.9s), Chrome release build (57.6s) and actual 390×844 browser
tab/pinned-action/pagination/Partial checks pass using only a public sample and
isolated profile. Desktop preview is current at http://localhost:7357.

**Requested APK, 21 November — 1.0.16+17:** all completed source features below
are now packaged, including recorded help, room deletion/recovery, tap-wall paint
and AI finishing handoff. **327 tests pass**, analysis is clean and Android release
compilation passes (20.4s after corrected assets). Native testing found browser
video timestamp incompatibility; all seven clips now use standard silent H.264
baseline MP4s with verified duration/decode. Signature, A icon, public-only assets,
restricted sharing and 64-bit ELF/ZIP 16KB alignment pass. Physical S21 and actual
16KB-runtime acceptance remain; no paid provider calls or real project edits.
The final APK installs/launches on the read-only API 37 emulator (4KB pages),
retaining existing project metadata. Its help clip plays advancing frames with
correct 27s duration; pause, actual seek to 25s, fullscreen and written fallback
pass. Desktop rebuild (66.3s) and actual playback/seek checks also pass at the
same localhost:7357 address with an isolated test profile.

**Public launch assessment, 21 November:** a working controlled-beta product,
not yet a production-ready Google Play release. The user has no Play Console
account yet. Code inspection confirms example package ID/debug signing, no public
privacy-policy entry, no connected in-app offensive-output reporting, no billing/
entitlement integration and incomplete permanent-delete/OS-backup decisions. Latest
phone acceptance, native 16KB runtime verification, real-provider comparisons and release
listing assets remain. Target SDK 36, Android Keystore keys, consent, metadata-stripped
AI image copies and portable backups are already present. All 327 existing tests
pass; this audit made no runtime changes or additional test/paid-API claim.
Use [the launch gates](CODEX_NEXT_STEPS.md#public-launch-review--21-november-2026)
instead of treating the whole future feature backlog as necessary for v1.
The owner now prefers account registration/payment after release-candidate polish.
Apple is not release-ready: its project/plugins exist, but Save/Open, image export/
share, native feedback and persistent Keychain support are missing or Android-only.
No Mac/iPhone build has been verified. Personal feedback email should remain on a
receiver service; a separate public support contact is required for Play.

**Desktop refresh, 21 November:** current shared source `aba3ee136c` is rebuilt
and served at **http://localhost:7357** in release mode (51.2s). All **327 tests
pass**, including a new real HTTP check for full/HEAD/range responses and exclusion
of files outside the public web bundle; analysis is clean. Eight focused responsive
workspace checks also pass. At 1440px, an isolated Chrome profile confirms the
served source, Settings/help navigation, play/pause, accurate duration, near-end
seek, full-screen round trip and written fallback. The earlier Flutter development
server could play fragmented MP4s but could not reliably seek; the release launcher
now builds then serves the public bundle with byte ranges and no-store caching.
Flutter engine assets are served locally. The same hostname/port/profile and app
store names are preserved; no customer browser/project data or paid AI was used.
Native Windows packaging remains a later stage; the subsequent requested 1.0.16
APK includes these shared features.

**Source follow-up, 21 November, after APK 1.0.15:** recorded walkthroughs now
replace the default text-first presentation (seven bundled MP4s, eight guides;
real app widgets with fictional data and clearly simulated AI/camera/file pickers).
Playback includes seek/full screen/background pause, retry and Read steps.
Room deletion requires the displayed room name; Undo and Deleted rooms restore
all retained work. Backups include deleted rooms. Live type changes save even
with autosave off, and legacy type labels produce Kitchen (Live), etc.
Local paint defaults to tap-selection then colour, with persistent selected/all
layer deletion. Its colour/edge heuristic is not semantic wall segmentation;
review boundaries, especially on similar adjacent surfaces. Outside-mask output
pixels remain unchanged. Feedback still needs the owner's email/form URL.
**326 tests pass**, static analysis is clean, the Chrome release build passes
(78.9 seconds) and Android Kotlin/plugin compilation passes (2m 52s). Source
`aba3ee136c`. Seven MP4s pass Chrome metadata/decode/seek/timing probes; all public
walkthrough assets total 2,496,530 bytes. Local paint also offers **Finish with AI**:
save the rough preview, then review a colour-specific correction before generating.
Actual Chrome release playback passes Help navigation, play/pause, near-end seeking,
full-screen round trip and written fallback/disposal in a separate test profile.
Physical S21 playback/boundaries and real AI finishing quality remain unverified.
This source batch was subsequently packaged in requested APK 1.0.16; icon A stays.

**Confirmed icon update, 21 November — 1.0.15+16:** the user chose A for now.
The olive/cream room-and-sparkle mark is applied to Android adaptive/legacy/themed
launcher resources, web icons, the startup screen and app header. All 40 generated
assets match the reviewed A candidate. iOS/macOS/Windows icon files are updated;
those native builds remain unverified. **315 tests pass**, icon export passes, analysis is clean, and Chrome/Android release builds pass (138.1/155.1 seconds). Existing projects, app ID,
signing identity and connection settings are preserved. Source `ce6b2da600`.

**21 November — requested APK 1.0.14+15:** local wall paint now has manual
polygon/brush/erase selection, per-wall colours, shading approximation, Undo/Redo,
comparison, autosaved drafts and editable version recipes in plain/protected
project copies. Lossless output preserves unselected pixels; originals/baselines
are unchanged. No provider calls or key are needed. Japanese, Italian, Moroccan
and Indian bring the style catalogue to 23, with a regional-influences picker.
Feedback in Help/Settings is also included; delivery needs the owner's email/URL.
**315 tests pass**, analysis is clean, and Chrome/Android release builds pass (111.2/234.8 seconds). Icons remain unchanged; physical S21 acceptance remains.

**Verified source update, 20 November:** Open/resume conflict handling, per-version
settings snapshots/reuse and startup loading/Retry pass regression tests.
**All 296 tests pass**, static analysis is clean and the final release web build
passes (102.4 seconds). Android 1.0.13+14 built in 145.5 seconds from source
`f69772aaa0`; package identity, signing, permissions and bundled files are verified.
Existing platform icons remain unchanged.

Six earlier alternatives remain under `output/design-review/icon-refinements/`;
A is now confirmed and applied for the current test build.
Preview generation uses local vector artwork, without a model key or paid AI call.
The remaining limits below distinguish completed source from device acceptance.

Audited 19 November 2026 (Australia/Sydney) against the project brief, the
conversation and actual source through `a948da0`. This replaces superseded
implementation diaries. The product brief is unchanged.

**Assessment: a working private Android-first beta, with important gaps in
precision enforcement, persistent file linkage and larger-project performance.** Keep the
existing app and Focus Canvas interface; a rewrite is not justified.

## 20 November follow-up — included in requested 1.0.13

AI settings is now the first clearly labelled expandable card with connection
status. App appearance is a matching collapsed card below Home cover/Storage.
Saved designs have a recoverable Delete action beside crop/markup/compare;
originals remain protected and an approved baseline must be replaced before deletion.

Refine shows New design / Precise correction directly. Both allow 1/2/3 outputs:
whole-room concepts versus variations of the specified correction. The new
optional `precisionConceptCount` preference defaults to one for older projects,
separately from the whole-room count, and survives autosave/backups. Selecting
three whole-room ideas therefore does not silently turn an older correction
into three paid requests. Live camera still confirms one preview at a time.

New design briefs with few/no comments now explicitly ask for substantial
coordinated changes within the permitted scope. Analysis prompt-writing no
longer defaults to a conservative near-copy for those requests. Precise corrections
keep narrow instructions. These are improved requests, not measured quality guarantees.

New direct OpenAI connections prefer available GPT Image 2.6 Sunburst at medium
quality. Saved model/quality choices are preserved. Room design / Quick ideas /
Final detail presets change local settings only and use available account models;
generation remains separately confirmed. Gemini is also implemented as a direct
provider with a separate Google key: Nano Banana 2.1 defaults to 2K; Final detail
prefers available Nano Banana Pro/4K. Curated recommendations can be viewed
without a key. Provider switches preserve separate keys and model preferences;
Android restores the selected provider without startup requests. Gemini analysis
uses an available supported vision model and records Gemini provenance. Claude
vision is for analysis, not image output, and has no adapter in this app.
Verified account model lists now survive restart. Older saved connections retain
their known selected model; Refresh available models checks access without sending
photos or re-entering the saved key, and never silently changes a valid selection.

All **296 tests passed** and static analysis is clean. The final release web build
passed in 102.4 seconds. Walkthrough UI is shared Flutter code; physical
phone acceptance remains pending the requested package.
Seventeen new tests cover Gemini transport, key isolation/switching, session-key
expiry, offline restore, safe errors and provider-specific consent. All responses
were synthetic; no paid provider call was made. The preceding Chrome test iframe
stalled before tests; browser
interaction acceptance remains. No paid app API call was made. The requested
1.0.13 includes these changes; installed 1.0.12 does not. The user confirmed RenoVision;
Android/web/Flutter display labels are updated in source while the package ID and
storage stay unchanged. A second board of six different icons was generated with
built-in imagegen. The user's latest mark prefers first-board A (RenoVision olive
room outline and sparkle) so far; dedicated launcher artwork remains pending.

Help dialogs now link to Sample walkthroughs: Camera & photos groups Photos,
Camera and Live view; Design & refine, Image tools & compare and Save & reopen
complete the six guides. Fictional kitchen examples run without a key or camera
and make no AI/project changes. Four new tests cover navigation, returning to an
existing project without writes, small phones, landscape and 180% text size.
Compare AI models is the seventh guide, also linked from AI settings. It explains
fair manual comparisons and makes clear the four core image models are an unranked
shortlist. No paid benchmark, saved rating system or automatic ranking is present.
AI settings also offers Use fixed brief for model tests: one-output requests skip
the usual rotating concept directions. The switch is opt-in and resets off after
restart; multi-output attempts are blocked before payment. Photos must still be
reselected consistently by the tester. Normal saved room choices stay unchanged.
The comparison follow-up adds four tests for guide/settings preservation, exact
prompts across attempts, repeat requests from the original and the pre-send
multi-output guard. Live Gemini quality/access and phone acceptance remain pending.

Live naming correction: generic saved Live names and new automatic room-picker
names display the actual selected type, e.g. **Bedroom (Live)** / **Kitchen (Live)**,
not the literal word Room. They follow a later type change. An optional
`automaticLiveName` flag preserves this behaviour through saves/restores without
rewriting stored names; explicit renaming clears it. Unknown types show
Unspecified (Live) until confirmed. Existing custom names/photos are preserved.

## Source versus installed app

| Item | Verified position |
| --- | --- |
| Latest existing APK | **1.0.17+18**, source stamp `d19f2fd3d2`; `output/mobile-test/renovision-test-1.0.17.apk`, also `renovision-test.apk` |
| APK contents | Focus Canvas, embedded camera, manual same-view overlay, Live design and all completed shared features through 1.0.17 |
| New in 1.0.13 | AI settings discovery, visible delete, 1/2/3 correction choices, creative prompts, typed Live names, OpenAI/Gemini presets, seven help guides, fixed-brief tests, Open/resume/conflict handling, saved recipes/reuse/refine, startup Retry, Save image / Share creation |
| New in 1.0.14 | Local paint and editable layers, regional style choices, saved feedback drafts/copy and optional contact handoff |
| New in 1.0.15 | Confirmed A icon, consistent launcher/startup/header/web branding; same app identity and storage |
| New in 1.0.16 | Recorded help with corrected native video timing, typed room deletion/recovery, legacy/immediate-save Live names, tap-wall recolouring, persistent wall deletion and save-then-review AI finishing |
| New in 1.0.17 | Pinned generation/readiness, compact options and navigation, fuller analysis/lighting direction, wall/floor/splashback tile previews and polish handoff, authorised kitchen replay/practice project, prepared tester invitations and display-label cleanup |
| Source after 1.0.17 | `71336f78f2`: automatic current design proposal, stronger material/lighting brief, bounded optional photo context and shared stale-proposal fallback across setup/workspace/Live; 368 tests and web build pass; no new APK or provider-quality benchmark |
| Last APK checks | **363 tests pass**, clean analysis, release web/Android builds and actual Chrome/API 37 emulator checks pass; matching 1.0.16 certificate, olive/cream icon, public assets, private-file exclusion and 64-bit ELF/ZIP 16KB alignment verified |
| Earlier audit | Reviewed code and 11 rendered screens; documentation and private-export ignore correction only. One temporary fixture-rendering test passed. The subsequent requested APK build made no paid AI call or data migration |
| Real user evidence | User reports successful phone installation, direct AI analysis/generation, good generated designs, project auto-reload and useful comparison/camera overlay. This does not validate every newer source change |

APK SHA256:
`9E4AE423009A1F6040203ACAD591A91B857381D6468D154FEDFD9D1DBC39E0E6`.
Size: 84,941,239 bytes. Signature matches 1.0.16; its checksum and rollback
packages remain unchanged. Camera hardware is optional, ARM64 is included, and
no microphone/storage-write permission or private project/credential files are
bundled. Its release-mode build uses the development signing key and example
application ID; it is a private-test package. S21 acceptance remains.

## Features present in the code

Implemented means code exists. Mocked tests and rendered layouts do not establish
provider quality, physical-camera behaviour or durable storage on every device.

| Area | What exists | Limits / unfinished work |
| --- | --- | --- |
| Projects and rooms | Local projects/rooms, rename, continue last room, saved setup progress, immutable originals; typed room deletion, Undo/persistent recovery, deleted-room backup support | Project deletion and permanent storage cleanup remain |
| Room catalogue | 42 home/utility/outdoor types, categories/search/custom names; compact photo-backed main types | Six sample images cover five main room types, not every room/style |
| Design direction | 23 styles, 12 palettes, custom text, blending/separate comparisons; Modern/Contemporary combined; expandable regional choices include Japanese/Italian/Moroccan/Indian | More illustrated samples and real-model quality comparisons remain |
| Guided start | Photos → Direction → Analyse/review → Final options; Finish later resumes | Room identification is not a structured AI result that automatically fills the room selector |
| Photo entry | Phone camera, gallery/multiple-photo import, embedded live preview, primary view and additional angles | Up to six original room views; reference images have no separate inspiration/material/sketch role |
| Room scope | Whole-room defaults coordinate surfaces, fittings/appliances, lighting and loose-clutter removal; optional room-specific Keep/Replace and precise correction | Fixed uncertain fittings need explicit instructions; AI compliance is not guaranteed |
| Local paint/material editing | Tap or outline wall/floor/splashback; reusable paint/tile layers, square/rectangular/brick patterns, grout/size/angle, swatches/custom hex/coverage; persistent delete one/all, undo/redo, compare, source-bound drafts and lossless PNG versions; plain/protected copies; optional one-polish AI handoff | Heuristic boundaries need review; approximate 2D tile patterns, no semantic planes, measured scale, imported textures/wallpaper, perspective mapping or cabinetry tool; preview up to 1000px, source up to 24MP; phone latency acceptance pending |
| AI analysis | Confirmed working photo plus context angles; fuller visible inventory/questions/editable brief; matching observations automatically inform New design across preference changes; optional AI-written brief stays reviewable | Different working image/view set needs fresh facts; optional AI-written brief still uses strict context freshness; no verified geometry, automatic quality critique or segmentation |
| Prompt preparation | Offline deterministic fallback, AI-written prompt option, preview/copy, current requirements/protected features, correct working/supporting-image roles | Copying text does not attach photos or automatically return external results |
| In-app AI | OpenAI/Gemini direct HTTPS with separate personal keys and saved model choices; curated image recommendations; optional OpenAI laptop relay; confirmation, progress stages/elapsed time, storage-only result retry | Gemini live account/image quality acceptance pending; no Claude/Bedrock adapter, in-flight paid-job cancellation, actual billed-cost meter or automatic output critique |
| Multiple concepts | One/two/three sequential requests from a frozen source; distinct specified material/design directions; partial successes saved | Strong difference is requested, not measured. Only exact-byte duplicate detection, no semantic diversity scoring |
| Refinement/history | Saved result selection/corrections, branches/parents, exact prompt and input IDs, immutable settings/analysis/model/quality snapshot; Saved settings / Use these settings / Refine this design; favourites/reject/approval | Older/manual/editor versions can lack a recipe; deleted source references must be restored before reuse; no automatic exact-request replay |
| Image viewing/export | Full-screen zoom/pan/pinch, landscape, before/after slider; Save image / Share creation; Android 10+ Gallery, older chooser, native share sheet; Chrome sharing/download fallback | Native/browser acceptance pending; no saved image rotation or comparison/overlay composites; sharing exports pixels only, not editable history |
| Crop/annotation | Resizable/movable crop, pen/line/arrow/rectangle/ellipse/note, colours/widths, select/move/remove and undo/redo; saved as a new reference | No enforced mask, full-frame compositing or persisted editable annotation geometry |
| Design deletion | Recoverable deletion, undo/restore, protected baseline handling | No permanent purge or comprehensive photo/storage manager |
| Camera renovation | Embedded preview/capture, saved-view comparison, manually aligned opacity/slider overlay | A flat image for a matching viewpoint; no camera-pose/depth tracking |
| Live design | Consent → one automatic reference capture/analysis → Room/style/Palette/Brief → confirmed generation → saved preview over camera → Continue to refine | Model latency remains; no continuous room scan, instant video transformation, moving-view redesign or composite/video export |
| Autosave | Debounced drafts, compact status, menu shortcut, manual save, save on normal exit, pending-request guards | Process termination can interrupt pending writes; no journaled crash/corruption recovery |
| Project files | Portable rooms/photos/designs/choices/history/recipes; Open preserves IDs, resumes unchanged matching work and offers Keep local / Open file as copy for conflicts; Restore copy is independent | Browser linkage is session-only; Android does not retain an overwrite destination; no divergent-revision merge |
| Appearance/help | Focus Canvas B, pinned preview and Room/Style/Refine/Ideas controls, desktop split view, contextual toolbars, compact text, tap/hover help with eight offline guides/seven recorded app workflows, stock/user-selectable home cover, five saved app themes | Native video/phone accessibility acceptance remains; demo AI/camera/file pickers are simulated; themes are separate from renovation palettes |
| Storage/privacy | Actual local storage/origin details, diagnostics; optional password-protected portable backup; Android encrypted API-key storage | Local photo/metadata database is not encrypted by the app; OS backup policy needs an explicit decision |
| Feedback | Included in 1.0.14: Help/Settings form, issue/feature categories, saved local draft, report preview/copy, optional build/platform and email/form handoff hooks | Contact destination pending; no submission backend, receipt confirmation, ticket history, voting or screenshot attachments |

## Corrections and incomplete requirements

### 1. Open/resume fixed; persistent file linkage remains

Open now validates the portable file and preserves its project/room/version/photo
IDs. Unchanged matching content resumes the existing project without duplication.
Divergent local/file revisions offer Keep local / Open file as copy / Cancel.
No existing revision is silently replaced or merged. Restore copy deliberately
remaps IDs for independent work, including saved-analysis references.
First imports publish the project last and roll back only newly staged records
on failure. Previously created duplicates are not automatically consolidated.

Chrome can reconnect a selected plain file on Open and update it during that
session. A divergent copy is not linked to the original file, and protected
backups never acquire a plaintext save link. Android still uses Create/Open
Document actions without persistent URI linkage. Same-destination Save across
restarts and comprehensive crash recovery remain unfinished.

### 2. Saved generation recipes implemented; legacy limits remain

New in-app AI generations capture detached palette/styles/scope/Keep-Replace,
protected features, brief/correction/mode/counts, saved analysis and provider/
model/quality/concept direction. Versions already retain the exact final prompt
and source/supporting IDs. Snapshot changes cannot mutate earlier history;
only allow-listed design fields enter the recipe, with no connection credentials.

History offers Saved settings, Use these settings and Refine this design. Reuse
keeps the original source; refine uses the selected result and precision mode.
It preserves the approved baseline and restores model/quality only where supported
by the connected provider. Legacy/manual/editor versions may lack recipes and are
labelled honestly. Missing/deleted source references need recovery first; stale
analysis can still need review. Exact paid request replay is not implemented.

### 3. Precision remains guidance rather than enforcement

Local paint is implemented in 1.0.14: reusable manual selections and colour trials
without regenerating the room. Its full-frame PNG compositor preserves pixels
outside the selected area in the oriented source frame. It does not remove objects
or infer missing geometry. Local tile patterns now share these saved masks;
wallpaper/imported textures and plane perspective remain later work. Existing
AI prompt palettes and text analysis are not image-edit masks.

The OpenAI edit request contains images and a prompt, with no mask.
Crop/markup creates a flattened reference image; there is no stored region model,
mask transport, AI-result compositor or detection of changes outside the selection.
A prompt saying "keep the window" is useful but not a pixel lock. This is the
largest gap against the brief's controlled-editing differentiation.

### 4. Analysis should separate photo facts from design preferences

The 22 November follow-up separates photo matching from brief-context matching.
New designs automatically use observations only when working and supporting
image IDs match; style/palette/brief changes do not require reanalysing those
photos. The optional AI-written prompt retains its strict context guard, so it
must be reviewed/reanalysed or switched off after preferences change. Precise
corrections do not automatically inherit whole-room facts, protecting the approved
image from old-finish descriptions. Live already reuses its matching reference.
Observation quality and first-result design quality still need real model tests.

### 5. Reliability and speed need measured larger-project tests

`main.dart` now paints startup before opening the same existing Hive boxes, with
a visible loading state and non-destructive Retry on failure. Photo bytes still
live in an eager box; a growing library can affect startup/memory. Native image preparation
and crypto use background work, but browser decode/resize/export work can still
block its UI thread. Workspace version thumbnails are eager and inactive control
tabs stay mounted. Add timing/memory measurements, journaled recovery
and bounded image loading before a storage migration. No general speed promise
has been verified on large real projects.

### 6. Camera ambitions need a separate milestone

The automatic capture/analyse/generate/overlay flow exists. It is not a spatial
scan or tracked AR. Moving the camera does not render the approved room from a
new angle. Future work includes tracking/alignment, occlusion, persistent room
geometry, bounded paid sessions, and saving an overlay composite. Keep the
working same-view path and label its limits honestly.

## Design assessment

The chosen Focus Canvas visual direction is coherent: warm panels, large images,
consistent toolbars, compact room tiles and a useful desktop split. Keep it.
The most useful next improvements are in information priority:

- Returning users: Continue and saved projects before the large discovery area.
- Room: one active-image/baseline header; avoid repeating strip/dropdown/status.
- Style: selected styles and palette in a compact summary; full choices in a picker.
- Refine: visibly distinguish creating alternatives from correcting a selected image.
- Ideas: saved versions and selection first; manual copy/import as secondary tools.
- Settings: project-specific files belong to the selected project; avoid a growing
  list of repeated export panels. Help must work by tapping on phones.

The first-view Refine controls already fit well. Do not reduce every font again
to solve hierarchy problems. Check contrast, touch sizes, keyboard, landscape,
screen readers and enlarged text on the actual phone. Full evidence and proposals:
[product/design audit](docs/PRODUCT_NOTES.md#whole-project-design-audit--19-november-2026).

## Storage and release boundaries

- Existing Hive boxes/IDs, originals, recovered projects, browser profiles and AI
  settings were preserved. No actual customer records were opened by the fixture audit.
- Plain `.renovision.json` files include private photos/metadata. Protected
  `.renovision` copies encrypt the export using AES-256-GCM and password derivation;
  they do not encrypt existing local databases. Both extensions are ignored by Git.
- Android protects the API key with Keystore and excludes its secret preference
  from OS backup. Other app data is not explicitly excluded by those backup rules;
  review OS-managed backup/transfer disclosure. No app-managed cloud sync exists.
- The personal-key test route works without a laptop. A future shared-credit
  commercial product needs its own backend, usage enforcement and billing design.
- Production application ID/name/icon/signing, privacy policy, account/credit
  handling, store submission and iOS verification are unfinished. These do not
  block the current private prototype; it is not ready for public release.

## Verification and next action

The audit checked source, tests/logs, platform files, the brief and conversation.
Eleven fixture screens were rendered at 390×844 phone / 1440×900 desktop using
real view metrics and fonts; outputs are private under `output/design-audit/`.
They are layout evidence, not an interactive Chrome/S21 acceptance run.
After the audit, all 296 tests and static analysis were rerun successfully for
the requested 1.0.13 update; final web compilation passed in 102.4 seconds.
These are automated source/build checks, not a physical-device acceptance run.

See [the ordered task list](CODEX_NEXT_STEPS.md) and
[testing/storage instructions](docs/TESTING_GUIDE.md). Validate the requested
1.0.15 update on the S21 before claiming device acceptance.
Build further phone packages only when requested.
