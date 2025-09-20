# Images Directory

This directory contains PNG images that can be used as icons in the Flutter app.

## How to Use PNG Images as Icons

### 1. Add PNG files to this directory
Place your PNG files directly in this folder, for example:
- `policy_icon.png`
- `subsidy_icon.png`
- `weather_icon.png`
- `crop_icon.png`

### 2. Use in Flutter code
```dart
// Using Image.asset for PNG icons
Image.asset(
  'assets/images/policy_icon.png',
  width: 24,
  height: 24,
)

// Or using Container with DecorationImage
Container(
  width: 24,
  height: 24,
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/policy_icon.png'),
      fit: BoxFit.contain,
    ),
  ),
)
```

### 3. Best Practices
- Use PNG format for icons with transparency
- Recommended sizes: 24x24, 32x32, 48x48, 64x64 pixels
- Use descriptive filenames
- Consider creating different sizes for different screen densities

### 4. After adding new images
Run `flutter pub get` to refresh the asset bundle.
