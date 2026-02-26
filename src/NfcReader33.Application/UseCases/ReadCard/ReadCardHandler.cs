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