part of '../Media.dart';

Media _fromSimklAnime(simklApi.Anime apiMedia) {
  var cover =
      'https://wsrv.nl/?url=https://simkl.in/posters/${apiMedia.show?.poster}_m.webp';
  return Media(
    id: apiMedia.show!.ids!.simkl!,
    idAnilist: apiMedia.show!.ids!.anilist?.toNullInt(),
    idSimkl: apiMedia.show!.ids!.simkl!,
    idKitsu: apiMedia.show!.ids!.kitsu?.toNullInt()?.toString(),
    idMAL: apiMedia.show!.ids!.mal?.toNullInt(),
    nameRomaji: apiMedia.show!.title ?? '',
    userPreferredName: apiMedia.show!.title ?? '',
    cover: cover,
    banner: cover,
    userStatus: apiMedia.status?.name,
    userProgress: apiMedia.watchedEpisodesCount,
    userScore: (apiMedia.userRating?.toInt() ?? 0) * 10,
    meanScore: ((apiMedia.rating ?? 0) * 10).toInt(),
    format: 'anime',
    status: _mapSimklAiringStatus(
        apiMedia.releaseStatus?.toLowerCase() ?? 'UNKNOWN'),
    anime: Anime(
      totalEpisodes: apiMedia.totalEpisodesCount,
    ),
    isAdult: false,
  );
}

Media _fromSimklSeries(simklApi.ShowElement apiMedia) {
  var cover =
      'https://wsrv.nl/?url=https://simkl.in/posters/${apiMedia.show?.poster}_m.webp';
  return Media(
    id: apiMedia.show!.ids!.simkl!,
    idAnilist: apiMedia.show!.ids!.anilist?.toNullInt(),
    idSimkl: apiMedia.show!.ids!.simkl!,
    idKitsu: apiMedia.show!.ids!.kitsu?.toNullInt()?.toString(),
    idMAL: apiMedia.show!.ids!.mal?.toNullInt(),
    nameRomaji: apiMedia.show?.title ?? '',
    userPreferredName: apiMedia.show?.title ?? '',
    cover: cover,
    banner: cover,
    userStatus: apiMedia.status?.name,
    userProgress: apiMedia.watchedEpisodesCount,
    userScore: (apiMedia.userRating?.toInt() ?? 0) * 10,
    meanScore: ((apiMedia.rating ?? 0) * 10).toInt(),
    status: _mapSimklAiringStatus(
        apiMedia.releaseStatus?.toLowerCase() ?? 'UNKNOWN'),
    format: 'tvShow',
    anime: Anime(
      totalEpisodes: apiMedia.totalEpisodesCount,
    ),
    isAdult: false,
  );
}

Media _fromSimklMovies(simklApi.MovieElement apiMedia) {
  var cover =
      'https://wsrv.nl/?url=https://simkl.in/posters/${apiMedia.movie?.poster}_m.webp';
  return Media(
    id: apiMedia.movie!.ids!.simkl!,
    idAnilist: apiMedia.movie!.ids!.anilist?.toNullInt(),
    idSimkl: apiMedia.movie!.ids!.simkl!,
    idKitsu: apiMedia.movie!.ids!.kitsu?.toNullInt()?.toString(),
    idMAL: apiMedia.movie!.ids!.mal?.toNullInt(),
    nameRomaji: apiMedia.movie!.title ?? '',
    userPreferredName: apiMedia.movie!.title ?? '',
    cover: cover,
    banner: cover,
    userStatus: apiMedia.status?.name,
    userProgress: apiMedia.watchedEpisodesCount,
    userScore: (apiMedia.userRating?.toInt() ?? 0) * 10,
    meanScore: ((apiMedia.rating ?? 0) * 10).toInt(),
    status: _mapSimklAiringStatus(
        apiMedia.releaseStatus?.toLowerCase() ?? 'UNKNOWN'),
    format: 'movie',
    anime: Anime(
      totalEpisodes: 1,
    ),
    isAdult: false,
  );
}

String _mapSimklAiringStatus(String status) {
  switch (status) {
    case 'ended':
      return 'FINISHED';
    case 'ongoing':
      return 'RELEASING';
    case 'upcoming':
      return 'NOT_YET_RELEASED';
    default:
      return status.toUpperCase();
  }
}
