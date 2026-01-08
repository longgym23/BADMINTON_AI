import 'package:flutter/material.dart';

class HighlightsTab extends StatelessWidget {
  const HighlightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nổi bật'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(child: Text('Chức năng Nổi bật đang được phát triển')),
    );
  }
}
