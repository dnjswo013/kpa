import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpa/firebase_options.dart';
import 'package:kpa/photo_list_screen.dart';
import 'package:kpa/provider/providers.dart';
import 'package:kpa/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'フォトアプリ',
      theme: CustomTheme.lightThemeData(),
      darkTheme: CustomTheme.darkThemeData(),
      themeMode: ThemeMode.system,
      // アプリ起動時にログイン画面を表示
      home: Consumer(
        builder: (context, ref, child) {
          // ユーザー情報を取得
          final asyncUser = ref.watch(userProvider);

          return asyncUser.when(
            data: (User? data) {
              return data == null
                  ? const SignInScreen()
                  : const PhotoListScreen();
            },
            loading: () {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            error: (e, stackTrace) {
              return Scaffold(
                body: Center(
                  child: Text(e.toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CustomTheme {
  static ThemeData lightThemeData() {
    return ThemeData(
      brightness: Brightness.light,
    );
  }

  static ThemeData darkThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
    );
  }
}
