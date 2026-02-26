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