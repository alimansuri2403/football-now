import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';

class PlayerAvatar extends StatelessWidget {
  final Player player;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.radius = 24,
    this.fontSize,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = player.name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    final Color bgColor = backgroundColor ?? theme.colorScheme.primary.withOpacity(0.12);
    final TextStyle textStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
      fontSize: fontSize ?? (radius * 0.7),
    );

    if (player.photoUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(initials, style: textStyle),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: player.photoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Center(
            child: Text(initials, style: textStyle),
          ),
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
