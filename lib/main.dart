import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models/coffee_profile.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_coffee_profile.dart';
import 'screens/sign_in_page.dart';
import 'services/auth_controller.dart';
import 'services/auth_service.dart';
import 'services/admin_mode_controller.dart';
import 'services/cart_controller.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TokokopiaApp());
}

class TokokopiaApp extends StatelessWidget {
  const TokokopiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final storage = FirebaseStorage.instance;
    final googleSignIn = GoogleSignIn();
    final firestoreService = FirestoreService(firestore);
    final authService = AuthService(auth, googleSignIn, firestoreService);
    final storageService = StorageService(storage);
    return MultiProvider(
      providers: [
        Provider.value(value: firestoreService),
        Provider.value(value: storageService),
        ChangeNotifierProvider(create: (_) => AuthController(authService)),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => AdminModeController()),
      ],
      child: MaterialApp(
        title: 'Tokokopiadjidjaya',
        theme: AppTheme.lightTheme(),
        home: const RootGate(),
        themeMode: ThemeMode.light,
      ),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  int _profileRefresh = 0;

  void _refreshProfile() {
    setState(() => _profileRefresh++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    Widget child;
    if (auth.isLoading) {
      child = const _FullScreenLoader();
    } else {
      final user = auth.user;
      if (user == null) {
        child = const SignInPage();
      } else {
        child = FutureBuilder<CoffeeProfile?>(
          key: ValueKey(_profileRefresh),
          future: context.read<FirestoreService>().fetchCoffeeProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _FullScreenLoader();
            }
            final profile = snapshot.data;
            if (profile == null) {
              return OnboardingCoffeeProfile(onCompleted: _refreshProfile);
            }
            return const HomeShell();
          },
        );
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
