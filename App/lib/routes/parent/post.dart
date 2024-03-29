import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solimage/components/child/example_text.dart';
import 'package:solimage/components/parent/data/delete_dialog.dart';
import 'package:solimage/components/parent/data/post_dialog.dart';
import 'package:solimage/components/parent/data/word_tree.dart';
import 'package:solimage/states/post.dart';
import 'package:solimage/states/user.dart';
import 'package:solimage/utils/classes/expData.dart';

final _whyProvider = StateProvider.autoDispose((ref) => '');
final _whatProvider = StateProvider.autoDispose((ref) => '');
final _whereProvider = StateProvider.autoDispose((ref) => '');
final _whenProvider = StateProvider.autoDispose((ref) => '');
final _whoProvider = StateProvider.autoDispose((ref) => '');
final _howProvider = StateProvider.autoDispose((ref) => '');
final _imageUrlProvider = StateProvider.autoDispose((ref) => '');
final _isRecommendDataProvider = StateProvider.autoDispose((ref) => false);
final _dataProvider =
    FutureProvider.autoDispose.family<ExpData?, String?>((ref, dataId) async {
  final uid = await ref.watch(userProvider.selectAsync((data) => data?.uid));
  var expData = dataId != null
      ? dataId != uid
          ? await ExpData.getExpData(int.parse(dataId))
          : await RecommendData.getRecommendData(dataId)
      : null;

  if (expData != null) {
    ref.read(wordProvider.notifier).state = expData.word;
    ref.read(_whyProvider.notifier).state = expData.why ?? '';
    ref.read(_whatProvider.notifier).state = expData.what ?? '';
    ref.read(_whereProvider.notifier).state = expData.where ?? '';
    ref.read(_whenProvider.notifier).state = expData.when ?? '';
    ref.read(_whoProvider.notifier).state = expData.who ?? '';
    ref.read(_howProvider.notifier).state = expData.how ?? '';
    ref.read(_imageUrlProvider.notifier).state = expData.imageUrl ?? '';

    if (expData is RecommendData) {
      ref.read(_isRecommendDataProvider.notifier).state = true;
    }
  }

  return expData;
});

class PostScreen extends ConsumerWidget {
  const PostScreen({Key? key, this.dataId}) : super(key: key);

  final String? dataId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(stepProvider);
    final word = ref.watch(wordProvider);
    final why = ref.watch(_whyProvider);
    final what = ref.watch(_whatProvider);
    final where = ref.watch(_whereProvider);
    final when = ref.watch(_whenProvider);
    final who = ref.watch(_whoProvider);
    final how = ref.watch(_howProvider);
    final is5W1HValid = [why, what, when, where, who, how]
        .map((element) => element.isNotEmpty)
        .contains(true);
    final imageUrl = ref.watch(_imageUrlProvider);
    final expData = ref.watch(_dataProvider(dataId));
    final user = ref.watch(userProvider.future);
    final isRecommendData = ref.watch(_isRecommendDataProvider);
    final steps = [
      Step(
          title: const Text('オススメ'),
          subtitle: Text(isRecommendData ? 'オススメする' : 'オススメしない'),
          content: Column(children: [
            RadioListTile<bool>(
              title: const Text('オススメする'),
              subtitle:
                  const Text('撮影後の待ち時間に広告のように表示され、子どもたちにあなたの伝えたい知識を伝えることができます'),
              value: true,
              onChanged: expData.value is! RecommendData
                  ? (value) {
                      ref.read(wordProvider.notifier).state = '';
                      ref.read(_isRecommendDataProvider.notifier).state =
                          value!;
                    }
                  : null,
              groupValue: isRecommendData,
            ),
            RadioListTile<bool>(
              title: const Text('オススメしない'),
              subtitle: const Text('画像で検索したときに表示され、子どもたちにあなたの経験を伝えることができます'),
              value: false,
              onChanged: expData.value is! RecommendData
                  ? (value) {
                      ref.read(wordProvider.notifier).state = '';
                      ref.read(_isRecommendDataProvider.notifier).state =
                          value!;
                    }
                  : null,
              groupValue: isRecommendData,
            ),
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.asset(
                        isRecommendData
                            ? 'assets/recommend_data.gif'
                            : 'assets/exp_data.gif',
                        gaplessPlayback: true,
                        height: 300.0))),
          ]),
          state: step != 0 ? StepState.complete : StepState.indexed),
      Step(
          title: const Text('画像'),
          subtitle: Text(imageUrl.isNotEmpty ? '追加済み' : '追加されていません'),
          content: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(children: [
                if (imageUrl.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 300.0),
                              child: imageUrl.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                              Icons
                                                  .signal_wifi_statusbar_connected_no_internet_4,
                                              size: 60.0))
                                  : Image.file(File(imageUrl))))),
                ElevatedButton.icon(
                    onPressed: () async {
                      final path = (await ImagePicker()
                              .pickImage(source: ImageSource.camera))
                          ?.path;

                      if (path != null) {
                        ref.read(_imageUrlProvider.notifier).state = path;
                      }
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: Text('画像を撮影${imageUrl.isEmpty ? 'する' : 'し直す'}')),
                ElevatedButton.icon(
                    onPressed: () async {
                      final path = (await ImagePicker()
                              .pickImage(source: ImageSource.gallery))
                          ?.path;

                      if (path != null) {
                        ref.read(_imageUrlProvider.notifier).state = path;
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('画像を選択${imageUrl.isEmpty ? 'する' : 'し直す'}'))
              ])),
          state: step != 1 && (isRecommendData ? imageUrl.isNotEmpty : true)
              ? StepState.complete
              : StepState.indexed),
      Step(
          title: const Text('ワード'),
          subtitle: Text(word.isNotEmpty ? word : '未入力'),
          content: SingleChildScrollView(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text.rich(TextSpan(children: [
                          TextSpan(text: '関連するワードを選択・追加してください\n'),
                          WidgetSpan(
                              child: Icon(Icons.chevron_right),
                              alignment: PlaceholderAlignment.middle),
                          TextSpan(text: 'を押すと関連するワードが表示されます\n')
                        ])),
                        WordTree()
                      ]))),
          state: step != 2 && word.isNotEmpty
              ? StepState.complete
              : StepState.indexed),
      Step(
          title: const Text('5W1H'),
          subtitle: const Text('少なくとも1つ以上入力してください'),
          content: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Wrap(spacing: 10.0, children: [
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        initialValue: why,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'なぜ'),
                        onChanged: (value) =>
                            ref.read(_whyProvider.notifier).state = value)),
                const ExampleText('それが発生する原因など'),
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        initialValue: what,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'なに'),
                        onChanged: (value) =>
                            ref.read(_whatProvider.notifier).state = value)),
                const ExampleText('その物の説明など'),
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        initialValue: where,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'どこ'),
                        onChanged: (value) =>
                            ref.read(_whereProvider.notifier).state = value)),
                const ExampleText('それが見られる場所など'),
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        initialValue: when,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'いつ'),
                        onChanged: (value) =>
                            ref.read(_whenProvider.notifier).state = value)),
                const ExampleText('それが発生する時間, その寿命など'),
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        initialValue: who,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'だれ'),
                        onChanged: (value) =>
                            ref.read(_whoProvider.notifier).state = value)),
                const ExampleText('それを発明した人, 関係する生き物など'),
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        initialValue: how,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: 'どうやって'),
                        onChanged: (value) =>
                            ref.read(_howProvider.notifier).state = value)),
                const ExampleText('それの作り方・育て方など')
              ])),
          state:
              step != 3 && is5W1HValid ? StepState.complete : StepState.indexed)
    ];

    return expData.maybeWhen(
        data: (data) => Scaffold(
              appBar: AppBar(title: const Text('投稿'), centerTitle: true),
              body: SingleChildScrollView(
                  child: Column(children: [
                if (data != null)
                  Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ListTile(
                          leading: const Icon(Icons.info),
                          title: Text('投稿済み\n閲覧数: ${data.views}回'),
                          trailing: ElevatedButton.icon(
                              onPressed: () async {
                                final awaitedUser = await user;
                                if (awaitedUser != null) {
                                  showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => DataDeleteDialog(
                                          user: awaitedUser, expData: data));
                                }
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('削除')))),
                Stepper(
                    physics: const NeverScrollableScrollPhysics(),
                    currentStep: step,
                    onStepCancel: step != 0
                        ? () => ref.read(stepProvider.notifier).state = step - 1
                        : null,
                    onStepContinue: step < steps.length - 1
                        ? () => ref.read(stepProvider.notifier).state = step + 1
                        : null,
                    onStepTapped: (index) =>
                        ref.read(stepProvider.notifier).state = index,
                    steps: steps,
                    controlsBuilder:
                        (BuildContext context, ControlsDetails details) =>
                            Container(
                                width: double.infinity,
                                margin: const EdgeInsets.all(10.0),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10.0,
                                  children: <Widget>[
                                    ElevatedButton(
                                      //13
                                      onPressed: details.onStepContinue,
                                      child: const Text('次へ'),
                                    ),
                                    ElevatedButton(
                                      //14
                                      onPressed: details.onStepCancel,
                                      child: const Text('戻る'),
                                    ),
                                  ],
                                )))
              ])),
              floatingActionButton: FloatingActionButton.extended(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).clearSnackBars();

                    if (word.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ワードが選択されていません')));
                      return;
                    }

                    if (isRecommendData && imageUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('画像を追加してください')));
                      return;
                    }

                    if (!is5W1HValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('5W1Hは1つ以上入力してください')));
                      return;
                    }

                    ExpData expData;

                    if (!isRecommendData) {
                      if (data != null) {
                        expData = data;
                      } else {
                        expData = ExpData(
                            word: '', meaning: '', userID: (await user)!.uid);
                        await expData.init();
                      }
                    } else {
                      expData = RecommendData(
                          word: '', meaning: '', userID: (await user)!.uid);
                    }

                    expData.setData(
                        word: word,
                        why: ref.read(_whyProvider),
                        what: ref.read(_whatProvider),
                        when: ref.read(_whenProvider),
                        where: ref.read(_whereProvider),
                        who: ref.read(_whoProvider),
                        how: ref.read(_howProvider));

                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => DataPostDialog(
                            expData: expData, imagePath: imageUrl));
                  },
                  icon: const Icon(Icons.check),
                  label: Text(expData.value is! RecommendData ? '投稿' : '保存')),
            ),
        orElse: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())));
  }
}
