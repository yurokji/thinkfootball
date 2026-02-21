import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:docushot/data/services/iap_service.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';

/// IAP service provider — lazily creates and initializes the service.
final iapServiceProvider = Provider<IapService>((ref) {
  final premiumNotifier = ref.read(premiumProvider.notifier);
  final service = IapService(
    activatePremium: premiumNotifier.activatePremium,
    deactivatePremium: premiumNotifier.deactivatePremium,
  );
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Products available for purchase.
final iapProductsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final iap = ref.watch(iapServiceProvider);
  return iap.loadProducts();
});

/// Stream of IAP state changes.
final iapStateProvider = StreamProvider<IapState>((ref) {
  final iap = ref.watch(iapServiceProvider);
  return iap.stateStream;
});
