import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_models.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;
  final FarmProfile farmProfile;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.farmProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.title'.tr()),
        actions: [
          IconButton(
            tooltip: 'profile.select_language'.tr(),
            onPressed: () => _showLanguageSelector(context),
            icon: const Icon(Icons.language),
          ),
          IconButton(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1500937386664-56d1dfef3854?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                ],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildIdSection(),
                const SizedBox(height: 24),
                _buildFarmInfoSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _showAvatarOptions(),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userProfile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userProfile.phone,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.identity_info'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildIdItem('profile.aadhaar'.tr(), userProfile.aadhaarHash),
            _buildIdItem('profile.farm_id'.tr(), userProfile.uniqueFarmId),
            _buildIdItem('profile.farmer_id'.tr(), userProfile.uniqueFarmerId),
          ],
        ),
      ),
    );
  }

  Widget _buildIdItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(value),
            icon: const Icon(Icons.copy, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmInfoSection() {
    final farmCards = [
      _FarmInfoCard(
        title: 'profile.state'.tr(),
        value: farmProfile.state,
        icon: Icons.location_on,
        color: Colors.blue,
      ),
      _FarmInfoCard(
        title: 'profile.district'.tr(),
        value: farmProfile.district,
        icon: Icons.map,
        color: Colors.green,
      ),
      _FarmInfoCard(
        title: 'profile.soil_type'.tr(),
        value: farmProfile.soilType,
        icon: Icons.terrain,
        color: Colors.brown,
      ),
      _FarmInfoCard(
        title: 'profile.land_area'.tr(),
        value: '${farmProfile.area} ${'profile.acres'.tr()}',
        icon: Icons.area_chart,
        color: Colors.orange,
      ),
      _FarmInfoCard(
        title: 'profile.primary_crop'.tr(),
        value: farmProfile.primaryCrop,
        icon: Icons.eco,
        color: Colors.lightGreen,
      ),
      _FarmInfoCard(
        title: 'profile.water_level'.tr(),
        value: farmProfile.waterLevel,
        icon: Icons.water_drop,
        color: Colors.cyan,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.farm_info'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: farmCards.length,
            itemBuilder: (context, index) => Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: farmCards[index],
            ),
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions() {
    // TODO: Implement avatar picker/camera
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // TODO: Show snackbar confirmation
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'profile.settings'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text('profile.language'.tr()),
              subtitle: Text('profile.change_app_language'.tr()),
              onTap: () => _showLanguageSelector(context),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text('profile.account_settings'.tr()),
              subtitle: Text('profile.manage_account'.tr()),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text('profile.notifications'.tr()),
              subtitle: Text('profile.manage_notifications'.tr()),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिन्दी'},
      {'code': 'ta', 'name': 'தமிழ்'},
      {'code': 'te', 'name': 'తెలుగు'},
      {'code': 'ml', 'name': 'മലയാളം'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => ListTile(
            title: Text(lang['name']!),
            onTap: () {
              Navigator.pop(context);
              context.setLocale(Locale(lang['code']!));
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _FarmInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _FarmInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'profile.view_details'.tr(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
