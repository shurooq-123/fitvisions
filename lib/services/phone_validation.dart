import 'package:phone_numbers_parser/phone_numbers_parser.dart';

String? internationalMobile(String digits, String countryCode) {
  try {
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return null;
    if (countryCode == 'OM' && digits.length != 8) return null;
    final country = IsoCode.values.byName(countryCode);
    final number = PhoneNumber.parse(digits, callerCountry: country, destinationCountry: country);
    if (number.isoCode != country ||
        !number.isValid(type: PhoneNumberType.mobile)) { return null; }
    return number.international;
  } catch (_) {
    return null;
  }
}
