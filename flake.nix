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
