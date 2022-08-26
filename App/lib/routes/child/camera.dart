import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solimage/states/camera.dart';
import 'package:solimage/states/permission.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraPermission = ref.watch(cameraPermissionProvider);

    if (cameraPermission.value == PermissionStatus.granted) {
      final controller = ref.watch(controllerProvider);

      return controller.when(
          data: (controller) {
            final size = MediaQuery.of(context).size;
            var scale = size.aspectRatio * controller.value.aspectRatio;
            if (scale < 1) scale = 1 / scale;

            return Scaffold(
                body: Stack(children: <Widget>[
              Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Center(child: CameraPreview(controller))),
              Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      margin: const EdgeInsets.all(20.0),
                      child: ElevatedButton.icon(
                          icon: const Icon(Icons.supervisor_account),
                          onPressed: () => showAnimatedDialog(
                              context: context,
                              animationType: DialogTransitionType.fadeScale,
                              barrierDismissible: true,
                              builder: (context) =>
                                  const SwitchToParentDialog()),
                          label: const FittedBox(
                            child: Text('大人用メニュー'),
                          ),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(20.0))))),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      height: 100.0,
                      margin: const EdgeInsets.all(20.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                                child: ElevatedButton.icon(
                                    onPressed: () {
                                      ref.refresh(imageProvider);
                                      context.push('/child/standby');
                                    },
                                    icon: const Icon(Icons.camera, size: 30.0),
                                    label: const FittedBox(
                                        child: Text('さつえい',
                                            style: TextStyle(fontSize: 30.0))),
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size.fromHeight(100.0),
                                        padding: const EdgeInsets.all(20.0)))),
                            const SizedBox(width: 20.0),
                            Expanded(
                                child: ElevatedButton.icon(
                                    icon: const Icon(Icons.star, size: 30.0),
                                    onPressed: () =>
                                        context.push('/child/favorite'),
                                    label: const FittedBox(
                                      child: Text('おきにいり',
                                          style: TextStyle(fontSize: 30.0)),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size.fromHeight(100.0),
                                        padding: const EdgeInsets.all(20.0)))),
                          ])))
            ]));
          },
          error: (error, _) => Text('Error: $error'),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())));
    } else {
      return const Scaffold(
          body: Center(
        child: Text('カメラの許可が必要です'),
      ));
    }
  }
}

class SwitchToParentDialog extends StatelessWidget {
  const SwitchToParentDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('大人用メニューに切り替えてもよろしいですか？'),
        actions: <Widget>[
          TextButton(
              child: const Text('はい'), onPressed: () => context.go('/parent')),
          TextButton(
              child: const Text('いいえ'),
              onPressed: () => Navigator.of(context).pop()),
        ],
      );
}
