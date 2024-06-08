import 'package:flutter/material.dart';
import 'package:kpa/model/photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpa/provider/providers.dart';
import 'package:share_plus/share_plus.dart';

class PhotoViewScreen extends ConsumerStatefulWidget {
  const PhotoViewScreen({super.key});

  @override
  PhotoViewScreenState createState() => PhotoViewScreenState();
}

class PhotoViewScreenState extends ConsumerState<PhotoViewScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      initialPage: ref.read(photoViewInitialIndexProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarの裏までbodyの表示エリアを広げる
      // 透明なAppBarを作る
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 画像一覧
          Consumer(
            builder: (context, ref, child) {
              AsyncValue<List<Photo>> asyncPhotoList;
              if (ref.read(photoListIndexProvider.notifier).state == 0) {
                asyncPhotoList = ref.watch(photoListProvider);
              } else {
                asyncPhotoList = ref.watch(favoritePhotoListProvider);
              }

              return asyncPhotoList.when(
                data: (photoList) {
                  return PageView(
                    controller: _controller,
                    onPageChanged: (int index) => {},
                    children: photoList.map((Photo photo) {
                      return Image.network(
                        photo.imageURL,
                      );
                    }).toList(),
                  );
                },
                loading: () {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                error: (e, stackTrace) {
                  return Center(
                    child: Text(e.toString()),
                  );
                },
              );
            },
          ),
          // アイコンボタンを画像の手前に重ねる
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // フッター部分にグラデーションを入れてみる
              decoration: BoxDecoration(
                // 線形グラデーション
                gradient: LinearGradient(
                  // 下方向から上方向に向かってグラデーションさせる
                  begin: FractionalOffset.bottomCenter,
                  end: FractionalOffset.topCenter,
                  // 半透明の黒から透明にグラデーションさせる
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 共有ボタン
                  IconButton(
                    onPressed: () => _onTapShare(),
                    color: Colors.white,
                    icon: const Icon(Icons.share),
                  ),
                  // 削除ボタン
                  IconButton(
                    onPressed: () => _onTapDelete(),
                    color: Colors.white,
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapDelete() async {
    final photoRepository = ref.read(photoRepositoryProvider);
    final photoList = ref.read(photoListProvider).value;
    final photo = photoList![_controller.page!.toInt()];

    if (photoList.length == 1) {
      Navigator.of(context).pop();
    } else if (photoList.last == photo) {
      await _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    await photoRepository!.deletePhoto(photo);
  }

  Future<void> _onTapShare() async {
    final photoList = ref.read(photoListProvider).value;
    final photo = photoList![_controller.page!.toInt()];

    // 画像URLを共有
    await Share.share(photo.imageURL);
  }
}
