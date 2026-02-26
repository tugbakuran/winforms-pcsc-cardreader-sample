# WinForms PC/SC Card Reader Sample

A Windows Forms sample application demonstrating how to integrate **PC/SC smart card readers** into a C# desktop application. This project shows how to list available card readers, detect card insertion and removal events, read card ATR (Answer To Reset) and UID data, and send raw APDU commands to smart cards using the [PCSC](https://www.nuget.org/packages/PCSC/) NuGet library.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Clone the Repository](#clone-the-repository)
  - [Install Dependencies](#install-dependencies)
  - [Build and Run](#build-and-run)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [How It Works](#how-it-works)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

PC/SC (Personal Computer/Smart Card) is a standard interface for connecting smart cards and smart card readers to computers. This sample application demonstrates the core patterns for interacting with PC/SC-compatible readers (USB or serial) from a Windows Forms desktop application built with C# and .NET.

Whether you are building an attendance system, an access-control panel, a payment terminal, or simply exploring NFC/contactless card technology, this project provides a working starting point.

---

## Features

- 📋 **List all connected card readers** – Enumerate all PC/SC-compatible readers available on the system at startup and refresh on demand.
- 🔔 **Card insertion / removal events** – Subscribe to real-time notifications when a card is placed on or removed from a reader.
- 📄 **Read ATR (Answer To Reset)** – Display the raw ATR bytes returned by the card when it is powered on, which identifies the card type.
- 🆔 **Read card UID** – Retrieve the unique identifier of contactless cards (ISO 14443 / MIFARE, etc.) using standard GET DATA APDU commands.
- 📡 **Send APDU commands** – Construct and transmit raw ISO 7816-4 APDU commands and display the response (status bytes + data).
- 🪟 **Clean WinForms UI** – A straightforward Windows Forms interface designed to be easy to understand and extend.

---

## Prerequisites

| Requirement | Version |
|---|---|
| Windows OS | Windows 10 / 11 (or Windows Server 2016+) |
| .NET SDK | .NET 6 or later (LTS recommended) |
| Visual Studio | 2022 (Community, Professional, or Enterprise) |
| PC/SC-compatible card reader | Any USB HID or contactless reader (e.g., ACR122U, ACR1252, SCL3711) |
| Smart Card Service | Windows Smart Card service (`SCardSvr`) must be **running** |

> **Note:** The Windows Smart Card service is enabled and started automatically when a card reader is connected on most modern Windows installations. You can verify it is running by opening `services.msc` and locating **Smart Card**.

---

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/tugbakuran/winforms-pcsc-cardreader-sample.git
cd winforms-pcsc-cardreader-sample
```

### Install Dependencies

This project uses NuGet packages managed via the `.csproj` file. Restore them with:

```bash
dotnet restore
```

Or, in Visual Studio, open the solution and Visual Studio will automatically restore packages on build.

### Build and Run

**Using the .NET CLI:**

```bash
dotnet build
dotnet run --project CardReaderSample
```

**Using Visual Studio:**

1. Open `CardReaderSample.sln` in Visual Studio 2022.
2. Press **F5** (or **Ctrl+F5**) to build and run.

---

## Usage

1. **Connect your card reader** to the computer before launching the application.
2. **Launch the application** – available readers are automatically listed in the *Reader* dropdown.
3. **Select a reader** from the dropdown list.
4. **Place a smart card** on the reader – the application detects the insertion and displays:
   - The card's **ATR** (Answer To Reset) in hexadecimal.
   - The card's **UID** (if it is a contactless card).
5. **Send an APDU command** – enter a hex-encoded APDU in the command text box and click **Send** to transmit it. The response data and status word (e.g., `90 00` for success) are displayed in the output area.
6. **Remove the card** – the application detects removal and clears the card info panel.

### Example APDU Commands

| Command | Hex String | Description |
|---|---|---|
| Get UID (contactless) | `FF CA 00 00 00` | Retrieve the unique identifier of the card |
| Select MF | `00 A4 00 00 02 3F 00` | Select the Master File |
| Get Challenge | `00 84 00 00 08` | Request an 8-byte random number |

---

## Project Structure

```
winforms-pcsc-cardreader-sample/
├── CardReaderSample/
│   ├── Forms/
│   │   └── MainForm.cs          # Main WinForms window and UI logic
│   ├── Services/
│   │   ├── CardReaderService.cs # PC/SC reader enumeration and monitoring
│   │   └── ApduHelper.cs        # APDU command builder and response parser
│   ├── Models/
│   │   └── CardInfo.cs          # Data model for card ATR, UID, and state
│   ├── Program.cs               # Application entry point
│   └── CardReaderSample.csproj  # Project file with NuGet dependencies
├── .gitignore
├── LICENSE
└── README.md
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| [PCSC](https://www.nuget.org/packages/PCSC/) | ≥ 6.x | Managed wrapper around the Windows SCard API |
| [PCSC.Iso7816](https://www.nuget.org/packages/PCSC.Iso7816/) | ≥ 6.x | ISO 7816-4 APDU command and response helpers |

These packages are authored by [Daniel Mueller](https://github.com/danm-de/pcsc-sharp) and provide a clean, idiomatic C# API over the native `winscard.dll` PC/SC subsystem.

---

## How It Works

### Reader Context

The application establishes a PC/SC context using `ISCardContext` and calls `ListReaders()` to enumerate all connected readers. A `SCardMonitor` is created to fire events whenever the card state changes.

```csharp
using var context = contextFactory.Establish(SCardScope.System);
var readerNames = context.GetReaders();
```

### Card Monitoring

```csharp
var monitor = monitorFactory.Create(SCardScope.System);
monitor.CardInserted  += OnCardInserted;
monitor.CardRemoved   += OnCardRemoved;
monitor.Start(selectedReader);
```

### Reading the ATR

When a card is inserted, the ATR is available directly from the `CardStatusEventArgs`:

```csharp
private void OnCardInserted(object sender, CardStatusEventArgs e)
{
    string atr = BitConverter.ToString(e.Atr);
    // e.g. "3B-8F-80-01-80-4F-0C-A0-00-00-03-06-03-00-01-00-00-00-00-6A"
}
```

### Sending an APDU

```csharp
using var reader = new SCardReader(context);
reader.Connect(readerName, SCardShareMode.Shared, SCardProtocol.Any);

var apdu = new CommandApdu(IsoCase.Case2Short, reader.ActiveProtocol)
{
    CLA = 0xFF,
    Instruction = InstructionCode.GetData,
    P1  = 0x00,
    P2  = 0x00,
    Le  = 0x00
};

reader.Transmit(apdu.ToArray(), out byte[] response);
// response = [ <data bytes> ... 0x90, 0x00 ]
```

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`.
3. Commit your changes: `git commit -m "Add my feature"`.
4. Push the branch: `git push origin feature/my-feature`.
5. Open a Pull Request.

Please open an issue first to discuss major changes.

---

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.
