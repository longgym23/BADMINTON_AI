import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

abstract class BaseWidget extends StatelessWidget {
  const BaseWidget({super.key});

  @override
  Widget build(BuildContext context);
}

abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({super.key});

  @override
  State<BaseStatefulWidget> createState();
}