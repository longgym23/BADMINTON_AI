import 'package:flutter/material.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class HighlightsTab extends StatelessWidget {
  const HighlightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('screens.outstanding'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text('screens.featuredFunctionalityIsUnde'.tr())),
    );
  }
}
