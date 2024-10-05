{
  description = "A Nix flake for Voices of the Void";

  inputs.erosanix.url = "github:emmanuelrosa/erosanix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.nix-gaming.url = "github:fufexan/nix-gaming";

  outputs = {
    self,
    nixpkgs,
    erosanix,
    ...
  }: {
    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };

      # I have tried unstable, and wine-ge can not seem to find it :(
      # sources = (import "${self.inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
      # mono = pkgs.fetchurl rec {
      #   version = "8.1.0";
      #   url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
      #   hash = "sha256-DtPsUzrvebLzEhVZMc97EIAAmsDFtMK8/rZ4rJSOCBA=";
      # };

      wine = self.inputs.nix-gaming.packages.x86_64-linux.wine-ge.override {
        # monos = [
        #   mono
        # ];
      };
      baseVotv = pkgs.callPackage ./votv.nix {
        inherit self;
        inherit (erosanix.lib.x86_64-linux) mkWindowsApp makeDesktopIcon copyDesktopIcons;
        inherit wine;
      };
    in {
      votv = baseVotv;
      default = self.packages.x86_64-linux.votv;

      inherit baseVotv;
      inherit wine;
    };

    apps.x86_64-linux.votv = {
      type = "app";
      program = "${self.packages.x86_64-linux.votv}/bin/votv";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.votv;
  };
}
