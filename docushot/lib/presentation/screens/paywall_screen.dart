import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _features = [
    _Feature(Icons.all_inclusive, 'Unlimited Documents', 'Create as many documents as you need'),
    _Feature(Icons.auto_fix_high, 'All Filters & Adjustments', 'Magic Color, B&W, brightness, contrast'),
    _Feature(Icons.text_snippet, 'OCR Text Recognition', 'Extract text in 5 languages'),
    _Feature(Icons.photo_library, 'Batch Scanning', 'Scan multiple pages in one session'),
    _Feature(Icons.folder_zip, 'ZIP Export', 'Export documents as ZIP archives'),
    _Feature(Icons.cloud_upload, 'Cloud Backup', 'Never lose your documents'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);

    if (premium.isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              const Text('You are Premium!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (premium.expiresAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Expires: ${premium.expiresAt!.year}-${premium.expiresAt!.month.toString().padLeft(2, '0')}-${premium.expiresAt!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Icon(Icons.workspace_premium, size: 56, color: Colors.amber),
                  SizedBox(height: 16),
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Unlock all features for professional scanning',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Feature list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber.withValues(alpha: 0.15),
                          ),
                          child: Icon(feature.icon, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(feature.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text(feature.subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Purchase buttons
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Annual
                  _PurchaseButton(
                    label: 'Annual',
                    price: '\$29.99/year',
                    savings: 'Save 50%',
                    isPrimary: true,
                    onTap: () {
                      // TODO: Trigger actual purchase via in_app_purchase
                      _showPurchasePlaceholder(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Monthly
                  _PurchaseButton(
                    label: 'Monthly',
                    price: '\$4.99/month',
                    onTap: () {
                      _showPurchasePlaceholder(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Restore
                  TextButton(
                    onPressed: () async {
                      await ref.read(premiumProvider.notifier).restorePurchase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Purchase restore checked')),
                        );
                      }
                    },
                    child: const Text('Restore Purchase', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchasePlaceholder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('In-app purchase will be available once the app is published to the store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);
}

class _PurchaseButton extends StatelessWidget {
  final String label;
  final String price;
  final String? savings;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.label,
    required this.price,
    this.savings,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (savings != null)
                  Text(
                    savings!,
                    style: TextStyle(
                      color: isPrimary ? Colors.black54 : Colors.amber,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            Text(
              price,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
