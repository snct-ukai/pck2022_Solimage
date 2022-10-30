import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solimage/components/child/child_actions.dart';
import 'package:solimage/components/tentative_card.dart';
import 'package:solimage/states/camera.dart';
import 'package:solimage/states/user.dart';
import 'package:solimage/utils/classes/expData.dart';

final historiesProvider = FutureProvider((ref) async {
  final histories =
      await ref.watch(userProvider.selectAsync((data) => data!.histories));
  final expDatas = await Future.wait(
      histories.map((history) => ExpData.getExpDataByWord(word: history)));
  final map = <String, ExpData?>{};
  for (final history in histories) {
    final expData = expDatas[histories.indexOf(history)];
    if (expData != null && expData.imageUrl != null) map[history] = expData;
  }
  return map;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histories = ref.watch(historiesProvider);

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text('きろく',
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Expanded(
                  child: histories.maybeWhen(
                      data: (histories) => histories.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: GridView.count(
                                  crossAxisCount: 2,
                                  children: histories.entries
                                      .map((history) => Card(
                                          child: InkWell(
                                              customBorder:
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              onTap: () {
                                                HapticFeedback.heavyImpact();
                                                ref
                                                    .read(imagePathProvider
                                                        .notifier)
                                                    .state = '';
                                                Navigator.of(context).pop();
                                                context.push(
                                                    '/child/result?word=${history.key}');
                                              },
                                              child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(
                                                      10.0),
                                                  child: history.value!.imageUrl!
                                                          .startsWith('data')
                                                      ? Image.memory(
                                                          UriData.parse(history.value!.imageUrl!)
                                                              .contentAsBytes(),
                                                          fit: BoxFit.cover)
                                                      : CachedNetworkImage(
                                                          imageUrl: history
                                                              .value!.imageUrl!,
                                                          fit: BoxFit.cover)))))
                                      .toList()))
                          : Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: TentativeCard(
                                      padding: const EdgeInsets.all(20.0),
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('さつえいしてみよう!',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                      onTap: () {
                                        HapticFeedback.heavyImpact();
                                        context.go('/child/camera');
                                      }))),
                      orElse: () => const Center(child: CircularProgressIndicator()))),
              ChildActions(actions: [
                ChildActionButton(
                    onPressed: () => context.pop(), child: const Text('もどる'))
              ])
            ])));
  }
}
