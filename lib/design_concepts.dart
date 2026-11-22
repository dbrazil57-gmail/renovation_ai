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
      'Create a complete designer architectural scheme: confident main materials, refined crafted detailing, considered joinery or furnishings and integrated lighting where permitted. Give the authorised surfaces and fittings a coordinated new design, with a strong focal treatment and quieter supporting finishes. Refine a minimalist style through proportions and details; a simple recolour with old-looking fittings is insufficient.',
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
  const shortDirections = {
    'Clean & architectural': 'Flush slab fronts or clean main furnishings, continuous focal surfaces and integrated fittings.',
    'Warm & tactile': 'Crafted or timber-dominant main elements, tactile materials, softer detailing and slim feature fittings.',
    'Bold & sculptural': 'Strong panel rhythms, bold focal surfaces, expressive permitted detailing and statement fittings.',
  };
  final kitchen = RegExp(
    r'ROOM TYPE:\s*Kitchen|real Kitchen',
    caseSensitive: false,
  ).hasMatch(prompt);
  const kitchenSchemes = [
    'CABINET / FITTING SCHEME A: Streamlined architectural joinery with uninterrupted slab fronts, crisp fine shadow lines and a predominantly stone focal surface. Use the palette darkest tone mainly on base cabinetry and its timber as controlled upper or feature panels. Where replacement is authorised, specify sleek flush-front appliances and a fully integrated or concealed modern extractor. Maintain existing cabinet capacity, main element positions and the required benchtop outline.',
    'CABINET / FITTING SCHEME B: Warm crafted joinery with clearly different cabinetry treatment: timber-dominant fronts where the palette permits, restrained reeded or fine vertical detailing and smooth painted upper fronts. Use a different balance of the SAME palette, tactile low-sheen splashback materials and softer edge detailing within the existing outline. Where replacement is authorised, use coordinated dark-glass appliances and a visibly distinct slim feature extractor. Do not repeat scheme A slab-front/material distribution.',
    'CABINET / FITTING SCHEME C: A sculptural contrasting composition with strong full-height panel rhythms, inset or framed contemporary front detailing, bold permitted stone focal surfaces and a distinct wall-mounted or feature hood where replacement is authorised. Redistribute the SAME palette through upper/lower/tower fronts, with integrated appliances and a different main-light silhouette. Do not copy schemes A/B and change accessories. Preserve useful cupboards, required handleless/push-open operation and any specifically retained hood.',
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
            '\n\nNEW DESIGN CONCEPT ${i + 1} OF $count: $label. Exploration attempt ${previousConcepts + i + 1}. ${direction.$2} Produce a visibly fresh design through authorised material, cabinet/furniture and fitting choices. Keep the selected palette, explicit instructions, protected features, viewpoint and layout. The source defines geometry and retained features, not every replaceable finish. Return one individual photorealistic image, not a collage.';
        if (count > 1) {
          if (kitchen) {
            brief +=
                '\nKITCHEN CHOICE BOARD: A uses crisp slab fronts and integrated hood; B uses warm crafted fronts and slim feature hood; C uses sculptural panel rhythms and a distinct feature hood. Render only the assigned specification below.\nYOUR ASSIGNED KITCHEN SCHEME: ${kitchenSchemes[(previousConcepts + i) % 3]}\nExplicit materials, style, Keep choices, palette and layout override alternative details. These are plausible appearances, not verified catalogue products.';
          }
          brief += '\nAI-PROPOSED SCHEME: Its suggestions are not a single approved design to repeat across options. Reinterpret open material, detailing and lighting choices. Explicit written materials, Keep choices, selected palette/style and scope take priority.';
          brief +=
              '\n\nDISTINCT REDESIGN OPTIONS: This batch is a choice between substantially different renovation schemes, not minor variations of one design. Planned directions:\n${[for (var j = 0; j < count; j++) '${j + 1}. ${batchDirections[j].$1}: ${shortDirections[batchDirections[j].$1]}'].join('\n')}\nRender ONLY option ${i + 1}, using its ${direction.$1} direction. Other entries are alternative briefs, not images you have already seen. Establish this option through major design decisions: material composition of main surfaces; finish, form or detailing of authorised cabinetry or main furnishings; and permitted lighting/fittings or focal treatment. Where the requested scope allows, make at least three of these decisions visibly distinct from the other planned schemes. Adding plants, ornaments, cushions, small accessories or a different camera exposure does not count as a different renovation. Do not keep the same cabinetry, surfaces and fittings and merely restage them.\nCONSTRAINT PRIORITY: Explicit user instructions, Keep choices, approved retained features, selected style and palette, room geometry and layout restrictions take priority. Use different allocations and textures within a fixed palette rather than forbidden colours. Only change elements authorised by the room brief; do not move walls, openings, plumbing positions or protected furniture to force variety. If constraints allow only limited alternatives, honour them rather than inventing changes or claiming a new layout. Treat the starting image as a geometry and retained-feature reference, not a mandate to copy every replaceable finish. Return one individual image for this option, not a collage.';
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
