# Fun Drive

Aplikacija **Fun Drive** pruža korisnicima interaktivnu navigaciju i mogućnost pregleda zanimljivih lokacija duž rute. Upravlja se putem mobilne aplikacije, a dodatne značajke se mogu dodavati preko web admin panela.

## Preduvjeti

Prije nego što pokreneš aplikaciju, pobrini se da imaš instalirane sljedeće alate:

- **Android Studio** (za razvoj i pokretanje aplikacije)
- **Flutter SDK** (preporuča se najnovija verzija, podržava verziju Flutter SDK-a 3.4.3+)
- **Google Maps API ključ** (za rad sa Google Maps integracijom)
- **Android Emulator** (ili fizički uređaj s omogućenim razvojnim načinom rada)

## Postavljanje Google Maps API ključa

Prije pokretanja aplikacije, potrebno je unijeti Google Maps API ključ. Slijedi ove korake:

1. Kreiraj ili nabavi **Google Maps API** ključ s [Google Cloud Console](https://console.cloud.google.com/).
2. U `android/app/src/main/AndroidManifest.xml` datoteku unesi API ključ unutar `<meta-data>` tagova:

   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

te u constants.dart datoteci.

