# Product and research reference

## Launch direction confirmed — 20 November 2026

Start with **Standard using the user's own AI API key**. The existing OpenAI and
Gemini connections support this without a RenoVision account or laptop relay.
An ordinary ChatGPT/Gemini subscription login is not a developer API credential;
the provider bills usage to the key owner separately. Grow Standard adoption
before investing in managed AI credits or other Pro services. No included AI
allowance, payment entitlement or pricing is implemented/promised by this decision.
Earlier credit-pack/price suggestions below are research hypotheses, not the
current launch plan. Local projects, image saving and sharing remain account-free.

Later, a subscription may include managed AI usage. Recommend a recoverable
RenoVision identity for cross-device entitlements, balances and account recovery;
that future service needs server-side payment/usage verification and spend limits.
Do not put a shared company provider key in the distributed app. This does not
require building accounts/billing now, or turning off the existing BYO-key path.

The user also wants an optional paid laptop/desktop companion later: capture,
analyse and explore on the phone, then refine on a larger screen. Chrome already
provides a desktop workspace, and one Flutter codebase can underpin a future
packaged Windows app. Portable project files carry rooms, original/generated
images, recipes and history between devices; API keys stay device-specific.
Windows packaging/install/export/key storage are not yet validated. Automatic
cross-device sync, accounts and a paid-download entitlement are separate future
work; exchanging a file is not live sync. No desktop installer is requested now.

### Affordable side-business experiment — 20 November

The user reports roughly one week and $30 spent developing the prototype and
wants an affordable app that can earn modest side income. Low development spend
supports trying a small launch; it does not establish ongoing maintenance,
support, distribution or AI costs. Keep the Standard BYO-key plan and test value
with real users before investing in hosted AI/enterprise services.

Suggested experiment, not selected or implemented pricing: free local viewing,
comparison/export and useful manual finish previews when those are built; test
an introductory **A$4.99 or A$9.99 one-off Standard phone-app unlock**, with the
user's AI provider charging separately. Compare with an annual licence only if
users demonstrate ongoing value. Keep existing project access/export available;
make included features, update terms and any later desktop charge explicit.
Do not promise lifetime AI or automatic access to future paid services.

At A$9.99, 100 purchases produce A$999 gross; 500 produce A$4,995 gross. These are
arithmetic examples, not demand forecasts, profit or take-home income. Allow for
store charges, taxes/refunds, support and maintenance. For Google Play, the
[current setup guide](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en)
lists US$25 once to register, and [service fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en)
depend on transaction, region and programme. Do not apply a blanket 15% assumption
to every Australian sale. No account registration, purchase or billing work is
authorised by this experiment alone.

Early validation: a small group completes a real room project, saves/reopens it
and exports a useful result without repeated help. Record willingness to pay,
BYO-key setup friction, provider spend and support time. Affordable local paint/
material tools could give no-key users a useful entry point; they are still on
the implementation backlog. Included-AI packs/subscriptions follow measured
cost and demand, with bounded usage. No final launch price is set.

## Verified outstanding-items and icon-refinement work — 20 November

Project Open/resume/conflicts, immutable version recipes with saved analysis and
reusable settings, plus startup loading/Retry now pass regression tests. All
296 tests pass, static analysis is clean and the final stamped web release build
passes (102.4 seconds). The renewed credits restored approval review; the
requested Android 1.0.13+14 update is built and verified from source `f69772aaa0`
(145.5 seconds). It includes Save image / Share creation alongside the recovery
and history changes; current icons and previous APKs remain unchanged.

Open preserves portable IDs and resumes matching unchanged content. Divergent
local/file content offers Keep local / Open file as copy instead of overwriting
either revision. Restore copy still remaps IDs, including historical analysis
references. New AI versions capture detached settings/analysis/model/quality and
expose Saved settings / Use these settings / Refine this design. Legacy versions
stay readable and show when structured settings were never recorded. Failed
imports and design writes clean up only new data; startup Retry does not clear
stores. Persistent Android file overwrites, analysis-fact caching, enforced masks
and measured large-library performance remain unfinished.

The clean vector rendering of A was shown, but the user requested refinement
and several design/colour alternatives. A remains acceptable and preferred so
far, not a final approval. Platform launcher assets and the app header were
returned to their previous versions; candidates are preview-only. A six-option
board is at `output/design-review/icon-refinements/renovision-icon-refinements.png`:
A olive/cream room, B lighter teal linework, C cream/olive framed room,
D navy/champagne geometric reveal, E terracotta/cream doorway and F graphite/sage
room planes. `tool/preview_brand_options.ps1` creates local SVG/raster previews;
no customer photo, model key or paid generation is involved. Name remains RenoVision.

## Settings, models and branding follow-up — 20 November 2026

The requested 1.0.13 update makes AI connection/models the first expandable card;
appearance now matches Home cover/Storage as a lower-priority collapsed card.
Delete is visible beside image tools for saved designs, with existing recovery
and baseline/original protection. Refine exposes New design / Precise correction.
Both support multiple outputs, but correction variations never inherit broad
renovation directions. Separate saved counts preserve old one-image correction
behaviour instead of silently multiplying requests.

The previous analysis-writing instruction proposed a conservative concept with
few comments; that contributed to cautious briefs. New design mode now calls for
a coordinated, visibly substantial redesign within allowed scope even with an
empty brief. Explicit narrow instructions/Keep features still take priority.
Models can still miss the request; no new real-room quality benchmark was run.

Official model guidance checked 20 November:

- [OpenAI image prompting](https://developers.openai.com/api/docs/guides/image-prompting)
  distinguishes 2.6 Sunburst for detailed/layout-sensitive editing from Flare for
  faster iteration. The new account-aware presets use Sunburst/medium for Room
  design, Flare/low for Quick ideas, and Sunburst/high for Final detail, falling
  back only within listed supported account models. These are starting choices,
  not a measured claim of the best result for Claylands. Saved choices stay saved.
- [Google image generation](https://aistudio.google.com/docs/image-generation)
  supports native generation/editing with Nano Banana models. Nano Banana 2.1 is
  the default Gemini editor; Nano Banana Pro is the complex-brief option. Gemini
  3.1 Flash-Lite Image is omitted because Google does not optimise it for the
  multi-reference/multi-turn editing this app needs. The adapter is implemented;
  a separate [Google API key](https://aistudio.google.com/docs/api-key) is required
  for actual testing. No key should be pasted into chat.
- [Claude vision](https://platform.claude.com/docs/en/build-with-claude/vision)
  supports image understanding, not image generation/editing. It could later write
  observations/briefs alongside an image renderer, with its own credentials.

The direct Gemini adapter follows the current [Interactions API](https://aistudio.google.com/docs/interactions-overview)
and [REST schema](https://aistudio.google.com/api-reference/interactions-api/create-interaction)
with revision 2026-05-20, store=false, metadata-free photo copies and no automatic
retry. Model-list checks send no photos and do not prove billable image access.
Nano Banana 2.1/2K is the starting preset; Quick ideas uses 1K, Final detail uses
available Pro/4K. These are documented capability-based starting choices, not a
comparative room-design benchmark. Real Gemini acceptance awaits a Google key.

### Model-comparison shortlist

The user's goal is a small working choice of strong image editors to test before
launch, then rank from actual renovation results. Keep the four primary candidates:
Nano Banana 2.1 and Pro under Gemini; GPT Image 2.6 Sunburst and Flare under OpenAI.
Google's current guide recommends 2.1 over the previous Nano Banana 2 for new
projects; Lite is not optimised for this app's multi-reference/refinement workflow.
Do not inflate the shortlist with general chat models or claim a measured winner.
Earlier OpenAI 2.5 options remain for existing account/project compatibility.

Settings labels the recommendations as an unranked testing shortlist and links
directly to Compare AI models. The same guide is available through Help. It covers
fixed input photos/views/brief, one confirmed result per model, reselecting the
original between attempts, manual 1–5 ratings, actual time/cost and several rooms
and edit types. A selected generated image must not become the next model's test
input accidentally. No automatic paid benchmark, stored scorecard or leaderboard
is implemented; a tested ranking remains future work after real comparisons.

Code inspection found that normal New design attempts rotate creative direction
even for one output. A fixed-brief test switch now skips that planning appendix
and sends the prepared prompt exactly, for one output only. It is off by default,
resets off after restart, blocks multi-output attempts before sending and preserves
the room's ordinary saved output counts. Testers must still keep source photos,
supporting views and the prepared brief identical. Normal variety is unchanged.

### App name and icon options

RenoVision is the confirmed display name in source. The user's latest marked
image selects first-board **A** as the preferred name/icon direction so far:
olive-green tile, cream room-corner outline and reveal sparkle. This supersedes
the previous open icon choice; clean launcher assets are still pending. A preview
board made with built-in imagegen is retained at
`output/design-review/brand-options-2026-11-20.png`; its exact prompt is in the
adjacent `brand-options-2026-11-20-prompt.txt`. These are ignored local design
artifacts, with no customer photo/API key used. They are not installed assets.

The first-board options are retained below; A is the current preferred direction.

| Option | Working name | Mark |
| --- | --- | --- |
| A, preferred so far | RenoVision | Olive room corner with an ivory reveal glint |
| B | RoomShift | Two contrasting room planes suggesting before/after |
| C | RoomCanvas | Forest-green room frame with a warm terracotta plane |
| D | RenoVision | Bold RV monogram with a doorway detail |

These are creative options, not name-availability clearance. Android,
Flutter and browser display labels now use RenoVision in source; the package
identity and launcher assets remain unchanged.
After selection, create a dedicated clean adaptive icon and small-size previews;
do not crop a labelled comparison board into the shipping icon. Preserve the
application ID/signature and all stored projects regardless of display-name choice.

The new six-icon board is
`output/design-review/brand-icons-2026-11-20-v2.png`, with the exact built-in
imagegen prompt in the adjacent `brand-icons-2026-11-20-v2-prompt.txt`:
A Reveal lens, B Material layers, C Design sweep, D Open view, E Plan to space,
F Room scan. B emphasizes material/interior design; F emphasizes the camera.
The later board remains as design history. The latest marked preference returns
to A on the first board; this is a direction choice, not a finished launcher asset.

## Whole-project design audit — 19 November 2026

Reviewed the original product brief, substantive conversation requests, source
through `a948da0`, platform integration and existing test evidence. This section
is the current assessment. Later research entries are dated records; their old
implementation statements, provider catalogues and pricing are not current
verification. No competitor pricing or model recommendation was freshly researched
for this audit. Use [feature status](../FEATURE_STATUS.md) and
[next steps](../CODEX_NEXT_STEPS.md) for current implementation and priorities.

### Product position

Renovision has progressed beyond a static UI prototype: users can capture/import,
analyse, generate options directly on Android, select/refine, compare and resume
saved work. The user reports successful AI generation, project auto-reload and
useful camera overlays. Keep the existing work. The original differentiation is
still controlled changes to real rooms, and mask/compositor enforcement is the
largest missing part of that promise. Reliability comes before subscriptions or
claiming continuous AR.

At audit time source was ahead of APK 1.0.11. The subsequent requested **1.0.12+13**
package now includes the caption/room-entry/camera-handoff/layout/theme/backup
fixes, source stamp `3cb94c972c`. All 249 tests and static analysis passed again;
phone acceptance remains. The audit itself produced no APK or paid AI call.

### Rendered interface evidence

Eleven current-source views were rendered using fictional rooms and fake services,
not the user's live projects: 390×844 phone and 1440×900 desktop, real view metrics
and fonts. PNGs are retained locally in ignored `output/design-audit/`:
`projects-mobile`, `rooms-mobile`, `room-chooser-mobile`, `explore-mobile`,
`library-mobile`, `settings-mobile`, `workspace-room-mobile`,
`workspace-style-mobile`, `workspace-refine-mobile`, `workspace-ideas-mobile`
and `workspace-desktop`. This is layout evidence, not interactive Chrome/S21 testing.

The selected **Focus Canvas B** is cohesive. The large persistent image, warm
panels, consistent top tools and desktop split are worth keeping. The remaining
work is largely hierarchy and states, rather than another skin or full redesign.

| Screen | Assessment | Recommended improvement, not implemented in this audit |
| --- | --- | --- |
| Projects | Attractive cover and clear camera/photo entry; saved work remains relatively far down for a returning user | Move Continue/saved projects above discovery; shorten returning-user hero; keep most catalogue browsing in Explore |
| Rooms and spaces | Cleaner source now opens onto rooms/actions without the large Save panel | Keep this; fix singular/plural captions and verify save-failure feedback on phone |
| Room chooser | Compact photo tiles and readable labels; Camera/Photos/Live choices remain available | Add more representative photos over time; retain icon fallback and search rather than making every tile bigger |
| Workspace Room | Image context is clear but strip/dropdown/baseline chips and explanations repeat | One active-source/baseline header; put photos/analysis and their state above optional management controls |
| Workspace Style | First phone panel is largely the palette carousel; the chosen palette can initially be offscreen | Compact selected style + palette/swatches summary; bottom sheet or expandable picker for the full catalogue; scroll to the selected choice |
| Workspace Refine | Brief, output count and Generate fit well together | Distinguish Create concepts from Refine selected; show active source/edit mode without opening advanced controls |
| Workspace Ideas | Version captions are improved; copy/import comes before history | Put saved options/selection first and manual handoff in secondary tools |
| Explore | User-result review and inspiration share one destination, and empty-review text pushes samples down | Clarify its two purposes with a compact switch/sections; avoid making returning users pass an empty panel to browse samples |
| Library | Full-width image/caption/actions fix the narrow-column problem | Keep this layout; add search/filter/storage management only as library size justifies it |
| Settings | Theme choices, collapsed AI/privacy and cover controls are clearer | Keep global preferences here; use a selected-project file panel instead of an increasingly long list of project export panels |
| Desktop workspace | Large image plus separate controls is balanced and recognisably the same app | Keep adaptive split; preserve scroll position/focus and keyboard access rather than stretching a phone panel |

Do not reduce all type again to solve these priorities. Keep adequate touch targets,
system text scaling, accessible contrast and TalkBack semantics. Phone help must
open on tap/long-press, not depend on hover. Verify landscape, keyboard, long labels
and reduced-height screens on S21. A small amount of vertical scrolling remains
appropriate; horizontal tabs choose tasks, rather than hiding required fields in
unlabelled horizontal swipes or nested scrolling regions.

### Suggested final workflow

1. **Resume or start:** existing projects/Continue first; Camera, Photos and Live
   design remain equally available. Let users name/confirm the room type.
2. **Understand:** save original views, analyse with consent, show concise visible
   facts and unresolved questions. Cache facts for those images independently of
   style changes; don't invent a scan percentage or measured dimensions.
3. **Direct:** selected style/palette and a plain-language brief in a short summary.
   Whole-room defaults remain; advanced Keep/Replace controls are optional.
4. **Create:** confirm one/two/three clearly different directions and their actual
   model/quality/request count. Show stages and elapsed time, save each success.
5. **Choose:** history/options first, with full-screen zoom, compare, favourite,
   approval and recoverable delete. Preserve the exact recipe per result.
6. **Refine selected:** a dedicated correction input against that image and its
   recipe. Start narrow mode explicitly and create a child; never silently replace
   the approved baseline or reuse an unrelated image's settings.
7. **Resume later:** local autosave plus an understandable portable document.
   Open resumes the same document; Restore copy is a deliberate separate action.

These are refinements of the present architecture, not a proposed replacement app.
Camera-first users can stay in the viewer through steps 2–5, see the saved overlay,
then choose Continue to refine. New palette/style requests still take model time.

### What the supplied kitchen images show

The original photo and restrained redesigns preserve a U-shaped kitchen, sink
window, peninsula and tall appliance tower. The better charcoal/walnut examples
coordinate more surfaces and remove visual clutter. The user's preferred dining
presentation also has broader framing, pendants, stools/table, lighting and changed
glazing/scene treatment. It demonstrates the desired atmosphere and material
coordination; it does not establish that every architectural change matches the
real room. A conservative preserve-everything prompt can suppress those richer
choices, while a very open prompt can invent structure.

The product should distinguish **layout-preserving renovation**, **broader concept
exploration** and **local correction**, then carry explicit retained elements into
each. A material/design board should be typed as inspiration, not another camera
view used to infer geometry. No image analysis proves concealed structure,
buildability or plan dimensions. Explain visible observations and uncertainties
before turning them into design instructions.

### Architecture and release assessment

One Flutter app shares UI/domain logic across web/Android. Platform boundaries
already exist for files, camera, credentials and API transport. Modules cover
drafts/prompts, analysis, concepts, project files, backup crypto and image tools.
Keep those boundaries. Large UI/store files and eager image storage deserve
incremental extraction/profiling when their related features change; a generic
architecture rewrite would add risk without solving the known user problems.

The audit prioritised document identity/reopen and immutable per-version recipes;
the 20 November batch implements those, with same-destination persistence and
real-device acceptance still outstanding. Next: less redundant analysis, precise
edit enforcement and measured startup/image/export performance. Local encryption,
OS backup policy and recovery
need an explicit design preserving old data. Commercial backend/credits, production
signing/identity, privacy policy and store/iOS validation belong to a later release.
Historical competitor promises should not be used as validated capabilities or
as a basis for fixed pricing without current evidence and measured usage.

## Settings protection decisions — 19 November

App appearance is a device preference, separate from renovation palettes and
project-file revisions. Five coordinated light-page themes preserve the selected
compact layout. No appearance preference or API credential enters project exports.

Optional protected backups use the maintained
[cryptography AES-GCM implementation](https://pub.dev/documentation/cryptography/latest/cryptography/AesGcm-class.html)
and [PBKDF2 API](https://pub.dev/documentation/cryptography/latest/cryptography/Pbkdf2-class.html).
Version 1 envelope: ASCII `RVENC01\n`, big-endian uint32 JSON-header byte length,
header, ciphertext, 16-byte authentication tag. Header contains cipher/KDF names,
600,000 iterations, 16-byte random salt and 12-byte random nonce. The complete
prefix/header is authenticated associated data. Decoder validates file/header
limits and fixed supported parameters before derivation, then authenticates before
returning plaintext. Binary packaging avoids adding another base64 expansion to
the existing JSON/photo payload. File limit remains 100 MB. Filenames remain visible.

Protected files are opened as separate local projects without linking their file
handles to ordinary plaintext autosave. Normal JSON export remains a separate
explicit choice. Passwords are not saved, resettable or recoverable; a lost one
does not affect the existing local project. Native encryption runs in an isolate;
the browser uses the package's web crypto implementation. No cloud processing.

This does not add encryption to the existing Hive photo/metadata boxes. A future
local-store migration needs separate key management/recovery and interruption
testing, preserving current work. Android API-key protection already uses Keystore;
browser keys remain session-only. Public-release privacy/billing work remains.

## Camera-first design clarification — 19 November

User wants the reference acquisition, analysis, direction questions, generated
overlay and palette tuning in one viewer, then Continue to refine into normal
editing. This supersedes a capture-first navigation requirement, while retaining
the existing comparison mode. The new source implements that workflow with one
automatically captured reference and separately confirmed preview requests. The
user chose confirmation per request; bounded paid live sessions interest them as
a later option. Never imply a timer measures room coverage or silently send video.
Current image generation can take time; partial streaming is a possible next
latency improvement, not an implemented feature. Provider capabilities/limits:
[OpenAI image generation](https://developers.openai.com/api/docs/guides/image-generation).
Geometric room scanning, pose tracking and continuous video transformation are
separate research/engineering work. The source batch made no real AI calls or
APK; it is now packaged in the requested 1.0.11 test build.

Follow-up source after 1.0.11: Camera renovation's primary Design in live camera
action uses this viewer; the workspace editor is an explicit separate tool.
Saved results appear automatically over the camera (or wait for it to become
ready), with a toggle on the image. Keyboard visibility must not reset the
overlay. Continue to refine explicitly opens the selected result for precision
editing, preserving the whole-room brief. This correction is packaged in the
requested 1.0.12 APK; physical phone acceptance remains.

Consolidated 15 November 2026. Supporting notes, not another current task list.
Use the [project brief](../RENOVISION_PROJECT_BRIEF.md) for requirements,
[feature status](../FEATURE_STATUS.md) for actual implementation and
[next steps](../CODEX_NEXT_STEPS.md) for current priorities. Research entries are
dated individually; the 14 November prices were not rechecked during cleanup.
Proposals and the earlier roadmap are not completed features.

## Visual direction review — 18 November 2026

### Mobile controls and scroll review — 18 November 2026

User wants the required inputs for each task to fit one phone screen and asks
about vertical/horizontal navigation, competitor images and videos. Current
Focus Canvas workspace addresses section navigation; `reference_editor.dart`
still uses a vertical ListView with stacked tool, colour and width Wraps,
guidance and duplicate body Undo/Redo/Save controls. This is the next UI priority.

Primary references checked (public documentation, screenshots/alt descriptions,
demo text and tutorial transcript; no hands-on competitor-device claim):
- [Lightroom mobile workspace, including labelled editor screenshot](https://helpx.adobe.com/lightroom/mobile/get-started/workspace-overview.html): image-focused Detail view with grouped editing tools and separate options menu.
- [Adobe mobile masking video](https://www.adobe.com/learn/lightroom-cc/web/ai-assisted-masking-lightroom-mobile): around 01:08 the transcript describes managing masks and dragging the bottom tab to expand the panel. Relevant to panel design, not a claim Renovision already has AI masks.
- [Snapseed tool workflow](https://support.google.com/snapseed/answer/6155517?hl=en) and [selective gestures](https://support.google.com/snapseed/answer/6157827?hl=en): explicit tools, hold-to-compare, pinch/pan; selective adjustment uses vertical choice and horizontal value changes. Gestures supplement visible actions.
- [Homestyler photo/style workflow](https://www.homestyler.com/ai-room-design?lang=en_US): upload, illustrated style selection, room type where applicable, then generation.
- [Planner 5D room-design demo](https://planner5d.com/use/ai-room-design): multiple transformation choices and before/after comparison; useful as a visual interaction reference, not proof every private editor option fits one screen.

Recommended Renovision interaction: retain B's image-led workspace and compact
first-time room steps. For crop/markup, reserve the canvas and fixed Save/Cancel
actions; use a compact tool strip with contextual properties. Draw shows colour
and width pickers; Shapes shows its small shape chooser; Notes shows text actions;
Select exposes actions for the selected mark. Reuse the existing tools/history,
not a new unrelated editor. Put secondary guidance behind the existing info icon.
Keep Undo/Redo in the shared top toolbar instead of repeating body controls.

Horizontal browsing suits image versions, style cards and palettes. Short vertical
scrolling belongs inside the active control panel; expand/collapse it with both a
visible button and an optional handle. Do not assign whole-screen navigation
swipes over the image: they conflict with crop handles, drawing and panning.
Preserve readable controls, keyboard access and large text; do not guarantee zero
scrolling on every screen/device. Save/generation actions and errors must remain
reachable and visible. This review records a proposal; it does not implement a
new bottom sheet, editor layout or gesture scheme, and builds no APK.

### Selected references: HOMLY workflow + Forma styling

User selected **B / Focus Canvas**. It is now implemented in the shared Flutter
source: large persistent image and version thumbnails, compact retained control
sections, desktop split, dark warm canvas/olive actions and camera-first project
home. Existing room setup, photo selection, AI requests, approvals, save/restore,
deletion and key storage remain the underlying implementation. Generated artwork
was visual guidance; its illustrative account/share/duplicate controls were not
added as unsupported features. The layout is included in requested APK 1.0.9;
APK 1.0.8 retains the old layout.
Actual Flutter widget review captures (fictional photos, disposable in-memory
storage, local review font) are in `output/design-review/focus-native-*.png`.
The generated boards below remain the original choice references.

Image concepts requested on 18 November: three original raster UI boards generated
with the built-in image tool and visually reviewed: A Warm Studio, B Focus Canvas,
C Room Journal. Each shows room/camera entry and a design/refinement workspace.
Copies are in ignored `output/design-review/app-look-a-warm-studio.png`,
`app-look-b-focus-canvas.png` and `app-look-c-room-journal.png`; exact prompt set
is `output/design-review/app-screen-image-prompts.txt`. These are illustrative
concept images, not app screenshots or implemented screens. Illustrative account,
notification/share/duplicate icons do not add those features to the product scope.
Use existing supported tools when implementing the chosen direction. User choice
is pending; A's room entry with B's image-focused workspace is a possible blend.
No source UI change or APK build made in this image-concept batch.

Review examples prepared with the requested APK 1.0.8 batch:
`output/design-review/renovision-next-look.html` contains Warm Studio (split
image/control layout), Focus Canvas (larger image and compact refinement area),
and Room Journal (editorial project view with contextual controls). Room, Style,
Refine and Ideas tabs work locally; refinement text survives switches, sample
selection changes the preview and no AI requests or project writes occur.
Images are existing fictional examples, not versions of the user's real room.
Three layouts passed 19 browser checks at both 320px content width and desktop
width; Warm Studio desktop and narrow screenshots were visually inspected.
The actual app retains its current layout until the user chooses a direction.

Latest user selection refines the earlier Planner 5D preference:
[HOMLY — AI Interior Design App UI/UX & Motion Animation](https://dribbble.com/shots/27821170-HOMLY-AI-Interior-Design-App-UI-UX-Motion-Animation)
is the requested functional reference;
[Forma — Interior Design & Renovation Platform](https://dribbble.com/shots/27758267-Forma-Interior-Design-Renovation-Platform)
is the requested styling reference. Retain Planner 5D's room choices and compact
fine-tuning as supporting inspiration. These are preferences, not implemented UI.

Access limits: the two exact shot pages did not load reliably in the research
tool. HOMLY's animation/interactions have not been inspected. A related
[Forma shot from the same designer](https://dribbble.com/shots/27728147-Forma-Interior-Design-Renovation-Platform)
was accessible and describes a visual canvas with precise controls, materials,
style variations and version comparison in one workspace. Its published palette
includes cream, taupe, charcoal and brown. Do not attribute unverified interaction
details or a reusable Flutter template to either reference.

Renovision adaptation: warm cream/taupe surfaces, charcoal text, restrained earthy
accents, strong room photography and a clear type hierarchy. Keep Take photo and
Choose photos prominent, then room/style choices and one image-led workspace.
Desktop: image/comparison beside a compact control panel. Phone: image with
Room, Style, Refine and Versions sections, exposing only the active controls.
Keep the contextual toolbar, visible save/progress state, clean result thumbnails
and selected-design refinement. Preserve keyboard/large-text access even where
some scrolling is necessary. Use existing room records, images and version data;
make no storage migrations just for styling. Camera Renovation View remains the
priority new capability. Do not introduce estimated budgets, shopping catalogues
or contractor features solely because a reference depicts them. No APK requested.

User preference now selects the Planner 5D-inspired direction: image-led room
choices, fine-tuning beside the image, and minimal page scrolling. This supersedes
the earlier open choice between three visual directions. Use its public page as
inspiration, not proof of the exact layout in an authenticated editor or as a
template/source licence. Retain Renovision's own branding and shared Flutter code.

Proposed desktop workspace: image/comparison canvas and nearby versions, alongside
one compact active control panel (Room/photos, Style/colours, Refine or Versions).
On phones retain a useful image preview above a compact tabbed/expandable panel;
let content reflow for keyboard/large text rather than promising zero scrolling.
Preserve contextual toolbar ordering, drafts across tab switches, source/version
identity and paid-job state. Use the existing 42 room choices with suitable visual
category examples. A dedicated refinement panel and this responsive layout are
still proposed, not shipped. Camera Renovation View remains the main new feature;
this workspace design should accommodate it rather than replace that priority.

Private Android testing is already possible; public-launch readiness is a separate
milestone. Current priorities are a clearer image-led workspace, selected-design
refinement, real-device storage/lifecycle/network acceptance, interrupted-job
recovery and production distribution/signing decisions. No release date is set.

Reviewed public examples: [Homestyler photo/style workflow](https://www.homestyler.com/ai-room-design?lang=en_US),
[Planner 5D room-design presentation](https://planner5d.com/use/ai-room-design),
and [Dribbble interior-app concepts](https://dribbble.com/search/interior-design-mobile-app).
Public pages and concept portfolios are inspiration, not evidence of tested
in-app usability or reusable Flutter source. No template was purchased/imported.

Three isolated previews explore Warm Studio (recommended), Image Workspace and
Editorial Home. They use an existing fictional kitchen sample; concept thumbnails
reuse that image and are not newly generated designs. The previews do not save
projects or call AI. Source: ignored `output/design-review/renovision-directions.html`.

Recommended direction: warm neutral surfaces and restrained teal, large room-photo
project cards, a dominant design image, visual styles/palettes, compact refinement
controls and consistent contextual toolbar. Desktop should use the available width
for image and controls; Android should stack them with touch-friendly controls.
Preserve local storage, originals, version history and current AI integration.
Choose one coherent design system first; optional skins can follow. No broad app
layout changes were made in this research batch. Build an APK only when requested.

- [AI design workflow](#ai-design-workflow)
- [Competitor review](#competitor-review)
- [DecAI user-review lessons](#decai-user-review-lessons)
- [Pricing review](#pricing-review)
- [Camera workflow](#camera-workflow)
- [Earlier roadmap](#earlier-roadmap)
- [AI model choice](#ai-model-choice)

## AI model choice

Historical model research recorded 15 November 2026, retained below. Model IDs,
availability, documentation claims and subscription/credit offers were not
reverified in the 19 November audit; do not treat the table as a current buying
recommendation. The app filters its configured image-model catalogue against
account access, but that is not a capability/quality benchmark. Start testing
with the existing working OpenAI route; another provider, local GPU or 3D engine
is not required for the basic photo-analysis/design/refinement app.

| Job | First test candidate | Reason / limitation |
| --- | --- | --- |
| Photo observations and prompt drafting | [GPT-6 Luna](https://developers.openai.com/api/docs/models/gpt-6-luna) | Existing analysis integration; supports image input/structured output. Check observations rather than trusting invented measurements. |
| Detailed room edits | [GPT Image 2.6 Sunburst](https://developers.openai.com/api/docs/models/gpt-image-2.6-sunburst) | Documented for detailed visual work; a sensible first candidate for controlled renovation edits. Actual room preservation still needs testing. |
| Fast concept/refinement comparison | [GPT Image 2.6 Flare](https://developers.openai.com/api/docs/models/gpt-image-2.6-flare) | Documented for interactive iteration. Compare against Sunburst with the same source/prompt and record actual time, cost and adherence. |
| Existing baseline/fallback | GPT Image 2.5 Sunburst / Flare | Retain the working configuration and allow side-by-side tests; do not change old saved records or automatically retry with another model. |

The relay now exposes the configured default plus both 2.5 and 2.6 pairs.
These models and low/medium/high quality are listed by the
[image-edit API reference](https://developers.openai.com/api/reference/resources/images/methods/edit).
Configured options are not a verification of the user's account access. Default
remains 2.5 Sunburst at low quality, so adding newer options does not silently
change the first request. No live model benchmark has been performed.

The separate [Gemini Nano Banana 2.1](https://aistudio.google.com/docs/image-generation)
adapter is now integrated in source. It has independent credentials and mocked
request/error tests; real quality/value comparison remains pending. Another
provider is optional, not a prerequisite. No provider guarantees unaltered
architecture solely from a prompt.

### API access and subscription credits

A ChatGPT login cannot be pasted into the relay. However, eligible paid Pro and
Business subscriptions may claim API credits by linking an owned API organisation
using the same email, subject to the current conditions. Active credits can be
used without an API payment method. Check the official
[subscription API-credit guide](https://developers.openai.com/api/docs/guides/chatgpt-api-credits)
before adding paid credit; the user's plan/eligibility has not been checked.
A developer API key and model access are still required. A subscription is not
an automatic unlimited API allowance.

## AI design workflow



User requirement recorded 14 November 2026; implementation reconciled 19 November.
Photo analysis, editable AI prompt drafting and one/two/three concept requests
exist through direct OpenAI HTTPS or the optional relay. The user reports working
phone AI generation; systematic quality/diversity benchmarking is still pending.

1. Add photos of the same room; choose the primary view, colours and preferences.
2. Describe the desired changes in ordinary language and identify what must stay.
3. AI reviews the photos and preferences, then writes a specific renovation prompt.
4. Show the proposed prompt to the user for editing and approval. Surface unclear
   or contradictory instructions rather than silently inventing requirements.
5. Let the user choose how many design alternatives to request. Show the count,
   provider/model and quality before submission; actual billed-cost information
   is not yet implemented. Never generate paid alternatives automatically merely
   because a prompt was drafted.
6. Show the returned designs together with individual status/error information,
   useful titles, zoom/compare controls and keep/pass selection. Preserve successful
   results if another option fails; do not automatically retry billable requests.
7. Select one design as the approved baseline. Enter a further instruction or
   markup to improve that exact version. Save refinements as new child versions.

### Prompt-writing requirements

Presentation reference supplied by the user: a kitchen/dining design board with
two labelled alternatives, a wider room render, a floor-plan inset and material
swatches for cabinetry, benchtops and flooring. This is the quality/presentation
target. Keep the provided image unchanged. It is a style/presentation reference,
not permission to change another room's walls/glazing. Any plan measurements must
come from confirmed user measurements; do not treat generated inset labels as a
survey or invent verified dimensions. Later boards should make option selection
and refinement straightforward rather than flattening all alternatives into an
uneditable single image.

- Use the actual room photographs, selected palette, user changes and room memory.
- Separate layout-preserving renovation from a small-area precision correction.
  Replacing cabinets, flooring and appliances together is a renovation request,
  even when the walls and room footprint must remain unchanged.
- Explicit scope choices must carry through: selected flooring requires replacing
  the old floor pattern, and selected old telephone removal includes the handset,
  visible cord and repaired wall finish. Respect protected features and retain
  unrelated functional/safety equipment. Do not infer removals from style alone.
- Room-specific Keep / Replace preferences are authoritative input. For kitchen
  appliances, resolve individual overrides before writing the prompt, so one
  appliance never receives both Keep and Replace. New appliance models must be
  visibly new rather than merely recoloured. Filter inactive room-profile choices;
  do not treat name-based room type suggestions as photo observations.
- State the working viewpoint and supporting photo roles. Do not claim that
  multiple photos establish measurements or a verified 3D model.
- Explain which requested change affects which part of the room. Preserve the
  windows, openings, walls, viewpoint and approved choices unless explicitly changed.
- Treat a palette as guidance within allowed changes, not permission to repaint
  protected features. Handle "nothing to retain" without contradictory wording.
- Require the relevant image attachments. A copied text prompt alone has no photos.
- Retain the deterministic template as an offline/manual fallback, clearly labelled.

### Implementation sequence

1. Implemented: photo analysis/review, editable prompt, autosave and explicit use
   selection, direct internet API plus optional private relay.
2. Implemented: photo previews/consent, stale-input checks, storage-only retry,
   distinct bounded concept directions, sequential saves and partial-success
   handling. In-flight cancellation/recovery is not implemented; normal Back
   waits and a process kill can still lose a billed response.
3. Implemented 20 November: immutable per-version structured settings/analysis
   snapshots and history reuse/refinement. Next: separate photo-fact caching
   from changed design preferences.
4. Benchmark real-room preservation, diversity, refinement, time and usage on
   the same inputs before claiming one provider/model is better or cheaper.

### Current implementation

The offline fallback builds a labelled deterministic template. A connected vision
model can analyse photos and draft an editable prompt. Choosing it for generation
retains the authoritative current room requirements. The room stores its latest
analysis and current choices; each design stores the final prompt, source/parent/
supporting images, provider/model and request ID. New in-app generations also
freeze structured settings, historical analysis and model/quality in an immutable
recipe. Older/manual/editor versions may lack recipes; no missing history is
invented. These records survive project backups.
One/two/three concepts are separate sequential image requests from the same source,
with explicit varied directions. Manual edits, saved versions, favourites, approval
and branching already exist and should be reused rather than replaced.

## Competitor review

### Local finish editing review — 20 November 2026

User direction: use AI when it adds value; changing only wall paint or wallpaper
on an otherwise accepted photo/design should not require a new whole-room AI
render. This is an ideas/architecture review, not an implemented editor or a
paid competitor benchmark. Existing project data, source images and APK stay intact.

**Published patterns worth adopting:**

| Official evidence | Useful pattern for RenoVision |
| --- | --- |
| [Renovate AI paint guide](https://help.renovateai.app/en/article/painting-your-house-or-building-interior-walls-1dnnx96/) describes wall detection, palettes, mobile brush/Smart Fill, undo/reset, using earlier renovations and downloading | Edit the selected existing result, select walls, and keep colour choices beside the image. Reuse a corrected selection for further colour trials. The guide does not establish which steps run locally or incur AI usage. |
| [Renovate AI Color Finder](https://help.renovateai.app/en/article/how-to-use-the-color-tool-to-find-paint-colors-1woiafn/) documents extracting suggested room colours without changing the image | Add an eyedropper and saved swatches; later offer dominant-colour extraction. Sampled photo RGB is an appearance reference, not proof of an exact branded paint match. |
| [Benjamin Moore FAQ](https://www.benjaminmoore.com/en-us/faq), Website Questions 48, describes masking multiple surfaces on an uploaded photo and selecting colours; its Personal Color Viewer is not optimised for phones | Keep separate wall selections and colours, with deliberate phone-sized controls. Treat surface identity/selection as reusable editing data. This source does not disclose its internal algorithms. |
| [Roomvo paint feature sheet](https://hello.roomvo.com/hubfs/_Inbound%20Assets/Feature%20Sheets/inbound-feature-sheet-roomvo-paint-visualizer.pdf) describes different wall colours, retained surface texture, comparison, favourites, image download/share and product details | Make colour trials visual, comparable and easy to save; later attach selected material names/codes to a room board. Its realism/speed claims are marketing, not our measured acceptance standard. |

Renovate AI's [exterior paint page](https://renovateai.app/exterior-paint-visualizer)
also explicitly advertises AI-generated repaint renders. Similar-looking tools
can therefore use different pipelines; do not claim every competitor palette
change is a local operation. Its [homepage](https://renovateai.app/) lists paint,
wallpaper, flooring and cabinetry visualizers, but that alone does not establish
all features in every consumer plan or prove they work without AI.

**Actual app position:** `reference_editor.dart` / `reference_markup.dart` provide
crop and annotation geometry during editing, but save flattened reference images.
Their Select tool selects annotations, not room surfaces. `screens.dart` records
these as new image versions. `design_palettes.dart` supplies AI prompt directions;
it does not recolour pixels. There is no persisted surface mask, local paint/
wallpaper renderer or editable material-layer recipe yet. `RoomAnalysis` contains
text observations, not a usable wall segmentation map. Existing before/after,
version history, local storage and save/share controls are foundations to reuse.

**Recommended next functional batch: local wall paint.** Open an original or
accepted AI result, choose Finishes > Paint, select the wall once, and try colours
from a compact strip. Use a manual polygon/brush plus erase/edge correction first;
allow exclusions for windows, trim, furniture and fittings. A later optional
wall-detection assist could use an on-device model or a consented cloud call.
Once a suitable mask exists, palette changes can render on the device with no
generative request or API key. Never make a silent paid request when a swatch is
tapped. Show selection/preparation progress separately from ordinary colour updates.

The renderer should modify only the selected area and aim to retain its texture,
brightness variation and shadows. Flat colour fill alone gives an unrealistic
paint-over effect. Dark-to-light changes, reflections and missing texture limit
what simple compositing can reproduce; show a visual approximation, not an exact
paint/lighting simulation. Do not promise instant performance until measured on
Chrome and the S21.

Save named selections and editable layers against the source image ID, decoded
dimensions/orientation and source revision. Keep the base image untouched. New
AI renders, crops or different viewpoints need fresh or explicitly realigned
selections; they must not silently inherit an old mask. Store the selected colour,
blend parameters, mask and local-operation provenance in a compatible portable
recipe. Preserve the source generation's history separately; do not label a local
paint version as a new AI generation or assign it an invented model/request ID.
Autosave the working edit; Save version adds a child with a lossless full-frame
PNG and its editable settings. Approval remains explicit. Reuse existing sharing.

**Then wallpaper, followed by floor/cabinet finish trials.** Wallpaper needs an
image/swatch, repeat scale, offset/rotation and perspective controls; a flat
pattern over the entire photo is inadequate. Reuse the surface mask and excluded
foreground regions. Begin with owned sample patterns and user-imported swatches.
Preserve existing 3D shape; adding cabinets, changing layout, removing an object
or revealing hidden background remains a different AI/geometry task. Photo scale
is not a verified measurement. More complex reflections/occlusion need separate
quality work rather than a promise that every material swap is trivial.

**Phone workflow:** selected image stays visible; one Finishes action opens Paint
/ Wallpaper / later Floor / Cabinets. Pick a named surface, then use swatches in
a short bottom sheet, with Undo/Redo, compare to the starting design, Save version
and existing Save image / Share creation. Multiple paint choices can be compared
locally without spending a generation per colour. Keep the current AI New design
and Precise correction paths for edits that need synthesis. A no-key user can
still get useful manual finish previews, supporting the Standard launch plan.

Other worthwhile follow-ups: typed inspiration/material references, a simple room
material board, per-surface saved favourites and a base-style plus regional-
influence picker (e.g. Contemporary + Japanese/Italian). Current 19 styles include
Japandi/Mediterranean/French provincial/Scandinavian, but no dedicated Japanese or
Italian buttons. These are proposed additions, not features in APK 1.0.13.

**Acceptance before shipping:** zero provider calls in manual/local mode, including
without a key/offline; correct mask mapping when zooming/rotating/resizing; saved
selections and layered recipes survive restart and plain/protected portable copies;
undo/cancel and failed saves preserve prior data; compare against the actual source
design; test occlusion/edges and dark/light paint; measure preview/export latency.
For a local full-frame PNG, assert decoded pixels outside the allowed mask/feather
band remain unchanged in the same oriented working frame. That guarantee belongs
to the tested compositor, not prompt wording or the current annotation tools.



Reviewed 14 November 2026 against RENOVISION_PROJECT_BRIEF.md and the current
Flutter implementation. Sources are official product/help pages. Features below
are advertised/documented capabilities, not independently tested performance or
guarantees. No competitor account, subscription or paid generation was used.

### What the competitors show

| Product / official source | Relevant capability or presentation | Renovision comparison and implication |
| --- | --- | --- |
| [DecAI](https://decai.ai/) | Dedicated interior/exterior, furniture, wall, floor and reference-style tasks, plus an AI design agent | The closest direct workflow benchmark identified by the user. Its published scope is broader than this prototype. Prioritise a coherent photo-to-edit-to-history experience and concrete surface controls. See the focused comparison below. |
| [Renovate AI Studio](https://studio.renovateai.app/home) | Separate tasks for flooring, paint, cabinets, object removal and selected-area editing; a guided design consultation | We have room-specific Keep/Replace controls and analysis/prompt drafting, but changes are still largely instructed in text. Add true selection/masking and concise task shortcuts. The published studio leads with the photo/upload action. |
| [Renovate AI editing help](https://help.renovateai.app/en/article/editing-images-overview-13vzd7k/) | Distinguishes typed edits, style exploration and a question-led consultation; accepts user component/material references | Keep Explore separate from Precision. Introduce explicit reference roles: material, inspiration and sketch, distinct from additional views of the same room. |
| [REimagineHome](https://www.reimaginehome.ai/) | Guided photo-to-refinement flow, inspiration/moodboard references and product/budget-oriented design | Our approved baseline and version history already support refinement. We lack clearly typed inspiration inputs, a material/specification board and a guided result-selection screen. Real-product availability and checkout are later-stage integrations. |
| [REimagineHome surface restyling](https://www.reimaginehome.ai/restyle-surfaces) | Dedicated wall/floor/cabinet material changes and subsequent refinement | Our palette is a direction, not a material sample. Add independent surface/material choices and reference swatches; verify actual output adherence. Do not equate a palette or checkbox with an enforced mask. |
| [Planner 5D room decorator](https://planner5d.com/use/ai-room-decorator) | A short photo/direction/generate/compare/refine journey, alongside its broader floor-planning ecosystem | We already support these ingredients but scatter them down a long workspace. Present clear stages, large images and accessible comparisons. A full measured 2D/3D planner is a separate scope from a renovation image concept. |
| [Planner 5D Android AI Designer](https://support.planner5d.com/en/articles/9310427-ai-designer-create-a-design-using-ai-android) | Separate furnishing, styling and arranging tasks; lets users explore another result before applying it | Provide bounded alternative generation and selection. Retain approval as an explicit action. These documented Android editor functions should not be assumed identical to the web photo workflow. |
| [Homestyler official AI update](https://www.homestyler.com/forum/view/2110216405773144066?lang=id_ID) | Partial renovation with furniture/material reference images; text guidance and moodboard generation | Explicit reference types and board export fit our kitchen use case. Model editing, CAD and its broader material-brush tools belong to a different 3D workflow; they do not establish that its photo edits preserve every pixel. |
| [RoomGPT](https://www.roomgpt.io/) | Simple one-photo entry point and prominent example imagery | Reduce setup friction and make returning to an existing room easy. Its public landing page alone does not establish detailed editing, storage or version-history capabilities, so those remain unknown in this review. |

Do not use competitors' advertised speed, popularity, exact colour matching or
structure-preservation claims as verified benchmarks. Plan/platform eligibility
can differ. See [Pricing review](PRODUCT_NOTES.md#pricing-review) for the separate dated
DecAI subscription/credit comparison and provisional Renovision pricing ideas.
Neither review recommends purchasing another service.

### DecAI: the closest direct benchmark

The user identified DecAI as similar to Renovision with a stronger experience.
That comparison fits its published product/workflow. This is an assessment of
documented capabilities and public screens, not a completed paid output-quality
benchmark or an inspection of its private implementation.

| DecAI experience | Renovision today | What to adopt |
| --- | --- | --- |
| [Its public workspace](https://decai.ai/app/home/) groups redesign, furniture changes, walls/floors and history into named tasks | One long workspace contains much of the functionality; provider setup/manual handoff can interrupt it | Give the user a room photo, a clear task and one next action. Keep advanced controls available in detail panels. |
| [Its gallery/edit update](https://decai.ai/blog/image-gallery-edit-and-more-features) describes a browsable gallery and editing a result directly without downloading/re-uploading | Versions and approved-baseline branching exist, but the gallery/return-to-room journey is basic | Show selected-result Edit / Compare / Approve actions together. Make original, current and approved images obvious. Add history filtering and thumbnails. |
| [Its style-transfer workflow](https://decai.ai/style-transfer) uses a room photo plus a distinct inspiration image | Supporting room angles exist; inspiration and material references have no dedicated roles | Store separate source roles and the intended influence. The user's kitchen board should guide style/materials without replacing the room geometry. |
| [Its room-design page](https://decai.ai/ai-room-design) documents dedicated finish choices and conversational iteration | Palette, Keep/Replace and AI-drafted prompts exist, with text-guided image requests; region enforcement is incomplete | Offer floor, walls, cabinets and appliances as visual tasks. Retain a concise room brief while applying follow-up edits to the selected baseline. |
| [Its FAQ](https://decai.ai/faqs) describes photo analysis and retained design history | Photo analysis is wired to the relay; live quality and the complete user flow still require verification | Make analysis produce visible observations and useful clarification, followed by an editable brief and a result saved to the same room. Verify this on the kitchen case. |

Do not assume that more styles, a polished gallery or claims about preserving
layout establish better image accuracy. Conversely, local originals and version
history are strengths to retain, not proven unique advantages over DecAI. Its
public materials do not establish every internal storage or locking behaviour.

### DecAI user-review lessons

Checked 15 November 2026 using the exact Android package supplied by the user,
[Google Play listing and visible reviews](https://play.google.com/store/apps/details?id=ai.interior.design.home.renovation.app),
and [US App Store reviews](https://apps.apple.com/us/app/ai-home-design-interior-decai/id6502747597?see-all=reviews)
for the same named product. Removing the referral/region query made the Play
listing accessible. This does not verify Android purchase prices. Both retrieved
store pages were US-facing; these are not Australian review statistics.

The visible selection is small, not a representative survey or a full review
export. Repeated App Store entries were treated as one review. Reviewers'
accounts are reported experiences, not independently reproduced defects or proof
of billing misconduct. No install, account, payment or photo upload was used.
Secondary review summaries were located but are not needed for the findings below.

**Direct Android examples:** Live Your Life (2 November 2026) objects to a
rating prompt before using the app. Mirko Hrovat (14 October 2026) reports that
the image placed twin beds differently from the written recommendation.
Vanessa B. (11 October 2026) reports added windows/changed ceiling height and
unclear subscription expectations. The listing displays 4.6 stars overall;
these selected complaints do not establish how frequently problems occur.
[Source](https://play.google.com/store/apps/details?id=ai.interior.design.home.renovation.app)

**Additional iOS examples:** MamaBoy+3 praises exploring alternatives.
wow werfcvhn (29 September 2025) reports invented space and difficulty with a
combined kitchen/living area. Ally Coyote (24 September 2025) reports ignored
colours and changed proportions. CD Bear (7 July 2025) describes misunderstood
weekly renewal. Augie247 reports interrupted refinement and having to repeat
the brief. These are separate iOS reports, not additional Android evidence.
[Source](https://apps.apple.com/us/app/ai-home-design-interior-decai/id6502747597?see-all=reviews)

The following are our product/engineering recommendations inferred from those
experiences, rather than assertions about DecAI's implementation:

| Priority | Renovision improvement | Existing work and acceptance check |
| --- | --- | --- |
| P0 | Keep the real room recognisable through changes and refinements | Layout/protection prompts exist; they are not enforced geometry locks. Check windows, doors, walls, viewpoint and usable circulation against the source; later add masks/compositing and outside-region warnings. Do not promise pixel-perfect retention from a checkbox. |
| P0 | Check the image against the approved brief | Scope, flooring/removal details, palettes and room-item choices exist. Show a concise requested-change checklist next to the result. Confirm tiles, phone removal, appliance updates and retained features visually; let the user flag a miss and refine the selected version. An AI check may assist, but is not a verified pass. |
| P0 | Resume without repeating the brief | Local drafts, versions and explicit approval exist. Finish normal-profile restart/restore tests and preserve preferences/source/parent across edits. Provider failure should retain the room context; local-save retry must not send another generation. Full conversation history and interrupted-request recovery remain incomplete. |
| P1 | Make exploration and selection straightforward | Add room cards/sample inspiration, then bounded alternatives with Compare / Choose / Refine. Current generation returns one image. A sample's composition must not replace the user's room geometry. |
| P1 | Support combined spaces explicitly | Current room profile is one selected type, including Living / dining; it cannot express independent kitchen/living zones. Later support named zones and retained features per zone. Multiple photos already exist, but do not establish a measured panorama or 3D model. Add an open-plan benchmark rather than assuming a wider photo solves it. |
| P1 | Make material choices concrete | Keep the existing palette and per-room controls, then add independent wall/floor/cabinet/benchtop selections and typed material references. Confirm the intended surface changes, instead of only checking whether palette text reached the prompt. |
| Later release | Make paid usage and interruptions understandable | Show exact output allowance, per-action usage, renewal total/period and cancellation route before purchase; avoid an early rating interruption. Billing and review prompts do not currently exist, so this is launch guidance. Do not promise every failed provider job is free; distinguish request failure, saved-result failure and poor adherence. |

Recommended sequence: save/restart correctness, visual room/sample entry,
clear result review and selected-version refinement, then bounded alternatives
and enforced region work. Evaluate genuine moving-camera AR separately. This
prioritises a trustworthy design journey while retaining the camera direction.

Extend the kitchen benchmark below with a narrow bedroom requiring two beds in
a specified arrangement and an open-plan kitchen/living scene. For each, compare
the brief, image and protected architecture; record retries and actual costs.

#### Practical benchmark using the kitchen

Use the same original kitchen photo and the same requested changes in both
systems. For the common-input test, use one primary photograph; test additional
room angles separately if both products support that role. Record the actual
settings, output count, quality, number of retries and any charges. No competitor
uploads or billable tests have been performed as part of this review.

Requested broad concept: keep the room walls, window, openings, camera viewpoint
and kitchen footprint. Use warm charcoal handleless push-open cabinetry and a
coordinated walnut colour/material direction. Replace the floor with large-format
warm greige tiles. Replace the visible oven, microwave, cooktop and extractor with
visibly new modern appliances in the existing positions. Remove the old wall
telephone and cord, and patch the wall. Do not add unseen appliances or openings.

Then choose a result and ask for one narrow correction, such as changing only
the benchtop finish while keeping the approved cabinetry, appliances, floor,
window and viewpoint. Compare the result to that approved source rather than
starting over from the original each time.

Score each check 0 = failed, 1 = partly met, 2 = met:

1. Room layout, window and viewpoint retained.
2. Old floor replaced, including visible edges.
3. Telephone and cord removed with a coherent repaired wall.
4. Requested appliances visibly replaced.
5. Cabinet fronts handleless and palette direction followed.
6. Unrelated/protected items retained.
7. Narrow follow-up edit preserves the approved result elsewhere.
8. User can resume the saved room and its versions after restarting.

Keep broad-concept and narrow-edit results separate. Also record usability,
time/retries and output cost independently; do not hide those in an image score.
Use the results to decide which gaps matter most. The next design batch remains
the photo-centred workspace, guided refinement and accessible saved alternatives;
reference roles and tested region edits follow as functional work.

### Current Renovision strengths

This is the dated competitor-review snapshot. The current inventory is in
FEATURE_STATUS.md; later source has added several items listed below as gaps.

- Original photographs are separate from generated/imported versions. Approved
  baseline, branches, favourites and before/after comparison already exist.
- Up to six same-room views, palettes, room types and individual Keep/Replace
  preferences are already implemented; new work should reuse them.
- Photo analysis and editable AI prompt drafting are wired to the relay, with
  consent, saved provenance and stale-input checks. They need live quality tests;
  they are not missing wholesale and are not an offline image model.
- Autosave, Save now, save-on-exit, named copies, PNG export and full project
  backups exist. Normal Chrome restart persistence and file-picker interaction
  remain required manual acceptance checks. Preserve the recovered kitchen files.

### Gaps and recommended order

| Priority | Gap / work | Completion evidence |
| --- | --- | --- |
| P0 | Finish the real saved-project restart and Save as checks | Restore the recovered kitchen once; close/reopen normal Chrome at the fixed address; verify photos, instructions, preferences, versions and a restored backup. |
| P1 | Responsive workspace centred on the photo | Large working image remains visible on desktop; grouped settings beside it. On phones, photo first, collapsible controls and a clear primary action. Keep controllers, IDs and save semantics intact. |
| P1 | Image-led project/library navigation | Room cover images, Resume room, meaningful status and version count; keyboard-accessible cards. Preserve text labels and empty/error states. |
| P1 | Clear result comparison and selection | Existing versions can be viewed A/B as well as against the original. Approve one baseline and refine that exact version without losing other ideas. |
| P2 | Multiple newly generated alternatives | An explicit result count and cost/usage confirmation; retain partial successes, no automatic billable retries, distinct IDs and parents. Currently generation returns one image. |
| P2 | Region-based edits, removal and protection | Brush/select a region, show its boundaries, send a compatible mask, composite where appropriate and test outside-region differences. Evaluate on the telephone/floor/appliance kitchen case. Do not claim precision guarantees until tested. |
| P2 | Reference materials and a design board | Distinguish a room angle from a material sample, inspiration image or sketch. Store the intended surface, finish, reference/source and notes. Export selected designs and swatches together. |
| P2 | Project organisation | Search/filter rooms and saved designs, useful version labels, reversible archive/trash/undo. Keep originals and restoration relationships safe. |
| Later | Measurement records, product links, budget and sharing | Use user-confirmed dimensions and source-linked specifications. User-entered budget is not a verified quotation; region/product availability needs validation. |
| Deferred | Full CAD/3D, live AR, retailer checkout, teams and billing | Treat as separate product stages, not prerequisites for reliable photo-based renovation. |

The first visual improvement should make the existing functionality easier to
use. More controls, styles or marketing badges alone will not solve unwanted
image changes or browser-session confusion.

### Current interface audit

Historical interface review before Focus Canvas. The current rendered assessment
is the whole-project audit at the beginning of this document.

Based on the actual Flutter widgets in lib/screens.dart and related controls:

- The working image follows the palette, saving panel, room analysis and photo
  controls. The room can be far below the initial viewport.
- Style, scope, appliance overrides, instructions and prompt details form a long
  vertical sequence. It is hard to change an option while seeing the room.
- Project/room lists and the favourites library rely mainly on small thumbnails
  and ListTiles, despite images being the core product.
- Explore, favourite, save-to-database, export and approve-baseline actions have
  different meanings. Make those labels consistent: Keep idea, Approve design,
  Save now and Export copy. Keep safety/status information close to its action.
- Advanced provider setup and full prompts compete with ordinary design work.
  Keep those available in collapsible detail panels; show connection/ready/error
  state without requiring the user to understand relay implementation details.

### Concrete proposed layout

Desktop: project/room breadcrumb, compact saving status and Save/Export actions;
a large working photo on the left; Style / Changes / Keep panels on the right;
room-view thumbnails and saved-option strip below the photo; one clear review
action. Compare and approve operate on the selected version.

Phone: same information and actions in a single column, with the room photo
first, comfortably sized controls, collapsible groups and a reachable review
action. Do not shrink desktop panels into unreadable columns.

Visual language: warm off-white background, restrained forest/teal accent,
charcoal text, consistent spacing and borders, larger photo areas and clear
selected/approved states. Retain sufficient contrast, text labels and keyboard
focus. Reuse Flutter's Material controls and current data/services.

### Retained review files

The earlier workspace prototype was superseded by the selected Focus Canvas
implementation; its disposable files were removed during cleanup on 19 November.
Current retained references:

- [Desktop widget capture](../output/design-review/focus-native-desktop.png)
- [Phone widget capture](../output/design-review/focus-native-phone.png)
- [Original selected B concept](../output/design-review/app-look-b-focus-canvas.png)

These captures use fictional sample photos and disposable in-memory storage.
They are not evidence of physical-device acceptance or paid AI quality. Original
kitchen photo/concept review copies are retained privately alongside them; the
actual project data, source photos and Chrome profile were not cleared.

The next implementation batch should cover the responsive workspace/navigation
and existing-version comparison first, followed by the multi-result/precision
work as separately tested feature batches. See CODEX_NEXT_STEPS.md.

## Pricing review

### Current refresh — 20 November 2026

This refresh takes precedence over the 14 November snapshot below. Public pages
and Australian App Store product lists were checked; no account, purchase,
checkout, image upload or paid generation was used. These are advertised consumer
prices, not competitors' underlying AI costs. Store catalogues may include old,
introductory or eligibility-specific products. They do not prove every offer is
available to a new customer, or establish Australian Android checkout prices.

**Public website offers.** Dollar currency was not explicitly identified in the
consumer pricing pages below; do not label these AUD or USD or convert them.

| Product / source | Recurring offer | Usage and other payment options |
| --- | --- | --- |
| [DecAI](https://decai.ai/pricing) | Plus $19.99/month, Pro $39.99/month; annual-view equivalents $4.99/$9.99 per month | Advertises 100/200 monthly generations. Non-expiring one-off packs: $29.99/100 or $69.99/300. Free: one web generation, watermarked. Annual equivalents are not monthly instalments; checkout totals/renewal terms were not confirmed. |
| [Renovate AI Studio](https://studio.renovateai.app/pricing), Trial and Error | Hobbyist $15/month, Pro $29/month, Max $99/month; current yearly promotion displays $5/$10/$33 per month, billed yearly | Usage described as more / 3× / 10× without absolute output counts. Pro adds estimation/staging/team tools; Max adds commercial/team/material features. Promotion duration, extra months, actual annual total and renewal price need checkout confirmation. |
| [Remodel AI](https://remodelai.app/faqs/), ReImage AI | Limited free renders followed by a paid subscription; FAQ directs customers to app stores | No numeric paid allowance or public web tariff established from this FAQ. Do not assume unlimited rendering. |

At full advertised usage, DecAI's monthly plans imply about $0.20 per included
generation; its packs imply about $0.30/$0.23. This is our arithmetic from its
published offers, not a model/provider cost estimate. Unused subscription allowance,
extra attempts, tools/quality and successful-result rate change practical value.

**Australian iOS benchmarks** (A$, separate from website offers and Android):

| Product / verified identity | Publicly listed purchase examples |
| --- | --- |
| [DecAI](https://apps.apple.com/au/app/decai-ai-home-design/id6502747597), COOL SUMMER LIMITED | Weekly A$9.99–14.99; annual A$49.99/59.99/99.99; annual sale products A$22.99/29.99; lifetime-labelled product A$79.99. The listing's description has different dollar examples, so use the regional product list as this benchmark, not as a verified checkout. Lifetime scope/AI allowance unconfirmed. |
| [Renovate AI](https://apps.apple.com/au/app/renovate-ai-house-design/id1661709494), Trial and Error, Inc | Explicit Weekly product A$14.99; Pro Yearly A$229.99; a product named PRO - 300 Credits A$14.99. Other PRO prices lack a period in their names. A credit is not established as one final design, and the 300-credit product's cadence/type is unconfirmed. |
| [Remodel AI](https://apps.apple.com/au/app/remodel-ai-home-design/id6446040791), REIMAGE AI INC. | Monthly variants A$9.99/12.99/14.99; yearly A$59.99/79.99/149.99; weekly A$7.99/9.99/14.99. Numeric paid render allowance not confirmed. |

**Name collision:** [remodelai.io pricing](https://www.remodelai.io/pricing) is a
different offer from ReImage's remodelai.app. Its App Store link identifies
app `6449718419`, while ReImage is `6446040791`. The .io page advertises annual
bills of $349/$599/$1,199, displayed as $29/$49/$99 monthly equivalents, with
1,000/5,000/25,000 monthly designs, model/quality tiers and three free designs.
Its header says unlimited but its cards give quotas; use the quotas pending
checkout confirmation. Currency is not explicit. Do not apply these allowances
to ReImage's app. Remodeled.ai and renovateai.io are further separate services.

Australian Google Play pricing was not verified: regional listing requests were
inaccessible, and the accessible .io-linked Android listing did not expose
subscription amounts. Mobile/web account portability, trial eligibility, renewal
price, refunds, credit expiry/rollover and render/credit conversion still require
the exact app's current paywall/terms. No iOS price is presented as an Android quote.

**Implications for RenoVision — recommendations, not implemented pricing:**

- Keep the confirmed Standard BYO-developer-key launch. Sell the project workflow,
  saved/refinable history, camera experience and control over provider/models.
  State before purchase that AI usage is billed separately by the user's provider.
  A lower app fee alone does not establish a lower total room-design cost.
- Test a modest one-off or annual Standard licence alongside monthly demand;
  homeowners may need the app for one project. No price has been selected, and
  earlier A$4.99/A$9.99 generation-pack ideas below are superseded launch hypotheses.
- Defer included-AI Pro until identical-room trials measure analysis, alternatives,
  refinements, failed billed attempts and support/payment overhead. Use bounded
  allowances with clear quality/count rules rather than promising unlimited AI.
- Compare cost per accepted room design, not credits or advertised images alone.
  Example test journey: one analysis, three concepts and two refinements, counting
  all billable attempts and recording which result the user accepts.
- Keep access/export of existing local projects independent of future AI balances.
  Treat the optional paid desktop companion and cross-device subscription rights
  as explicit later decisions, so phone customers understand any second charge.

Remaining pricing acceptance: inspect the three exact Android apps' AU paywalls
without purchasing; record offered period, annual upfront total, renewal price,
trial cutoff, included allowance, reset/expiry rules, top-ups and device coverage.
Then validate RenoVision's own costs/value with testers before setting prices.

### Historical snapshot — 14 November 2026


Checked 14 November 2026. Public information only; no account, checkout,
purchase, photo upload or billable generation was used. Prices and eligibility
can change. These are research findings and proposed experiments, not prices
implemented in Renovision.

### Published DecAI offers

[Web pricing](https://decai.ai/pricing), monthly view:

| Offer | Advertised price | Included generation allowance |
| --- | --- | --- |
| Free | $0 | 1 web generation; watermarked |
| Plus | $19.99/month (crossed-out $29.99) | 100/month |
| Pro | $39.99/month (crossed-out $59.99) | 200/month |
| One-off credits | $29.99 | 100 |
| One-off credits | $69.99 | 300 |

The page does not label the dollar currency; do not treat these as AUD.
Credit packs are advertised as non-expiring. Subscriptions renew automatically;
the FAQ says cancel at least 24 hours before renewal. Promotional renewal prices
and annual checkout totals were not verified.

[DecAI's own comparison article](https://decai.ai/blog/planner-5d-vs-decai)
advertises $4.99/month billed yearly, approximately $60/year, and a $199.99
lifetime option. This is a separate marketing source, not a verified annual
checkout or confirmation of the monthly plan's allowance on that offer. Do not
infer unlimited image generation from its promotional wording. Annual billing
requires the annual payment, rather than twelve optional $4.99 payments.

[Australian App Store listing](https://apps.apple.com/au/app/decai-ai-home-design/id6502747597):

| Listed purchase names | Australian prices |
| --- | --- |
| Weekly Premium variants | A$9.99 / A$12.99 / A$14.99 |
| Yearly Premium variants | A$49.99 / A$59.99 / A$99.99 |
| Yearly Sale variants | A$22.99 / A$29.99 |
| Lifetime | A$79.99 |

These are multiple listed products, not a guarantee every customer can choose
every offer. Eligibility, allowances and lifetime entitlements are unverified.
The Australian Google Play listing was inaccessible to this research tool;
Android prices remain unverified. Do not substitute iOS prices for Android.

### What this means for Renovision

DecAI's annual offers are already inexpensive. A lower upfront payment could
appeal to a homeowner renovating one room, but we cannot claim lower cost per
usable design until quality, included outputs and retry rates are measured.
DecAI already sells credit packs, so pay-as-you-go alone is not a unique feature.

Recommended initial commercial experiment after the prototype works reliably:

| Proposed offer | Test price | Scope to validate |
| --- | --- | --- |
| Local project workspace | Free | Original photos, preferences, saved versions and local backups; paid AI use separately capped |
| Starter pack | A$4.99 once | A small, explicitly bounded number of AI outputs; count set after cost testing |
| Larger room pack | A$9.99 once | More alternatives/refinements; show the exact remaining allowance before each generation |

These prices are hypotheses, consistent with the brief's approximate A$5
homeowner entry point. They do not establish profitability or a launch promise.
Keep subscriptions for demonstrated repeat demand. Avoid unlimited AI or a
lifetime payment that promises ongoing uncapped generation. Buying a design
pack should not determine whether someone can keep their existing local work.

For the user's desired workflow, three alternatives plus two refinements mean
five image outputs, plus photo analysis/prompt drafting. That is a useful test
bundle, not yet a promise that five outputs fit within the proposed starter
price. All follow-up attempts must be counted in the cost study.

### Cost validation before fixing the allowance

The current local relay defaults to `gpt-image-2.5-sunburst`, low quality, one
image per request, with `gpt-6-luna` for analysis. These are configuration values,
not evidence of model availability, current provider prices or actual costs.
No live cost benchmark or model-specific price was established in this review.

Measure the full photo-to-selected-result journey with the intended supported
provider/model before advertising output counts. Record analysis, each image
output, refinements, retries, input-image processing and high-resolution export.
Use current official provider billing, then allow for payment/store fees,
applicable taxes, hosting/storage, support and refunds. Keep currencies explicit.

For a conservative pack calculation:

    generation budget = net pack receipts - other variable costs - target contribution
    maximum outputs = floor(generation budget / conservative measured cost per output)

Include analysis and failed/repeated attempts in the measured workflow cost;
do not assume a failed provider request is free. Test a range of rooms and
multiple reference photos, rather than basing the allowance on the cheapest
single request. Show quality and output-count choices with their usage cost.
Protect the business with server-side allowances, usage records and spend caps;
never expose the provider key in the distributed Flutter app.

Before monetisation, finish reliable restart/resume testing, the visible
analysis-to-design flow, selection/refinement and output adherence. A cheaper
price will not compensate for lost projects or repeated unwanted changes.

## Camera workflow



Recorded 14 November 2026; reconciled 19 November. Embedded camera capture,
frozen comparison, manual same-view overlay and consented Live design are
implemented initially through 1.0.11. APK 1.0.12 also packages the main camera
handoff/automatic result overlay fixes and room-first Live entry. The user reports
useful earlier overlays; these later fixes still need phone acceptance.
Continuous, consistent whole-room AR is a separate milestone; composite exports
are not yet implemented.

### Updated first milestone and acceptance

Open a room's Camera Renovation View; show a responsive embedded camera feed.
Choose style/palette and explicitly capture the current view for generation.
Show genuine request progress while keeping the captured viewpoint available;
generation is asynchronous, not an instantaneous transformation of video frames.
When the result arrives, immediately enable a slider/opacity comparison against
that frozen source frame. Save the clean original, result and settings to the
existing room automatically, with the existing retry/error handling. Refinement
starts from the selected saved result. This frozen-frame milestone is distinct
from a later overlay on the running camera, which needs manual viewpoint alignment.

Accept on Android only after checking permission denial, portrait/landscape crop
and orientation alignment, app background/resume, failed/interrupted requests,
source/result persistence after restart and no extra requests when moving the
slider or phone. Manual camera overlays must be labelled approximate and should
be hidden or realigned by the user after viewpoint changes; automatic mismatch
detection must not be claimed before it is implemented and tested.

Technical references checked 18 November:
[OpenAI image generation](https://developers.openai.com/api/docs/guides/image-generation)
documents latency limitations (complex requests may take up to two minutes);
[ARCore session configuration](https://developers.google.com/ar/develop/java/session-config)
documents camera frames and device poses. Neither supplies instantaneous,
view-consistent whole-room renovation from one generated still image.

### Intended experience

Open a room, point the phone at it, choose the renovation direction, preview
alternatives, save the view that looks promising and refine it in the same app.
Keep the original capture, selected design and follow-up versions together so
the user can resume without repeating their setup.

### What other products document

| Official source | Documented experience | Distinction |
| --- | --- | --- |
| [DecAI FAQ](https://decai.ai/faqs) | Analyses an uploaded room photo and generates a design | A camera photo can supply the image, but the reviewed documentation does not establish continuous, tracked whole-room transformation. |
| [Dulux Visualizer](https://www.dulux.co.uk/en/expert-help/see-share-paint-introducing-updated-dulux-visualizer) | Previews wall colours in real time | A live surface-colour preview, rather than a complete renovation. This is a UK product source, not a verification of Australian availability. |
| [Roomle app listing](https://apps.apple.com/sg/app/roomle-ai-3d-room-planner/id732050356) | Advertises augmented reality and 3D live view alongside room planning | Camera/AR viewing already exists in this market. The listing does not establish generative renovation of every video frame. Device/region availability was not tested. |
| [IKEA Kreativ help](https://www.ikea.com/us/en/customer-service/knowledge/articles/e308d20e-895e-47ce-9aba-2f30c0d98a75.html) | Photo-based design, furniture placement and whole-room scanning on supported LiDAR devices | Room scanning and later design are distinct from an AI redesign that continuously follows a moving camera. |

These are documented/advertised capabilities, not independent device tests.
Avoid claiming camera input is unique or that competitors offer only uploads.

### What exists in this repository

`room_camera.dart` wraps the camera package for embedded preview/capture and
serialized lifecycle operations. `camera_room_view.dart` provides capture,
comparison and manually aligned flat overlays. `live_design_screen.dart` keeps
consented automatic still capture/analysis, options, confirmed image generation
and saved result overlay in the viewer, then explicitly continues to refinement.
Image picking/gallery import remains available. There is no continuous frame
analysis pipeline, pose/depth tracking, AR room model or moving-view renderer.

Original photos, supporting room views, preferences, AI analysis, generated
versions and approved-baseline refinement already provide much of the storage
and design workflow to reuse. Multi-option generation is now implemented as
two or three sequential saved image requests; it is not continuous video generation.

### Suggested stages

1. **Camera capture into the existing room workflow (implemented, acceptance ongoing).** Verify the current still
   camera path first. Design a guided capture/review screen, then show visible
   analysis and editable preferences. Generate explicitly bounded alternatives,
   choose one and refine from that selected design. Save each result immediately
   to its room; keep draft autosave behaviour and explicit save controls.
2. **Return-to-view comparison (implemented as a manual same-view overlay).** Display a saved design with adjustable opacity
   over the camera to help the user return to the original viewpoint. Start with
   a clearly labelled manual alignment aid. It is an approximate 2D comparison;
   moving to a different angle does not reveal a valid new design view. Pause or
   prompt to realign when the view no longer matches. Never describe this as a
   measured 3D model or reliable tracked AR.
3. **Tracked surface previews (future).** Investigate wall/floor selection, camera pose,
   surface mapping and material projection on supported Android hardware.
   Preserve openings and handle objects blocking surfaces. Validate tracking
   loss, occlusion, lighting and scale before claiming realistic live preview.
4. **Consistent whole-room AR (future).** A separate later investigation into room
   geometry, a persistent approved design and rendering from new viewpoints.
   Independent AI edits of successive frames can change the design between
   views. A successful image edit does not prove consistent moving-camera AR.

[ARCore anchors](https://developers.google.com/ar/develop/anchors) and
[depth/occlusion](https://developers.google.com/ar/develop/depth) document
components relevant to the later Android stages. They do not themselves turn a
generated flat image into a navigable renovation.

### What a snapshot must save

- The clean source camera frame as an immutable original, separately from any
  preview graphics; retain timestamp/orientation and source-room association.
- The actual rendered design/preview as a separate version, with the selected
  design ID, parent, prompt, palette and Keep/Replace preferences.
- Preview type and alignment/crop information where available. Label approximate
  camera composites so they are not mistaken for verified new-angle designs.
- Export/share a clean image without app buttons. For later AI refinement, use
  the clean capture or selected generated design as appropriate; keep overlays
  and annotations explicitly separate instead of baking the app UI into input.

Taking a snapshot should not silently trigger an AI request. Camera permission
does not imply permission to transmit a continuous video stream. Generate only
on an explicit action, show output count/usage and preserve partial successes.
Continuous cloud generation requires a separate cost/performance study.

### Testing and near-term priority

Continue Chrome on Windows for the project, saved captures, preferences,
generation/selection, refinement and restart tests. Use Android device tests for
real camera behaviour and any later tracking; desktop Chrome does not establish
phone AR performance. Retain gallery upload as an equivalent entry point for
existing photos and devices without the camera/AR capability.

Preserve reliable saving and the in-app photo-to-refinement journey. Validate
the latest same-view camera handoff/overlay on the phone before selecting an AR
dependency. Tracked rendering and clean composite export remain future work;
the existing manual overlay and five app themes are already implemented.

## Earlier roadmap

> Historical planning from 12 November 2026. Stage labels, setup tasks and initial acceptance checklists may be superseded by FEATURE_STATUS.md and CODEX_NEXT_STEPS.md. Optional private AI testing now exists; earlier no-AI planning is not the current implementation status.

**Working name; Android first; Flutter project; 12 November 2026.**

### Product vision
A privacy-conscious home renovation visualisation app: photograph a real room, explore ideas, save/reject alternatives, crop/zoom, mask a specific region, annotate with rough drawings or Paint sketches, refine an approved version without unexpectedly changing unrelated features, and maintain a local, portable project library.

One app; consumer, tradie and enterprise feature tiers later. iOS from shared Flutter source when ready. No public release during Stage 1.

### Non-negotiable design principles
- The original uploaded photo is **immutable**; keep an unmodified source copy and derivatives.
- A user-approved image is the **locked baseline** for each subsequent edit. Never silently switch to an earlier image or regenerate the whole room when an area is selected.
- Support **Explore** (creative full-room changes) separately from **Precision Edit** (selected-area-only corrections).
- Every edit tracks input image hash/id, prompt, mask/sketch, model/provider, result, approval/rejection, and parent version.
- Preserve project choices as structured **room memory**, including locks for windows, doors, architectural openings and floor edges.
- Prefer masked image editing and compositing when supported. Crop with adequate surrounding context, then blend result back into the unmodified image. Full-room generative regeneration is *not* reliable for exact changes.
- Compare output with baseline; highlight changes outside an editable area. This is a warning, not a structural guarantee.
- Keep projects and photo files on-device; add export/import and backups. No mandatory account for basic use.
- No API keys, photos, addresses, or payment credentials in source control. No AI processing during the UI-only prototype.

### Stage 0 — Developer setup
- Windows PC: VS Code already installed. Install Git, Flutter via the official VS Code extension, GitHub account/private repo, then Android Studio/SDK/AVD.
- Verify `git --version`, `flutter doctor`, `flutter devices`, `flutter run -d chrome`, `flutter test`.
- Avoid native Windows desktop build until needed (requires full Visual Studio desktop C++ tools, separate from VS Code).
- Optional IDE AI assistant: official OpenAI Codex or GitHub Copilot; use it for **coding**, not as the app's production AI service.

### Stage 1 — UI proof of concept (no AI/server/payments)
- Responsive app shell and navigation: Explore, Projects, Library, Settings.
- Project creation, room list, sample assets, local draft data model.
- Design preference browsing: skip/save; store saved idea and feedback.
- Later in Stage 1: import photo, rotate/zoom/crop, selected-area masks, simple sketch overlay; before/after compare; branch/restore versions; export/import project.
- Acceptance: works on Chrome and Android emulator; sample design interaction works; no cloud requests; no real photo leaves device.

### Stage 2 — Persistent local library and editing
- Durable project store (e.g. SQLite-based abstraction with platform implementation); photo files stored in app-private directories, with explicit project export/import.
- Separate original, approved baseline, current candidate and rejected branches.
- Edit records: project_id, room_id, source_id, parent_version_id, selection region/mask, prompt, locks, provider, timestamp, output id, approval state.
- Validate shutdown/restart, deletion, low storage, permission changes and failed imports.
- If browser prototype uses temporary storage, warn users; Android persistence is the source of truth until robust web persistence is implemented.

### Stage 3 — AI provider experiment
- Start with manual share-to-ChatGPT/Gemini/import workflow; inspect whether full photo + precise prompt is preserved through sharing.
- Optional developer-only controlled API experiment with ONE image-edit model: compare full-image edit vs crop + mask + compositing.
- Build a provider interface: `generateDesign`, `editSelectedArea`, `capabilities`, `usageEstimate`, `cancel`.
- Customer API key is NOT the same as their ChatGPT subscription. Do not embed reusable secrets in a distributed app. Confirm provider terms and a secure relay or delegated auth before enabling bring-your-own-key in public builds.
- Prepaid generation bundles and in-app billing deferred until outcomes and costs are measured.

### Stage 4 — Claylands benchmark and quality gates
- Test with original before photos (office/dining, kitchen, exterior), with user's permission and local-only test assets.
- Cases: remove fireplace; retain broad rear windows; only fix hallway passage/wall trim; change one cabinet; only fix skirting edge; preserve camera perspective; keep previously approved lighting/furniture; integrate sketch drawn in Paint.
- For every case: record expected edit region, non-edit lock mask, baseline output, result, provider, actual charge, user rating and corrections needed.
- QA metrics: outside-region pixel/perceptual change, room geometry consistency, prompt adherence, revision rework count, generation cost, crash rate.
- A pretty output that changes unrelated walls or windows **fails** precision mode.

### Stage 5 — Android distribution to private testers
- Chrome for rapid UI iteration; Android Studio emulator for Android behavior; USB or wireless connected physical Android phone for camera/pinch/gesture/permissions.
- Use `flutter run` for debug installs, then `flutter build apk` for private APK testing. No Google Play account required to run personal-device debug builds.
- Test APK signing, package identifiers, reproducible build, permissions, data export and safe failure when AI unavailable.
- Review side-loading warnings and only share private builds with trusted testers.

### Stage 6 — Public launch
- Before public launch: security/privacy review, provider data-processing review, AI content reporting/policy review, accessibility, crash reporting with privacy controls, terms and privacy policy.
- Google Play Console developer registration, listing, screenshots, release signing, developer verification and applicable closed-testing gate.
- Build Android App Bundle (`flutter build appbundle`), submit via Play Console. Prepare one app with feature tiers and Google Play Billing for digital content.
- Pricing to test: one-room free trial, optional paid local project/pro features, prepaid generations (capped), watermark only when our paid AI service provides an unlockable preview.
- Track net unit economics: gross revenue - store fees - AI inputs/outputs/retries - infrastructure - refunds/support.

### Stage 7 — Later expansion
- Level 2 camera-aligned comparison (not live generative AR), device capability detection and fallbacks.
- Tradie features: separate clients, branded exports, job folders, controlled sharing, team review.
- Enterprise: central accounts and storage, tenancy isolation, access roles, governance/compliance, billing and audit logs.
- iOS: reuse most Flutter/UI/business logic; Mac + Xcode for iOS builds, testing and release; platform-specific camera, storage and in-app purchases adaptation.

### Initial architecture sketch
```
Flutter UI
  -> Project controller / room design state
     -> Local project repository + photo storage
     -> Edit workflow (prompt builder, crop, mask, sketch, approval)
     -> AI Provider Adapter
        -> Manual handoff/import (Stage 1-3)
        -> Secure API service / approved delegated auth (future)
     -> Export/import service
```

### Privacy/security checklist
- Make original images immutable; encryption at rest where appropriate; avoid saving photo EXIF/geolocation.
- Default local-only storage. For cloud edits, obtain informed consent before transmission and identify the provider.
- Use private code repo, `.gitignore` for sensitive files, strong GitHub MFA; do not commit tokens, test photos or release signing keys.
- Platform backups may back up app data; review Android backup rules and communicate data handling truthfully.
- Public API service must authenticate/limit generation usage and prevent abuse; do not trust client counters.
- Export and delete functions, readable data-retention disclosure, provider retention review and breach response planning before launch.

### First demo acceptance checklist
- [ ] Flutter SDK installed and `flutter doctor` runs
- [ ] Private GitHub repo created
- [ ] `flutter run -d chrome` opens Renovision demo
- [ ] Explore > Save idea > Library shows saved concept
- [ ] Projects > Create project adds a project
- [ ] `flutter test` passes
- [ ] `flutter analyze` is clean
- [ ] Android emulator starts app
- [ ] First real photo import milestone planned (not part of starter)

### Official references
- Flutter install via VS Code: https://docs.flutter.dev/install/with-vs-code
- Flutter Android setup: https://docs.flutter.dev/platform-integration/android/setup
- Git for Windows: https://git-scm.com/install/win
- GitHub private repo setup: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
- Flutter Android deploy: https://docs.flutter.dev/deployment/android
