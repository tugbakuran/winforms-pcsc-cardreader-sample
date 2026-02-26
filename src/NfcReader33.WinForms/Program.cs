using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using NfcReader33.Application.Abstractions;
using NfcReader33.Application.UseCases.ListReaders;
using NfcReader33.Application.UseCases.ReadCard;
using NfcReader33.Infrastructure.Pcsc;

namespace NfcReader33.WinForms;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();

        using var host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                // Infrastructure
                services.AddSingleton(new PcscOptions { MonitorPollingMs = 1000 });
                services.AddSingleton<ICardReaderMonitor, PcscReaderMonitor>();
                services.AddSingleton<ICardSessionFactory, PcscCardSessionFactory>();

                // Use-cases
                services.AddTransient<ListReadersHandler>();
                services.AddTransient<ReadCardHandler>();

                // UI
                services.AddSingleton<MainForm>();
            })
            .Build();

        var form = host.Services.GetRequiredService<MainForm>();
        Application.Run(form);
    }
}