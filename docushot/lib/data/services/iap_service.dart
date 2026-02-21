import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// In-App Purchase product IDs.
const String kPremiumMonthly = 'premium_monthly';
const String kPremiumAnnual = 'premium_annual';
const Set<String> kProductIds = {kPremiumMonthly, kPremiumAnnual};

/// Callback when a purchase is verified and premium should be activated.
typedef PremiumActivator = void Function({Duration duration});
/// Callback when premium should be deactivated.
typedef PremiumDeactivator = void Function();

/// Service that wraps [InAppPurchase] for subscription management.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final PremiumActivator _activatePremium;
  final PremiumDeactivator _deactivatePremium;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  /// Stream controller for purchase state changes (UI can listen).
  final _stateController = StreamController<IapState>.broadcast();
  Stream<IapState> get stateStream => _stateController.stream;

  IapService({
    required PremiumActivator activatePremium,
    required PremiumDeactivator deactivatePremium,
  })  : _activatePremium = activatePremium,
        _deactivatePremium = deactivatePremium;

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  /// Initialize the store connection and start listening to purchase updates.
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      _stateController.add(const IapState(status: IapStatus.storeUnavailable));
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('IAP stream error: $error');
        _stateController.add(IapState(status: IapStatus.error, error: error.toString()));
      },
    );

    // Load products
    await loadProducts();
  }

  /// Query product details from the store.
  Future<List<ProductDetails>> loadProducts() async {
    if (!_isAvailable) return [];

    final response = await _iap.queryProductDetails(kProductIds);

    if (response.error != null) {
      debugPrint('IAP product query error: ${response.error}');
      _stateController.add(IapState(status: IapStatus.error, error: response.error!.message));
      return [];
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    _stateController.add(IapState(status: IapStatus.productsLoaded, products: _products));
    return _products;
  }

  /// Initiate a subscription purchase.
  Future<bool> buySubscription(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product $productId not found'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    _stateController.add(const IapState(status: IapStatus.purchasing));

    // Subscriptions are non-consumable (auto-renewed by Play Store)
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    _stateController.add(const IapState(status: IapStatus.restoring));
    await _iap.restorePurchases();
  }

  /// Handle purchase update stream from the store.
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _stateController.add(const IapState(status: IapStatus.purchasing));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;

        case PurchaseStatus.error:
          _stateController.add(IapState(
            status: IapStatus.error,
            error: purchase.error?.message ?? 'Purchase failed',
          ));
          break;

        case PurchaseStatus.canceled:
          _stateController.add(const IapState(status: IapStatus.canceled));
          break;
      }

      // Complete pending purchases
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Verify purchase and activate premium.
  void _verifyAndDeliver(PurchaseDetails purchase) {
    // Client-side verification: check that we received valid data
    // For production, consider server-side verification with purchase.verificationData
    final isValid = purchase.verificationData.localVerificationData.isNotEmpty;

    if (!isValid) {
      _stateController.add(const IapState(status: IapStatus.error, error: 'Purchase verification failed'));
      return;
    }

    // Determine duration based on product ID
    final duration = purchase.productID == kPremiumAnnual
        ? const Duration(days: 365)
        : const Duration(days: 30);

    _activatePremium(duration: duration);

    final isRestored = purchase.status == PurchaseStatus.restored;
    _stateController.add(IapState(
      status: isRestored ? IapStatus.restored : IapStatus.purchased,
    ));
  }

  /// Get a product by ID, or null if not found.
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}

/// Status of the IAP system.
enum IapStatus {
  idle,
  storeUnavailable,
  productsLoaded,
  purchasing,
  purchased,
  restored,
  restoring,
  canceled,
  error,
}

/// State snapshot of the IAP system.
class IapState {
  final IapStatus status;
  final String? error;
  final List<ProductDetails>? products;

  const IapState({
    this.status = IapStatus.idle,
    this.error,
    this.products,
  });
}
