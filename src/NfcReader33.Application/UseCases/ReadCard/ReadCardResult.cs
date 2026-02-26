namespace NfcReader33.Application.UseCases.ReadCard;

public sealed record ReadCardResult(
    string ReaderName,
    string Atr,
    string ResponseText
);