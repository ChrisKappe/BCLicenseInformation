codeunit 98765 "ImportLicenseFile"
{
    procedure ImportLicense()
    var
        Powershellrunner: DotNet PowerShellRunner;
        ActiveSession: Record "Active Session";
        TempBlob: Record TempBlob;
        FileMgt: Codeunit "File Management";
        Window: Dialog;
        FileName: Text;
    begin
        FileName := FileMgt.BLOBImportWithFilter(TempBlob, 'Select License File', '', FileFilter, AllFilesFilterTxt);

        if FileName = '' then
            Error(CancelledErr);

        FileName := TemporaryPath + FileName;

        if Exists(FileName) then
            Erase(FileName);

        FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        ActiveSession.Get(ServiceInstanceId(), SessionId());

        PowerShellRunner := PowerShellRunner.CreateInSandbox;
        PowerShellRunner.WriteEventOnError := true;
        PowerShellRunner.ImportModule(ApplicationPath + NAVAdminTool);
        PowerShellRunner.AddCommand('Import-NAVServerLicense');
        Powershellrunner.AddParameter('ServerInstance', ActiveSession."Server Instance Name");
        PowerShellRunner.AddParameter('LicenseFile', FileName);
        PowerShellRunner.BeginInvoke;

        Window.Open(BusyDlg);

        while not PowerShellRunner.IsCompleted do
            Sleep(1000);

        Window.Close();
    end;

    var
        CancelledErr: Label 'Operation cancelled by user.';
        BusyDlg: Label 'Busy importing......';
        AllFilesFilterTxt: Label '*.*';
        NAVAdminTool: Label 'NavAdminTool.ps1';
        FileFilter: Label 'License (*.flf)|*.flf|All Files (*.*)|*.*';
}
