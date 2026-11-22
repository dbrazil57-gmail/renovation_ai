import 'models.dart';
import 'room_draft.dart';

// Reserve headroom below the 16,000-character request limit for distinct options.
const _roomContextBudget = 11000;

String _photoFactsExcerpt(String observations, int budget) {
  if (observations.length <= budget) return observations;
  const notice =
      '\n[Photo observations excerpt; full analysis remains saved in the room.]';
  final limit = budget - notice.length;
  if (limit <= 0) {
    return '[Full observations remain saved; use the attached photo and current brief.]';
  }
  final cut = observations.substring(0, limit);
  final sentence = cut.lastIndexOf(RegExp(r'[.!?\n]'));
  final word = cut.lastIndexOf(' ');
  final end = sentence > limit ~/ 2
      ? sentence + 1
      : word > 0
      ? word
      : cut.length;
  return '${cut.substring(0, end)}$notice';
}

String liveRoomAnalysisPrompt(String template) =>
    'Identify the likely room type from this camera reference and describe visible features, uncertainty and useful renovation questions. This is one view, not a spatial scan.\n$template';

bool usesRoomDesignProposal(
  String template,
  RoomDraft draft, {
  String? sourceImageId,
  Iterable<String> supportingImageIds = const [],
  String? analysisContext,
}) =>
    !draft.preciseEdit &&
    draft.useAiPrompt &&
    draft.aiPrompt.text.trim().isNotEmpty &&
    sourceImageId != null &&
    (draft.analysis?.matches(
          sourceImageId,
          supportingImageIds,
          analysisContext ?? template,
        ) ??
        false);

String roomTemplatePrompt(
  RenovationRoom room,
  RoomDraft draft, {
  bool includeRoomContext = true,
  bool conciseDesignDirection = false,
}) {
  final precise = draft.preciseEdit;
  return buildRenovationPrompt(
        roomName: room.name,
        instructions: precise ? draft.correction.text : draft.changes.text,
        protectedFeatures: draft.protected.text,
        preciseEdit: precise,
        colourPaletteId: precise ? '' : room.colourPaletteId,
        designStyleIds: precise ? const [] : draft.styleIds.toList(),
        otherStyle: precise ? '' : draft.otherStyle.text,
        keepLayout: draft.keepLayout,
        renovationScopeIds: precise ? const [] : draft.effectiveScopeIds,
        flooringNotes: precise ? '' : draft.flooringNotes.text,
        removeItems: precise ? '' : draft.removeItems.text,
        roomTypeId: draft.roomTypeId,
        roomItemChoices: precise
            ? Map.fromEntries(
                draft.roomItemChoices.entries.where((e) => e.value == 'keep'),
              )
            : draft.effectiveRoomItemChoices,
        wholeRoomDirection: !precise && draft.fullRenovation,
        conciseDesignDirection: conciseDesignDirection,
      ) +
      (!precise && !draft.fullRenovation
          ? '\nPARTIAL RENOVATION: Change only the requested items, selected surfaces and written instructions. Keep unselected finishes, fittings and furniture as they are; style and palette apply only within this scope. If nothing has been selected or requested, ask what should change before creating a renovation.'
          : '') +
      (includeRoomContext && room.photoIds.length > 1
          ? '\nMULTIPLE VIEWS OF THE SAME ROOM: Image 1 is the working image and defines the output camera viewpoint and any approved design. Remaining images show other angles for spatial context. Consolidate the room details across these views; do not make a collage, duplicate furniture or invent unseen geometry. Do not use older reference furnishings to undo approved changes in image 1. If views conflict, prioritise image 1. Produce one design from its viewpoint, not a verified 3D reconstruction.'
          : '');
}

String reviewedRoomPrompt(
  String template,
  RoomDraft draft, {
  String? sourceImageId,
  Iterable<String> supportingImageIds = const [],
  String? analysisContext,
  String? proposalRequirements,
}) {
  // Suggestions apply to one exact brief, never a new photo, changed choices
  // or a precise correction. Saved proposals and historical prompts stay intact.
  if (draft.preciseEdit) return template;
  final analysis = draft.analysis;
  final useFacts =
      sourceImageId != null &&
      (analysis?.matchesPhotos(sourceImageId, supportingImageIds) ?? false);
  final useProposal = usesRoomDesignProposal(
    template,
    draft,
    sourceImageId: sourceImageId,
    supportingImageIds: supportingImageIds,
    analysisContext: analysisContext,
  );
  if (!useFacts) return template;
  final requirements = useProposal
      ? proposalRequirements ?? template
      : template;
  final proposal = useProposal
      ? 'AI DESIGN PROPOSAL (a coordinated scheme for these photos and choices):\n${draft.aiPrompt.text.trim()}\nCurrent requirements, Keep choices, selected style/palette and option-specific concept directions override suggestions.\n'
      : '';
  final prefix =
      'CURRENT USER REQUIREMENTS (take priority over AI suggestions):\n$requirements\n\n'
      'PHOTO ANALYSIS (AI observations, not verified measurements or additional edit instructions):\n';
  const evidenceRules =
      '\nCheck against the actual photo. Existing finishes are starting conditions, not protected features. An observed object is not automatically authorised for removal.\n\n';
  // Leave room for the separately planned concept directions. Never shorten
  // written requirements or an edited proposal; only excerpt optional AI facts.
  final available =
      _roomContextBudget -
      prefix.length -
      evidenceRules.length -
      proposal.length;
  final facts = _photoFactsExcerpt(analysis!.result.observations, available);
  return '$prefix$facts$evidenceRules$proposal';
}
