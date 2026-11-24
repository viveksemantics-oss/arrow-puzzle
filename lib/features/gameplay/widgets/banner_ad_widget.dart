import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../config/ad_config.dart';
import '../../gameplay/providers/game_providers.dart';

/// Anchored Adaptive Banner Ad widget with smooth loading and zero layout shift.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  Orientation? _currentOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_currentOrientation != orientation) {
      _currentOrientation = orientation;
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    final storage = ref.read(storageProvider);
    if (storage.isPremium || kIsWeb) return;

    if (!Platform.isAndroid && !Platform.isIOS) return;

    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (adSize == null || !mounted) return;

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );

    await _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);
    if (storage.isPremium) {
      return const SizedBox.shrink();
    }

    if (_bannerAd != null && _isLoaded) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Fixed clean placeholder height to avoid UI jumps while loading
    return const SizedBox(
      height: 52,
      child: Center(
        child: Text(
          'Sponsored Placement',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFFCBD5E1),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
