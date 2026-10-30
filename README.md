# GarminWindowsConnect

# ⌚ Garmin Remote Watch Trigger

<p align="center">
  <b>A lightweight, secure open-source bridge allowing you to trigger local Windows apps, scripts, and Wake-on-LAN packets directly from your Garmin smartwatch using ntfy.sh webhooks.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Garmin-blue" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/Tech-Python%20%7C%20Monkey%20C-orange" alt="Tech Stack">
</p>

---

## 🛠️ Technology Stack & Attributions

* **[ntfy.sh](https://ntfy.sh)** — Open-source HTTP-based pub/sub notification service for real-time messaging between your smartwatch and local PC.
* **VS Code & Garmin Connect IQ SDK (Monkey C)** — Powers the smartwatch user interface and background network requests.
* **Python & PowerShell** — Manages the local background listener (`listener.py`), process polling, and automated application launching on Windows.

---

## 🚀 Getting Started & Installation

### 📋 Prerequisites & Tools

Before you begin, ensure you have the following installed on your Windows machine:

*   **[Visual Studio Code](https://code.visualstudio.com/)** — Required for compiling and exporting your Garmin watch app.
*   **[Python 3.x](https://www.python.org/)** — Required to run the listener and build script. 
    > 💡 **Tip:** Make sure to check **"Add Python to PATH"** during installation. Alternatively, you can install it instantly via PowerShell: 
    > `winget install Python.Python.3.11`

Once Python is installed, open your terminal, Command Prompt, or Git Bash inside your preferred projects folder in your file system and install the required Python packages:

```bash
pip install requests python-dotenv
```

### Step 1: Clone the Repository

Open your terminal or Git Bash and clone the repository to your local machine:

```bash
git clone https://github.com/kevingiff/GarminWindowsConnect.git
cd GarminWindowsConnect
```

### Step 2: Set Up the Desktop Shortcut
Right-click start_listener.bat in your project folder and select Send to ➔ Desktop (create shortcut) (on Windows 11, click "Show more options" first).

Move or copy the new shortcut to your Windows Desktop and rename it to something clean like Garmin Listener.

### Step 3: Configure Your Settings (.env & config.json)
#### Environment Setup (.env):

A) Copy .env.example and rename the copy to .env.

B) Open .env in a text editor and set your NTFY_TOPIC_URL (choose a random, secure, unguessable string of letters and numbers).

#### Action Setup (config.json):

C) Copy config.json.example and rename the copy to config.json.

D) Open config.json & Pick a desktop application you want to test (like a large game or program that takes significant time to launch, you can use the second RuneScape OSRS example out of the box if you have the game). Re-assign [YOUR_SECURE_PASSWORD_1] & [YOUR_SECURE_PASSWORD_2] to random, secure password strings and verify your program execution path inside the launch_direct.bat or launch_osrs.bat files respectively.

## You are more than 50% of the way there. Finishing stretch!

### Step 4: Build Your Custom Watch App
Because your watch app requires your personal secure tokens and topics, you will build it once using your local settings:

#### A) Generate Your Config File: Run this command in your terminal from the project root folder:

``` Bash
python build_watch.py
```

#### B) Prepare for export: Open the App Folder in VS Code: (Requires desktop application VS Code)

### 💡 Important Workspace Note: The Garmin Connect IQ SDK requires you to open the /app/ folder directly as your workspace root.
Open Visual Studio Code, click File ➔ Open Folder, and select the /app/ folder inside your cloned project directory.

#### C) Build via Run and Debug:

Go to the Run and Debug menu on the left sidebar of VS Code (or press Ctrl+Shift+D / Cmd+Shift+D).

Click the Play (Run) button at the top of the panel. Choose the project root folder to save the app.prg file.

Look at the terminal output at the bottom for the "Build Successful" message. This compiles your customized app.prg file.

### Step 5: Close VS Code and Install the App on Your Garmin Watch
Plug your Garmin watch into your computer using its USB charging cable.

Ensure your watch is set to Mass Storage / USB Mode (look for the green USB connection indicator on your watch screen).

Wait 5–30 seconds for Windows Explorer to recognize your watch as an external drive.

Open the watch drive in File Explorer and navigate to:

Garmin/App/

Drag and drop your newly built app.prg file into the watch's /Garmin/App/ folder.

Safely eject the watch from Windows and disconnect the USB cable. The app is now ready on your watch!

## 🎮 How to Use the App on Your Watch
Once opened from your watch's activity menu, you can interact with the app in two ways:

## 🌐 Geofence Listener (Touchscreen): Enter the main activity interface and use the touchscreen to start or manage your geofence background listener.

## ⚡ Manual Triggers (Menu Button): Want to fire an action manually without waiting for a geofence? Simply hold the Menu (Up) button on your watch to open your action list. Tap or select any configured trigger to send it instantly to your PC!

⚙️ Optional Customizations & Developer Guide
🎨 Changing Your Desktop Shortcut Icon
To give your desktop shortcut a custom visual appearance:

Right-click your Desktop shortcut and select Properties.

Click Change Icon... and browse to select the custom icon image provided in the root of this project (icon.ico or your own image file).

⌚ Matching Your Specific Watch Model
By default, the app is configured for the Fēnix 8 Solar 47mm. If you use a different Garmin model:

Open /app/manifest.xml.

Locate the product ID tag:

XML
<iq:product id="fenix8solar47mm"/>
Replace fenix8solar47mm with your watch model's official Connect IQ product identifier before building.

🔑 Adding a Garmin Developer Key (Optional)
If you encounter signing prompts when building in VS Code:

Obtain a developer key from the Garmin Connect IQ Developer Portal.

Place your developer key file into the /app/source/ directory as required by the SDK.
