namespace NfcReader33.Domain.ValueObjects;

public sealed record ApduResponse(byte[] Data, byte Sw1, byte Sw2)
{
    public ushort StatusWord => (ushort)((Sw1 << 8) | Sw2);

    public bool IsSuccess => Sw1 == 0x90 && Sw2 == 0x00;

    public override string ToString()
        => $""SW={Sw1:X2}{Sw2:X2} DATA={BitConverter.ToString(Data).Replace(""-"", "" "")}"";
}