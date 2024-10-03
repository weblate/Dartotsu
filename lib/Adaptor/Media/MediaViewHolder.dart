import 'package:dantotsu/DataClass/Media.dart';
import 'package:flutter/material.dart';

import '../../Widgets/CachedNetworkImage.dart';
import 'Widgets/MediaReleaseingIndicator.dart';
import 'Widgets/MediaScoreBadge.dart';

class MediaViewHolder extends StatelessWidget {
  final media mediaInfo;
  final bool isLarge;

  const MediaViewHolder(
      {super.key, required this.mediaInfo, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    // holder for media
    final theme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: cachedNetworkImage(
                imageUrl: mediaInfo.cover ?? '',
                fit: BoxFit.cover,
                width: 108,
                height: 160,
                placeholder: (context, url) => Container(
                  color: Colors.white12,
                  width: 108,
                  height: 160,
                ),
              ),
            ),
            if (mediaInfo.status == 'RELEASING') ReleasingIndicator(),
            ScoreBadge(context, mediaInfo),
          ],
        ),
        if (isLarge && mediaInfo.relation != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mediaInfo.anime != null
                      ? Icons.movie_filter_rounded
                      : Icons.import_contacts,
                  size: 16,
                  color: theme.onSurface.withOpacity(0.58),
                ),
                const SizedBox(width: 4),
                Text(
                  mediaInfo.relation ?? "",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: theme.onSurface.withOpacity(0.58),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

        ],
        const SizedBox(height: 8),
        Text(
          mediaInfo.userPreferredName,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${mediaInfo.userProgress ?? "~"}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: theme.secondary,
                  fontSize: 14,
                ),
              ),
              const TextSpan(
                text: ' | ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: mediaInfo.anime == null
                    ? "${mediaInfo.manga?.totalChapters ?? "~"}"
                    : formatMediaInfo(mediaInfo),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String formatMediaInfo(media media) {
  final nextAiringEpisode = media.anime?.nextAiringEpisode;
  final totalEpisodes = media.anime?.totalEpisodes?.toString() ?? "~";

  return nextAiringEpisode != null && nextAiringEpisode != -1
      ? "$nextAiringEpisode | $totalEpisodes"
      : totalEpisodes;
}
