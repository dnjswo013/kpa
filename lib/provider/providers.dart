import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpa/model/photo.dart';
import 'package:kpa/repository/photo_repository.dart';

final userProvider = StreamProvider.autoDispose((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 他ProviderからPhotoRepositoryを受け取る
final photoListProvider = StreamProvider.autoDispose(
  (ref) {
    final photoRepository = ref.watch(photoRepositoryProvider);
    return photoRepository == null
        ? Stream.value(<Photo>[])
        : photoRepository.getPhotoList();
  },
);

final photoListIndexProvider = StateProvider.autoDispose((ref) {
  return 0;
});

final photoViewInitialIndexProvider = Provider<int>((ref) => 0);

// ProviderからPhotoRepositoryを渡す
final photoRepositoryProvider = Provider.autoDispose(
  (ref) {
    final user = ref.watch(userProvider).value;
    return user == null ? null : PhotoRepository(user);
  },
);

// photoListProviderのデータを元に、お気に入り登録されたデータのみ受け渡せるようにする
final favoritePhotoListProvider = Provider.autoDispose(
  (ref) {
    return ref.watch(photoListProvider).whenData(
      (List<Photo> data) {
        return data.where((photo) => photo.isFavorite == true).toList();
      },
    );
  },
);
