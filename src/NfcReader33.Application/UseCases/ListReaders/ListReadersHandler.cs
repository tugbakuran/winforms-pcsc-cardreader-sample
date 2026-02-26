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