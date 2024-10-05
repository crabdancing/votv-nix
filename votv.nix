{
  stdenv,
  lib,
  mkWindowsApp,
  wine,
  fetchurl,
  makeDesktopItem,
  makeDesktopIcon, # This comes with erosanix. It's a handy way to generate desktop icons.
  copyDesktopItems,
  copyDesktopIcons, # This comes with erosanix. It's a handy way to generate desktop icons.
  unzip,
  system,
  self,
  pkgs,
  setDPI ? null,
}: let
  # This registry file sets winebrowser (xdg-open) as the default handler for
  # text files, instead of Wine's notepad.
  pname = "votv";
  txtReg = ./txt.reg;
  stateDir = "$HOME/.local/share/${pname}";

  setDPIReg = pkgs.writeText "set-dpi-${toString setDPI}.reg" ''
    Windows Registry Editor Version 5.00
    [HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts]
    "LogPixels"=dword:${toString setDPI}
  '';
in
  mkWindowsApp rec {
    inherit wine pname;

    version = "pa07_0011";

    src = builtins.fetchurl {
      url = "https://archive.org/download/votv_20231027/${version}.7z";
      sha256 = "sha256:1vsjhyfadc5xm3w4x7a0km4vgyd4ycs2b66s0kdbmyb3725bd4ld";
    };

    dontUnpack = true;
    wineArch = "win64";

    enableInstallNotification = true;
    # This should work, but it doesn't seem to?
    # More testing required.
    fileMap = {
      "${stateDir}" = "drive_c/users/$USER/AppData/Local/VotV";
      # drive_c/users/steamuser/AppData/Local/VotV/Saved/SaveGames
    };
    enableMonoBootPrompt = false;
    fileMapDuringAppInstall = false;
    persistRegistry = false;
    persistRuntimeLayer = false;
    # persistRuntimeLayer = false;
    inputHashMethod = "store-path";

    nativeBuildInputs = [copyDesktopItems copyDesktopIcons];

    winAppInstall =
      # doubt that this actually helps
      # winetricks -q corefonts
      # # https://askubuntu.com/questions/29552/how-do-i-enable-font-anti-aliasing-in-wine
      # winetricks -q settings fontsmooth=rgb
      # # https://www.advancedinstaller.com/silent-install-exe-msi-applications.html
      # $WINE msiexec /i ${src} /qb!
      # regedit ${txtReg}
      # regedit ${./use-theme-none.reg}
      # regedit ${./wine-breeze-dark.reg}
      ''
        winetricks -q fontsmooth=rgb vcrun2022 dxvk
        d="$WINEPREFIX/drive_c/${pname}"
        mkdir -p "$d"
        ${pkgs.ouch}/bin/ouch d ${src} -d "$d"

        mkdir -p ${stateDir}
      ''
      + lib.optionalString (setDPI != null) ''
        regedit ${setDPIReg}
      '';
    winAppPreRun = ''
      mkdir -p "${stateDir}"
    '';

    winAppRun = ''
      mkdir -p "${stateDir}"
      wine "$WINEPREFIX/drive_c/votv/${version}/WindowsNoEditor/VotV.exe" "$ARGS"
    '';

    winAppPostRun = "";

    installPhase = ''
      runHook preInstall
      ln -s $out/bin/.launcher $out/bin/${pname}
      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = pname;
        exec = pname;
        icon = pname;
        desktopName = "Voices of the Void";
        genericName = "Weird game";
        categories = ["Games"];
      })
    ];

    desktopIcon = makeDesktopIcon {
      name = "votv";

      src = ./votv.png;
    };

    meta = with lib; {
      description = "Voices of the Voice packaged for NixOS";
      homepage = "https://mrdrnose.itch.io/votv";
      license = licenses.unfree;
      maintainers = with maintainers; [];
      platforms = ["x86_64-linux"];
    };
  }
