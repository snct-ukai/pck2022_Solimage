import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as image;
import 'package:solimage/components/child_actions.dart';
import 'package:solimage/states/camera.dart';
import 'package:solimage/states/user.dart';
import 'package:solimage/utils/classes/expData.dart';
import 'package:solimage/utils/imageProcess/classifier.dart';

final _recommendDataProvider = FutureProvider.autoDispose((ref) async {
  final uid = await ref.watch(userProvider.selectAsync((data) => data?.uid));
  final groups =
      await ref.watch(userProvider.selectAsync((data) => data?.groups));
  if (groups == null || groups.isEmpty) return null;
  final recommendData = uid != null
      ? await RecommendData.getRecommendDataByCurrentUid(uid)
      : null;

  if (recommendData != null) {
    await recommendData.addViews();
  }

  return recommendData;
});

final _labelsProvider =
    FutureProvider.autoDispose<Map<String, ExpData>>((ref) async {
  final imagePath = ref.watch(imagePathProvider);

  if (imagePath.isNotEmpty) {
    final classifier = Classifier.instance;
    await classifier.loadModel();
    final result = await classifier
        .predict(image.decodeImage(File(imagePath).readAsBytesSync())!);
    final labels = result.getRange(0, 5).toList();
    final expDatas = await Future.wait(result.getRange(0, 5).map(
        (label) async => await ExpData.getExpDataByWord(word: label.label)));
    final map = <String, ExpData>{};
    for (final label in labels) {
      map[label.label] = expDatas[labels.indexOf(label)]!;
    }
    return map;
  }
  throw const FileSystemException();
});

final _currentPageProvider = StateProvider.autoDispose((ref) => 0);

class StandbyDialog extends ConsumerWidget {
  const StandbyDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendData = ref.watch(_recommendDataProvider);
    final labels = ref.watch(_labelsProvider);
    final controller = PageController();
    final currentPage = ref.watch(_currentPageProvider);

    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
          child: recommendData.maybeWhen(
              data: (data) => PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: controller,
                      onPageChanged: (page) =>
                          ref.read(_currentPageProvider.notifier).state = page,
                      children: [
                        AlertDialog(
                            title: Center(
                                child: Text(
                                    data != null ? data.word : 'けっかをみてみよう!',
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold))),
                            content: data != null
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        AspectRatio(
                                            aspectRatio: 1,
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                                child: CachedNetworkImage(
                                                    fit: BoxFit.cover,
                                                    imageUrl: data.imageUrl!))),
                                        Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(data.meaning,
                                                style: const TextStyle(
                                                    fontSize: 20.0))),
                                        ChildActionButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              context.push(
                                                  '/child/result?userId=${data.userId}');
                                            },
                                            child: const Text('くわしく'))
                                      ])
                                : null),
                        AlertDialog(
                            title: const Center(
                                child: Text('どれだろう?',
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold))),
                            content: labels.maybeWhen(
                                data: (labels) => SizedBox(
                                    width: 300.0,
                                    child: GridView.count(
                                        crossAxisCount: 2,
                                        children: labels.entries
                                            .map((label) => Card(
                                                child: InkWell(
                                                    customBorder:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    onTap: () {
                                                      ref
                                                          .read(
                                                              imagePathProvider
                                                                  .notifier)
                                                          .state = '';
                                                      Navigator.of(context)
                                                          .pop();
                                                      context.push(
                                                          '/child/result?word=${label.key}');
                                                    },
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0),
                                                        child: label
                                                                .value.imageUrl!
                                                                .startsWith(
                                                                    'data')
                                                            ? Image.memory(
                                                                UriData.parse(label.value.imageUrl!)
                                                                    .contentAsBytes(),
                                                                fit: BoxFit
                                                                    .cover)
                                                            : CachedNetworkImage(
                                                                imageUrl: label.value.imageUrl!,
                                                                fit: BoxFit.cover)))))
                                            .toList())),
                                orElse: () => const Center(child: CircularProgressIndicator())))
                      ]),
              orElse: () => const AlertDialog(
                  content: Center(
                      heightFactor: 1.0, child: CircularProgressIndicator())))),
      ChildActions(actions: [
        ChildActionButton(
            child: const Text('もどる'),
            onPressed: () => Navigator.of(context).pop()),
        labels.maybeWhen(
            data: (data) => currentPage == 0
                ? ChildActionButton(
                    onPressed: () => controller.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut),
                    child: const Text('つぎへ', textAlign: TextAlign.center))
                : const SizedBox.shrink(),
            orElse: () => const Center(child: CircularProgressIndicator()))
      ])
    ]);
  }
}