import 'package:flutter/services.dart';

class InputFormattersHelper {
  static List<TextInputFormatter> getPhoneInputFormatter() {
    List<TextInputFormatter> phoneInputFormatter = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly
    ];

    return [
      ...phoneInputFormatter,
      LengthLimitingTextInputFormatter(10),
      TelephoneNumberFormatter(),
    ];
  }

  static List<TextInputFormatter> getEmailInputFormatter() {
    List<TextInputFormatter> emailInputFormatter = <TextInputFormatter>[
      LowercaseInputFormatter(),
    ];

    return emailInputFormatter;
  }
}

class TelephoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      if (text.isNotEmpty) {
        return newValue.copyWith(
          text: '',
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }

    return newValue;
  }
}

class LowercaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

class UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}