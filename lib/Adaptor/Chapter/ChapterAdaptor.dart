import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../Animation/ScaleAnimation.dart';
import '../../DataClass/Chapter.dart';
import '../../DataClass/Media.dart';
import '../../api/Mangayomi/Model/Source.dart';
import 'ChapterCompactViewHolder.dart';
import 'ChapterListViewHolder.dart';

class ChapterAdaptor extends StatefulWidget {
  final int type;
  final Source source;
  final List<Chapter> chapterList;
  final Media mediaData;
  final VoidCallback? onEpisodeClick;

  const ChapterAdaptor({
    super.key,
    required this.type,
    required this.source,
    required this.chapterList,
    required this.mediaData,
    this.onEpisodeClick,
  });

  @override
  ChapterAdaptorState createState() => ChapterAdaptorState();
}

class ChapterAdaptorState extends State<ChapterAdaptor> {
  late List<Chapter> chapterList;

  @override
  void initState() {
    super.initState();
    chapterList = widget.chapterList;
  }

  @override
  void didUpdateWidget(ChapterAdaptor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterList != widget.chapterList) {
      chapterList = widget.chapterList;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case 0:
        return _buildListLayout();
      case 1:
        return _buildCompactView();
      default:
        return _buildListLayout();
    }
  }

  Widget _buildListLayout() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        constraints: const BoxConstraints(maxHeight: double.infinity),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: chapterList.length,
          itemBuilder: (context, index) {
            return SlideAndScaleAnimation(
              initialScale: 0.0,
              finalScale: 1.0,
              initialOffset: const Offset(1.0, 0.0),
              finalOffset: Offset.zero,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () {},
                child: SizedBox(
                  width: double.infinity,
                  child: ChapterListView(
                    chapter: chapterList[index],
                    mediaData: widget.mediaData,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        var crossAxisCount = (parentWidth / 82).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: StaggeredGrid.count(
              crossAxisCount: crossAxisCount,
              children: List.generate(
                chapterList.length,
                (index) {
                  return SlideAndScaleAnimation(
                    initialScale: 0.0,
                    finalScale: 1.0,
                    initialOffset: const Offset(1.0, 0.0),
                    finalOffset: Offset.zero,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: () {},
                      onLongPress: () {},
                      child: SizedBox(
                        width: 82,
                        height: 82,
                        child: ChapterCompactView(
                          chapter: chapterList[index],
                          mediaData: widget.mediaData,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
