<#
.SYNOPSIS
  Creates a Clean Architecture WinForms + PC/SC sample solution (reader-agnostic) in the current directory.

.DESCRIPTION
  - Creates:
      .gitignore (if missing)
      README.md
      NfcReader33.sln
      src/ (4 projects)
        - NfcReader33.Domain (net8.0)
        - NfcReader33.Application (net8.0)
        - NfcReader33.Infrastructure.Pcsc (net8.0, PCSC NuGet)
        - NfcReader33.WinForms (net8.0-windows, WinForms)
  - Adds references and restores packages.

.PREREQUISITES
  - .NET SDK 8+
  - Windows (WinForms target)
  - Optional: Git

.USAGE
  powershell -ExecutionPolicy Bypass -File .\setup.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step($msg) {
  Write-Host "==> $msg"
}

function Ensure-DotNet {
  Write-Step ".NET SDK kontrol ediliyor..."
  $v = & dotnet --version
  if (-not $v) { throw ".NET SDK bulunamadı. Lütfen .NET 8 SDK kur." }
  Write-Host "dotnet --version: $v"
}

function Ensure-Dir([string]$path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
}

function Write-FileUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path -Parent $path
  if ($dir) { Ensure-Dir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Ensure-File([string]$path, [string]$content) {
  if (Test-Path $path) {
    Write-Host "Skip (exists): $path"
    return
  }
  Write-Step "Create file: $path"
  Write-FileUtf8NoBom $path $content
}

Ensure-DotNet

# Root files
$gitignore = @"
# Build results
[Bb]in/
[Oo]bj/

# Visual Studio
.vs/
*.user
*.suo
*.userosscache
*.sln.docstates

# Rider
.idea/

# OS
.DS_Store
Thumbs.db

# NuGet
packages/

# Logs
*.log
"@

$readme = @"
# WinForms PC/SC Card Reader Sample (Clean Architecture)

This repository contains a simple **WinForms + .NET** sample that connects to any **PC/SC-compatible smart card reader** (CCID) installed on Windows, lists readers, connects to a card, reads **ATR**, and sends a sample APDU (Get UID for MIFARE-like cards; may not work for all cards).

## Requirements
- Windows
- .NET SDK 8+
- A PC/SC smart card reader driver installed (Device Manager should show it)
- NuGet restore access

## Run
Open `NfcReader33.sln` and run `NfcReader33.WinForms`.

## Notes
- "Reader-agnostic" means the app uses the PC/SC layer; vendor-specific devices still need proper drivers.
- For Turkish eID (T.C. Kimlik) / EMV cards, you must implement proper APDU flows (Strategy pattern suggested).

## Packages
- `PCSC` (PC/SC wrapper)
- `Microsoft.Extensions.Hosting` (DI/hosting in WinForms)
"@

Ensure-File ".gitignore" $gitignore
Ensure-File "README.md" $readme

# Create solution and projects (idempotent-ish)
Ensure-Dir "src"

Write-Step "Create solution and projects (if not exists)..."
if (-not (Test-Path "NfcReader33.sln")) {
  & dotnet new sln -n "NfcReader33" | Out-Null
} else {
  Write-Host "Skip (exists): NfcReader33.sln"
}

# Create projects
if (-not (Test-Path "src/NfcReader33.Domain/NfcReader33.Domain.csproj")) {
  & dotnet new classlib -n "NfcReader33.Domain" -o "src/NfcReader33.Domain" -f "net8.0" | Out-Null
}
if (-not (Test-Path "src/NfcReader33.Application/NfcReader33.Application.csproj")) {
  & dotnet new classlib -n "NfcReader33.Application" -o "src/NfcReader33.Application" -f "net8.0" | Out-Null
}
if (-not (Test-Path "src/NfcReader33.Infrastructure.Pcsc/NfcReader33.Infrastructure.Pcsc.csproj")) {
  & dotnet new classlib -n "NfcReader33.Infrastructure.Pcsc" -o "src/NfcReader33.Infrastructure.Pcsc" -f "net8.0" | Out-Null
}
if (-not (Test-Path "src/NfcReader33.WinForms/NfcReader33.WinForms.csproj")) {
  & dotnet new winforms -n "NfcReader33.WinForms" -o "src/NfcReader33.WinForms" -f "net8.0-windows" | Out-Null
}

# Add to solution (safe to re-run; dotnet will warn if already added)
Write-Step "Add projects to solution..."
& dotnet sln "NfcReader33.sln" add "src/NfcReader33.Domain/NfcReader33.Domain.csproj" | Out-Null
& dotnet sln "NfcReader33.sln" add "src/NfcReader33.Application/NfcReader33.Application.csproj" | Out-Null
& dotnet sln "NfcReader33.sln" add "src/NfcReader33.Infrastructure.Pcsc/NfcReader33.Infrastructure.Pcsc.csproj" | Out-Null
& dotnet sln "NfcReader33.sln" add "src/NfcReader33.WinForms/NfcReader33.WinForms.csproj" | Out-Null

# Project references
Write-Step "Add project references..."
& dotnet add "src/NfcReader33.Application/NfcReader33.Application.csproj" reference "src/NfcReader33.Domain/NfcReader33.Domain.csproj" | Out-Null
& dotnet add "src/NfcReader33.Infrastructure.Pcsc/NfcReader33.Infrastructure.Pcsc.csproj" reference "src/NfcReader33.Application/NfcReader33.Application.csproj" | Out-Null
& dotnet add "src/NfcReader33.WinForms/NfcReader33.WinForms.csproj" reference "src/NfcReader33.Application/NfcReader33.Application.csproj" | Out-Null
& dotnet add "src/NfcReader33.WinForms/NfcReader33.WinForms.csproj" reference "src/NfcReader33.Infrastructure.Pcsc/NfcReader33.Infrastructure.Pcsc.csproj" | Out-Null

# NuGet packages
Write-Step "Add NuGet packages..."
& dotnet add "src/NfcReader33.Infrastructure.Pcsc/NfcReader33.Infrastructure.Pcsc.csproj" package "PCSC" --version "6.2.0" | Out-Null
& dotnet add "src/NfcReader33.WinForms/NfcReader33.WinForms.csproj" package "Microsoft.Extensions.Hosting" --version "9.0.2" | Out-Null

# Now overwrite the generated placeholder class files with our real code
Write-Step "Write Clean Architecture source files..."

# Domain
Write-FileUtf8NoBom "src/NfcReader33.Domain/Entities/ReaderDevice.cs" @"
namespace NfcReader33.Domain.Entities;

public sealed record ReaderDevice(string Name);
"@

Write-FileUtf8NoBom "src/NfcReader33.Domain/ValueObjects/CardAtr.cs" @"
namespace NfcReader33.Domain.ValueObjects;

public sealed record CardAtr(byte[] Bytes)
{
    public override string ToString() => BitConverter.ToString(Bytes).Replace("" - "", "" "");
}
"@.Replace(' - ', '-')

Write-FileUtf8NoBom "src/NfcReader33.Domain/ValueObjects/ApduCommand.cs" @"
namespace NfcReader33.Domain.ValueObjects;

public sealed record ApduCommand(byte[] Bytes)
{
    public override string ToString() => BitConverter.ToString(Bytes).Replace("" - "", "" "");
}
"@.Replace(' - ', '-')

Write-FileUtf8NoBom "src/NfcReader33.Domain/ValueObjects/ApduResponse.cs" @"
namespace NfcReader33.Domain.ValueObjects;

public sealed record ApduResponse(byte[] Data, byte Sw1, byte Sw2)
{
    public ushort StatusWord => (ushort)((Sw1 << 8) | Sw2);

    public bool IsSuccess => Sw1 == 0x90 && Sw2 == 0x00;

    public override string ToString()
        => $""SW={Sw1:X2}{Sw2:X2} DATA={BitConverter.ToString(Data).Replace(""-"", "" "")}"";
}
"@

# Application abstractions
Write-FileUtf8NoBom "src/NfcReader33.Application/Abstractions/ICardReaderMonitor.cs" @"
using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.Abstractions;

public interface ICardReaderMonitor : IDisposable
{
    event EventHandler? ReadersChanged;

    Task<IReadOnlyList<ReaderDevice>> GetReadersAsync(CancellationToken ct);
}
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/Abstractions/ICardSessionFactory.cs" @"
using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.Abstractions;

public interface ICardSessionFactory
{
    Task<ICardSession> ConnectAsync(ReaderDevice reader, CancellationToken ct);
}
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/Abstractions/ICardSession.cs" @"
using NfcReader33.Domain.ValueObjects;

namespace NfcReader33.Application.Abstractions;

public interface ICardSession : IDisposable
{
    Task<CardAtr> GetAtrAsync(CancellationToken ct);

    Task<ApduResponse> TransmitAsync(ApduCommand command, CancellationToken ct);
}
"@

# Use cases
Write-FileUtf8NoBom "src/NfcReader33.Application/UseCases/ListReaders/ListReadersQuery.cs" @"
namespace NfcReader33.Application.UseCases.ListReaders;

public sealed record ListReadersQuery();
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/UseCases/ListReaders/ListReadersResult.cs" @"
using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.UseCases.ListReaders;

public sealed record ListReadersResult(IReadOnlyList<ReaderDevice> Readers);
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/UseCases/ListReaders/ListReadersHandler.cs" @"
using NfcReader33.Application.Abstractions;

namespace NfcReader33.Application.UseCases.ListReaders;

public sealed class ListReadersHandler
{
    private readonly ICardReaderMonitor _monitor;

    public ListReadersHandler(ICardReaderMonitor monitor)
    {
        _monitor = monitor ?? throw new ArgumentNullException(nameof(monitor));
    }

    public async Task<ListReadersResult> HandleAsync(ListReadersQuery query, CancellationToken ct)
    {
        var readers = await _monitor.GetReadersAsync(ct);
        return new ListReadersResult(readers);
    }
}
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/UseCases/ReadCard/ReadCardCommand.cs" @"
using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.UseCases.ReadCard;

public sealed record ReadCardCommand(ReaderDevice Reader);
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/UseCases/ReadCard/ReadCardResult.cs" @"
namespace NfcReader33.Application.UseCases.ReadCard;

public sealed record ReadCardResult(
    string ReaderName,
    string Atr,
    string ResponseText
);
"@

Write-FileUtf8NoBom "src/NfcReader33.Application/UseCases/ReadCard/ReadCardHandler.cs" @"
using NfcReader33.Application.Abstractions;
using NfcReader33.Domain.ValueObjects;

namespace NfcReader33.Application.UseCases.ReadCard;

public sealed class ReadCardHandler
{
    private readonly ICardSessionFactory _factory;

    public ReadCardHandler(ICardSessionFactory factory)
    {
        _factory = factory ?? throw new ArgumentNullException(nameof(factory));
    }

    public async Task<ReadCardResult> HandleAsync(ReadCardCommand command, CancellationToken ct)
    {
        // Sample APDU: Get UID (works for many MIFARE-like cards/readers, not all cards).
        var sampleApdu = new ApduCommand(new byte[] { 0xFF, 0xCA, 0x00, 0x00, 0x00 });

        using var session = await _factory.ConnectAsync(command.Reader, ct);

        var atr = await session.GetAtrAsync(ct);

        try
        {
            var resp = await session.TransmitAsync(sampleApdu, ct);

            return new ReadCardResult(
                ReaderName: command.Reader.Name,
                Atr: atr.ToString(),
                ResponseText: resp.ToString()
            );
        }
        catch (Exception ex)
        {
            return new ReadCardResult(
                ReaderName: command.Reader.Name,
                Atr: atr.ToString(),
                ResponseText: $""APDU transmit failed: {ex.Message}""
            );
        }
    }
}
"@

# Infrastructure (PCSC)
Write-FileUtf8NoBom "src/NfcReader33.Infrastructure.Pcsc/PcscOptions.cs" @"
namespace NfcReader33.Infrastructure.Pcsc;

public sealed class PcscOptions
{
    public int MonitorPollingMs { get; init; } = 1000;
}
"@

Write-FileUtf8NoBom "src/NfcReader33.Infrastructure.Pcsc/PcscReaderMonitor.cs" @"
using NfcReader33.Application.Abstractions;
using NfcReader33.Domain.Entities;
using PCSC;

namespace NfcReader33.Infrastructure.Pcsc;

public sealed class PcscReaderMonitor : ICardReaderMonitor
{
    private readonly ISCardContext _context;
    private readonly Timer _timer;

    private string[] _lastReaders = Array.Empty<string>();

    public event EventHandler? ReadersChanged;

    public PcscReaderMonitor(PcscOptions options)
    {
        _context = ContextFactory.Instance.Establish(SCardScope.System);

        _timer = new Timer(_ =>
        {
            try
            {
                var current = _context.GetReaders() ?? Array.Empty<string>();
                if (!current.SequenceEqual(_lastReaders))
                {
                    _lastReaders = current;
                    ReadersChanged?.Invoke(this, EventArgs.Empty);
                }
            }
            catch
            {
                // In production, log this exception.
            }
        }, null, dueTime: options.MonitorPollingMs, period: options.MonitorPollingMs);
    }

    public Task<IReadOnlyList<ReaderDevice>> GetReadersAsync(CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();

        var readers = _context.GetReaders() ?? Array.Empty<string>();
        IReadOnlyList<ReaderDevice> result = readers.Select(r => new ReaderDevice(r)).ToList();
        return Task.FromResult(result);
    }

    public void Dispose()
    {
        _timer.Dispose();
        _context.Dispose();
    }
}
"@

Write-FileUtf8NoBom "src/NfcReader33.Infrastructure.Pcsc/PcscCardSessionFactory.cs" @"
using NfcReader33.Application.Abstractions;
using NfcReader33.Domain.Entities;

namespace NfcReader33.Infrastructure.Pcsc;

public sealed class PcscCardSessionFactory : ICardSessionFactory
{
    public Task<ICardSession> ConnectAsync(ReaderDevice reader, CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();
        ICardSession session = new PcscCardSession(reader.Name);
        return Task.FromResult(session);
    }
}
"@

Write-FileUtf8NoBom "src/NfcReader33.Infrastructure.Pcsc/PcscCardSession.cs" @"
using NfcReader33.Application.Abstractions;
using NfcReader33.Domain.ValueObjects;
using PCSC;
using PCSC.Iso7816;

namespace NfcReader33.Infrastructure.Pcsc;

public sealed class PcscCardSession : ICardSession
{
    private readonly ISCardContext _context;
    private readonly SCardReader _reader;
    private readonly string _readerName;
    private readonly SCardProtocol _activeProtocol;

    public PcscCardSession(string readerName)
    {
        _readerName = readerName ?? throw new ArgumentNullException(nameof(readerName));

        _context = ContextFactory.Instance.Establish(SCardScope.System);
        _reader = new SCardReader(_context);

        var sc = _reader.Connect(_readerName, SCardShareMode.Shared, SCardProtocol.Any);
        if (sc != SCardError.Success)
            throw new InvalidOperationException($""Could not connect to reader '{_readerName}': {SCardHelper.StringifyError(sc)}"");

        _activeProtocol = _reader.ActiveProtocol;
    }

    public Task<CardAtr> GetAtrAsync(CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();

        var status = _reader.GetStatus();
        if (status is null)
            throw new InvalidOperationException(""Could not get card status."");

        return Task.FromResult(new CardAtr(status.GetAtr() ?? Array.Empty<byte>()));
    }

    public Task<ApduResponse> TransmitAsync(ApduCommand command, CancellationToken ct)
    {
        ct.ThrowIfCancellationRequested();

        if (command.Bytes.Length < 4)
            throw new ArgumentException(""APDU must be at least 4 bytes (CLA INS P1 P2)."", nameof(command));

        // Case2Short for example (no data, expects response)
        var apdu = new CommandApdu(IsoCase.Case2Short, _activeProtocol)
        {
            CLA = command.Bytes[0],
            INS = command.Bytes[1],
            P1 = command.Bytes[2],
            P2 = command.Bytes[3],
            Le = command.Bytes.Length >= 5 ? command.Bytes[4] : 0x00
        };

        var sendPci = SCardPCI.GetPci(_activeProtocol);
        var sendBuffer = apdu.ToArray();

        var receiveBuffer = new byte[258];

        var rc = _reader.Transmit(
            sendPci: sendPci,
            sendBuffer: sendBuffer,
            receivePci: IntPtr.Zero,
            receiveBuffer: receiveBuffer,
            out var receiveLength);

        if (rc != SCardError.Success)
            throw new InvalidOperationException($""APDU transmit error: {SCardHelper.StringifyError(rc)}"");

        var raw = receiveBuffer.AsSpan(0, receiveLength).ToArray();
        var response = new ResponseApdu(raw, IsoCase.Case2Short, _activeProtocol);

        var data = response.HasData ? response.GetData() : Array.Empty<byte>();
        return Task.FromResult(new ApduResponse(data, response.SW1, response.SW2));
    }

    public void Dispose()
    {
        try { _reader.Disconnect(SCardReaderDisposition.Leave); } catch { }
        _reader.Dispose();
        _context.Dispose();
    }
}
"@

# WinForms UI
Write-FileUtf8NoBom "src/NfcReader33.WinForms/Program.cs" @"
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using NfcReader33.Application.Abstractions;
using NfcReader33.Application.UseCases.ListReaders;
using NfcReader33.Application.UseCases.ReadCard;
using NfcReader33.Infrastructure.Pcsc;

namespace NfcReader33.WinForms;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();

        using var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                // Infrastructure
                services.AddSingleton(new PcscOptions { MonitorPollingMs = 1000 });
                services.AddSingleton<ICardReaderMonitor, PcscReaderMonitor>();
                services.AddSingleton<ICardSessionFactory, PcscCardSessionFactory>();

                // Use-cases
                services.AddTransient<ListReadersHandler>();
                services.AddTransient<ReadCardHandler>();

                // UI
                services.AddSingleton<MainForm>();
            })
            .Build();

        var form = host.Services.GetRequiredService<MainForm>();
        Application.Run(form);
    }
}
"@

Write-FileUtf8NoBom "src/NfcReader33.WinForms/MainForm.cs" @"
using NfcReader33.Application.Abstractions;
using NfcReader33.Application.UseCases.ListReaders;
using NfcReader33.Application.UseCases.ReadCard;
using NfcReader33.Domain.Entities;

namespace NfcReader33.WinForms;

public partial class MainForm : Form
{
    private readonly ICardReaderMonitor _monitor;
    private readonly ListReadersHandler _listReaders;
    private readonly ReadCardHandler _readCard;

    public MainForm(
        ICardReaderMonitor monitor,
        ListReadersHandler listReaders,
        ReadCardHandler readCard)
    {
        _monitor = monitor ?? throw new ArgumentNullException(nameof(monitor));
        _listReaders = listReaders ?? throw new ArgumentNullException(nameof(listReaders));
        _readCard = readCard ?? throw new ArgumentNullException(nameof(readCard));

        InitializeComponent();

        _monitor.ReadersChanged += (_, __) =>
        {
            if (!IsHandleCreated) return;

            BeginInvoke(async () =>
            {
                await LoadReadersAsync();
            });
        };
    }

    protected override async void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        await LoadReadersAsync();
    }

    private async Task LoadReadersAsync()
    {
        try
        {
            var result = await _listReaders.HandleAsync(new ListReadersQuery(), CancellationToken.None);

            comboReaders.DataSource = result.Readers.ToList();
            comboReaders.DisplayMember = nameof(ReaderDevice.Name);

            AppendLine($""Readers found: {result.Readers.Count}"");
        }
        catch (Exception ex)
        {
            AppendLine($""List readers failed: {ex.Message}"");
        }
    }

    private async void btnRefresh_Click(object sender, EventArgs e)
        => await LoadReadersAsync();

    private async void btnRead_Click(object sender, EventArgs e)
    {
        if (comboReaders.SelectedItem is not ReaderDevice reader)
        {
            AppendLine(""Select a reader first."");
            return;
        }

        btnRead.Enabled = false;
        try
        {
            var result = await _readCard.HandleAsync(new ReadCardCommand(reader), CancellationToken.None);

            AppendLine($""Reader: {result.ReaderName}"");
            AppendLine($""ATR: {result.Atr}"");
            AppendLine($""Response: {result.ResponseText}"");
            AppendLine(""----"");
        }
        catch (Exception ex)
        {
            AppendLine($""Read failed: {ex.Message}"");
        }
        finally
        {
            btnRead.Enabled = true;
        }
    }

    private void AppendLine(string text)
    {
        txtOutput.AppendText($""{DateTime.Now:HH:mm:ss} {text}{Environment.NewLine}"");
    }
}
"@

Write-FileUtf8NoBom "src/NfcReader33.WinForms/MainForm.Designer.cs" @"
namespace NfcReader33.WinForms;

partial class MainForm
{
    private System.ComponentModel.IContainer components = null!;
    private ComboBox comboReaders = null!;
    private Button btnRefresh = null!;
    private Button btnRead = null!;
    private TextBox txtOutput = null!;

    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null))
        {
            components.Dispose();
        }
        base.Dispose(disposing);
    }

    private void InitializeComponent()
    {
        comboReaders = new ComboBox();
        btnRefresh = new Button();
        btnRead = new Button();
        txtOutput = new TextBox();

        SuspendLayout();

        comboReaders.DropDownStyle = ComboBoxStyle.DropDownList;
        comboReaders.Location = new Point(12, 12);
        comboReaders.Size = new Size(560, 23);

        btnRefresh.Location = new Point(12, 45);
        btnRefresh.Size = new Size(120, 30);
        btnRefresh.Text = ""Refresh"";
        btnRefresh.Click += btnRefresh_Click;

        btnRead.Location = new Point(138, 45);
        btnRead.Size = new Size(120, 30);
        btnRead.Text = ""Read Card"";
        btnRead.Click += btnRead_Click;

        txtOutput.Location = new Point(12, 85);
        txtOutput.Size = new Size(560, 360);
        txtOutput.Multiline = true;
        txtOutput.ScrollBars = ScrollBars.Vertical;
        txtOutput.ReadOnly = true;

        ClientSize = new Size(584, 461);
        Controls.Add(comboReaders);
        Controls.Add(btnRefresh);
        Controls.Add(btnRead);
        Controls.Add(txtOutput);
        Text = ""NfcReader33 - PC/SC Card Reader Example"";

        ResumeLayout(false);
        PerformLayout();
    }
}
"@

# Remove template Class1.cs etc (optional)
Write-Step "Remove template placeholder files (if present)..."
$placeholders = @(
  "src/NfcReader33.Domain/Class1.cs",
  "src/NfcReader33.Application/Class1.cs",
  "src/NfcReader33.Infrastructure.Pcsc/Class1.cs"
)
foreach ($p in $placeholders) {
  if (Test-Path $p) {
    Remove-Item $p -Force
    Write-Host "Removed: $p"
  }
}

Write-Step "Restore & build..."
& dotnet restore "NfcReader33.sln" | Out-Null
& dotnet build "NfcReader33.sln" -c Release | Out-Null

Write-Step "Done."
Write-Host ""
Write-Host "Next:"
Write-Host "  git add ."
Write-Host "  git commit -m `"Initial clean architecture WinForms PC/SC sample`""
Write-Host "  git push origin main"