using NfcReader33.Domain.ValueObjects;

namespace NfcReader33.Application.Abstractions;

public interface ICardSession : IDisposable
{
    Task<CardAtr> GetAtrAsync(CancellationToken ct);

    Task<ApduResponse> TransmitAsync(ApduCommand command, CancellationToken ct);
}