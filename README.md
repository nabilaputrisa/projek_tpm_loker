# Installation Guide

## 1. Clone Repository

```bash
git clone https://github.com/username/projektpm.git
cd projektpm
```

## 2. Create API Key Files

Copy the example configuration files:

```bash
cp lib/core/constants/api_keys_example.dart lib/core/constants/api_keys.dart
cp android/secrets_example.properties android/secrets.properties
```

## 3. Configure API Keys

Fill in the required API keys with your own credentials.

### `lib/core/constants/api_keys.dart`

Add:

* Gemini API Key
* Adzuna API Key
* RapidAPI Key

### `android/secrets.properties`

Add:

* Google Maps API Key

## 4. Run the Application

Install dependencies and start the app:

```bash
flutter pub get
flutter run
```

---

# Required API Keys

Before running the application, obtain the following API keys:

| Service             | Source                  |
| ------------------- | ----------------------- |
| Google Maps API Key | Google Cloud Console    |
| Adzuna API Key      | Adzuna Developer Portal |
| RapidAPI Key        | RapidAPI                |
| Gemini API Key      | Google AI Studio        |

---

## Security Note

Files containing sensitive information are intentionally excluded from the repository:

* `lib/core/constants/api_keys.dart`
* `android/secrets.properties`

These files are listed in `.gitignore` to prevent accidental exposure of API credentials.
