
// Enum to represent different calculation methods for prayer times
// Mirrors functionality that was likely present in the local package or legacy code.
import "package:adhan_dart/adhan_dart.dart";

enum CalculationMethodEnum {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  // qatar, // Check if supported by official package or map to similar
  kuwait,
  moonsightingCommittee,
  singapore,
  northAmerica,
  turkey,
  tehran,
  other
}

CalculationParameters getCalculationParameters(CalculationMethodEnum method) {
  switch (method) {
    case CalculationMethodEnum.muslimWorldLeague:
      return CalculationMethodParameters.muslimWorldLeague();
    case CalculationMethodEnum.egyptian:
      return CalculationMethodParameters.egyptian();
    case CalculationMethodEnum.karachi:
      return CalculationMethodParameters.karachi();
    case CalculationMethodEnum.ummAlQura:
      return CalculationMethodParameters.ummAlQura();
    case CalculationMethodEnum.dubai:
      return CalculationMethodParameters.dubai();
    case CalculationMethodEnum.kuwait:
      return CalculationMethodParameters.kuwait();
    case CalculationMethodEnum.moonsightingCommittee:
      return CalculationMethodParameters.moonsightingCommittee();
    case CalculationMethodEnum.singapore:
      return CalculationMethodParameters.singapore();
    case CalculationMethodEnum.northAmerica:
      return CalculationMethodParameters.northAmerica();
    case CalculationMethodEnum.turkey:
      return CalculationMethodParameters.turkiye(); // Note: spelling in file is turkiye
    case CalculationMethodEnum.tehran:
      return CalculationMethodParameters.tehran();
    case CalculationMethodEnum.other:
      return CalculationMethodParameters.other();
  }
}

CalculationMethodEnum fromLibraryEnum(CalculationMethod method) {
  try {
    return CalculationMethodEnum.values.firstWhere((e) => e.name == method.name);
  } catch (_) {
    return CalculationMethodEnum.other;
  }
}

extension CalculationMethodEnumExt on CalculationMethodEnum {
  String get fullName {
    switch (this) {
      case CalculationMethodEnum.muslimWorldLeague:
        return "Muslim World League";
      case CalculationMethodEnum.egyptian:
        return "Egyptian General Authority of Survey";
      case CalculationMethodEnum.karachi:
        return "University of Islamic Sciences, Karachi";
      case CalculationMethodEnum.ummAlQura:
        return "Umm al-Qura University, Makkah";
      case CalculationMethodEnum.dubai:
        return "Dubai";
      case CalculationMethodEnum.kuwait:
        return "Kuwait";
      case CalculationMethodEnum.moonsightingCommittee:
        return "Moonsighting Committee";
      case CalculationMethodEnum.singapore:
        return "Singapore";
      case CalculationMethodEnum.northAmerica:
        return "North America (ISNA)";
      case CalculationMethodEnum.turkey:
        return "Turkey (Diyanet)";
      case CalculationMethodEnum.tehran:
        return "Institute of Geophysics, University of Tehran";
      case CalculationMethodEnum.other:
        return "Other"; 
    }
  }
}

