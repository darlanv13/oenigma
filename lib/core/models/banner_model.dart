import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class BannerModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String actionUrl;
  final String tagText;
  final String tagIcon;
  final String buttonText;
  final String bgIcon;
  final int order;
  final bool isActive;
  final String bannerType; // 'card' or 'image'
  final String gradientStartHex;
  final String gradientEndHex;
  final String colorHex;

  const BannerModel({
    required this.id,
    this.title = '',
    this.description = '',
    this.imageUrl = '',
    this.actionUrl = '',
    this.tagText = '',
    this.tagIcon = '',
    this.buttonText = '',
    this.bgIcon = '',
    this.order = 1,
    this.isActive = true,
    this.bannerType = 'card',
    this.gradientStartHex = '#005861',
    this.gradientEndHex = '#007D8A',
    this.colorHex = '#007D8A',
  });

  bool get isImageOnly =>
      bannerType == 'image' || (imageUrl.isNotEmpty && title.trim().isEmpty);

  Color get startColor =>
      _parseColor(gradientStartHex, defaultColor: const Color(0xFF005861));
  Color get endColor =>
      _parseColor(gradientEndHex, defaultColor: const Color(0xFF007D8A));

  LinearGradient get gradient => LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Color _parseColor(String? hexString, {required Color defaultColor}) {
    if (hexString == null || hexString.trim().isEmpty) return defaultColor;
    try {
      String cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  static String colorToHex(Color color) {
    final int argb = color.toARGB32();
    return '#${(argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static FaIconData? getIconData(String? iconName) {
    if (iconName == null || iconName.trim().isEmpty) return null;
    switch (iconName.toLowerCase().trim()) {
      case 'trophy':
      case 'trofeu':
        return FontAwesomeIcons.trophy;
      case 'fire':
      case 'fogo':
        return FontAwesomeIcons.fire;
      case 'star':
      case 'estrela':
        return FontAwesomeIcons.star;
      case 'bolt':
      case 'raio':
        return FontAwesomeIcons.bolt;
      case 'crown':
      case 'coroa':
        return FontAwesomeIcons.crown;
      case 'gem':
      case 'diamante':
        return FontAwesomeIcons.gem;
      case 'gamepad':
      case 'jogos':
        return FontAwesomeIcons.gamepad;
      case 'playstation':
        return FontAwesomeIcons.playstation;
      case 'mobile':
      case 'mobile-alt':
      case 'celular':
        return FontAwesomeIcons.mobileScreenButton;
      case 'gift':
      case 'presente':
        return FontAwesomeIcons.gift;
      case 'compass':
      case 'bussola':
        return FontAwesomeIcons.compass;
      case 'rocket':
      case 'foguete':
        return FontAwesomeIcons.rocket;
      case 'bell':
      case 'sino':
        return FontAwesomeIcons.bell;
      case 'wallet':
      case 'carteira':
        return FontAwesomeIcons.wallet;
      case 'bullhorn':
      case 'megafone':
        return FontAwesomeIcons.bullhorn;
      case 'shield':
      case 'escudo':
        return FontAwesomeIcons.shieldHalved;
      case 'sparkles':
      case 'brilho':
        return FontAwesomeIcons.wandMagicSparkles;
      case 'download':
        return FontAwesomeIcons.download;
      case 'clock':
      case 'relogio':
        return FontAwesomeIcons.clock;
      case 'tag':
        return FontAwesomeIcons.tag;
      case 'ticket':
      case 'ingresso':
        return FontAwesomeIcons.ticket;
      default:
        return FontAwesomeIcons.star;
    }
  }

  factory BannerModel.fromParse(ParseObject doc) {
    final rawOrder = doc.get<num>('order');
    final active = doc.get<bool>('isActive') ?? doc.get<bool>('active') ?? true;
    final img = doc.get<String>('imageUrl') ?? '';
    final tit = doc.get<String>('title') ?? '';
    final rawType = doc.get<String>('bannerType');

    final type = rawType != null && rawType.isNotEmpty
        ? rawType
        : (img.isNotEmpty && tit.trim().isEmpty ? 'image' : 'card');

    final colorHex = doc.get<String>('colorHex') ?? '#007D8A';
    final gradStart = doc.get<String>('gradientStartHex') ??
        (doc.get<String>('colorHex') ?? '#005861');
    final gradEnd = doc.get<String>('gradientEndHex') ?? '#007D8A';

    return BannerModel(
      id: doc.objectId ?? '',
      title: tit,
      description: doc.get<String>('description') ?? '',
      imageUrl: img,
      actionUrl: doc.get<String>('actionUrl') ?? '',
      tagText: doc.get<String>('tagText') ?? '',
      tagIcon: doc.get<String>('tagIcon') ?? '',
      buttonText: doc.get<String>('buttonText') ?? '',
      bgIcon: doc.get<String>('bgIcon') ?? '',
      order: rawOrder?.toInt() ?? 1,
      isActive: active,
      bannerType: type,
      gradientStartHex: gradStart,
      gradientEndHex: gradEnd,
      colorHex: colorHex,
    );
  }

  Map<String, dynamic> toParseMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'tagText': tagText,
      'tagIcon': tagIcon,
      'buttonText': buttonText,
      'bgIcon': bgIcon,
      'order': order,
      'isActive': isActive,
      'active': isActive, // Double write for backward compatibility
      'bannerType': bannerType,
      'gradientStartHex': gradientStartHex,
      'gradientEndHex': gradientEndHex,
      'colorHex': colorHex,
    };
  }
}
