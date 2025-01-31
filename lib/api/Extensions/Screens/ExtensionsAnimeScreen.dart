import 'package:dantotsu/api/Mangayomi/Eval/dart/model/m_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../../Adaptor/Media/Widgets/MediaSection.dart';
import '../../../DataClass/Media.dart';
import '../../../Functions/Function.dart';
import '../../../Functions/GetExtensions.dart';
import '../../../Services/Screens/BaseAnimeScreen.dart';
import '../../../logger.dart';
import '../../Mangayomi/Model/Manga.dart';
import '../../Mangayomi/Model/Source.dart';
import '../../Mangayomi/Search/get_popular.dart';

class ExtensionsAnimeScreen extends BaseAnimeScreen {
  var data = Rxn<Map<String, List<Media>>>({});

  @override
  get paging => false;

  @override
  Future<void> loadAll() async {
    resetPageData();
    var sources = await Extensions.getSortedExtension(ItemType.anime);
    _buildSections(sources);
    for (var source in sources) {
      List<Media>? result;
      try {
        var res = await getPopular(
          source: source,
          page: 1,
        );
        result = res?.toMedia(isAnime: true, source: source) ?? [];
      } catch (e) {
        Logger.log('Source ${source.name} failed: ${e.toString()}');
      }
      if (result != null && result.isNotEmpty) {
        trending.value = result;
        return;
      }
    }
  }

  Future<void> _buildSections(List<Source> sources) async {
    List<Future<void>> tasks = [];

    for (var source in sources.take(6)) {
      tasks.add(
        () async {
          try {
            var result = (await getPopular(
              source: source,
              page: 1,
            ))
                ?.toMedia(isAnime: true, source: source);
            if (result != null && result.isNotEmpty) {
              data.value = {
                ...data.value!,
                source.name!: result,
              };
            }
          } catch (e) {
            Logger.log(
                'Failed to load data for source: ${source.name}, error: $e');
          }
        }(),
      );
    }

    await Future.wait(tasks);
  }

  @override
  void loadTrending(int page) {}

  @override
  List<Widget> mediaContent(BuildContext context) {
    return [
      if (data.value == null || data.value!.isEmpty || data.value == {})
        const Center(
          child: CircularProgressIndicator(),
        )
      else
        Column(
          children: [
            for (var entry in data.value!.entries)
              MediaSection(
                context: context,
                type: 0,
                title: entry.key,
                mediaList: entry.value,
              ),
          ],
        ),
    ];
  }

  @override
  int get refreshID => RefreshId.Extensions.animePage;

  void resetPageData() {
    data.value = {};
  }
}
