# Win-Auto-Setup ⚙️

A PowerShell-based automation suite designed to streamline Windows setup, optimization, and application management. This project provides tools for installing software, removing bloatware, tweaking performance settings, and more, all through a user-friendly interface or command-line options. It aims to simplify the process of configuring a new or existing Windows installation to your specific needs.

🚀 **Key Features**

*   **Graphical User Interface (GUI):**  Provides an intuitive interface for selecting and running various scripts.
*   **Automated Script Execution:**  Executes scripts for system optimization, application installation, and bloatware removal.
*   **Winget Integration:**  Leverages the Windows Package Manager (Winget) for streamlined application installation.
*   **Bloatware Removal:**  Removes pre-installed Windows applications to improve system performance.
*   **Performance Tweaks:**  Applies various performance tweaks to optimize system responsiveness.
*   **GitHub Fallback:** Downloads scripts from a GitHub repository if local versions are unavailable.
*   **Logging:**  Logs script execution progress and errors to the UI or console.
*   **Administrative Privilege Handling:**  Automatically requests and elevates to administrator privileges when required.
*   **Chocolatey Integration:** Installs WinGet using Chocolatey package manager.

🛠️ **Tech Stack**

*   **PowerShell:** Core scripting language.
*   **System.Windows.Forms:**  GUI framework.
*   **System.Drawing:**  Image handling in GUI.
*   **System.Security.Principal:**  Administrator privilege checking.
*   **System.Diagnostics.Process:**  Process management (UAC elevation).
*   **WinGet (Windows Package Manager):** Application installation.
*   **Chocolatey:** Package manager (WinGet prerequisite).
*   **GitHub:** Script hosting and distribution.

📦 **Getting Started / Setup Instructions**

### Prerequisites

*   PowerShell 5.1 or later (recommended: PowerShell 7+)
*   Internet connection (for downloading scripts and applications)
*   Administrator privileges

## 🎯 Usage

### Basic Usage
To run the main script:
```powershell
irm https://sunrisecomputers.github.io/PowerShell/win-auto-setup/main.ps1 | iex
```

### Advanced Usage
For more advanced features, use the interactive UI [RECOMMEND] :
```powershell
irm https://sunrisecomputers.github.io/PowerShell/win-auto-setup/main_UI.ps1 | iex
```

### Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository_url>
    cd win-auto-setup
    ```

2.  **Set Execution Policy (if needed):**

    Open PowerShell as Administrator and run:

    ```powershell
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser
    ```

    **Warning:**  Setting the execution policy to `Unrestricted` can pose a security risk. Consider using a more restrictive policy like `RemoteSigned` and signing your scripts.

### Running Locally

**Using the GUI:**

1.  Run `main_UI.ps1`:

    ```powershell
    .\main_UI.ps1
    ```

**Using the Command Line:**

1.  Run `main.ps1`:

    ```powershell
    .\main.ps1
    ```

    Follow the on-screen menu to select and run scripts.

📂 **Project Structure**

```
win-auto-setup/
├── Files/
│   └── Appslist.txt          # List of applications to uninstall
├── Scripts/
│   ├── App_Remover.ps1       # Script to remove pre-installed apps (bloatware)
│   ├── Online-app-Install.ps1 # Script to install applications using Winget
│   ├── Performance-Tweaks-noUI.ps1 # Script to apply performance tweaks (no UI)
│   ├── Winget_Install.ps1    # Script to install Winget and its prerequisites
├── main.ps1                # Main script with command-line menu
├── main_UI.ps1             # Main script with graphical user interface
└── README.md               # This file
```

📸 **Screenshots**

1. ./main.ps1 - CLI Version
   <img width="852" height="745" alt="{F85305DE-6236-41BB-B1D4-A46A50C52E55}" src="https://github.com/user-attachments/assets/76f485d4-973d-4856-adec-45eb7dcebad6" />

3. ./main_UI.ps1 - GUI Version [RECOMMEND]
   <img width="1246" height="650" alt="{140CFBCB-7F24-47E6-9AAC-651103E33DBF}" src="https://github.com/user-attachments/assets/d4228911-a5ea-4734-8064-f15053fc0102" />

🤝 **Contributing**

Contributions are welcome! Please follow these steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Make your changes and commit them with descriptive messages.
4.  Submit a pull request.

📝 **License**

This project is licensed under the [MIT License](LICENSE) - see the `LICENSE` file for details.

## 👥 Authors & Contributors

- **Maintainer:** [![GitHub Profile](https://img.shields.io/badge/GitHub-quietcod-blue?logo=github)](https://github.com/quietcod)
- **Contributor:** [![GitHub Profile](https://img.shields.io/badge/GitHub-quietcod-blue?logo=github)](https://github.com/quietcod)

📬 **Contact**

[quietcod](https://github.com/quietcod)

💖 **Thanks**

Thank you for using and contributing to Win-Auto-Setup! We hope this project simplifies your Windows setup experience.

This README is written by [readme.ai](https://readme-generator-phi.vercel.app/).
