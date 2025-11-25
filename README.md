# PowerShell

## 🚀 Overview
PowerShell is a collection of PowerShell scripts designed to optimize your Windows environment. This repository includes scripts for tweaking performance, installing applications through WinGet, and managing system settings. Whether you're a power user looking to streamline your workflow or a developer seeking to automate tasks, PowerShell has you covered.

## ✨ Features
- **Performance Tweaks**: Optimize your system for better performance.
- **App Installation**: Install and manage applications using WinGet.
- **System Settings**: Configure system settings and remove bloatware.
- **Network Management**: Tweak network settings and manage SMB connections.
- **Hardware Information**: Generate detailed hardware reports.
- **User-Friendly UI**: An interactive UI for easier management.

## 🛠️ Tech Stack
- **Programming Language**: PowerShell
- **Frameworks and Tools**: WinGet, Chocolatey, PowerShell modules

## 📦 Installation

### Prerequisites
- PowerShell 5.0 or later
- Administrator privileges

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

## 📁 Project Structure
```
win-auto-setup/
├── main.ps1
├── main_UI.ps1
├── Scripts/
│   ├── App_Remover.ps1
│   ├── Delay-WindowsUpdates.ps1
│   ├── Disable-WindowsUpdates.ps1
│   ├── Hardware_Report_Generator.ps1
│   ├── Lanman_Network.ps1
│   ├── link-speed.ps1
│   ├── Online-app-Install.ps1
│   ├── Performance_Tweaks.ps1
│   ├── Performance-Tweaks-noUI.ps1
│   ├── SMB-Connection-Reset.ps1
│   ├── Winget_Install.ps1
├── Files/
│   |── Appslist.txt
│   └── S_Logo.png
```

## 🔧 Configuration
- **Environment Variables**: None required.
- **Configuration Files**: `Appslist.txt` for app management.

## 🤝 Contributing
We welcome contributions! Here's how you can get involved:

1. **Fork the repository**.
2. **Create a new branch** for your feature or bug fix.
3. **Make your changes** and ensure they follow the project's coding standards.
4. **Submit a pull request** with a clear description of your changes.

### Development Setup
1. Clone the repository:
    ```bash
    git clone https://github.com/SunriseComputers/PowerShell.git
    ```
2. Navigate to the project directory:
    ```bash
    cd PowerShell
    ```

## 👥 Authors & Contributors
- **Maintainers**: [![GitHub Profile](https://img.shields.io/badge/GitHub-quietcod-blue?logo=github)](https://github.com/quietcod)
- **Contributors**: [![GitHub Profile](https://img.shields.io/badge/GitHub-quietcod-blue?logo=github)](https://github.com/quietcod)

## 🐛 Issues & Support
- **Report Issues**: Open an issue on the [GitHub Issues page](https://github.com/SunriseComputers/PowerShell/issues).
- **Get Help**: Join the [PowerShell Community](https://github.com/SunriseComputers/PowerShell/discussions) for support.


**Note**: Ensure you have the necessary permissions to run scripts with elevated privileges. Always review and understand the scripts before execution.
