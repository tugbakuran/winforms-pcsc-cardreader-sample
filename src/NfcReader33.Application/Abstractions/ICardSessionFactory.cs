using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.Abstractions;

public interface ICardSessionFactory
{
    Task<ICardSession> ConnectAsync(ReaderDevice reader, CancellationToken ct);
}