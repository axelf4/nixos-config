{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
  };

  outputs = inputs@{ self, nixpkgs }: let
    packages = pkgs: {
      iosevka-custom = pkgs.callPackage packages/iosevka-custom.nix {};
      gfm-preview = pkgs.callPackage packages/gfm-preview {};
      git-absorb = pkgs.callPackage packages/git-absorb {};
      texlive-nix-pm = pkgs.callPackage packages/texlive-nix-pm {};
    };

    mkHost = name: nixpkgs.lib.nixosSystem {
      modules = builtins.attrValues self.nixosModules ++ [
        ({ config, ... }: {
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
          nix.channel.enable = false;
          networking.hostName = name;
          # Extend nixpkgs with packages from this flake
          nixpkgs.config.packageOverrides = packages;
        })
        ./configuration.nix
        (modules/hosts + "/${name}")
      ];
    };
  in {
    nixosConfigurations = nixpkgs.lib.genAttrs
      ["axel-t450" "axel-g751jy" "axel-pi4" ]
      mkHost;

    nixosModules = {
      spotify-inhibit-sleepd = modules/spotify-inhibit-sleepd;
    };

    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
      (system: packages nixpkgs.legacyPackages.${system});
  };
}
