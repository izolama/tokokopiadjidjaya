import 'package:flutter/material.dart';

class CoffeeHeroImage extends StatelessWidget {
  const CoffeeHeroImage({
    super.key,
    required this.heroTag,
    this.imageProvider,
    this.radius = 20,
    this.aspectRatio = 1.0,
    this.fit = BoxFit.cover,
  });

  final String heroTag;
  final ImageProvider? imageProvider;
  final double radius;
  final double? aspectRatio;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = const AssetImage('assets/ic_tokokopi.png');
    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
            child: toHeroContext.widget,
          ),
        );
      },
      child: aspectRatio == null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox.expand(
                child: Image(
                  image: imageProvider ?? fallback,
                  fit: fit,
                  alignment: Alignment.center,
                ),
              ),
            )
          : AspectRatio(
              aspectRatio: aspectRatio!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image(
                  image: imageProvider ?? fallback,
                  fit: fit,
                  alignment: Alignment.center,
                ),
              ),
            ),
    );
  }
}
