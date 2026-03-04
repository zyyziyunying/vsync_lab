import 'package:common/common.dart';

class RefreshRateParser {
  const RefreshRateParser();

  CommonResult<double> parse(String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null) {
      return CommonResult.failure(
        const CommonFailure('Refresh rate must be a numeric value.'),
      );
    }

    if (value < 24 || value > 240) {
      return CommonResult.failure(
        const CommonFailure('Refresh rate must be between 24 and 240 Hz.'),
      );
    }

    return CommonResult.success(value);
  }
}
