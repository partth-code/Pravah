import 'package:flutter/material.dart';
import '../widgets/png_icon.dart';

class IconDemoScreen extends StatelessWidget {
  const IconDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Demo'),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your ICO Image as Icon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Different sizes of your ICO icon
            const Text('Different Sizes:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                const AppIcon(width: 16, height: 16),
                const SizedBox(width: 10),
                const Text('16x16'),
                const SizedBox(width: 20),
                const AppIcon(width: 24, height: 24),
                const SizedBox(width: 10),
                const Text('24x24'),
                const SizedBox(width: 20),
                const AppIcon(width: 32, height: 32),
                const SizedBox(width: 10),
                const Text('32x32'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Different colors
            const Text('Different Colors:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                const AppIcon(color: Colors.green),
                const SizedBox(width: 10),
                const Text('Green'),
                const SizedBox(width: 20),
                const AppIcon(color: Colors.blue),
                const SizedBox(width: 10),
                const Text('Blue'),
                const SizedBox(width: 20),
                const AppIcon(color: Colors.red),
                const SizedBox(width: 10),
                const Text('Red'),
                const SizedBox(width: 20),
                const AppIcon(color: Colors.orange),
                const SizedBox(width: 10),
                const Text('Orange'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // In a card like the policy screen
            const Text('In Policy Card Style:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const AppIcon(
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your ICO Icon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This is your ICO image being used as an icon',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Direct image display
            const Text('Direct Image Display:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            
            Center(
              child: Image.asset(
                'assets/images/ico.jpg',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
