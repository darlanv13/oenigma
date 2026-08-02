import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _currentCarouselIndex = 0;

  FaIconData? _getIconData(String iconName) {
    if (iconName.isEmpty) return null;
    switch (iconName.toLowerCase()) {
      case 'trophy':
        return FontAwesomeIcons.trophy;
      case 'playstation':
        return FontAwesomeIcons.playstation;
      case 'mobile':
      case 'mobile-alt':
        return FontAwesomeIcons.mobileScreenButton;
      case 'fire':
        return FontAwesomeIcons.fire;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
      case 'download':
        return FontAwesomeIcons.download;
      default:
        return FontAwesomeIcons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParseResponse>(
      future: (QueryBuilder<ParseObject>(ParseObject('Banner'))
            ..whereEqualTo('isActive', true)
            ..orderByAscending('order'))
          .query(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            !snapshot.data!.success ||
            snapshot.data!.results == null ||
            snapshot.data!.results!.isEmpty) {
          return const SizedBox.shrink(); // Hide if no banners
        }

        final banners = snapshot.data!.results as List<ParseObject>;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 150.0, // Fixed height from HTML banner-carousel-wrapper
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: false,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentCarouselIndex = index;
                    });
                  },
                ),
                items: banners.map((doc) {
                  // final imageUrl = doc.get<String>('imageUrl') ?? '';
                  final actionUrl = doc.get<String>('actionUrl') ?? '';
                  final title = doc.get<String>('title') ?? '';
                  final description = doc.get<String>('description') ?? '';
                  final tagText = doc.get<String>('tagText') ?? '';
                  final tagIcon = doc.get<String>('tagIcon') ?? '';
                  final buttonText = doc.get<String>('buttonText') ?? '';
                  final bgIcon = doc.get<String>('bgIcon') ?? '';

                  return GestureDetector(
                    onTap: () async {
                      if (actionUrl.isNotEmpty) {
                        final Uri url = Uri.parse(actionUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06080B),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: const Color(0xFFC0A060).withValues(alpha: 0.20),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        gradient: const RadialGradient(
                          center: Alignment(-0.4, -0.4), // roughly 30% 30%
                          radius: 1.2,
                          colors: [
                            Color(0xFF1a2f35),
                            Color(0xFF06080b),
                          ],
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background glowing icon
                          Positioned(
                            right: -10,
                            top: 0,
                            bottom: 0,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _getIconData(bgIcon) != null
                                ? FaIcon(
                                    _getIconData(bgIcon)!,
                                    size: 80, // roughly 4.5rem
                                    color: const Color(0xFFC0A060).withValues(alpha: 0.10),
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFC0A060).withValues(alpha: 0.05),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                            ),
                          ),
                          // Content
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Tag
                              if (tagText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC0A060).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFC0A060).withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (tagIcon.isNotEmpty) ...[
                                        if (_getIconData(tagIcon) != null)
                                          FaIcon(
                                            _getIconData(tagIcon)!,
                                            size: 10,
                                            color: const Color(0xFFC0A060),
                                          ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        tagText.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFFC0A060),
                                          fontSize: 9, // roughly 0.55rem
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Title
                              if (title.isNotEmpty)
                                Text(
                                  title,
                                  style: GoogleFonts.orbitron(
                                    color: const Color(0xFFF0E6C5),
                                    fontSize: 20, // roughly 1.3rem
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 2),
                              // Description
                              if (description.isNotEmpty)
                                Text(
                                  description,
                                  style: const TextStyle(
                                    color: Color(0xFFB0A07A),
                                    fontSize: 12, // roughly 0.75rem
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              // Button
                              if (buttonText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFC0A060),
                                        Color(0xFFA8894A),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFC0A060).withValues(alpha: 0.3),
                                        spreadRadius: 0,
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    buttonText,
                                    style: GoogleFonts.orbitron(
                                      color: const Color(0xFF06080B),
                                      fontSize: 10, // roughly 0.6rem
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: banners.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentCarouselIndex == entry.key
                          ? const Color(0xFFC0A060)
                          : const Color(0xFF3A3A3A),
                      boxShadow: _currentCarouselIndex == entry.key
                          ? [
                              BoxShadow(
                                color: const Color(0xFFC0A060).withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }
}
