enum BriefTarget { room, style, palette, refine }

class BriefCheck {
  final String label;
  final int points, possible;
  final BriefTarget target;
  final String suggestion;
  const BriefCheck(
    this.label,
    this.points,
    this.possible,
    this.target,
    this.suggestion,
  );
  bool get complete => points == possible;
}

/// Local input coverage, not an AI quality/confidence prediction. No photo
/// analysis, provider connection or paid request is required to earn points.
class BriefReadiness {
  static const reminderThreshold = 75;
  static const explanation =
      'This measures supplied design direction, not predicted image quality. Optional choices can be left to AI.';
  final List<BriefCheck> checks;
  final bool precise;
  BriefReadiness._(this.precise, List<BriefCheck> checks)
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
    if (precise) {
      return BriefReadiness._(true, [
        BriefCheck(
          'Working photo',
          imageAvailable ? 55 : 0,
          55,
          BriefTarget.room,
          'Choose the image you want to correct.',
        ),
        BriefCheck(
          'Specific correction',
          hasInstruction ? 40 : 0,
          40,
          BriefTarget.refine,
          'Describe the detail to change in Refine.',
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
    return BriefReadiness._(false, [
      BriefCheck(
        'Working photo',
        imageAvailable ? 35 : 0,
        35,
        BriefTarget.room,
        'Add or choose your room photo.',
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
  List<BriefCheck> get missing =>
      checks.where((item) => !item.complete).toList();
  BriefTarget get recommendedTarget =>
      missing.firstOrNull?.target ?? BriefTarget.refine;
  bool needsReminder({required bool previouslyReviewed}) =>
      percentage < reminderThreshold || !previouslyReviewed;
}
