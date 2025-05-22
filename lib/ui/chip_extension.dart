
import 'dart:ui';

import 'ui_utils.dart';
import '../model/chip.dart';

extension ChipColor on GameChip {
  Color get color => getColorFromIdx(this.id);
}

