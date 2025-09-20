import 'package:flutter/material.dart';

class PngIcon extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackSize;

  const PngIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.image,
    this.fallbackSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      color: color,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to Material Icon if PNG not found
        return Icon(
          fallbackIcon,
          color: color,
          size: fallbackSize,
        );
      },
    );
  }
}

// Predefined icon paths for common use cases
class AppIcons {
  static const String appIcon = 'assets/images/ico.jpg';
  static const String policy = 'assets/images/policy_icon.png';
  static const String subsidy = 'assets/images/subsidy_icon.png';
  static const String weather = 'assets/images/weather_icon.png';
  static const String crop = 'assets/images/crop_icon.png';
  static const String disease = 'assets/images/disease_icon.png';
  static const String calendar = 'assets/images/calendar_icon.png';
  static const String profile = 'assets/images/profile_icon.png';
  static const String scan = 'assets/images/scan_icon.png';
}

// Convenience constructors for common icons
class PolicyIcon extends PngIcon {
  const PolicyIcon({
    super.key,
    super.width = 24,
    super.height = 24,
    super.color,
    super.fallbackIcon = Icons.description,
  }) : super(assetPath: AppIcons.policy);
}

class SubsidyIcon extends PngIcon {
  const SubsidyIcon({
    super.key,
    super.width = 24,
    super.height = 24,
    super.color,
    super.fallbackIcon = Icons.payments,
  }) : super(assetPath: AppIcons.subsidy);
}

class WeatherIcon extends PngIcon {
  const WeatherIcon({
    super.key,
    super.width = 24,
    super.height = 24,
    super.color,
    super.fallbackIcon = Icons.wb_sunny,
  }) : super(assetPath: AppIcons.weather);
}

class AppIcon extends PngIcon {
  const AppIcon({
    super.key,
    super.width = 24,
    super.height = 24,
    super.color,
    super.fallbackIcon = Icons.apps,
  }) : super(assetPath: AppIcons.appIcon);
}
