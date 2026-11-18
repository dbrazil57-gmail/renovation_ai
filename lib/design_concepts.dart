import 'ai_types.dart';
import 'design_styles.dart';

class DesignConcept {
  final String label;
  final String prompt;
  const DesignConcept(this.label, this.prompt);
}

/// One request per concept: frozen source, distinct briefs, bounded paid work.
List<DesignConcept> planDesignConcepts({
  required String prompt,
  required bool precise,
  required int count,
  required List<String> styleIds,
  required bool compareStyles,
  String otherStyle = '',
  int previousConcepts = 0,
}) {
  if (count < 1 || count > 3 || (precise && count != 1)) {
    throw const AiFailure(
      'Use one result for a precise correction, or choose Whole-room renovation for multiple ideas.',
    );
  }
  if (precise) return [DesignConcept('Precision edit', prompt)];
  final styles = canonicalStyleIds(styleIds)
      .where(designStyles.containsKey)
      .toList();
  if (count > 1 && compareStyles && styles.length > count) {
    throw const AiFailure(
      'Choose at most as many styles as concepts to compare them separately, or switch off Compare styles separately to blend them.',
    );
  }
  const directions = [
    (
      'Materials',
      'Develop a material-led alternative with a distinct combination of unprotected cabinetry or furniture finishes, surface textures and coordinated details appropriate to this room.',
    ),
    (
      'Light & detail',
      'Develop a noticeably different alternative through layered lighting, refined fittings and distinctive unprotected joinery or furniture detailing appropriate to this room.',
    ),
    (
      'Contrast & texture',
      'Develop a contrasting alternative using tonal balance, tactile finishes and a different focal treatment of unprotected elements appropriate to this room.',
    ),
  ];
  return [
    for (var i = 0; i < count; i++)
      (() {
        final direction =
            directions[(previousConcepts + i) % directions.length];
        final separate = count > 1 && compareStyles && styles.length > 1;
        final chosen = separate && i < styles.length ? [styles[i]] : styles;
        final label = separate
            ? (i < styles.length ? designStyles[styles[i]]! : 'Blended styles')
            : direction.$1;
        var brief = prompt;
        if (separate) {
          brief = brief.replaceAll(
            RegExp(r'^(DESIGN STYLE:|STYLE DETAILS:).*\n?', multiLine: true),
            '',
          );
          brief +=
              '\n\nSTYLE FOR THIS CONCEPT (overrides earlier AI style suggestions only):\n${styleDirection(chosen, other: otherStyle)}\n${chosen.length == 1 ? 'Use this selected style alone; other checked styles belong to separate concepts. Do not blend them into this image.' : 'This option intentionally blends the selected styles.'}';
        }
        brief +=
            '\n\nNEW DESIGN CONCEPT ${i + 1} OF $count: $label. Exploration attempt ${previousConcepts + i + 1}: choose another design solution within this brief. ${direction.$2} Produce a visibly fresh design interpretation, rather than reproducing the working photo or a previous result. Make changes in material treatment, detailing or styling visible; a near-identical recolour is insufficient. Keep the selected palette, explicit user instructions, protected features, camera viewpoint and layout restrictions. Do not add furniture or change protected items merely to make this option different. The working image establishes room geometry and retained features; unprotected finishes are available for this new concept. Return one individual photorealistic image, not a collage or contact sheet. Freshness is a request, not permission to relax the brief.';
        if (brief.length > 16000) {
          throw const AiFailure(
            'The concept prompt is too long. Shorten the room instructions or reviewed AI prompt.',
          );
        }
        return DesignConcept(label, brief);
      })(),
  ];
}
