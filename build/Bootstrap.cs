using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.Versioning;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

[assembly: AssemblyTitle("Fortnite Tweaks Launcher")]
[assembly: AssemblyProduct("Fortnite Tweaks")]
[assembly: AssemblyDescription("Windows launcher for the Fortnite Tweaks graphical interface")]
[assembly: AssemblyVersion("0.1.0.0")]
[assembly: AssemblyFileVersion("0.1.0.0")]
[assembly: TargetFramework(".NETFramework,Version=v4.8", FrameworkDisplayName = ".NET Framework 4.8")]

internal static class Bootstrap
{
    private static readonly string[,] Payload = new string[,]
    {
        { "FortniteTweaks.EntryPoint", "Launcher.ps1" },
        { "FortniteTweaks.Interface", "src/Launcher.psm1" },
        { "FortniteTweaks.Layout", "src/Launcher.xaml" },
        { "FortniteTweaks.Settings", "src/FortniteTweaks.psm1" }
    };

    [STAThread]
    private static int Main(string[] args)
    {
        bool verifyOnly = args.Length == 1 && args[0] == "--verify-payload";
        string directory = null;
        try
        {
            if (args.Length != 0 && !verifyOnly)
                throw new ArgumentException("Unbekanntes Argument. Starte die EXE per Doppelklick.");

            directory = Path.Combine(Path.GetTempPath(), "Fortnite-Tweaks-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(directory);
            ExtractAndVerify(directory);

            string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
                "WindowsPowerShell", "v1.0", "powershell.exe");
            if (!File.Exists(powershell))
                throw new FileNotFoundException("Windows PowerShell 5.1 wurde nicht gefunden.", powershell);

            if (verifyOnly)
            {
                Console.WriteLine("Payload verified: 4 files; Windows PowerShell found.");
                return 0;
            }

            RunLauncher(powershell, directory);
            return 0;
        }
        catch (Exception error)
        {
            if (verifyOnly)
                Console.Error.WriteLine(error.ToString());
            else
            {
                string log = SaveErrorLog(error);
                string message = "Der Fortnite-Tweaks-Launcher konnte nicht gestartet werden.\n\n" + error.Message;
                if (log != null) message += "\n\nFehlerprotokoll: " + log;
                MessageBox.Show(message, "Fortnite Tweaks", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            return 1;
        }
        finally
        {
            if (directory != null)
            {
                // Only this process's freshly created payload directory is removed.
                // Game settings and backups live outside it.
                try { Directory.Delete(directory, true); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            }
        }
    }

    private static void ExtractAndVerify(string directory)
    {
        Assembly assembly = Assembly.GetExecutingAssembly();
        for (int index = 0; index < Payload.GetLength(0); index++)
        {
            byte[] bytes;
            using (Stream resource = assembly.GetManifestResourceStream(Payload[index, 0]))
            {
                if (resource == null || resource.Length == 0)
                    throw new InvalidDataException("Eine eingebettete Launcher-Datei fehlt: " + Payload[index, 1]);
                using (MemoryStream memory = new MemoryStream())
                {
                    resource.CopyTo(memory);
                    bytes = memory.ToArray();
                }
            }

            string file = Path.Combine(directory, Payload[index, 1].Replace('/', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(Path.GetDirectoryName(file));
            using (FileStream output = new FileStream(file, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                output.Write(bytes, 0, bytes.Length);

            using (SHA256 sha = SHA256.Create())
            using (FileStream written = File.OpenRead(file))
            {
                string expected = Convert.ToBase64String(sha.ComputeHash(bytes));
                string actual = Convert.ToBase64String(sha.ComputeHash(written));
                if (!String.Equals(expected, actual, StringComparison.Ordinal))
                    throw new InvalidDataException("Die entpackte Launcher-Datei konnte nicht verifiziert werden.");
            }
        }
    }

    private static void RunLauncher(string powershell, string directory)
    {
        string script = Path.Combine(directory, "Launcher.ps1");
        ProcessStartInfo start = new ProcessStartInfo();
        start.FileName = powershell;
        start.WorkingDirectory = directory;
        start.Arguments = "-NoLogo -NoProfile -NonInteractive -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File \"" + script + "\"";
        start.UseShellExecute = false;
        start.CreateNoWindow = true;
        start.RedirectStandardError = true;
        start.RedirectStandardOutput = true;
        StringBuilder errors = new StringBuilder();
        using (Process process = new Process())
        {
            process.StartInfo = start;
            process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs eventArgs)
            {
                if (eventArgs.Data != null)
                    lock (errors) { if (errors.Length < 16000) errors.AppendLine(eventArgs.Data); }
            };
            process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs eventArgs) { };
            if (!process.Start()) throw new InvalidOperationException("PowerShell konnte nicht gestartet werden.");
            process.BeginErrorReadLine();
            process.BeginOutputReadLine();
            process.WaitForExit();
            if (process.ExitCode != 0)
            {
                string details = errors.ToString().Trim();
                if (details.Length == 0) details = "PowerShell meldet Fehlercode " + process.ExitCode + ".";
                throw new InvalidOperationException(details);
            }
        }
    }

    private static string SaveErrorLog(Exception error)
    {
        try
        {
            string folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Fortnite-Tweaks", "Logs");
            Directory.CreateDirectory(folder);
            string file = Path.Combine(folder, "launcher-" + DateTime.UtcNow.ToString("yyyyMMddTHHmmssfff") + "-" + Guid.NewGuid().ToString("N") + ".log");
            File.WriteAllText(file, error.ToString(), new UTF8Encoding(false));
            return file;
        }
        catch { return null; }
    }
}
