using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.Abstractions;

public interface ICardReaderMonitor : IDisposable
{
    event EventHandler? ReadersChanged;

    Task<IReadOnlyList<ReaderDevice>> GetReadersAsync(CancellationToken ct);
}