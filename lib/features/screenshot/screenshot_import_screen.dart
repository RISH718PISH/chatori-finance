import 'package:flutter/material.dart';

import '../_shared/placeholder_screen.dart';

class ScreenshotImportScreen extends StatelessWidget {
  const ScreenshotImportScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Import Paytm Screenshot',
        milestone: 'M5 — on-device OCR import flow',
      );
}
