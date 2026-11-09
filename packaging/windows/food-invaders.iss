#define AppVersion GetEnv("FOOD_INVADERS_VERSION")
#define StageRoot GetEnv("FOOD_INVADERS_STAGE")
#define OutputRoot GetEnv("FOOD_INVADERS_OUTPUT")

[Setup]
AppId={{8E94CEAA-29A8-4CD8-A6D2-60E7FFB8F4B1}
AppName=Food Invaders
AppVersion={#AppVersion}
AppVerName=Food Invaders {#AppVersion}
AppPublisher=Food Invaders contributors
AppPublisherURL=https://github.com/Patt-00/Food-Invaders
AppSupportURL=https://github.com/Patt-00/Food-Invaders/issues
AppUpdatesURL=https://github.com/Patt-00/Food-Invaders/releases
DefaultDirName={autopf}\Food Invaders
DefaultGroupName=Food Invaders
UninstallDisplayIcon={app}\DOSBox-X\dosbox-x.exe
OutputDir={#OutputRoot}
OutputBaseFilename=Food-Invaders-Setup-{#AppVersion}-x64
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
DisableProgramGroupPage=yes
VersionInfoVersion={#AppVersion}.0
VersionInfoCompany=Food Invaders contributors
VersionInfoDescription=Food Invaders installer
VersionInfoProductName=Food Invaders
VersionInfoProductVersion={#AppVersion}

[Files]
Source: "{#StageRoot}\game\INVADERS.COM"; DestDir: "{app}\game"; Flags: ignoreversion
Source: "{#StageRoot}\DOSBox-X\*"; DestDir: "{app}\DOSBox-X"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#StageRoot}\config\desktop.conf"; DestDir: "{app}\config"; Flags: ignoreversion
Source: "{#StageRoot}\run-food-invaders.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#StageRoot}\licenses\*"; DestDir: "{app}\licenses"; Flags: ignoreversion
Source: "{#StageRoot}\third-party\*"; DestDir: "{app}\third-party"; Flags: recursesubdirs createallsubdirs ignoreversion

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Icons]
Name: "{autoprograms}\Food Invaders"; Filename: "{app}\run-food-invaders.cmd"; WorkingDir: "{app}"
Name: "{autodesktop}\Food Invaders"; Filename: "{app}\run-food-invaders.cmd"; WorkingDir: "{app}"; Tasks: desktopicon
