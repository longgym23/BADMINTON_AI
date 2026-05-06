import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

abstract class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key});

  @override
  Widget build(BuildContext context);
}

abstract class BaseStatefulScreen extends StatefulWidget {
  const BaseStatefulScreen({super.key});

  @override
  State<BaseStatefulScreen> createState();
}