# Testing and storage reference

Updated after the whole-project audit, 19 November 2026. Use
[feature status](../FEATURE_STATUS.md) for implementation limits and
[next steps](../CODEX_NEXT_STEPS.md) for the ordered backlog. Earlier dated test
instructions have been consolidated here; no real project data was changed.

## 20 November source follow-up testing

These changes are after APK 1.0.12 and need a new package only when requested.
All 258 local tests pass; static analysis is clean. New coverage checks first/
collapsed AI settings and appearance, model presets without generation, safe
toolbar deletion, separate saved precision counts and three strictly scoped
correction requests from one source. Existing originals/baselines are preserved.
The targeted Chrome runner stalled in its JavaScript test iframe before running
tests; its diagnostic reported a responsive host with no pending network requests.
The isolated runner was stopped. Do not count that browser attempt as a pass.
Release-web compilation passed separately in 74.9 seconds, recorded in the
feedback logs; it does not establish browser interaction acceptance.

Logs: `output/feedback-2026-11-20-analysis.log`, `-focused-tests.log`,
`-regression.log`, `-chrome-tests.log` and `-web-build.log` with the same prefix.
All application AI responses in these checks are synthetic; the brand board was
generated separately with built-in imagegen, without the app key/customer photos.

Next acceptance after the requested package:

1. Settings: AI connection and models is the first card, shows status and opens
   on tap. Home cover/Storage/Appearance use the same expandable-card pattern.
2. Connected OpenAI: try Room design, Quick ideas and Final detail. Check model/
   quality change without an API request. Fresh direct connections prefer available
   2.6 Sunburst/medium; saved choices remain unchanged unless selected explicitly.
   Older saved connections show the previously selected model until Refresh
   available models checks account access. The saved Android key is reused, no
   photos are sent, and a valid saved model/quality is not changed by refreshing.
3. Choose a saved design and tap Delete next to crop/markup. Cancel, delete/undo,
   and try an approved baseline. Originals stay protected and deletion is recoverable.
4. Refine: switch New design / Precise correction without opening advanced help.
   Whole-room mode offers 2/3 ideas; correction mode offers 2/3 scoped variations.
   Each explicitly confirmed result is a separate paid request. Counts save
   independently; old projects keep a one-output correction default.
5. With little/no brief, test a New design for substantial coordinated changes.
   Check architecture, layout and Keep choices, not merely attractive styling.
   For an older reviewed AI prompt marked stale, reanalyse with consent or deselect
   its use to preview the new deterministic brief. Do not silently repeat analysis.

Gemini is not integrated by these fixes. It requires a separate Google key and
adapter. Claude is an optional analysis/prompt-writing candidate, not an image
generator. The OpenAI key cannot authenticate with either provider.

Live-room naming check (same source-only follow-up): start through the room
picker with Bedroom and Live design; the room should display **Bedroom (Live)**.
Confirming Kitchen instead should produce **Kitchen (Live)**. The label must
survive a project backup/open and leave originals intact. An explicit custom
rename must stay unchanged when the type later changes. Older Live room / Live
view / Room (Live view) placeholders use the same type-based display; an unknown
type shows Unspecified (Live) until selected. No existing room names are migrated.
Naming verification: 39 focused tests and all 258 regression tests pass; analysis
is clean. Logs use `output/live-room-labels-2026-11-20-` with `focused.log`,
`analysis.log` and `regression.log`. No APK, paid AI request or browser rerun for
this naming-only correction.

## Current source and phone package

Latest test APK: **1.0.12+13**, source `3cb94c972c`:
`output/mobile-test/renovision-test-1.0.12.apk`, alias `renovision-test.apk`.
SHA256: `CD3A047F2D84C515B279F2686B506017AB1A46199A00038A23B410799A88CB99`.
Size: 76,231,742 bytes. Its application ID/signature match 1.0.11 for an in-place
update. Previous APKs 1.0.11/1.0.10 are retained with unchanged checksums;
obsolete 1.0.8/1.0.9 were removed during cleanup. Development signing is not
public-release signing. ARM64, optional camera and internet are verified; no
microphone/storage-write permission or private project/credential assets.

Packages the completed source through `a948da0`: camera handoff/automatic overlay
fixes, version-history captions, compact room selection/live entry, simpler room
lists, smaller typography, five themes, storage details and optional password-
protected backups. All 249 tests rerun and passed, analyser clean, Android build
passed in 139.1 seconds. S21 acceptance remains. **Do not build another APK unless
the user asks.** No real AI calls or stored-user-data changes during packaging.

Start the phone test by installing over the existing app, opening the existing
project and checking its photos/versions/AI connection. Then test Camera → Live
design → analysis/options → generation → immediate overlay without leaving the
viewer → Continue to refine. Also check history captions, compact room choices
and Settings themes/plain/protected project backups. Confirm prompts before
paid requests; storage/theme tests need no AI calls.

## Windows preview

```powershell
cd C:\Dev\renovision_ai
flutter pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1
```

Use **http://localhost:7357**, the same normal Chrome profile, and no Incognito.
Do not replace the profile or clear its storage. A different scheme/host/port or
profile has a different project store. The launcher deliberately avoids Flutter's
temporary Chrome profiles. Settings > App build and saved data identifies the
running build/origin and project/room/image/version counts.

Check local saving writes/reads disposable diagnostic records in the current
stores. Reopening the same address/profile and confirming real project contents
is the persistence test. Do not interpret a successful diagnostic as a backup.

## Saving and storage

### Working copies and portable files

- Local metadata/preferences/history use Hive `renovision_records_v1`; image
  bytes use the separate `renovision_photo_bytes_v1` box. Existing IDs/boxes remain.
- Imports/captures/generation save new image records immediately. Originals are
  kept separate from generated results, crops and markup references.
- Room draft text/style/mode choices autosave after a short pause. More tools
  holds the Autosave shortcut; compact status shows saving/saved/failure.
- Manual Save now and normal Back/Save and close wait for pending drafts and
  received unsaved results. Save on normal exit still applies with Autosave off.
  Browser/process termination cannot guarantee completion of async work.
- Portable Save project/Save as/Back up project includes all rooms, original bytes,
  saved versions/prompts/approval and current room choices/setup/analysis. API
  keys/relay codes are never part of that file. Individual designs do not yet
  contain a complete structured snapshot of the settings used to create them.
- Save as can create a separate local project copy, export an image or write a
  project file. Image export is metadata-free PNG; project exports preserve exact
  originals and may therefore contain original metadata as well as private photos.
- Open project and Restore currently both import a separate local copy with new
  IDs. Open does not yet resume the matching previous local copy. Avoid repeatedly
  opening one file if a suitable local project is already listed.
- Chrome can update a file while its selected handle stays linked during that
  app session. After restarting, selecting the file imports/relinks a copy.
  Android uses its system Create/Open Document chooser; the app does not persist
  a writable URI for later same-file Save. Other browsers can download a copy.
- Protected backup files are deliberately not linked to plaintext automatic saves.
  Local autosave continues; create another protected backup to update that copy.

Use Settings > Storage and privacy for the actual native store paths or browser
origin, copyable details, export behaviour and current protection. Changing a
backup destination does not move the internal Hive database. There is no app-managed
cloud sync. Android's OS-managed backup/transfer policy for non-secret project
files still needs an explicit product decision; do not promise those files are
excluded merely because API-key preferences are excluded.

### Plain and password-protected backups

Plain projects use **`.renovision.json`** and are readable without a password.
Optional **Password-protected backup** uses **`.renovision`**, AES-256-GCM with
fresh salt/nonce and PBKDF2-HMAC-SHA256 (600,000 iterations). The header is
authenticated; wrong passwords/tampering fail before records are written.
Current encrypted-file size limit is 100 MB. Native crypto work is off the UI
isolate; browser file preparation can still take visible time.

Passwords are not stored or recoverable. This protects the portable file, not
existing local databases/photos. No existing store was migrated/encrypted.

Safe acceptance on disposable copies:

1. Save a plain and protected copy to chosen locations. Check that a cancel leaves
   local data intact and both filenames/extensions are clear.
2. Open them on Chrome and Android. Cancel the password prompt, then try a wrong
   password; neither should create a partial project.
3. Open with the correct password. Compare every room/photo, prompt, choice,
   history link, approved baseline and setup state against the source copy.
4. Generate no AI image for this storage test. Confirm credentials were not imported
   and that protected files cannot receive a plaintext autosave overwrite.
5. Close/restart and check local project/appearance settings. Repeat with a larger
   disposable project and interrupted/failed writes before trusting a new release.

### Local settings and Git

Ignored: local environment/config files, `.vscode/`, `.aws/`, `.codex/`, `.local/`,
`local_data/`, `private/`, `secrets/`, browser profiles, `output/`, local databases,
`*.renovision.json` and `*.renovision`, signing keys and recovered projects.
Use placeholder-only `.env.example` if setup needs an example.

Ignore rules do not redact tracked history. Two private kitchen output files
remain in commit `f94fe9b`; their local copies were kept when untracked. Review
history before publishing. Source snapshots are not photo/project backups.

## Recovered projects

14 November recovery found earlier tests in cached browser databases under four
localhost ports. It read isolated copies and exported validated portable files;
the original cached databases were not opened by the recovery browser or cleared.

[Latest recovered Claylands kitchen](../recovered_projects/browser-recovery-20261114071955480959/port-61028-project-1.renovision.json)
contains two room views, the saved handleless-bench instructions, Layout protection,
Charcoal & walnut and Contemporary (now labelled Modern / Contemporary). That
historical attempt had no imported design version; later in-app work is separate.

| Other preserved filename in that folder | Historical content |
| --- | --- |
| `port-7357-project-1.renovision.json` | New / Kitchen, one saved design |
| `port-58523-project-1.renovision.json` | Claylands / Kitchen, two views |
| `port-59613-project-1.renovision.json` | Claylands / Kitchen, one view and earlier instructions |

Restore a recovery file once through Settings, then resume its listed local
project at the fixed address. Restore adds a copy; it does not overwrite a newer
project. Keep all these private files and `.local_backups/` ignored.
Images made in another AI website enter Renovision only after **Import generated
AI result**. Copying a prompt does not import the returned image automatically.

## AI test setup

### Independent Android internet connection

1. Open Settings > AI connection and models. Disconnect a laptop relay if needed.
2. Choose **Internet API**, enter the personal OpenAI developer API key privately,
   then **Connect OpenAI over internet**. The connection checks available models;
   it does not generate an image. Select a supported model/quality shown by the app.
3. Open the room, choose its working image and confirm a separate analysis request.
   Review observations/questions and the editable draft prompt.
4. Choose whether to use that AI-written prompt. Confirm generation separately.
   Each analysis/image request uses the provider account; selecting a theme/style
   or merely uploading a photo does not itself run cloud AI.
5. Restart Android and verify local projects and the saved connection. Disconnect
   and remove API key clears that device's saved key, not project images.

Android encrypts the saved key with Keystore and excludes its secret preference
from OS backup/transfer. Chrome direct mode keeps the key in memory for that
session only, so reload requires re-entry. Projects do not transport credentials.
No shared key is embedded in source/APK. A subscription login is not an API key.
The independent phone route uses fixed OpenAI HTTPS endpoints, rejects redirects
and does not silently retry requests. No laptop or `adb reverse` is needed.

The existing in-app provider is OpenAI only. Other image providers would require
an adapter/capability checks and testing; provider-neutral copy/import works with
any external tool that supports the requested image task. The app does not log
into ChatGPT, Gemini or Claude subscriptions. Historical model/pricing research
in Product notes is dated; it is not a verified current access or cost guarantee.

### Optional Windows relay

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_ai_relay.ps1
```

Enter the key in its hidden terminal prompt, never chat/source. Keep that terminal
open. The launcher uses the key in the process environment and prints a temporary
local connection code, not the provider key. Stop it with Ctrl+C. A restarted
relay changes the code. It is development infrastructure, not a public backend.

Choose Laptop relay in app Settings and use its address (normally
`http://127.0.0.1:8787`) plus connection code. Remembered relay settings are stored
separately from projects in the same device/origin. A startup health check can
reconnect to that relay without sending photos or making a paid generation.
A new code must be entered if it changed. Relay health is not proof of provider
billing/model access.

### Analysis, concepts and refinement

1. Import/capture up to six original views of the same room. Select a primary
   viewpoint and optionally other views as AI context. A saved/approved result
   can become the working image; references must not undo its accepted design.
2. In whole-room mode, set the room/style/palette and goal. Default scope includes
   coordinated surfaces, fittings/appliances, lighting and loose-clutter removal.
   Keep text and optional room-specific Keep/Replace overrides take precedence.
   Request removal of uncertain fixed fittings such as an old wall handset explicitly.
3. Analyse room photos: check the upload previews, model and preferences before
   consenting. A successful analysis saves visible observations/questions and a
   draft; it cannot establish hidden construction, accurate dimensions or a 3D model.
4. Review/edit the draft and select Use this AI prompt if desired. The offline
   fallback is a deterministic template, labelled as such. In the normal workspace,
   changed preferences can invalidate a reviewed prompt; reanalyse or deselect it.
   Separating photo facts from design choices is an outstanding improvement.
5. Select one/two/three concepts and confirm the bounded image request count.
   The app freezes the source and generates sequentially with distinct design
   directions. Each success saves before the next call. Stop after current prevents
   later calls; it does not cancel the request already submitted.
6. Compare options, use one, favourite or explicitly approve it as the baseline.
   Refinement must start from the intended saved version. Select Precise correction
   and enter its narrow correction; broad renovation preferences are not reapplied.
   The correction is still prompt guidance, without an enforced region mask.
7. Check outputs for retained architecture/viewpoint, requested appliances/flooring,
   useful storage and unwanted changes. For three options, compare material/form
   choices, not only decorative plants. Exact-byte duplication is flagged; meaningful
   difference is not yet scored automatically.

Working image copies have orientation baked, unnecessary metadata stripped and
longest side limited to 2048 px for API transfer; stored original bytes stay intact.
Exact input limits/model choices live in source and depend on the configured
adapter. Check actual account usage to compare model cost/time/quality; no new
benchmark or paid call was performed by the audit.

### Errors and progress

Progress reports stages and elapsed time, not invented percentages. Preparation,
provider response and local storage are separate waits. A storage-only retry
reuses the received result/analysis instead of billing another request. Keep that
screen open until saved. Normal navigation guards pending work, but a killed app
can still lose a response while the provider completes/bills it. Check usage before
retrying an uncertain timeout. In-flight paid-job cancellation/recovery is absent.

## Android target and device acceptance

The S21 is the primary real-phone test so far. A work-policy restriction previously
blocked APK installation; the user resolved it and successfully installed/tested.
Install a requested new APK as an update with the matching ID/signature. Do not
uninstall/clear data as a routine update. This app does not require Play Store
publication for private APK testing.

Use **1.0.12** for these fixes; testing the older 1.0.11 cannot establish their
acceptance. Checklist:

- Existing projects/images/settings survive upgrade, normal exit, restart and
  background/resume. Plain/protected file pickers behave as documented.
- Camera/gallery cancellation and permission denial leave no empty/partial room.
  Camera preview/capture remain usable in portrait/landscape and after resuming.
- Live design stays in viewer after generation, waits for camera readiness,
  overlays automatically, toggles camera/design and preserves overlay across keyboard
  changes. Continue to refine opens the saved result in precise mode.
- Room-first Camera/Photos/Live paths carry room name/type/style/palette. Generic
  live names display the confirmed type; custom names are unchanged.
- Before/after, opacity overlay and zoom work without generating more images.
  Moving the camera does not imply a correctly tracked/reprojected design.
- Crop corners/edges/move; pen/shapes/arrows/text/colours/select/undo; generated
  references remain separate from originals. No claim of enforceable masks.
- Long version captions sit below previews. Use design/favourite/approval/delete/
 undo preserve baseline/history; thumbnail strip labels remain readable.
- All themes save/restart without changing room palette or draft, and all tabs
  remain readable with enlarged system text, keyboard and landscape.
- Check TalkBack/semantics, colour contrast and tap-accessible help. Phone hover
  is not a sufficient way to expose a required action.

## Verification

Requested 1.0.12 package: **249 tests rerun and passed**, `flutter analyze` clean,
Android release build passed in 139.1 seconds. Logs and package verification are
private under `output/mobile-test/`: `test-1.0.12.log`, `analysis-1.0.12.log`,
`build-1.0.12.log`, `metadata-1.0.12.log` and `signing-1.0.12.log`.
The preceding web build passed in 54.9 seconds; its settings-batch logs remain
under `output/`. Web compilation was not repeated for the package-version change.

The audit rendered eleven fictional-fixture screens with correct view metrics,
fonts and fake AI/file services: Projects, Rooms, room chooser, Explore, Library,
Settings, four phone workspace tabs and desktop workspace. One temporary render
test passed; PNGs/log are ignored under `output/design-audit/` and
`output/design-audit-render.log`. No customer store, real API or camera was used.
These captures establish layout only, not interactive browser/device acceptance.
When adding layout checks, set both view physical size/devicePixelRatio and
surface size where required; changing test surface size alone can leave an
incorrect MediaQuery width and exercise the wrong adaptive layout.

The subsequent workspace cleanup removed generated Android/test/tool caches and
superseded logs while retaining the then-current web build, settings/audit logs,
current/rollback APK verification records and all project/recovery/browser data.
The loose audit fixture generator and old source/tool snapshots are retained in
one SHA256-verified archive under `.local_backups/archives/`. Cleanup changed no
application code, so checks were not repeated solely for cleanup. The subsequent
requested APK build reran tests/analysis and recreated the necessary caches.

For implementation changes, run relevant tests and the required suite/analyser:

```powershell
flutter test
flutter analyze
flutter test --platform chrome test/workflow_test.dart test/editor_test.dart
flutter build web
```

Tests use synthetic fixtures/disposable stores. Broader manual coverage remains:
provider adherence/diversity, real Chrome/S21 choosers and lifecycle, large image
libraries, memory/timings, low storage/corruption and interrupted-request recovery.
The audit is not a claim of exhaustive device or AI-quality validation.
