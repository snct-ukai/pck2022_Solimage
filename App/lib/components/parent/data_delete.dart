import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solimage/utils/classes/expData.dart';
import 'package:solimage/utils/classes/group.dart';
import 'package:solimage/utils/classes/user.dart';

class DataDeleteDialog extends StatelessWidget {
  const DataDeleteDialog({Key? key, required this.user, required this.expData})
      : super(key: key);

  final AppUser user;
  final ExpData expData;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('この投稿を削除してもよろしいでしょうか?'),
        actions: <Widget>[
          TextButton(
              child: const Text('はい'),
              onPressed: () {
                expData.delete().then((_) async {
                  user.expDatas.remove(expData.dataId);
                  await user.save();
                  await Future.wait(user.groups.map(
                      (groupId) => Group.getGroup(groupId).then((group) async {
                            group?.removeExpData(expData.dataId);
                            await group?.update();
                          })));
                });
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('投稿を削除しました')));
                context.go('/parent');
              }),
          TextButton(
              child: const Text('いいえ'),
              onPressed: () => Navigator.of(context).pop()),
        ],
      );
}
