Step 1: Clone repository

bash
git clone https://github.com/username/projektpm.git
cd projektpm
Step 2: Buat file API keys
# Copy contoh file
cp lib/core/constants/api_keys_example.dart lib/core/constants/api_keys.dart
cp android/secrets_example.properties android/secrets.properties

Step 3: Isi API key yang asli

Buka lib/core/constants/api_keys.dart dan isi dengan key asli.

Buka android/secrets.properties dan isi dengan Google Maps API key.

Step 4: Jalankan aplikasi

bash
flutter pub get
flutter run


Isi API keys:
Dapatkan Google Maps API Key dari Google Cloud Console
Dapatkan Adzuna API Key dari Adzuna
Dapatkan RapidAPI Key dari RapidAPI
Dapatkan Gemini API Key dari Google AI Studio

Note: File api_keys.dart dan secrets.properties tidak di-commit ke repository karena berisi informasi sensitif.