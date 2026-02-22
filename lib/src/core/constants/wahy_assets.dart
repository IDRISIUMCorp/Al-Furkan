class WahyAssets {
  const WahyAssets._();

  static const String _root = "assets/wahy";

  static const String svg = "$_root/svg";
  static const String images = "$_root/images";
  static const String icons = "$_root/icons";
  static const String lottie = "$_root/lottie";
  static const String json = "$_root/json";

  static const String besmAllahSvg = "$svg/besmAllah.svg";
  static const String besmAllah2Svg = "$svg/besmAllah2.svg";

  static const String surahBannerAyah1Svg = "$svg/surah_banner_ayah1.svg";
  static const String surahBannerAyah2Svg = "$svg/surah_banner_ayah2.svg";

  static String surahNameSvg(int surahNumber) {
    final surahNum3 = surahNumber.toString().padLeft(3, "0");
    return "$svg/surah_name/$surahNum3.svg";
  }

  static const String arrowBackPng = "$icons/arrow_back.png";

  static const String imgHomePng = "$images/home.png";
  static const String imgPagesPng = "$images/pages.png";
  static const String imgAyahsPng = "$images/ayahs.png";
  static const String imgAudioPng = "$images/audio.png";
  static const String imgAthkarPng = "$images/athkar.png";
  static const String imgIslamicOccasionsPng = "$images/IslamicOccasions.png";
  static const String imgQuranBannerPng = "$images/quran_banner.png";
  static const String imgTafsirBooksJpg = "$images/tafsir_books.jpg";

  static const String lottieArrow = "$lottie/arrow.json";
  static const String lottieAzkar = "$lottie/azkar.json";
  static const String lottieEidWhite = "$lottie/eid_white.json";
  static const String lottieLoading = "$lottie/loading.json";
  static const String lottieMoon = "$lottie/moon.json";
  static const String lottieNoInternet = "$lottie/noInternet.json";
  static const String lottieNotFound = "$lottie/notFound.json";
  static const String lottieNotification = "$lottie/notification.json";
  static const String lottieOpenBook = "$lottie/open_book.json";
  static const String lottiePlayButton = "$lottie/play_button.json";
  static const String lottieQuranAuIc = "$lottie/quran_au_ic.json";
  static const String lottieRamadanWhite = "$lottie/ramadan_white.json";
  static const String lottieSearch = "$lottie/search.json";
  static const String lottieShare = "$lottie/share.json";
  static const String lottieSplashLoading = "$lottie/splash_loading.json";
  static const String lottieSun = "$lottie/sun.json";

  static const String jsonAzkar = "$json/azkar.json";
  static const String jsonCollections = "$json/collections.json";
  static const String jsonReligiousEvent = "$json/religious_event.json";
  static const String jsonWaqfTranslated = "$json/waqf_translated.json";
}
