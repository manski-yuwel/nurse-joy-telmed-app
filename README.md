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

## 🗺️ Setting Up Google Maps API Key for Local Development

This project uses the [secrets-gradle-plugin](https://github.com/google/secrets-gradle-plugin) to securely manage your Google Maps API key.

### 1. Obtain a Google Maps API Key

You have two options:

- **Option 1: Request the API key from a teammate or project admin**  
  Ask a team member who already has a working `secrets.properties` file to share the Google Maps API key with you (privately).

- **Option 2: Generate your own Google Maps API key**  
  1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
  2. Select or create your project.
  3. Enable the **Maps SDK for Android**.
  4. Go to **APIs & Services > Credentials**.
  5. Click **Create Credentials > API key**.
  6. (Recommended) Restrict your API key to your app’s package name and SHA-1.
  7. Copy the generated API key.

### 2. Create `secrets.properties`

In the `android/` directory, create a file named `secrets.properties` (if it does not already exist):
