# Application Installation & Update Guide

This guide provides step-by-step instructions on how to install and update the **Bizos Pro** application on your Windows PC and Android devices.

## 🪟 Windows Installation

The Windows application is provided as a **portable folder**. You do not need a traditional installer; you can simply copy the folder to your computer and run the application.

### Step-by-Step Instructions:
1.  **Locate the Build Folder**: 
    Go to `C:\Users\sc\Develop\atik\build\windows\x64\runner\Release`
2.  **Copy the Entire Folder**: 
    Copy the **entire** `Release` folder to your preferred location (e.g., `Documents`, `Desktop`, or `C:\Program Files\BizosPro`).
    > [!IMPORTANT]
    > You **must** copy the entire folder, not just the `.exe` file. The application requires the DLL files and the `data` subfolder to run.
3.  **Create a Shortcut**:
    Right-click `ebficBM.exe` and select **Show more options > Send to > Desktop (create shortcut)**.
4.  **Run the App**: 
    Double-click the shortcut on your desktop or the `.exe` file in the folder.

---

## 🤖 Android Installation

The Android application is provided as an `.apk` file.

### Step-by-Step Instructions:
1.  **Locate the APK**: 
    The file is located at `C:\Users\sc\Develop\atik\build\app\outputs\flutter-apk\app-release.apk`.
2.  **Transfer the APK**: 
    Transfer the `app-release.apk` file to your phone's storage.
3.  **Install the APK**:
    Open a file manager app on your phone, find the file, and tap on it. Follow the prompts to install.

---

## 🛠️ Update Command
To build a new version anytime, run:
`flutter clean; flutter pub get; flutter build windows; flutter build apk`
