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
  bool fixedBrief = false,
}) {
  if (count < 1 || count > 3) {
    throw const AiFailure('Choose one, two or three results.');
  }
  if (fixedBrief) {
    if (count != 1) {
      throw const AiFailure(
        'Select one result for a fixed-brief model test, or turn off Use fixed brief for model tests in AI settings. No request was sent.',
      );
    }
    return [DesignConcept('Fixed-brief model test', prompt)];
  }
  if (precise) {
    if (count == 1) return [DesignConcept('Precision edit', prompt)];
    return [
      for (var index = 0; index < count; index++)
        DesignConcept(
          'Correction variation ${index + 1}',
          '$prompt\n\nPRECISE CORRECTION VARIATION ${index + 1} OF $count: Apply exactly the same specific correction to this same starting image. Offer an alternative execution only within details the user has left open. Keep all unrelated regions, approved design choices, layout and protected features unchanged. Do not reapply whole-room styles, recolour unrelated surfaces or add decorative objects to force variety. If the instruction permits only one valid outcome, follow it faithfully rather than inventing extra changes. Return one individual image, not a collage.',
        ),
    ];
  }
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
      'Clean & architectural',
      'Create a restrained architectural scheme: broad uninterrupted planes, low visual texture, crisp integrated detailing and a calm light material balance. Give authorised cabinetry or main furnishings and surfaces a coherent minimal treatment within the selected style. Use integrated or linear lighting where lighting changes are allowed.',
    ),
    (
      'Warm & tactile',
      'Create a warm tactile scheme: visibly textured natural-looking surfaces, timber or other warm materials allowed by the palette, crafted detailing and softer forms where permitted. Reinterpret authorised cabinetry or main furnishings as a materially different composition, with layered warm lighting where allowed. Avoid the flat crisp finish language of the architectural alternative.',
    ),
    (
      'Bold & sculptural',
      'Create a bold sculptural scheme: stronger light/dark contrast within the selected palette, substantial-looking focal surfaces, expressive permitted cabinet or furniture detailing and distinctive statement lighting where allowed. Make authorised main elements and material combinations visually different from the restrained architectural and warm tactile alternatives.',
    ),
  ];
  final batchDirections = [
    for (var i = 0; i < count; i++)
      directions[(previousConcepts + i) % directions.length],
  ];
  return [
    for (var i = 0; i < count; i++)
      (() {
        final direction = batchDirections[i];
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
        if (count > 1) {
          brief +=
              '\n\nDISTINCT REDESIGN OPTIONS: This batch is a choice between substantially different renovation schemes, not minor variations of one design. Planned directions:\n${[for (var j = 0; j < count; j++) '${j + 1}. ${batchDirections[j].$1}: ${batchDirections[j].$2}'].join('\n')}\nRender ONLY option ${i + 1}, using its ${direction.$1} direction. Other entries are alternative briefs, not images you have already seen. Establish this option through major design decisions: material composition of main surfaces; finish, form or detailing of authorised cabinetry or main furnishings; and permitted lighting/fittings or focal treatment. Where the requested scope allows, make at least three of these decisions visibly distinct from the other planned schemes. Adding plants, ornaments, cushions, small accessories or a different camera exposure does not count as a different renovation. Do not keep the same cabinetry, surfaces and fittings and merely restage them.\nCONSTRAINT PRIORITY: Explicit user instructions, Keep choices, approved retained features, selected style and palette, room geometry and layout restrictions take priority. Use different allocations and textures within a fixed palette rather than forbidden colours. Only change elements authorised by the room brief; do not move walls, openings, plumbing positions or protected furniture to force variety. If constraints allow only limited alternatives, honour them rather than inventing changes or claiming a new layout. Treat the starting image as a geometry and retained-feature reference, not a mandate to copy every replaceable finish. Return one individual image for this option, not a collage.';
        }
        if (brief.length > 16000) {
          throw const AiFailure(
            'The concept prompt is too long. Shorten the room instructions or reviewed AI prompt.',
          );
        }
        return DesignConcept(label, brief);
      })(),
  ];
}
