import 'package:flutter/material.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class HighlightsTab extends StatelessWidget {
  const HighlightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Nổi bật'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(child: Text('Chức năng Nổi bật đang được phát triển')),
    );
  }
}
