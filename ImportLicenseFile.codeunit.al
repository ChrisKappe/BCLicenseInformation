codeunit 98765 "ImportLicenseFile"
{
    trigger OnRun()
    begin
        ImportLicense();
    end;

    procedure ImportLicense()
    var
        Powershellrunner: DotNet PowerShellRunner;
        ActiveSession: Record "Active Session";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        Window: Dialog;
        FileName: Text;

    begin
        FileName := FileMgt.BLOBImportWithFilter(TempBlob, 'Select License File', '', FileFilter, AllFilesFilterTxt);

        if FileName = '' then begin
            Error(Txt001);
        end;

        FileName := TemporaryPath + FileName;

        if Exists(FileName) then begin
            Erase(FileName);
        end;

        FileMgt.BLOBExportToServerFile(TempBlob, FileName);
        ActiveSession.Get(ServiceInstanceId(), SessionId());

        PowerShellRunner := PowerShellRunner.CreateInSandbox;
        PowerShellRunner.WriteEventOnError := true;
        PowerShellRunner.ImportModule(ApplicationPath + NAVAdminTool);
        PowerShellRunner.AddCommand('Import-NAVServerLicense');
        Powershellrunner.AddParameter('ServerInstance', ActiveSession."Server Instance Name");
        PowerShellRunner.AddParameter('LicenseFile', FileName);
        PowerShellRunner.BeginInvoke;

        if GuiAllowed then begin
            Window.Open(Txt002);
        end;

        repeat
            Sleep(1000);
        until PowerShellRunner.IsCompleted;

        if GuiAllowed then begin
            Window.Close();
        end;
    end;

    var
        Txt001: Label 'Operation cancelled by user.';
        Txt002: Label 'Busy importing......';
        AllFilesFilterTxt: Label '*.*';
        NAVAdminTool: Label 'NavAdminTool.ps1';
        FileFilter: Label 'License (*.fin)|*.fin|All Files (*.*)|*.*';
}