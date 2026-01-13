import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final healthProfile = user?.healthProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      user?.username.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.username ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (user?.email.isNotEmpty ?? false)
                    Text(
                      user!.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Health Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (healthProfile != null) ...[
            _buildProfileSection(
              context,
              'Allergies',
              healthProfile.allergies,
              Icons.warning_amber,
            ),
            _buildProfileSection(
              context,
              'Dietary Restrictions',
              healthProfile.dietaryRestrictions,
              Icons.restaurant,
            ),
            _buildProfileSection(
              context,
              'Health Conditions',
              healthProfile.healthConditions,
              Icons.local_hospital,
            ),
            _buildProfileSection(
              context,
              'Avoid Ingredients',
              healthProfile.avoidIngredients,
              Icons.block,
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('No health profile set up'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () {
                        // TODO: Navigate to health profile setup
                      },
                      child: const Text('Set Up Health Profile'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive safety alerts'),
                  value: healthProfile?.notificationEnabled ?? true,
                  onChanged: (value) {
                    // TODO: Update notification settings
                  },
                ),
                SwitchListTile(
                  title: const Text('Scan Reminders'),
                  subtitle: const Text('Remind to scan products'),
                  value: healthProfile?.scanReminder ?? true,
                  onChanged: (value) {
                    // TODO: Update scan reminder settings
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(items.join(', ')),
        trailing: const Icon(Icons.edit),
        onTap: () {
          // TODO: Navigate to edit screen
        },
      ),
    );
  }
}
