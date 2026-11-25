import 'design_styles.dart' show isWholeRoomRequest;

enum BriefTarget { room, style, palette, refine }

class BriefCheck {
  final String label;
  final int points, possible;
  final BriefTarget target;
  final String suggestion;
  final bool requiredForGeneration;
  const BriefCheck(
    this.label,
    this.points,
    this.possible,
    this.target,
    this.suggestion, {
    this.requiredForGeneration = false,
  });
  bool get complete => points == possible;
}

/// Local input coverage, not an AI quality/confidence prediction. No photo
/// analysis, provider connection or paid request is required to earn points.
class BriefReadiness {
  static const reminderThreshold = 75;
  static const explanation =
      'This measures supplied design direction, not predicted image quality. Optional choices can be left to AI.';
  final List<BriefCheck> checks;
  final bool precise, fullRoom;
  bool get isNewDesign => !precise && fullRoom;
  BriefReadiness._(this.precise, this.fullRoom, List<BriefCheck> checks)
    : checks = List.unmodifiable(checks);

  factory BriefReadiness.assess({
    required bool imageAvailable,
    required bool precise,
    required String instruction,
    required bool fullRoom,
    required bool selectedChanges,
    required bool roomTypeKnown,
    required bool styleDefined,
    required bool paletteDefined,
  }) {
    final hasInstruction = instruction.trim().isNotEmpty;
    if (precise || !fullRoom) {
      final validChange = precise
          ? hasInstruction && !isWholeRoomRequest(instruction)
          : hasInstruction || selectedChanges;
      return BriefReadiness._(precise, fullRoom, [
        BriefCheck(
          'Working photo',
          imageAvailable ? 55 : 0,
          55,
          BriefTarget.room,
          'Choose the image you want to correct.',
          requiredForGeneration: true,
        ),
        BriefCheck(
          precise ? 'Specific correction' : 'Requested changes',
          validChange ? 40 : 0,
          40,
          BriefTarget.refine,
          precise
              ? 'Describe one specific correction in Refine, or choose New design for a whole-room concept.'
              : 'Choose the items to update, or describe your changes in Refine.',
          requiredForGeneration: true,
        ),
        const BriefCheck(
          'Keep unrelated details',
          5,
          5,
          BriefTarget.refine,
          '',
        ),
      ]);
    }
    final clearGoal =
        hasInstruction ||
        selectedChanges ||
        (fullRoom && styleDefined && paletteDefined);
    return BriefReadiness._(false, true, [
      BriefCheck(
        'Working photo',
        imageAvailable ? 35 : 0,
        35,
        BriefTarget.room,
        'Add or choose your room photo.',
        requiredForGeneration: true,
      ),
      BriefCheck(
        'Room type',
        roomTypeKnown ? 10 : 0,
        10,
        BriefTarget.style,
        'Confirm the room type under Renovation scope in Style.',
      ),
      BriefCheck(
        'Goal / renovation scope',
        clearGoal
            ? 25
            : fullRoom
            ? 15
            : 0,
        25,
        fullRoom ? BriefTarget.refine : BriefTarget.style,
        fullRoom
            ? 'Add your goal in Refine, or choose both a style and palette.'
            : 'Choose the items to change in Style, or describe your partial renovation in Refine.',
      ),
      BriefCheck(
        'Style direction',
        styleDefined ? 15 : 0,
        15,
        BriefTarget.style,
        'Choose a style or add your own direction; otherwise AI will choose.',
      ),
      BriefCheck(
        'Colour palette',
        paletteDefined ? 10 : 0,
        10,
        BriefTarget.palette,
        'Choose a palette, or leave colour choices to AI.',
      ),
      const BriefCheck('Layout rule included', 5, 5, BriefTarget.style, ''),
    ]);
  }

  int get percentage => checks.fold(0, (sum, item) => sum + item.points);
  BriefCheck? get blockingCheck => checks
      .where((check) => check.requiredForGeneration && !check.complete)
      .firstOrNull;
  bool get canProceed => blockingCheck == null;
  String? get blockingReason => blockingCheck?.suggestion;
  String get label => isNewDesign
      ? 'Brief $percentage% complete'
      : blockingCheck?.target == BriefTarget.room
      ? 'Choose an image'
      : precise
      ? canProceed
            ? 'Correction ready'
            : 'Add a specific correction'
      : canProceed
      ? 'Changes ready'
      : 'Add changes to continue';
  String get reviewTitle => isNewDesign
      ? 'Brief $percentage% complete'
      : precise
      ? 'Review correction'
      : 'Review changes';
  String get description => isNewDesign
      ? explanation
      : precise
      ? 'Describe only the correction to apply to this image. The original room brief, style and palette are not reapplied.'
      : 'Choose what should change. Unselected items stay outside this update; style and palette alone are not a change request.';
  List<BriefCheck> get missing =>
      checks.where((item) => !item.complete).toList();
  BriefTarget get recommendedTarget =>
      missing.firstOrNull?.target ?? BriefTarget.refine;
  bool needsReminder({required bool previouslyReviewed}) =>
      isNewDesign && (percentage < reminderThreshold || !previouslyReviewed);
}
