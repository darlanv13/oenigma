import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeBannerCarousel extends StatelessWidget {
  const HomeBannerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParseResponse>(
      future:
          (QueryBuilder<ParseObject>(ParseObject('Banner'))
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
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 150.0,
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
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // Fundo escuro premium
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFD54F),
                              ),
                            ),
                            errorWidget: (context, url, error) => const FaIcon(
                              FontAwesomeIcons.circleExclamation,
                              color: Colors.grey,
                            ),
                          )
                        : const Center(
                            child: FaIcon(
                              FontAwesomeIcons.image,
                              color: Colors.grey,
                            ),
                          ),
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
