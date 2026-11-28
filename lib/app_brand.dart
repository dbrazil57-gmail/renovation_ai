/// Public branding only. Package IDs, project formats and device data retain
/// their existing identifiers so updating the name cannot orphan saved work.
const appName = 'RenoImagineAI';
const appTagline = 'Snap. Imagine. Renovate.';
const appDescription = 'Australian designed. Globally inspired.';

// Eucalyptus & stone: shared by app UI, vector exports and draft media.
const brandForestArgb = 0xFF243C34;
const brandEucalyptusArgb = 0xFF9BB29E;
const brandActionArgb = 0xFF476452;
const brandPaperArgb = 0xFFF5F2EB;
const brandPanelArgb = 0xFFFFFEFA;
const brandInkArgb = 0xFF29352F;
const brandSelectionArgb = 0xFFDFE7DE;
String brandRgbHex(int argb) =>
    (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
