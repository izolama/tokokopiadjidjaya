import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/pressable_scale.dart';
import 'package:provider/provider.dart';

import '../models/coffee_profile.dart';
import '../services/admin_mode_controller.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../admin/admin_home.dart';
import 'persona_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isAdmin(String? email) {
    const adminEmails = [
      'faizollama11@gmail.com',
      'owner@tokokopiadjidjaya.com',
      'admin@tokokopiadjidjaya.com',
    ];
    return email != null && adminEmails.contains(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your profile.')),
      );
    }
    final adminMode = context.watch<AdminModeController>();
    final canUseAdmin = _isAdmin(user.email);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _Stagger(
              controller: _controller,
              order: 0,
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    scale: 1,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      opacity: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppTheme.deepBlue.withOpacity(0.1),
                          backgroundImage:
                              user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                          child:
                              user.photoURL == null
                                  ? const Icon(Icons.person_outline)
                                  : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Coffee Friend',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (adminMode.enabled)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Admin',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        user.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Stagger(
              controller: _controller,
              order: 1,
              child: FutureBuilder<CoffeeProfile?>(
                future: context.read<FirestoreService>().fetchCoffeeProfile(
                  user.uid,
                ),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  if (profile == null) {
                    return const SizedBox.shrink();
                  }
                  return PressableScale(
                    scale: 0.99,
                    onTap: () {
                      _pushSmooth(
                        context,
                        PersonaDetailPage(profile: profile),
                      );
                    },
                    child: GestureDetector(
                      onLongPress:
                          canUseAdmin
                              ? () => _enterAdminMode(context, adminMode)
                              : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF7F2ED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your coffee persona',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.personaLabel,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Based on your brews & taste',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (adminMode.enabled)
              _Stagger(
                controller: _controller,
                order: 2,
                child: TextButton(
                  onPressed: () => _confirmExitAdmin(context, adminMode),
                  child: const Text('Exit Admin Mode'),
                ),
              ),
            const SizedBox(height: 32),
            _Stagger(
              controller: _controller,
              order: 3,
              child: OutlinedButton(
                onPressed: () => _confirmSignOut(context, auth),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthController auth,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DAD2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to leave your coffee journey?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Stay'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          auth.signOut();
                        },
                        child: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _enterAdminMode(
    BuildContext context,
    AdminModeController adminMode,
  ) async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Admin tools unlocked')));
    adminMode.setEnabled(true);
    _pushSmooth(context, const AdminHome());
  }

  Future<void> _confirmExitAdmin(
    BuildContext context,
    AdminModeController adminMode,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DAD2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Return to personal view?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Stay'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          adminMode.setEnabled(false);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Exit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pushSmooth(BuildContext context, Widget page) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _Stagger extends StatelessWidget {
  const _Stagger({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.12).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
