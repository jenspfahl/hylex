import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:super_tooltip/super_tooltip.dart';

class Tooltips {

  final _tooltipControllers = HashMap<String, SuperTooltipController>();

  static final Tooltips _singleton = Tooltips._internal();

  factory Tooltips() {
    return _singleton;
  }

  Tooltips._internal() {}

  controlTooltip(String key) => _tooltipControllers
      .putIfAbsent(key, () => SuperTooltipController());
  
  hideTooltipLater(String key) {
    final tooltip = getTooltip(key);
    if (tooltip == null) {
      return;
    }

    for (final c in _tooltipControllers.values) {
      if (c != tooltip) {
        c.hideTooltip();
      }
    }

    Future.delayed(Duration(seconds: 3), () {
      tooltip.hideTooltip();
    });
  }

  SuperTooltipController? getTooltip(String key) => _tooltipControllers[key];

}