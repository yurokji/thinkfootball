import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';

/// Premium tier status.
enum PremiumTier {
  free,
  premium,
}

/// Thrown when a free user tries to use a premium-only feature.
class PremiumRequiredException implements Exception {
  final String feature;
  const PremiumRequiredException(this.feature);
  @override
  String toString() => 'Premium required for: $feature';
}

/// Premium feature flags and limits.
class PremiumStatus {
  final PremiumTier tier;
  final DateTime? expiresAt;
  final int ocrUsedToday;
  final String lastOcrDate; // 'yyyy-MM-dd'

  const PremiumStatus({
    this.tier = PremiumTier.free,
    this.expiresAt,
    this.ocrUsedToday = 0,
    this.lastOcrDate = '',
  });

  bool get isPremium => tier == PremiumTier.premium;

  // Free tier limits
  static const int freeOcrPerDay = 3;

  // Feature checks — premium-only
  bool get hasAllFilters => isPremium;
  bool get hasZipExport => isPremium;
  bool get hasMerge => isPremium;
  bool get hasBatchExport => isPremium;
  bool get hasBackup => isPremium;

  // OCR: free users get limited daily usage
  bool get canUseOcr {
    if (isPremium) return true;
    final today = _todayString();
    if (lastOcrDate != today) return true; // new day, reset
    return ocrUsedToday < freeOcrPerDay;
  }

  int get ocrRemaining {
    if (isPremium) return -1; // unlimited
    final today = _todayString();
    if (lastOcrDate != today) return freeOcrPerDay;
    return (freeOcrPerDay - ocrUsedToday).clamp(0, freeOcrPerDay);
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  PremiumStatus copyWith({
    PremiumTier? tier,
    DateTime? expiresAt,
    int? ocrUsedToday,
    String? lastOcrDate,
  }) {
    return PremiumStatus(
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
      ocrUsedToday: ocrUsedToday ?? this.ocrUsedToday,
      lastOcrDate: lastOcrDate ?? this.lastOcrDate,
    );
  }
}

class PremiumNotifier extends Notifier<PremiumStatus> {
  late final SharedPreferences _prefs;

  @override
  PremiumStatus build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromPrefs();
  }

  PremiumStatus _loadFromPrefs() {
    final tierName = _prefs.getString('premiumTier') ?? 'free';
    final expiresStr = _prefs.getString('premiumExpires');
    final ocrUsed = _prefs.getInt('ocrUsedToday') ?? 0;
    final ocrDate = _prefs.getString('lastOcrDate') ?? '';

    var tier = tierName == 'premium' ? PremiumTier.premium : PremiumTier.free;
    DateTime? expires;

    if (expiresStr != null) {
      expires = DateTime.tryParse(expiresStr);
      if (expires != null && expires.isBefore(DateTime.now())) {
        tier = PremiumTier.free;
        _prefs.setString('premiumTier', 'free');
      }
    }

    return PremiumStatus(
      tier: tier,
      expiresAt: expires,
      ocrUsedToday: ocrUsed,
      lastOcrDate: ocrDate,
    );
  }

  /// Check premium for a feature; throws PremiumRequiredException if not allowed.
  void requirePremium(String feature) {
    if (!state.isPremium) {
      throw PremiumRequiredException(feature);
    }
  }

  /// Check and consume one OCR usage. Throws if limit reached.
  void consumeOcr() {
    if (state.isPremium) return; // unlimited

    final today = PremiumStatus._todayString();
    int used = state.ocrUsedToday;
    if (state.lastOcrDate != today) {
      used = 0; // new day
    }

    if (used >= PremiumStatus.freeOcrPerDay) {
      throw PremiumRequiredException('OCR (daily limit reached)');
    }

    used++;
    _prefs.setInt('ocrUsedToday', used);
    _prefs.setString('lastOcrDate', today);
    state = state.copyWith(ocrUsedToday: used, lastOcrDate: today);
  }

  /// Call after successful purchase verification.
  void activatePremium({Duration duration = const Duration(days: 365)}) {
    final expires = DateTime.now().add(duration);
    _prefs.setString('premiumTier', 'premium');
    _prefs.setString('premiumExpires', expires.toIso8601String());
    state = PremiumStatus(tier: PremiumTier.premium, expiresAt: expires);
  }

  /// Call when subscription is cancelled or expired.
  void deactivatePremium() {
    _prefs.setString('premiumTier', 'free');
    _prefs.remove('premiumExpires');
    state = const PremiumStatus(tier: PremiumTier.free);
  }

  /// Restore purchase — delegates to IapService.
  /// The actual premium activation happens via IapService's purchase stream handler.
  Future<void> restorePurchase() async {
    // IapService handles restore and calls activatePremium via callback.
    // This method is kept for direct calls; the actual flow goes through IapService.
  }
}

final premiumProvider = NotifierProvider<PremiumNotifier, PremiumStatus>(
  PremiumNotifier.new,
);
