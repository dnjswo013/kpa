import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpa/model/photo.dart';
import 'package:kpa/provider/providers.dart';
import 'package:kpa/repository/photo_repository.dart';
import 'package:kpa/photo_view_screen.dart';
import 'package:kpa/sign_in_screen.dart';

class PhotoListScreen extends ConsumerStatefulWidget {
  const PhotoListScreen({super.key});

  @override
  PhotoListScreenState createState() => PhotoListScreenState();
}

class PhotoListScreenState extends ConsumerState<PhotoListScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    // PageViewで表示されているWidgetの番号を持っておく
    _controller = PageController(
      // Riverpodを使いデータを受け取る
      initialPage: ref.read(photoListIndexProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォトアプリ'),
        actions: [
          // ログアウト用ボタン
          IconButton(
            onPressed: () => _onSignOut(),
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (int index) => _onPageChanged(index),
        children: [
          // 「全ての画像」を表示する部分
          Consumer(
            builder: (context, ref, child) {
              // 画像データ一覧を受け取る
              final asyncPhotoList = ref.watch(photoListProvider);
              return asyncPhotoList.when(
                data: (List<Photo> photoList) {
                  return PhotoGridView(
                    photoList: photoList,
                    onTap: (photo) => _onTapPhoto(photo, photoList),
                    onTapFav: (photo) => _onTapFav(photo),
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
          //「お気に入り登録した画像」を表示する部分
          Consumer(
            builder: (context, ref, child) {
              // 画像データ一覧を受け取る
              final asyncPhotoList = ref.watch(favoritePhotoListProvider);
              return asyncPhotoList.when(
                data: (List<Photo> photoList) {
                  return PhotoGridView(
                    photoList: photoList,
                    onTap: (photo) => _onTapPhoto(photo, photoList),
                    onTapFav: (photo) => _onTapFav(photo),
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
        ],
      ),
      // 画像追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPhoto(),
        child: const Icon(Icons.add),
      ),
      // 画面下部のボタン部分
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final photoIndex = ref.watch(photoListIndexProvider);

          return BottomNavigationBar(
            // BottomNavigationBarItemがタップされたときの処理
            //   0: フォト
            //   1: お気に入り
            onTap: (int index) => _onTapBottomNavigationItem(index),
            // 現在表示されているBottomNavigationBarItemの番号
            //   0: フォト
            //   1: お気に入り
            currentIndex: photoIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.image),
                label: 'フォト',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'お気に入り',
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPageChanged(int index) {
    ref
        .read(photoListIndexProvider.notifier)
        .state = index;
  }

  void _onTapBottomNavigationItem(int index) {
    // PageViewで表示するWidgetを切り替える
    _controller.animateToPage(
      // 表示するWidgetの番号
      //   0: 全ての画像
      //   1: お気に入り登録した画像
      index,
      // 表示を切り替える時にかかる時間（300ミリ秒）
      duration: const Duration(milliseconds: 300),
      // アニメーションの動き方
      //   この値を変えることで、アニメーションの動きを変えることができる
      //   https://api.flutter.dev/flutter/animation/Curves-class.html
      curve: Curves.easeIn,
    );
    // PageViewで表示されているWidgetの番号を更新
    ref
        .read(photoListIndexProvider.notifier)
        .state = index;
  }

  void _onTapPhoto(Photo photo, List<Photo> photoList) {
    final initialIndex = photoList.indexOf(photo);

    Navigator.of(context).push(
      MaterialPageRoute(
        // ProviderScopeを使いScopedProviderの値を上書きできる
        // ここでは、最初に表示する画像の番号を指定
        builder: (_) =>
            ProviderScope(
              overrides: [
                photoViewInitialIndexProvider.overrideWithValue(initialIndex),
              ],
              child: const PhotoViewScreen(),
            ),
      ),
    );
  }

  Future<void> _onAddPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      // リポジトリ経由でデータを保存する
      final User user = FirebaseAuth.instance.currentUser!;
      final PhotoRepository repository = PhotoRepository(user);
      final File file = File(result.files.single.path!);
      await repository.addPhoto(file);
    }
  }

  Future<void> _onTapFav(Photo photo) async {
    final photoRepository = ref.read(photoRepositoryProvider);
    final toggledPhoto = photo.toggleIsFavorite();
    await photoRepository!.updatePhoto(toggledPhoto);
  }

  Future<void> _onSignOut() async {
    // ログアウト処理
    await FirebaseAuth.instance.signOut();

    // ログアウトに成功したらログイン画面に戻す
    //   現在の画面は不要になるのでpushReplacementを使う
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SignInScreen(),
        ),
      );
    }
  }
}

class PhotoGridView extends StatelessWidget {
  const PhotoGridView({
    super.key,
    required this.photoList,
    required this.onTap,
    required this.onTapFav,
  });

  final List<Photo> photoList;
  final void Function(Photo photo) onTap;
  final void Function(Photo photo) onTapFav;

  @override
  Widget build(BuildContext context) {
    // GridViewを使いタイル状にWidgetを表示する
    return GridView.count(
      // 1行あたりに表示するWidgetの数
      crossAxisCount: 2,
      // Widget間のスペース（上下）
      mainAxisSpacing: 8,
      // Widget間のスペース（左右）
      crossAxisSpacing: 8,
      // 全体の余白
      padding: const EdgeInsets.all(8),
      // 画像一覧
      children: photoList.map((Photo photo) {
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InkWell(
                onTap: () => onTap(photo),
                child: Image.network(
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: (
                            loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        ),
                      ),
                    );
                  },
                  photo.imageURL,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => onTapFav(photo),
                color: Colors.purple,
                icon: Icon(
                  // お気に入り登録状況に応じてアイコンを切り替え
                  photo.isFavorite == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
