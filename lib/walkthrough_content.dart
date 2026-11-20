/// Read-only examples. These guides never create projects or call camera/AI APIs.
class WalkthroughStep {
  final String title, instruction, example;
  final String? note;
  const WalkthroughStep(
    this.title,
    this.instruction,
    this.example, {
    this.note,
  });
}

class AppWalkthrough {
  final String id, title, summary;
  final List<WalkthroughStep> steps;
  const AppWalkthrough(this.id, this.title, this.summary, this.steps);
}

const photoWalkthrough = AppWalkthrough(
  'photos',
  'Choose photos',
  'Start with photos already on your device.',
  [
    WalkthroughStep(
      'Open a project and choose your room',
      'Create or open a project in Projects. Open it, tap Choose photos, then choose the room type and Photos.',
      'Project: Sample home. Room: Kitchen. Tap Continue to photos.',
    ),
    WalkthroughStep(
      'Choose photos of the same room',
      'Select your room photos from the phone gallery or computer. In Room photos, choose the primary view and add other angles if useful.',
      'Use the dining-side kitchen photo as the primary view, with another angle showing the sink.',
      note: 'The primary view sets the design viewpoint. Uploading saves the photos locally; it does not run AI.',
    ),
    WalkthroughStep(
      'Set a design direction',
      'Continue to Design direction. Choose a style and palette, describe what you want, and protect anything you want to keep.',
      'Modern / Contemporary. Charcoal & walnut. Keep the layout; update flooring, cabinetry and appliances.',
    ),
    WalkthroughStep(
      'Analyse and review',
      'In Analyse and review, confirm sending the selected photos to your connected AI. Review its observations, questions and editable prompt.',
      'Check that the prompt keeps the existing window and peninsula position.',
      note: 'Analysis needs a connected developer API key and may be billed. It does not create the design image.',
    ),
    WalkthroughStep(
      'Generate, choose and refine',
      'In Finalise and generate, choose one, two or three concepts and review the confirmation. Select a saved result to refine or compare.',
      'Try two coordinated design ideas. Select your favourite, then ask for a lighter benchtop.',
      note: 'Each concept is a separate paid request. Originals stay saved; generated images become new versions.',
    ),
  ],
);

const cameraWalkthrough = AppWalkthrough(
  'camera',
  'Take a photo',
  'Capture a room, then follow the guided design steps.',
  [
    WalkthroughStep(
      'Choose Camera',
      'Open a project and tap Take photo. Choose your room type and Camera, then Continue to camera.',
      'Project: Sample home. Room: Kitchen. Allow camera access when asked.',
      note: 'A camera must be available on the device or browser. You can use Photos if camera access is unavailable.',
    ),
    WalkthroughStep(
      'Capture your room',
      'Frame the room clearly and take the photo. Accept the capture to use it as the room photo.',
      'Stand at the dining side so the window, cooktop and peninsula are visible.',
    ),
    WalkthroughStep(
      'Review the saved photo',
      'The app opens Room photos. Keep the clearest view as primary and add more room angles if needed.',
      'Add a second angle of the kitchen. Keep the first photo as the design viewpoint.',
      note: 'Capturing a photo does not automatically send it to AI.',
    ),
    WalkthroughStep(
      'Choose, analyse and generate',
      'Follow Design direction, Analyse and review, then Finalise and generate. Review the prompt and confirm each paid AI step.',
      'Choose Modern / Contemporary and Charcoal & walnut. Ask for a fresh design while keeping the layout.',
    ),
    WalkthroughStep(
      'Keep working on the result',
      'Open a saved design full screen, compare it with the original, or refine it in the workspace.',
      'Select the version you like and request large warm-grey floor tiles.',
      note: 'Use the Live view walkthrough to design while staying in the camera viewer.',
    ),
  ],
);

const liveWalkthrough = AppWalkthrough(
  'live',
  'Live view',
  'Analyse and design while staying in the camera viewer.',
  [
    WalkthroughStep(
      'Open Live design',
      'Open a project and tap Take photo. In Choose your room, select the room type and Live design, then Continue to live design.',
      'Choose Kitchen for Sample home. Allow camera access and connect AI in Settings if needed.',
    ),
    WalkthroughStep(
      'Hold the view and start analysis',
      'Aim at the room and tap Start live design. Review the provider confirmation and choose Start and analyse. Hold this viewpoint while the reference is prepared.',
      'The app captures and saves one reference frame, then analyses that image.',
      note: 'Preparation progress is not a 3D scan. Video stays on the device; the confirmed reference image is sent to AI and may be billed.',
    ),
    WalkthroughStep(
      'Review the room and choose a direction',
      'Review the observations and questions. Confirm the room type, then choose your style, palette and changes in the camera controls.',
      'Kitchen, Modern / Contemporary, Charcoal & walnut. Keep the layout and modernise the finishes.',
    ),
    WalkthroughStep(
      'Generate the overlay',
      'Review and confirm a design request. When the result is saved, it overlays the camera. Use Live camera, Reference or Design overlay and adjust opacity.',
      'Keep the camera aimed at the original viewpoint and fade the overlay to compare.',
      note: 'This is a still design aligned by you, not tracked AR or an instant transformation of every video frame. Generation takes time.',
    ),
    WalkthroughStep(
      'Try an update or continue refining',
      'Change a palette or another option, then confirm a new generation to apply it. When happy with the saved design, choose Continue to refine.',
      'Try a lighter palette, compare the saved overlay, then refine the chosen version in the workspace.',
      note: 'Changing an option does not trigger a paid request automatically. Each confirmed update is saved as a new design version.',
    ),
  ],
);

const designWalkthrough = AppWalkthrough(
  'design',
  'Design & refine',
  'Explore different ideas, then improve the one you choose.',
  [
    WalkthroughStep(
      'Connect the AI you want to use',
      'Open Settings, then AI connection and models. Choose OpenAI or Gemini and connect that provider’s developer API key. Review the model choice.',
      'Browse Recommended design models before connecting a key.',
      note: 'Chat subscriptions and developer API access are separate. Reading these walkthroughs needs neither.',
    ),
    WalkthroughStep(
      'Give the room a clear direction',
      'Choose New design for a coordinated renovation. Add a style, palette and any features to keep. Analyse your photos and review the drafted prompt.',
      'A modern kitchen with charcoal cupboards and pale stone. Keep the walls, window and layout.',
    ),
    WalkthroughStep(
      'Ask for different ideas',
      'Choose two or three concepts when you want alternatives. Review the model, photos and prompt before sending.',
      'Compare a warm timber-led scheme with a lighter stone-led scheme.',
      note: 'Each concept is a paid request. The app asks for distinct designs, but AI can still produce similar results.',
    ),
    WalkthroughStep(
      'Refine a selected design',
      'Select the saved version you like. In Refine, choose Precise correction for a small change and describe only that change.',
      'Change only the benchtop to pale stone. Keep the chosen cabinetry, flooring and layout.',
      note: 'Precise prompts and markup guide the AI; they do not guarantee unchanged pixels outside the edit.',
    ),
    WalkthroughStep(
      'Work without an in-app key',
      'You can also use Copy AI prompt, attach the working photo and supporting views in an external image-editing AI, then Import generated AI result.',
      'Attach the kitchen photos along with the copied prompt; import the resulting image into this room.',
      note: 'Copying a prompt copies text only. External AI results do not return to the app automatically.',
    ),
  ],
);

const toolsWalkthrough = AppWalkthrough(
  'tools',
  'Image tools & compare',
  'Inspect details, guide edits and manage versions.',
  [
    WalkthroughStep(
      'Open the image full screen',
      'Tap an image or its thumbnail. Pinch to zoom and drag to pan, or use the zoom and Fit image tools. Rotate your phone for a wider view.',
      'Zoom in to inspect the kitchen cabinet fronts.',
      note: 'Enable Auto rotate on Android if needed. Viewing and zooming do not change the image.',
    ),
    WalkthroughStep(
      'Crop or mark a reference',
      'Select Crop or markup in the workspace image tools. Move or resize the crop, or add coloured lines, arrows, shapes and notes.',
      'Draw an arrow to the extractor and add “Replace with a slim modern hood”.',
      note: 'Save the edited reference as a new image. The original stays unchanged; a marked reference is not an enforced AI mask.',
    ),
    WalkthroughStep(
      'Compare before and after',
      'Choose Compare original on a saved design and drag the before/after slider to inspect changes.',
      'Check that the window and room layout still match the original.',
    ),
    WalkthroughStep(
      'Keep or remove a version',
      'Use favourites or approve a baseline for the design you want to keep working from. Use Delete beside the image tools for an unwanted generated design.',
      'Delete an unused idea, then use Undo or restore it from Deleted designs.',
      note: 'Originals and approved baselines are protected. Delete is recoverable.',
    ),
  ],
);

const savingWalkthrough = AppWalkthrough(
  'saving',
  'Save & reopen',
  'Keep local work and a portable project file.',
  [
    WalkthroughStep(
      'Check local autosave',
      'Open More tools in the design workspace to check Autosave. With it enabled, room choices and saved versions stay on this device.',
      'Turn Autosave on before experimenting with the kitchen.',
      note: 'Browser storage belongs to the browser address and profile. A portable file helps you move work or recover it elsewhere.',
    ),
    WalkthroughStep(
      'Save a portable project',
      'Use the Save project file toolbar action, or the project file controls in Settings. Save project as lets you choose another file.',
      'Save Sample home with its rooms, original photos, designs and saved instructions.',
      note: 'Check that the file was saved or downloaded. API keys are kept separately and are never included in project files.',
    ),
    WalkthroughStep(
      'Reopen your work',
      'Select the saved local project in Projects, or use Open project to choose a portable project file. Open the room and select the design you want to continue.',
      'Open your Sample home file on another device, then return to Kitchen.',
      note: 'Opening a file currently imports a local copy. Opening it repeatedly can create separate project copies.',
    ),
    WalkthroughStep(
      'Keep backups private',
      'Settings offers optional password-protected project exports. Keep the password somewhere safe and check that you can open your backup.',
      'Use a protected file when sharing a project containing private room photos.',
      note: 'Protected exports encrypt the portable file. App-local photo storage is not encrypted by this option. Chrome needs API key re-entry after reload; Android can retain its key securely.',
    ),
  ],
);

const modelComparisonWalkthrough = AppWalkthrough(
  'models',
  'Compare AI models',
  'Test the same room fairly before choosing a favourite model.',
  [
    WalkthroughStep(
      'Start with the image-model shortlist',
      'In Settings, open AI connection and models, then Recommended design models. Start with Nano Banana 2.1 and Nano Banana Pro under Gemini, and GPT Image 2.6 Sunburst and Flare under OpenAI.',
      'Compare two Gemini models first with one Google developer key. Add an OpenAI key when you want to compare across providers.',
      note: 'These are suggested candidates, not a measured ranking. A provider key can access its listed models; generation still depends on account permissions and billing.',
    ),
    WalkthroughStep(
      'Keep the test inputs fixed',
      'Choose one original room photo, the same supporting views, style, palette and brief. Review the prepared prompt once and keep it unchanged for the first comparison.',
      'Use the same kitchen photo and ask for charcoal cupboards, pale stone and new flooring while keeping the layout.',
      note: 'Use the same reviewed analysis/prompt across models where possible. Rewriting it between attempts makes the result harder to attribute to the model.',
    ),
    WalkthroughStep(
      'Generate one result per model',
      'In Recommended design models, enable Use fixed brief for model tests. Select a model and choose one concept in the room. Review the confirmation before sending. For the first Gemini comparison, use 2K for both models.',
      'Save a Nano Banana 2.1 result, then reselect the same original before testing Nano Banana Pro.',
      note: 'The switch skips the normal rotating creative direction and sends the prepared prompt unchanged. It resets off after restart. Reselect the same original after each saved result; each confirmed test can be billed.',
    ),
    WalkthroughStep(
      'Score the results against the brief',
      'Use version history and Compare original to check the room. Rate design appeal, instruction following, layout preservation, realism and useful creativity from 1 to 5.',
      'Appeal __/5; follows brief __/5; preserves layout __/5; realism __/5; creativity __/5.',
      note: 'Compare provider/model and the exact prompt saved with each version. Record settings, elapsed time and actual cost separately. OpenAI quality levels and Gemini output resolutions are different controls.',
    ),
    WalkthroughStep(
      'Test more than one room and task',
      'Repeat with a bedroom or living room, then try a precise correction. A model that excels at creative renovations may be less reliable at preserving a small edit.',
      'Kitchen redesign: change finishes. Bedroom redesign: new coordinated scheme. Correction: change only the benchtop.',
      note: 'AI results vary. Repeat the important cases before drawing conclusions, with a deliberate budget for each additional paid request.',
    ),
    WalkthroughStep(
      'Choose defaults from your own results',
      'Rank candidates separately for best overall design, precise corrections and quick previews. Balance quality with speed and actual cost, then set your preferred model in Settings and turn off Use fixed brief for model tests.',
      'Best redesign: ____; best correction: ____; best quick preview: ____. Review these choices before going live.',
      note: 'The app does not score images or maintain a model leaderboard yet. These are manual test notes; no model is automatically promoted and no paid test runs automatically.',
    ),
  ],
);

const appWalkthroughs = [
  photoWalkthrough,
  cameraWalkthrough,
  liveWalkthrough,
  designWalkthrough,
  toolsWalkthrough,
  savingWalkthrough,
  modelComparisonWalkthrough,
];
