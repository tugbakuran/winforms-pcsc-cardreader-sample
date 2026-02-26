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