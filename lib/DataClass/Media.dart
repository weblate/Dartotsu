import 'package:dantotsu/Functions/string_extensions.dart';
import 'package:dantotsu/api/Mangayomi/Model/Source.dart';
import 'package:json_annotation/json_annotation.dart';

import '../Preferences/IsarDataClasses/Selected/Selected.dart';
import '../api/Anilist/Data/fuzzyData.dart';
import '../api/Anilist/Data/media.dart' as anilistApi;
import '../api/Anilist/Data/others.dart';
import '../api/EpisodeDetails/GetMediaIDs/GetMediaIDs.dart';
import '../api/MyAnimeList/Data/media.dart' as malApi;
import '../api/Simkl/Data/Media.dart' as simklApi;
import 'Anime.dart';
import 'Author.dart';
import 'Character.dart';
import 'Manga.dart';
import 'User.dart';

part 'Data/Media.g.dart';
part 'Media/AnilistMedia.dart';
part 'Media/MalMedia.dart';
part 'Media/SimklMedia.dart';

class MediaMapWrapper {
  final Map<String, List<Media>> mediaMap;

  MediaMapWrapper({required this.mediaMap});

  factory MediaMapWrapper.fromJson(Map<String, dynamic> json) {
    return MediaMapWrapper(
      mediaMap: json.map((key, value) => MapEntry(
          key, (value as List).map((e) => Media.fromJson(e)).toList())),
    );
  }

  Map<String, dynamic> toJson() {
    return mediaMap.map((key, value) =>
        MapEntry(key, value.map((media) => media.toJson()).toList()));
  }
}

@JsonSerializable()
class Media {
  final Anime? anime;
  final Manga? manga;
  int id;

  String? typeMAL;
  final String? name;
  final String nameRomaji;
  final String userPreferredName;

  String? cover;
  String? banner;
  String? relation;
  int? favourites;
  bool? minimal = false;
  bool isAdult;
  bool isFav = false;
  bool notify = false;

  int? userListId;
  bool isListPrivate = false;
  String? notes;
  int? userProgress;
  String? userStatus;
  int? userScore = 0;
  int userRepeat = 0;
  int? userUpdatedAt;
  dynamic userStartedAt = FuzzyDate();
  dynamic userCompletedAt = FuzzyDate();
  Map<String, bool>? inCustomListsOf;
  int? userFavOrder;

  final String? status;
  String? format;
  String? source;
  String? countryOfOrigin;
  final int? meanScore;
  List<String> genres = [];
  List<String> tags = [];
  String? description;
  List<String> synonyms = [];
  String? trailer;
  FuzzyDate? startDate;
  FuzzyDate? endDate;
  int? popularity;

  int? timeUntilAiring;

  List<character>? characters;
  List<Review>? review;
  List<author>? staff;
  Media? prequel;
  Media? sequel;
  List<Media>? relations;
  List<Media>? recommendations;
  List<userData>? users;
  String? vrvId;
  String? crunchySlug;

  String? nameMAL;
  String? shareLink;
  Selected? selected;
  List<anilistApi.MediaStreamingEpisode>? streamingEpisodes;

  bool cameFromContinue = false;
  bool mal = false;
  bool kitsu = false;
  int? idAnilist;
  int? idMAL;
  String? idKitsu;
  int? idSimkl;
  Source? sourceData;

  Media({
    this.anime,
    this.manga,
    required this.id,
    this.typeMAL,
    this.name,
    required this.nameRomaji,
    required this.userPreferredName,
    this.cover,
    this.banner,
    this.relation,
    this.favourites,
    this.minimal = false,
    this.isAdult = false,
    this.isFav = false,
    this.notify = false,
    this.userListId,
    this.isListPrivate = false,
    this.notes,
    this.userProgress,
    this.userStatus,
    this.userScore = 0,
    this.userRepeat = 0,
    this.userUpdatedAt,
    this.userStartedAt = 0,
    this.userCompletedAt = 0,
    this.inCustomListsOf,
    this.userFavOrder,
    this.status,
    this.format,
    this.source,
    this.countryOfOrigin,
    this.meanScore,
    this.genres = const [],
    this.tags = const [],
    this.description,
    this.synonyms = const [],
    this.trailer,
    this.startDate,
    this.endDate,
    this.popularity,
    this.timeUntilAiring,
    this.characters,
    this.review,
    this.staff,
    this.prequel,
    this.sequel,
    this.relations,
    this.recommendations,
    this.users,
    this.vrvId,
    this.crunchySlug,
    this.nameMAL,
    this.shareLink,
    this.selected,
    this.streamingEpisodes,
    this.idKitsu,
    this.idAnilist,
    this.idMAL,
    this.idSimkl,
    this.cameFromContinue = false,
    this.mal = false,
    this.kitsu = false,
    this.sourceData,
  });

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

  Map<String, dynamic> toJson() => _$MediaToJson(this);

  String mainName() => name ?? nameMAL ?? nameRomaji;

  String mangaName() => countryOfOrigin == 'JP' ? mainName() : nameRomaji;

  //Anilist
  static Media mediaData(anilistApi.Media apiMedia) => _mediaData(apiMedia);

  static Media mediaEdgeData(anilistApi.MediaEdge apiMediaEdge) =>
      _mediaEdgeData(apiMediaEdge);

  static Media mediaListData(anilistApi.MediaList mediaList) =>
      _mediaListData(mediaList);

  //MyAnimeList
  static Media fromMal(malApi.Media apiMedia) => _fromMal(apiMedia);

  //Simkl
  static Media fromSimklAnime(simklApi.Anime apiMedia) =>
      _fromSimklAnime(apiMedia);

  static Media fromSimklSeries(simklApi.ShowElement apiMedia) =>
      _fromSimklSeries(apiMedia);

  static Media fromSimklMovies(simklApi.MovieElement apiMedia) =>
      _fromSimklMovies(apiMedia);
}
