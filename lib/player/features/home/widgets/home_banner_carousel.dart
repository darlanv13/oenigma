import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oenigma/core/models/banner_model.dart';
import 'package:oenigma/core/widgets/banner_card_widget.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int _currentCarouselIndex = 0;
  late Future<List<BannerModel>> _bannersFuture;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  void _loadBanners() {
    _bannersFuture = _fetchBanners();
  }

  Future<List<BannerModel>> _fetchBanners() async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Banner'))
        ..orderByAscending('order');

      final response = await query.query();

      if (response.success && response.results != null) {
        final list = response.results as List<ParseObject>;
        return list
            .map((doc) => BannerModel.fromParse(doc))
            .where((banner) => banner.isActive)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _handleBannerTap(String actionUrl) async {
    if (actionUrl.trim().isEmpty) return;
    final trimmed = actionUrl.trim();

    try {
      final Uri? url = Uri.tryParse(trimmed);
      if (url != null && (url.scheme == 'http' || url.scheme == 'https')) {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: _bannersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Elegant subtle placeholder height matching banner height
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        final bool hasMultipleBanners = banners.length > 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 155.0,
                  autoPlay: hasMultipleBanners,
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: false,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: hasMultipleBanners,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentCarouselIndex = index;
                    });
                  },
                ),
                items: banners.map((banner) {
                  return BannerCardWidget(
                    banner: banner,
                    onTap: () => _handleBannerTap(banner.actionUrl),
                  );
                }).toList(),
              ),
              if (hasMultipleBanners) ...[
                const SizedBox(height: 8),
                // Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: banners.asMap().entries.map((entry) {
                    final isSelected = _currentCarouselIndex == entry.key;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isSelected ? 20.0 : 6.0,
                      height: 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isSelected
                            ? AppColors.verdeVale
                            : AppColors.cinzaBorda,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
