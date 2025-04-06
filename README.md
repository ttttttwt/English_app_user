# English Learning App

A Flutter application for learning English with interactive exercises and AI-powered features.

## Features

- Interactive vocabulary exercises
- Reading comprehension practice
- AI-powered conversation (using Gemini)
- Personalized exercises by AI (reading, speaking, multiple choice, fill-in-the-blanks)
- Firebase integration for user data
- Cross-platform support (iOS, Android, Web)

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase account
- Gemini API key

### Environment Setup

1. Copy `.env.example` to create `.env`:

```bash
cp .env.example .env
```

2. Fill in your API keys in `.env`:

```properties
FIREBASE_WEB_API_KEY=your_web_api_key
FIREBASE_ANDROID_API_KEY=your_android_api_key
FIREBASE_IOS_API_KEY=your_ios_api_key
FIREBASE_APP_ID_WEB=your_web_app_id
FIREBASE_APP_ID_ANDROID=your_android_app_id
FIREBASE_APP_ID_IOS=your_ios_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_AUTH_DOMAIN=your_auth_domain
GEMINI_API_KEY=your_gemini_api_key
```

### Installation

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run --dart-define-from-file=.env
```

## Project Structure

```
lib/
  ├── common/          # Common utilities and constants
  ├── features/        # Feature-based modules
  ├── core/           # Core functionality
  └── main.dart       # Entry point
```

## Environment Variables

This project uses environment variables for sensitive data. Required variables:

- Firebase configuration
- Gemini API key

See `.env.example` for all required variables.

## Development

Make sure to:

1. Never commit `.env` file
2. Keep `.env.example` updated
3. Run tests before pushing: `flutter test`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
