# Test AI inside Renovision

This private development feature sends a selected room photo and prompt to the
OpenAI Images API and saves the returned image as a new local version. The photo
picker, prompt, generation, result review, comparison and approval stay in the app.
The AI itself runs at OpenAI; this is not an offline/on-device image model.

## 1. Obtain API access

A ChatGPT login/subscription is not an API key. Sign into the OpenAI developer
platform, check API billing/available credits and model access, and create a
project-scoped API key. Image-model access may require organisation verification.
Do not paste the key into chat, Dart files, browser settings or a screenshot.

Official references:

- [Developer quickstart](https://developers.openai.com/api/docs/quickstart)
- [Create API keys](https://platform.openai.com/api-keys)
- [API key safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)
- [Image generation/editing](https://developers.openai.com/api/docs/guides/image-generation)

## 2. Start the private relay on Windows

Open a separate PowerShell terminal in `C:\Dev\renovision_ai`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\start_ai_relay.ps1
```

When prompted, enter your developer API key. Input is hidden. The script keeps it
in the process environment for the relay session, restores the previous value
when it exits, and does not write it to a file or print it. If OPENAI_API_KEY is
already set in that terminal's environment, the script uses it without prompting.
The relay runs in this terminal; leave it open while testing.

It displays the local address and a temporary **connection code**. This code is
not your OpenAI key. Copy it into Renovision's AI connection form. Stop the relay
with Ctrl+C when finished. A restarted relay has a new code.

The relay defaults to `gpt-image-2.5-sunburst`, low quality, one result per request,
using the documented Images edit endpoint. Model availability depends on your API
account. To select another compatible GPT Image model, set its public model ID
before starting the relay, for example:

```powershell
$env:RENOVISION_IMAGE_MODEL = 'gpt-image-2.5-flare'
```

This is a model identifier, not a credential. The relay has no automatic retries.
Low quality and one image limit request size, not the total spend across repeated
button presses. Review provider pricing/usage and configure account limits.

## 3. Connect from Chrome

Reload/restart the existing Flutter app session to pick up the code changes while
keeping its browser profile and address. Avoid changing its port or clearing site
storage when checking existing projects. If starting a fresh app session:

```powershell
flutter pub get
flutter run -d chrome
```

In **Settings**, find **In-app AI test connection**:

1. Keep the address `http://127.0.0.1:8787`.
2. Enter the relay's connection code, not the API key.
3. Choose **Connect local AI**. This checks the local relay only; it does not
   validate your key against OpenAI, generate an image or incur an AI charge.

The connection code is held only in app memory. Reconnect after an app restart.
The OpenAI key stays in the relay process and is not included in Flutter builds,
Hive data or browser storage.

## 4. Run one real room edit

Multiple room views: import several photos when creating a room, or use **Add
room photos** in its workspace (up to six original views). Use **Use as primary**
to save a default viewpoint; an approved design still takes priority when opening
the room. Turn on **Use other views as AI context** to include the other angles.
If a saved design is selected, that design is image 1 and originals serve only as
spatial references; the prompt explicitly prioritises the approved changes.

Restart the updated relay and reconnect after upgrading from the single-image
version. The confirmation dialog previews every image that will be uploaded.
More input views can increase API input charges. The request accepts up to seven
images, each up to 18 MB, with a 36 MB combined limit before working-copy resizing.
The result remains one design from image 1's viewpoint, not a measured 3D model.

1. Open a test project/room and select the intended image under **Working from**.
2. Enter the requested change and protected features. For Precision edit, a
   specific instruction is required. Start with a narrow Claylands office change.
3. Choose **Generate AI design**.
4. Review the image, prompt and model in the confirmation dialog. **Send to
   OpenAI** transmits them and can incur API charges. Cancel sends nothing.
5. Wait for the result to save. It becomes a new branch with the source image ID,
   parent version, supporting image IDs, prompt, provider, model and provider request ID.
6. Compare it with the original. Approval is separate: choose **Approve as
   baseline** only if satisfied. Neither the original nor the previous approved
   baseline is overwritten by generation.

The relay removes EXIF/location metadata from a working copy, strips its ICC and
text metadata, and limits its longest side to 2048 pixels before uploading. Source
bytes stored in the app are unchanged. The provider receives the full selected
working copy, not a masked crop unless that crop is what you selected. Protected
features and precise-edit wording are instructions, not preservation guarantees.

No masks, compositing or outside-region change detection are implemented yet.

## 5. Failures and recovery

- Cannot connect: check the relay is running, the address/code match, and port
  8787 is available. Only local HTTP browser origins are accepted.
- Rejected API request: check API key, billing/credits, model access and provider
  restrictions. The relay prints only a status code, never the key or image.
- Timeout/interruption: a provider charge may already have occurred. Check usage
  before trying again. The app/relay do not automatically repeat paid requests.
- Local save failure after generation: keep the screen open and choose **Retry
  saving result**. This reuses the received image without another provider call.
  Unsaved results are held in memory and are lost if that screen/app is closed.
- An in-progress request may finish and be billed after leaving the screen.
  Cancellation of an already submitted provider job is not implemented.

## Android development later

Complete SDK setup first. Run the Windows relay as above. In an Android emulator,
use `http://10.0.2.2:8787` with the displayed connection code. Only the debug
manifest allows cleartext HTTP for this local test. For a USB phone, use an
ADB reverse tunnel and the loopback address; LAN/public hosting is not supported.
Android and live provider calls have not yet been verified.

## Verification

Automated relay tests replace the OpenAI HTTP client with simulated responses;
they never use your credentials or send images to a provider. UI tests cover
confirmation, new-version saving, provider failure and retrying a failed local
save without paying for another generation. A real API test still needs your key
and your explicit **Send to OpenAI** action in the app.

The completed code passes all 25 VM/widget tests, static analysis and the web
release build. The launcher passes PowerShell syntax validation. The previous automated Chrome test runner
stalled before executing cases; interactive Chrome and live API behaviour still
require testing. No automated test result here claims a successful paid generation.

This loopback relay is for your private Windows development workflow. It is not
a production backend and must not be exposed on the internet or packaged with a
reusable API key for distribution.
