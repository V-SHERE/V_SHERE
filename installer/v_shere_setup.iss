#define MyAppName      "V-Shere"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "V-Shere"
#define MyAppURL       "https://github.com/v-shere"
#define MyAppExeName   "v_shere.exe"
#define ReleaseDir     "..\build\windows\x64\runner\Release"
#define IconFile       "..\Asset\Logo.jpg"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=.\Output
OutputBaseFilename=V-Shere-Setup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardSizePercent=120
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
MinVersion=10.0.17763


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";   Description: "Create a &desktop shortcut";   GroupDescription: "Additional icons:"; Flags: unchecked
Name: "startupicon";   Description: "Launch V-Shere when Windows &starts"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
; Main executable
Source: "{#ReleaseDir}\{#MyAppExeName}";      DestDir: "{app}"; Flags: ignoreversion

; Flutter engine DLL
Source: "{#ReleaseDir}\flutter_windows.dll";  DestDir: "{app}"; Flags: ignoreversion

; App data (Flutter assets, icudtl.dat, app.so)
Source: "{#ReleaseDir}\data\*";               DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}";           Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";     Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Auto-start on Windows login (optional task)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
  ValueType: string; ValueName: "{#MyAppName}"; \
  ValueData: """{app}\{#MyAppExeName}"""; \
  Flags: uninsdeletevalue; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; \
  Description: "Launch {#MyAppName}"; \
  Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// Close any running instance of v_shere before installing
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/f /im v_shere.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;
