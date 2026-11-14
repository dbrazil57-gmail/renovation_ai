# Renovision feature status

Updated 14 November 2026. Product requirements: RENOVISION_PROJECT_BRIEF.md.
"Implemented" means present in code, not necessarily verified on a real device.

Latest automated checks: all 63 VM/widget tests pass; static analysis is clean;
the web release build passes.
Existing user data was not opened, cleared or migrated during these checks.

## Implemented

| Feature | Status / practical limit |
| --- | --- |
| Explore, Projects, Library, Settings | Working app navigation |
| Projects and rooms | Create named projects and rooms |
| Rename projects/rooms | Pencil control in each project/room header; names update without changing IDs, photos or history |
| Photo import | Gallery/file picker; originals saved separately |
| Multiple room photos | Up to six views per room, bulk upload at creation or later, and a persistent primary-view choice |
| Combined AI context | Working image first, other room angles as optional supporting inputs; all input views previewed before consent and tracked in version metadata |
| Colour palettes | Seven coordinated presets with named swatches, hex references and suggested surfaces; choose after uploading a new room or change later in its workspace |
| Visible palette controls | Palette panel appears above room photos; choose directly from the swatch strip or open the full chooser |
| Saved colour direction | Palette preference persists with the room, survives backup/restore and enters copied / in-app AI prompts; previous versions retain the palette text used in their saved prompt |
| Design style choices | Tick Modern, Contemporary, Classic and other styles; add Other / extra direction; preferences persist and enter prompts |
| Scope-aware prepared prompts | Distinguishes a coordinated renovation from a precision correction, handles "nothing to retain", respects layout/style/palette priorities and asks for missing photos |
| Prompt preview | Live preview of locally prepared text; clearly labelled as not AI-written |
| Draft autosave | Local saves for instructions, protections, styles and mode; visible saving/saved/failure state, manual retry and pending-save handling on normal back navigation |
| Local persistence | Hive metadata and image boxes; isolated file-reopen tests pass |
| Immutable originals | Edit/generation flows create separate images and versions |
| Image viewing | Workspace zoom/pan |
| Crop | Rectangular crop saved as a new reference |
| Sketch / markup | Draw on a copy; reset and undo strokes |
| Version history | Select versions, branch edits and track parent IDs |
| Approved baseline | Explicit approval retained when reopening a room |
| Favourites / pass | Buttons, swipe review and favourites Library |
| Review status | History labels distinguish passed, pending and favourite designs; review menu can return an idea to Explore |
| Before / after | Slider comparison against original; differing crops may not align |
| Room instructions | Save requested changes and protected-feature text |
| Design styles | Ten tickable style choices plus Other free text; saved per room and included in prompts/backups |
| Draft autosave | Text, styles, mode and layout preference save after a short pause; status, retry and save-before-Back handling |
| Prompt preparation | Scope-aware local template, layout preference, broad-request hint and prepared-prompt preview; not AI-authored |
| Explore / Precision modes | Different prompts; precision is not technically enforced |
| Manual AI handoff | Copy prompt and import external result |
| In-app OpenAI integration | Local relay, private key entry, consent, new-version saving and failure handling; tested with simulated responses only |
| AI edit metadata | Source image ID, parent, prompt, provider/model and request ID |
| Image download | Metadata-free PNG copy of selected image; originals remain intact |
| Project backup | Versioned .renovision.json file with exact photo bytes, instructions, versions, approvals, favourites and AI edit metadata |
| Backup restore | Validates photo checksums/references; adds a new project with remapped IDs, without replacing existing projects |
| Clearer local workflow | Current-image badges, optional collapsed AI controls, backup and download controls |

Backups include original photo metadata and should be kept private. Prototype
limits: 64 MB total photo bytes / 100 MB backup file. Browser download requests
do not prove a file was kept: check the downloaded file and test restoring it.
File transfer targets Chrome and Android; native Windows desktop export is not
implemented. Android file choosers and camera capture need device testing.

Multi-view AI creates one design from the working viewpoint; it does not create a
measured 3D reconstruction, panoramic stitch or guaranteed consistent geometry.
AI request limits: seven input images maximum (a design + six room originals),
18 MB per image and 36 MB total before metadata removal/resizing. All views count
toward provider input usage. Live multi-view design quality remains unverified.
New backups use format version 2; the updated app also restores version 1 backups.

Palette choices: Warm neutrals, Charcoal & walnut, Sage & oak, Coastal blues,
Navy & stone, Earthy terracotta, Soft monochrome, or No palette preference.
Palettes guide future designs, not existing-photo recolouring or exact paint-brand
matching. Protected features and precision edit boundaries take priority. Older
rooms/backups without this optional preference remain readable.

## Implemented but awaiting live/manual verification

- The user's saved test example in the existing Chrome profile/address.
- Real browser download, file chooser and restore behaviour.
- Chrome persistence after closing/reopening the actual user app session.
- Live OpenAI generation: user currently has a subscription/login, not an API key.
- Android build, emulator/device, photo permissions/camera, file save/restore,
  interrupted picker recovery and restart persistence.
- Automated Chrome tests previously stalled during Flutter bootstrap; passing
  VM/widget tests and a web build do not establish interactive browser behaviour.

## Not implemented yet

- AI-authored, user-editable prompt drafts based on room photos/preferences.
- Multiple generated design options in one requested batch, with selection and
  refinement from the chosen option. See AI_DESIGN_WORKFLOW.md.

- Brush/selectable edit masks with saved mask geometry.
- Structured locks for windows, doors, floor edges and other room features.
- Crop + masked edit + compositing into the unchanged full-room image.
- Outside-region change detection and visual warnings.
- Separate reference/result types and editable sketch/annotation history.
- Dedicated Paint/sketch reference attachment workflow (ordinary images can be imported).
- Rotation, eraser and brush controls.
- Delete projects/rooms and versions; review filters and richer rejected-version management.
- Stronger protection against browser/process shutdown and persistent backup scheduling.
- Comprehensive startup/storage corruption, low-space and interrupted-import recovery.
- Persistent Android AI connection settings / secure production backend.
- Guaranteed encrypted-at-rest photo storage.

## Deferred beyond private Stage 1 testing

- Payments, credits/subscriptions, purchase verification and production billing.
- Public hosting, customer authentication and public API service.
- Play Store release, signing/distribution and launch compliance work.
- Camera-aligned overlays and live AR/video transformation.
- Tradie/client/job features, branded exports and team/enterprise roles.
- iOS build/device verification and release.

No API key is needed for local photo, version, download or backup work. See
AI_TEST_SETUP.md when ready to test provider calls, and CODEX_NEXT_STEPS.md for
the next acceptance checks.
