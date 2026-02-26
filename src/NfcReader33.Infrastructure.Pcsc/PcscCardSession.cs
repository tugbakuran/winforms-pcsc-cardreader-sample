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