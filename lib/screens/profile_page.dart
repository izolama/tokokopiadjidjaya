import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coffee_profile.dart';
import '../services/admin_mode_controller.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../admin/admin_home.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.deepBlue.withOpacity(0.1),
                    backgroundImage:
                        user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Coffee Friend',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        user.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<CoffeeProfile?>(
                future: context
                    .read<FirestoreService>()
                    .fetchCoffeeProfile(user.uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  if (profile == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your coffee persona',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.personaLabel,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (canUseAdmin) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: adminMode.enabled,
                  title: const Text('Admin mode'),
                  subtitle: const Text('Toggle between admin and user view'),
                  onChanged: adminMode.setEnabled,
                ),
                if (adminMode.enabled)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const AdminHome()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Open admin panel'),
                  ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: auth.signOut,
                child: const Text('Sign out'),
              ),
          ],
        ),
      ),
    );
  }
}
