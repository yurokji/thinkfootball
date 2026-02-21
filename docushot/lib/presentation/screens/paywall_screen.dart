import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:docushot/data/services/iap_service.dart';
import 'package:docushot/presentation/providers/iap_provider.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:docushot/l10n/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  StreamSubscription<IapState>? _iapSubscription;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _listenToIapState();
  }

  void _listenToIapState() {
    final iap = ref.read(iapServiceProvider);
    _iapSubscription = iap.stateStream.listen((state) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;

      switch (state.status) {
        case IapStatus.purchasing:
          setState(() => _isPurchasing = true);
          break;

        case IapStatus.purchased:
          setState(() => _isPurchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.purchaseSuccess)),
          );
          // Premium state auto-refreshes via premiumProvider
          break;

        case IapStatus.restored:
          setState(() => _isPurchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.purchaseRestored)),
          );
          break;

        case IapStatus.canceled:
          setState(() => _isPurchasing = false);
          break;

        case IapStatus.error:
          setState(() => _isPurchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.purchaseFailed(state.error ?? ''))),
          );
          break;

        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _iapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final premium = ref.watch(premiumProvider);

    if (premium.isPremium) {
      return Scaffold(
        appBar: AppBar(title: Text(l.premiumLabel)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(l.youArePremium, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (premium.expiresAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  l.expiresOn('${premium.expiresAt!.year}-${premium.expiresAt!.month.toString().padLeft(2, '0')}-${premium.expiresAt!.day.toString().padLeft(2, '0')}'),
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final iap = ref.watch(iapServiceProvider);
    final products = iap.products;
    final annualProduct = iap.getProduct(kPremiumAnnual);
    final monthlyProduct = iap.getProduct(kPremiumMonthly);

    final features = [
      _Feature(Icons.all_inclusive, l.featureUnlimitedDocs, l.featureUnlimitedDocsDesc),
      _Feature(Icons.auto_fix_high, l.featureAllFilters, l.featureAllFiltersDesc),
      _Feature(Icons.text_snippet, l.featureOcr, l.featureOcrDesc),
      _Feature(Icons.photo_library, l.featureBatchScan, l.featureBatchScanDesc),
      _Feature(Icons.folder_zip, l.featureZipExport, l.featureZipExportDesc),
      _Feature(Icons.cloud_upload, l.featureBackup, l.featureBackupDesc),
    ];

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 56, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    l.upgradeToPremium,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.unlockAllFeatures,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
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
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
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
              child: _isPurchasing
                  ? Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(l.purchaseInProgress, style: const TextStyle(color: Colors.white60)),
                      ],
                    )
                  : Column(
                      children: [
                        // Annual
                        _PurchaseButton(
                          label: l.annual,
                          price: annualProduct?.price ?? l.annualPrice,
                          savings: l.save50,
                          isPrimary: true,
                          onTap: products.isEmpty
                              ? () => _showStoreUnavailable(context, l)
                              : () => _buySubscription(kPremiumAnnual),
                        ),
                        const SizedBox(height: 12),
                        // Monthly
                        _PurchaseButton(
                          label: l.monthly,
                          price: monthlyProduct?.price ?? l.monthlyPrice,
                          onTap: products.isEmpty
                              ? () => _showStoreUnavailable(context, l)
                              : () => _buySubscription(kPremiumMonthly),
                        ),
                        const SizedBox(height: 16),
                        // Restore
                        TextButton(
                          onPressed: _restorePurchases,
                          child: Text(l.restorePurchase, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _buySubscription(String productId) {
    final iap = ref.read(iapServiceProvider);
    iap.buySubscription(productId).catchError((e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.purchaseFailed(e.toString()))),
        );
      }
    });
  }

  void _restorePurchases() {
    final iap = ref.read(iapServiceProvider);
    iap.restorePurchases();
  }

  void _showStoreUnavailable(BuildContext context, AppLocalizations l) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.storeUnavailable)),
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
