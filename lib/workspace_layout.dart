/// Device display preference only; never part of a renovation brief/project file.
class WorkspaceLayout {
  final double? portraitImageFraction, wideImageFraction;
  const WorkspaceLayout({this.portraitImageFraction, this.wideImageFraction});

  factory WorkspaceLayout.fromMap(Object? raw) {
    double? fraction(Object? value) =>
        value is num && value.isFinite && value >= 0 && value <= 1
        ? value.toDouble()
        : null;
    return raw is Map
        ? WorkspaceLayout(
            portraitImageFraction: fraction(raw['portrait']),
            wideImageFraction: fraction(raw['wide']),
          )
        : const WorkspaceLayout();
  }

  WorkspaceLayout resize(double fraction, {required bool wide}) =>
      WorkspaceLayout(
        portraitImageFraction: wide ? portraitImageFraction : fraction,
        wideImageFraction: wide ? fraction : wideImageFraction,
      );

  Map<String, double> toMap() => {
    'portrait': ?portraitImageFraction,
    'wide': ?wideImageFraction,
  };
}
