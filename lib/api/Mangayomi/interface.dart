import 'Eval/dart/model/filter.dart';
import 'Eval/dart/model/m_manga.dart';
import 'Eval/dart/model/m_pages.dart';
import 'Eval/dart/model/page.dart';
import 'Eval/dart/model/source_preference.dart';
import 'Eval/dart/model/video.dart';
import 'Model/Source.dart';

abstract interface class ExtensionService {
  late Source source;

  ExtensionService(this.source);

  String get sourceBaseUrl;

  bool get supportsLatest;

  Map<String, String> getHeaders();

  Future<MPages> getPopular(int page);

  Future<MPages> getLatestUpdates(int page);

  Future<MPages> search(String query, int page, List<dynamic> filters);

  Future<MManga> getDetail(String url);

  Future<List<PageUrl>> getPageList(String url);

  Future<List<Video>> getVideoList(String url);

  Future<String> getHtmlContent(String url);

  Future<String> cleanHtmlContent(String html);

  FilterList getFilterList();

  List<SourcePreference> getSourcePreferences();
}
