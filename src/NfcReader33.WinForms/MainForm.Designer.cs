namespace NfcReader33.WinForms;

partial class MainForm
{
    private System.ComponentModel.IContainer components = null!;
    private ComboBox comboReaders = null!;
    private Button btnRefresh = null!;
    private Button btnRead = null!;
    private TextBox txtOutput = null!;

    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null))
        {
            components.Dispose();
        }
        base.Dispose(disposing);
    }

    private void InitializeComponent()
    {
        comboReaders = new ComboBox();
        btnRefresh = new Button();
        btnRead = new Button();
        txtOutput = new TextBox();

        SuspendLayout();

        comboReaders.DropDownStyle = ComboBoxStyle.DropDownList;
        comboReaders.Location = new Point(12, 12);
        comboReaders.Size = new Size(560, 23);

        btnRefresh.Location = new Point(12, 45);
        btnRefresh.Size = new Size(120, 30);
        btnRefresh.Text = ""Refresh"";
        btnRefresh.Click += btnRefresh_Click;

        btnRead.Location = new Point(138, 45);
        btnRead.Size = new Size(120, 30);
        btnRead.Text = ""Read Card"";
        btnRead.Click += btnRead_Click;

        txtOutput.Location = new Point(12, 85);
        txtOutput.Size = new Size(560, 360);
        txtOutput.Multiline = true;
        txtOutput.ScrollBars = ScrollBars.Vertical;
        txtOutput.ReadOnly = true;

        ClientSize = new Size(584, 461);
        Controls.Add(comboReaders);
        Controls.Add(btnRefresh);
        Controls.Add(btnRead);
        Controls.Add(txtOutput);
        Text = ""NfcReader33 - PC/SC Card Reader Example"";

        ResumeLayout(false);
        PerformLayout();
    }
}