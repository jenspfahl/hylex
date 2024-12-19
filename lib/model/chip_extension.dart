
import 'dart:ui';

import '../utils.dart';
import 'chip.dart';

extension ChipColor on GameChip {
  Color get color => getColorFromIdx(this.id);
}

