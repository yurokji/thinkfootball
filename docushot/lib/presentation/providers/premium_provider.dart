import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Premium tier status.
enum PremiumTier {
  free,
  premium,
}

/// Premium feature flags.
class PremiumStatus {
  final PremiumTier tier;
  final DateTime? expiresAt;

  const PremiumStatus({
    this.tier = PremiumTier.free,
    this.expiresAt,
  });

  bool get isPremium => tier == PremiumTier.premium;

  // Free tier limits
  static const int freeDocumentLimit = 5;
  static const int freeOcrPerDay = 3;

  // Feature checks
  bool get hasUnlimitedDocuments => isPremium;
  bool get hasAllFilters => isPremium;
  bool get hasOcr => isPremium;
  bool get hasCloudBackup => isPremium;
  bool get hasBatchMode => isPremium;
  bool get hasZipExport => isPremium;

  PremiumStatus copyWith({PremiumTier? tier, DateTime? expiresAt}) {
    return PremiumStatus(
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class PremiumNotifier extends Notifier<PremiumStatus> {
  late final Box _box;

  @override
  PremiumStatus build() {
    _box = Hive.box('settings');
    return _loadFromBox();
  }

  PremiumStatus _loadFromBox() {
    final tierName = _box.get('premiumTier', defaultValue: 'free') as String;
    final expiresStr = _box.get('premiumExpires') as String?;

    var tier = tierName == 'premium' ? PremiumTier.premium : PremiumTier.free;
    DateTime? expires;

    if (expiresStr != null) {
      expires = DateTime.tryParse(expiresStr);
      if (expires != null && expires.isBefore(DateTime.now())) {
        tier = PremiumTier.free;
        _box.put('premiumTier', 'free');
      }
    }

    return PremiumStatus(tier: tier, expiresAt: expires);
  }

  /// Call after successful purchase verification.
  void activatePremium({Duration duration = const Duration(days: 365)}) {
    final expires = DateTime.now().add(duration);
    _box.put('premiumTier', 'premium');
    _box.put('premiumExpires', expires.toIso8601String());
    state = PremiumStatus(tier: PremiumTier.premium, expiresAt: expires);
  }

  /// Call when subscription is cancelled or expired.
  void deactivatePremium() {
    _box.put('premiumTier', 'free');
    _box.delete('premiumExpires');
    state = const PremiumStatus(tier: PremiumTier.free);
  }

  /// Restore purchase (check with store).
  Future<void> restorePurchase() async {
    // TODO: Implement with in_app_purchase package
  }
}

final premiumProvider = NotifierProvider<PremiumNotifier, PremiumStatus>(
  PremiumNotifier.new,
);
