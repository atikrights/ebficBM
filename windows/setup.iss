#ifndef MyAppVersion
  #define MyAppVersion "1.1.44"
#endif
[Setup]
AppName=ebfic Business Manager
AppVersion={#MyAppVersion}
AppPublisher=atikrights (ebfic Group Limited)
AppPublisherURL=https://github.com/atikrights/ebficBM
AppSupportURL=https://github.com/atikrights/ebficBM/issues
AppUpdatesURL=https://github.com/atikrights/ebficBM/releases
DefaultDirName={autopf}\ebficBM
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
OutputDir=..\build\windows\inno
OutputBaseFilename=ebficBM-windows
Compression=lzma
SolidCompression=yes
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\ebficBM.exe
DisableProgramGroupPage=yes
PrivilegesRequired=lowest

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\ebfic Business Manager"; Filename: "{app}\ebficBM.exe"
Name: "{autodesktop}\ebfic Business Manager"; Filename: "{app}\ebficBM.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"
