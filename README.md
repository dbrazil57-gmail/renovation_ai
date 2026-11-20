# Renovision AI

Latest source follow-up: **305 tests pass**; Feedback in Help/Settings supports
saved issue/feature drafts, preview/copy and email/form handoff hooks. The owner's
support address/form URL is still needed to activate delivery. Chrome release
and Android Kotlin compilation pass. This is after the APK described below;
no further APK was built or actual feedback sent.

Verified 20 November 2026: **296 tests pass**, static analysis is clean and the
release web build passes. The requested Android **1.0.13+14** update is built and
verified. Existing icons remain in place while six design/colour alternatives
await a final choice.

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
fixes on **20 November**. The app is suitable for continued private testing.
Precise edit enforcement, persistent Android project-file linkage and measured
larger-project reliability remain unfinished. No public backend, payment system
or store-ready release is included.

The latest source adds prominent expandable AI settings, visible recoverable
design deletion, New design / Precise correction with separate 1/2/3 output
choices, stronger creative briefs, OpenAI/Gemini model presets, seven offline
walkthroughs and a fixed-brief model comparison aid. Automatic Live room names
use the actual type, such as Bedroom (Live), while preserving custom names.

Open project now resumes unchanged matching work; conflicting file/local
revisions offer Keep local or Open file as copy. New AI versions retain their
own settings, analysis and model/quality with Saved settings / Use these settings /
Refine this design actions. Startup shows loading and a non-destructive Retry.
Older versions remain readable without inventing missing historical settings.

Latest test package: **1.0.13+14**, source `f69772aaa0`, at
`output/mobile-test/renovision-test-1.0.13.apk` (also `renovision-test.apk`).
All 296 tests pass, analyzer clean; final web/Android release builds passed in
102.4/145.5 seconds. APK identity, matching 1.0.12 signing certificate, ARM64,
optional camera, restricted share paths and sample-only assets were checked.
Install over the existing app without uninstalling. Older APKs remain for rollback.
Physical S21 acceptance and live Gemini comparisons remain. No paid AI calls or
user-data reset were performed.
Build further APKs only when requested.

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
flutter pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_web_test.ps1
```

Open **http://localhost:7357** in the same normal Chrome profile each time.
Bookmark it. Different ports, profiles and Incognito have separate saved stores.
Do not clear site data to fix missing projects. The launcher keeps browser ownership
with Chrome rather than creating a disposable Flutter Chrome profile.
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
Each uses a fictional kitchen with Next/Previous steps. These are read-only
examples, available without a key; they do not capture photos or send AI requests.
Walkthroughs are included in the source for the requested 1.0.13 package.

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
