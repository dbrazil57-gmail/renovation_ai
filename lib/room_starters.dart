/// Bundled fictional-room examples. These are preferences, never room sources.
class RoomStarter {
  final String id, title, roomTypeId, styleId, paletteId, asset, description;
  final bool anyRoom;
  const RoomStarter({
    required this.id,
    required this.title,
    required this.roomTypeId,
    required this.styleId,
    required this.paletteId,
    required this.asset,
    required this.description,
    this.anyRoom = false,
  });
}

const roomStarters = [
  RoomStarter(
    id: 'charcoal_kitchen',
    title: 'Charcoal & walnut kitchen',
    roomTypeId: 'kitchen',
    styleId: 'modern',
    paletteId: 'charcoal_walnut',
    asset: 'assets/inspiration/charcoal-kitchen.png',
    description: 'Handleless charcoal cabinetry, walnut accents, pale stone and warm greige tiles.',
  ),
  RoomStarter(
    id: 'sage_bathroom',
    title: 'Calm sage bathroom',
    roomTypeId: 'bathroom',
    styleId: 'japandi',
    paletteId: 'sage_oak',
    asset: 'assets/inspiration/sage-bathroom.png',
    description: 'Sage joinery, oak details and pale stone with a simple, uncluttered finish.',
  ),
  RoomStarter(
    id: 'coastal_living',
    title: 'Light coastal living',
    roomTypeId: 'living',
    styleId: 'coastal',
    paletteId: 'coastal',
    asset: 'assets/inspiration/coastal-living.png',
    description:
        'Soft white, sea blue and sand, with light timber and relaxed fabrics.',
  ),
  RoomStarter(
    id: 'white_oak_bedroom',
    title: 'Warm oak bedroom',
    roomTypeId: 'bedroom',
    styleId: 'scandinavian',
    paletteId: 'white_oak',
    asset: 'assets/inspiration/white-oak-bedroom.png',
    description: 'Warm white, pale oak and oatmeal linen for a calm bedroom.',
  ),
  RoomStarter(
    id: 'navy_classic_kitchen',
    title: 'Classic navy kitchen',
    roomTypeId: 'kitchen',
    styleId: 'hamptons',
    paletteId: 'navy_stone',
    asset: 'assets/inspiration/navy-classic-kitchen.png',
    description: 'Navy shaker cabinetry, pale stone and subtle brass fittings.',
  ),
  RoomStarter(
    id: 'industrial_office',
    title: 'Walnut home office',
    roomTypeId: 'office',
    styleId: 'industrial',
    paletteId: 'charcoal_walnut',
    asset: 'assets/inspiration/industrial-office.png',
    description: 'Walnut, charcoal metal and practical storage for a warm industrial study.',
  ),
];
