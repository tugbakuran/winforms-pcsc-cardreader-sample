using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.UseCases.ReadCard;

public sealed record ReadCardCommand(ReaderDevice Reader);