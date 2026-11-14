/// Stable preset IDs are saved with rooms; generated prompts snapshot the
/// names, surface suggestions and hex values used for each design version.
class PaletteColour {
  final String name;
  final int rgb;
  final String surface;
  const PaletteColour(this.name, this.rgb, this.surface);
  String get hex => '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class DesignPalette {
  final String id;
  final String name;
  final List<PaletteColour> colours;
  const DesignPalette(this.id, this.name, this.colours);

  String prompt({required bool precise}) =>
      'COLOUR PALETTE: $name. ${colours.map((colour) => '${colour.surface}: ${colour.name} (${colour.hex})').join('; ')}. '
      '${precise ? 'Apply this palette only to the explicitly requested edit areas. It does not authorise recolouring the whole room or altering protected features.' : 'Use these colours as a coordinated direction for the requested redesign; respect protected features.'} '
      'Surface assignments are suggestions, not permission to replace or repaint a protected item. Colours are visual references, not exact paint-brand or material matches.';
}

const designPalettes = [
  DesignPalette('warm_neutrals', 'Warm neutrals', [
    PaletteColour('Warm white', 0xF4EFE6, 'Walls'),
    PaletteColour('Mushroom', 0xB6A89A, 'Cabinetry'),
    PaletteColour('Limestone', 0xD8CFBF, 'Worktops / finishes'),
    PaletteColour('Bronze', 0x7D6247, 'Accents'),
  ]),
  DesignPalette('charcoal_walnut', 'Charcoal & walnut', [
    PaletteColour('Soft ivory', 0xF1EDE5, 'Walls'),
    PaletteColour('Warm charcoal', 0x383A37, 'Cabinetry'),
    PaletteColour('Walnut brown', 0x77523B, 'Timber / finishes'),
    PaletteColour('Brushed brass', 0xB49761, 'Accents'),
  ]),
  DesignPalette('sage_oak', 'Sage & oak', [
    PaletteColour('Chalk white', 0xF1F1E8, 'Walls'),
    PaletteColour('Sage green', 0x98A58E, 'Cabinetry'),
    PaletteColour('Natural oak', 0xC49F73, 'Timber / finishes'),
    PaletteColour('Graphite', 0x454A46, 'Accents'),
  ]),
  DesignPalette('coastal', 'Coastal blues', [
    PaletteColour('Cloud white', 0xF4F6F3, 'Walls'),
    PaletteColour('Sea blue', 0x7897A7, 'Cabinetry'),
    PaletteColour('Sand', 0xD7C7AC, 'Worktops / finishes'),
    PaletteColour('Deep blue', 0x304D60, 'Accents'),
  ]),
  DesignPalette('navy_stone', 'Navy & stone', [
    PaletteColour('Porcelain', 0xF2F0EB, 'Walls'),
    PaletteColour('Navy', 0x273B52, 'Cabinetry'),
    PaletteColour('Pale stone', 0xCAC5BA, 'Worktops / finishes'),
    PaletteColour('Antique gold', 0xAB8C54, 'Accents'),
  ]),
  DesignPalette('earthy', 'Earthy terracotta', [
    PaletteColour('Cream', 0xF3E8D5, 'Walls'),
    PaletteColour('Clay', 0xB96F52, 'Cabinetry'),
    PaletteColour('Travertine', 0xD1BA99, 'Worktops / finishes'),
    PaletteColour('Olive', 0x6D7350, 'Accents'),
  ]),
  DesignPalette('monochrome', 'Soft monochrome', [
    PaletteColour('Soft white', 0xF7F7F2, 'Walls'),
    PaletteColour('Graphite', 0x414446, 'Cabinetry'),
    PaletteColour('Silver grey', 0xBCBFC0, 'Worktops / finishes'),
    PaletteColour('Black', 0x202425, 'Accents'),
  ]),
];

DesignPalette? paletteById(String? id) {
  for (final palette in designPalettes) {
    if (palette.id == id) return palette;
  }
  return null;
}
