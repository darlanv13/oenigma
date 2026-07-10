import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class HomeBannerCarousel extends StatelessWidget {
  const HomeBannerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParseResponse>(
      future: (QueryBuilder<ParseObject>(ParseObject('Banner'))
            ..whereEqualTo('isActive', true)
            ..orderByAscending('order'))
          .query(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.success || snapshot.data!.results == null || snapshot.data!.results!.isEmpty) {
          return const SizedBox.shrink(); // Hide if no banners
        }

        final banners = snapshot.data!.results as List<ParseObject>;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 100.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              initialPage: 0,
            ),
            items: banners.map((doc) {
              final imageUrl = doc.get<String>('imageUrl') ?? '';
              final actionUrl = doc.get<String>('actionUrl') ?? '';

              return GestureDetector(
                onTap: () async {
                  if (actionUrl.isNotEmpty) {
                     final Uri url = Uri.parse(actionUrl);
                     if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                     }
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: primaryAmber)),
                            errorWidget: (context, url, error) => const FaIcon(FontAwesomeIcons.circleExclamation),
                          )
                        : const Center(child: FaIcon(FontAwesomeIcons.image, color: secondaryTextColor)),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
