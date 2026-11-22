# Renovision AI

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

In the Design workspace, choose **Paint walls without AI**. Tap a clear part of a
wall, check the highlighted boundary, then choose a swatch or custom hex colour.
Adjust sensitivity if needed; outline/brush/erase remain optional fallbacks. Drafts
save locally; **Save paint version** creates a lossless PNG and editable layers,
leaving the source and approved baseline intact. Undo/Redo and Compare before
are available. Layer chips and Delete selected wall / Delete all walls remain
available after reopening. Tap selection uses local colour/edge connectivity,
not semantic recognition: similarly coloured adjacent objects may need correction.
Colour/shading is approximate, with no AI call; wallpaper remains later work. Local paint
preserves unselected pixels; that does not establish the same guarantee for AI edits.

Choose another colour on the same wall layer to replace it, without selecting
again. **Finish with AI** saves the local preview and opens Precise correction
with its wall colours. Review and explicitly generate when ready; this uses your
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
The current desktop build is `75ffe41898`, including all completed source features
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
