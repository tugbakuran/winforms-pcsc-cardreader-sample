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