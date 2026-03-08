import 'package:flutter/material.dart';

// Dark Theme Colors
const Color darkMaddaNecessary = Color(0xFFe65aa7);
const Color darkIdghamGhunnah = Color(0xFF57d342);
const Color darkIkhafaShafawi = Color(0xFFf050d7);
const Color darkIdghamWoGhunnah = Color(0xFF57d342);
const Color darkSlnt = Color(0xFFcccccc);
const Color darkIdghamMutajanisayn = Color(0xFFd0d0d0);
const Color darkGhunnah = Color(0xFFff9a50);
const Color darkIdghamMutaqaribayn = Color(0xFFd0d0d0);
const Color darkHamWasl = Color(0xFFcccccc);
const Color darkQalaqah = Color(0xFF4dc5ff);
const Color darkMaddaObligatoryMonfasel = Color(0xFFfa5aa7);
const Color darkMaddaNormal = Color(0xFF80a0ff);
const Color darkIkhafa = Color(0xFFca50e0);
const Color darkIdghamShafawi = Color(0xFF85e030);
const Color darkLaamShamsiyah = Color(0xFFcccccc);
const Color darkMaddaPermissible = Color(0xFFffb040);
const Color darkMaddaObligatoryMottasel = Color(0xFFfa5aa7);
const Color darkIqlab = Color(0xFF60d0ff);
const Color darkCustomAlefMaksora = Color(0xFFb070f0);

// Light Theme Colors
const Color lightMaddaNecessary = Color(0xFFa9045c);
const Color lightIdghamGhunnah = Color(0xFF169200);
const Color lightIkhafaShafawi = Color(0xFFd500b7);
const Color lightIdghamWoGhunnah = Color(0xFF169200);
const Color lightSlnt = Color(0xFFaaaaaa);
const Color lightIdghamMutajanisayn = Color(0xFFa1a1a1);
const Color lightGhunnah = Color(0xFFff7e1e);
const Color lightIdghamMutaqaribayn = Color(0xFFa1a1a1);
const Color lightHamWasl = Color(0xFFaaaaaa);
const Color lightQalaqah = Color(0xFF009ee6);
const Color lightMaddaObligatoryMonfasel = Color(0xFFf2007f);
const Color lightMaddaNormal = Color(0xFF537fff);
const Color lightIkhafa = Color(0xFF9400a8);
const Color lightIdghamShafawi = Color(0xFF58b800);
const Color lightLaamShamsiyah = Color(0xFFaaaaaa);
const Color lightMaddaPermissible = Color(0xFFf38e02);
const Color lightMaddaObligatoryMottasel = Color(0xFFf2007f);
const Color lightIqlab = Color(0xFF26bffd);
const Color lightCustomAlefMaksora = Color(0xFF6a0dad);

class TajweedRules {
  static const List<Type> all = [
    GhunnahRule,
    IdghamShafawiRule,
    IqlabRule,
    IkhafaShafawiRule,
    QalqalahRule,
    IdghamGhunnahRule,
    IdghamWoGhunnahRule,
    IkhafaRule,
    MaddTabiiRule,
    MaddLazimRule,
    MaddLeenRule,
    MaddWajibMuttasilRule,
    MaddJaizMunfasilRule,
    HamWaslRule,
    LaamShamsiyahRule,
    SlntRule,
    IdghamMutajanisaynRule,
    IdghamMutaqaribaynRule,
    CustomAlefMaksoraRule,
  ];
}

class GhunnahRule {
  static const Color lightColor = lightGhunnah;
  static const Color darkColor = darkGhunnah;
  static const String key = "ghunnah";
}

class IdghamShafawiRule {
  static const Color lightColor = lightIdghamShafawi;
  static const Color darkColor = darkIdghamShafawi;
  static const String key = "idgham_shafawi";
}

class IqlabRule {
  static const Color lightColor = lightIqlab;
  static const Color darkColor = darkIqlab;
  static const String key = "iqlab";
}

class IkhafaShafawiRule {
  static const Color lightColor = lightIkhafaShafawi;
  static const Color darkColor = darkIkhafaShafawi;
  static const String key = "ikhafa_shafawi";
}

class QalqalahRule {
  static const Color lightColor = lightQalaqah;
  static const Color darkColor = darkQalaqah;
  static const String key = "qalaqah";
}

class IdghamGhunnahRule {
  static const Color lightColor = lightIdghamGhunnah;
  static const Color darkColor = darkIdghamGhunnah;
  static const String key = "idgham_ghunnah";
}

class IdghamWoGhunnahRule {
  static const Color lightColor = lightIdghamWoGhunnah;
  static const Color darkColor = darkIdghamWoGhunnah;
  static const String key = "idgham_wo_ghunnah";
}

class IkhafaRule {
  static const Color lightColor = lightIkhafa;
  static const Color darkColor = darkIkhafa;
  static const String key = "ikhafa";
}

class MaddTabiiRule {
  static const Color lightColor = lightMaddaNormal;
  static const Color darkColor = darkMaddaNormal;
  static const String key = "madda_normal";
}

class MaddLazimRule {
  static const Color lightColor = lightMaddaNecessary;
  static const Color darkColor = darkMaddaNecessary;
  static const String key = "madda_necessary";
}

class MaddLeenRule {
  static const Color lightColor = lightMaddaPermissible;
  static const Color darkColor = darkMaddaPermissible;
  static const String key = "madda_permissible";
}

class MaddWajibMuttasilRule {
  static const Color lightColor = lightMaddaObligatoryMottasel;
  static const Color darkColor = darkMaddaObligatoryMottasel;
  static const String key = "madda_obligatory_mottasel";
}

class MaddJaizMunfasilRule {
  static const Color lightColor = lightMaddaObligatoryMonfasel;
  static const Color darkColor = darkMaddaObligatoryMonfasel;
  static const String key = "madda_obligatory_monfasel";
}

class HamWaslRule {
  static const Color lightColor = lightHamWasl;
  static const Color darkColor = darkHamWasl;
  static const String key = "ham_wasl";
}

class LaamShamsiyahRule {
  static const Color lightColor = lightLaamShamsiyah;
  static const Color darkColor = darkLaamShamsiyah;
  static const String key = "laam_shamsiyah";
}

class SlntRule {
  static const Color lightColor = lightSlnt;
  static const Color darkColor = darkSlnt;
  static const String key = "slnt";
}

class IdghamMutajanisaynRule {
  static const Color lightColor = lightIdghamMutajanisayn;
  static const Color darkColor = darkIdghamMutajanisayn;
  static const String key = "idgham_mutajanisayn";
}

class IdghamMutaqaribaynRule {
  static const Color lightColor = lightIdghamMutaqaribayn;
  static const Color darkColor = darkIdghamMutaqaribayn;
  static const String key = "idgham_mutaqaribayn";
}

class CustomAlefMaksoraRule {
  static const Color lightColor = lightCustomAlefMaksora;
  static const Color darkColor = darkCustomAlefMaksora;
  static const String key = "custom-alef-maksora";
}
