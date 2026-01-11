import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coffee_profile.dart';
import '../services/auth_controller.dart';
import '../services/firestore_service.dart';

class OnboardingCoffeeProfile extends StatefulWidget {
  const OnboardingCoffeeProfile({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<OnboardingCoffeeProfile> createState() =>
      _OnboardingCoffeeProfileState();
}

class _OnboardingCoffeeProfileState extends State<OnboardingCoffeeProfile> {
  String _tastePreference = 'balanced';
  String _drinkTime = 'morning';
  String _brewStyle = 'manual';
  String _purpose = 'relax';
  bool _saving = false;

  String _personaLabel() {
    final focus = switch (_tastePreference) {
      'bitter' => 'Bold',
      'acidic' => 'Bright',
      _ => 'Balanced',
    };
    final moment = switch (_drinkTime) {
      'night' => 'Night',
      'afternoon' => 'Afternoon',
      _ => 'Morning',
    };
    return '$focus $moment Drinker';
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _saving = true);
    final profile = CoffeeProfile(
      tastePreference: _tastePreference,
      drinkTime: _drinkTime,
      brewStyle: _brewStyle,
      purpose: _purpose,
      personaLabel: _personaLabel(),
    );
    await context.read<FirestoreService>().saveCoffeeProfile(user.uid, profile);
    if (mounted) {
      setState(() => _saving = false);
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Let us learn your coffee journey.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'A few calm questions to shape your personal companion.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildDropdown(
              label: 'Taste preference',
              value: _tastePreference,
              items: const ['bitter', 'acidic', 'balanced'],
              onChanged: (value) => setState(() => _tastePreference = value),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Your usual coffee time',
              value: _drinkTime,
              items: const ['morning', 'afternoon', 'night'],
              onChanged: (value) => setState(() => _drinkTime = value),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Preferred brew style',
              value: _brewStyle,
              items: const ['manual', 'milk', 'machine'],
              onChanged: (value) => setState(() => _brewStyle = value),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Coffee purpose',
              value: _purpose,
              items: const ['relax', 'work', 'socialize'],
              onChanged: (value) => setState(() => _purpose = value),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your persona',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _personaLabel(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Start my journey'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item[0].toUpperCase() + item.substring(1)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ],
    );
  }
}
