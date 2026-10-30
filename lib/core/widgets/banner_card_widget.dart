import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/models/banner_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class BannerCardWidget extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback? onTap;
  final double height;
  final double? width;
  final bool showShadow;
  final EdgeInsetsGeometry margin;

  const BannerCardWidget({
    super.key,
    required this.banner,
    this.onTap,
    this.height = 155.0,
    this.width,
    this.showShadow = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
  });

  static String resolveImageUrl(String url) {
    if (url.trim().isEmpty) return '';
    // Tratamento para a foto do iPhone que foi enviada anteriormente com compressão JPEG indevida
    if (url.contains('iphone17_PNG39') && url.contains('back4app.com')) {
      return 'https://pngimg.com/uploads/iphone17/iphone17_PNG39.png';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width ?? MediaQuery.of(context).size.width,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: banner.isImageOnly
                        ? Colors.black.withValues(alpha: 0.25)
                        : banner.startColor.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: banner.isImageOnly
              ? _buildImageOnlyBanner(context)
              : _buildCardBanner(context),
        ),
      ),
    );
  }

  Widget _buildImageOnlyBanner(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (banner.imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: resolveImageUrl(banner.imageUrl),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.darkCardColor,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.verdeVale,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.darkCardColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 36,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      banner.title.isNotEmpty
                          ? banner.title
                          : 'Banner Promocional',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: banner.gradient,
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.image,
                color: Colors.white38,
                size: 40,
              ),
            ),
          ),

        // Optional title scrim if title exists
        if (banner.title.isNotEmpty || banner.description.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banner.tagText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amareloVale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        banner.tagText.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.cinzaEscuro,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  if (banner.title.isNotEmpty)
                    Text(
                      banner.title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (banner.description.isNotEmpty)
                    Text(
                      banner.description,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardBanner(BuildContext context) {
    final bgIconData = BannerModel.getIconData(banner.bgIcon);
    final tagIconData = BannerModel.getIconData(banner.tagIcon);

    return Container(
      decoration: BoxDecoration(
        gradient: banner.gradient,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background glowing icon watermark
          if (bgIconData != null)
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: FaIcon(
                  bgIconData,
                  size: 85,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

          // Side illustration if imageUrl is provided in card mode (Showcase com sombra de piso e estrelinhas)
          if (banner.imageUrl.isNotEmpty)
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              width: 125,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildProductShowcase(),
              ),
            ),

          // Main Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tag
              if (banner.tagText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tagIconData != null) ...[
                        FaIcon(
                          tagIconData,
                          size: 10,
                          color: AppColors.amareloVale,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        banner.tagText.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.amareloVale,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

              // Title
              if (banner.title.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    right: banner.imageUrl.isNotEmpty ? 125.0 : 40.0,
                  ),
                  child: Text(
                    banner.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 3),

              // Description
              if (banner.description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    right: banner.imageUrl.isNotEmpty ? 125.0 : 30.0,
                  ),
                  child: Text(
                    banner.description,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 10),

              // Button
              if (banner.buttonText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amareloVale,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amareloVale.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner.buttonText,
                        style: GoogleFonts.poppins(
                          color: AppColors.cinzaEscuro,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const FaIcon(
                        FontAwesomeIcons.arrowRight,
                        size: 9,
                        color: AppColors.cinzaEscuro,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductShowcase() {
    return SizedBox(
      width: 125,
      height: 125,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Estrela de 4 pontas decorativa dourada/amarela (canto superior direito)
          const Positioned(
            top: 4,
            right: 8,
            child: _SparkleWidget(
              color: Color(0xFFF3A522),
              size: 14,
            ),
          ),

          // 2. Estrela de 4 pontas decorativa ciano (canto inferior esquerdo)
          const Positioned(
            bottom: 22,
            left: 6,
            child: _SparkleWidget(
              color: Color(0xFF00A4B4),
              size: 10,
            ),
          ),

          // 3. Mini estrela brilhante branca (topo esquerdo suave)
          Positioned(
            top: 24,
            left: 10,
            child: _SparkleWidget(
              color: Colors.white.withValues(alpha: 0.85),
              size: 7,
            ),
          ),

          // 4. Sombra de piso suave elíptica abaixo do produto
          Positioned(
            bottom: 12,
            child: Container(
              width: 70,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 5. Imagem do Objeto (PNG transparente recortado)
          Positioned(
            top: 2,
            bottom: 16,
            left: 6,
            right: 6,
            child: CachedNetworkImage(
              imageUrl: resolveImageUrl(banner.imageUrl),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              placeholder: (context, url) => const SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white24,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SPARKLE WIDGET & PAINTER (Estrelas de 4 pontas decorativas com brilho)
// =============================================================================
class _SparkleWidget extends StatelessWidget {
  final Color color;
  final double size;

  const _SparkleWidget({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;
    const waist = 0.16;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy * (1 - waist), cx + (w / 2) * waist, cy);
    path.quadraticBezierTo(cx + (w / 2) * (1 - waist), cy, w, cy);
    path.quadraticBezierTo(cx + (w / 2) * waist, cy, cx, cy + (h / 2) * waist);
    path.quadraticBezierTo(cx, cy + (h / 2) * (1 - waist), cx, h);
    path.quadraticBezierTo(cx, cy + (h / 2) * waist, cx - (w / 2) * waist, cy);
    path.quadraticBezierTo(cx - (w / 2) * (1 - waist), cy, 0, cy);
    path.quadraticBezierTo(cx - (w / 2) * waist, cy, cx, cy * (1 - waist));
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
