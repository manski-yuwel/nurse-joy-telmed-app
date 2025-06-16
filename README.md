# nursejoyapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Maps API Key Setup

1. Ask the project admin for the Google Maps API key.
2. Open (or create) `android/local.properties` in the project root.
3. Add this line (replace with the actual key):
   ```
   MAPS_API_KEY=your_real_api_key_here
   ```
4. Do **not** commit `local.properties` to Git. make sure nasa gitignore local.properties (which should already be in there)
5. Run the app as usual!
