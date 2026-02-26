namespace NfcReader33.Domain.ValueObjects;

public sealed record ApduCommand(byte[] Bytes)
{
    public override string ToString() => BitConverter.ToString(Bytes).Replace(""-"", "" "");
}