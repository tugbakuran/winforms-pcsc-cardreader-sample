using NfcReader33.Domain.Entities;

namespace NfcReader33.Application.UseCases.ListReaders;

public sealed record ListReadersResult(IReadOnlyList<ReaderDevice> Readers);