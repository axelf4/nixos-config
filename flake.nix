{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
  };

  outputs = inputs@{ self, nixpkgs }: {
    nixosConfigurations = let
      mkHost = system: name: {
        inherit name;
        value = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = builtins.attrValues self.nixosModules ++ [
            ({ config, ... }: {
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
              nix.channel.enable = false;
              nix.settings.nix-path = config.nix.nixPath; # NixOS/nix#9574
              networking.hostName = name;
              # Extend nixpkgs with packages from this flake
              nixpkgs.overlays = [ (final: prev: self.packages.${system}) ];
            })
            ./configuration.nix
            (modules/hosts + "/${name}")
          ];
        };
      };
    in builtins.listToAttrs [
      (mkHost "x86_64-linux" "axel-t450")
      (mkHost "x86_64-linux" "axel-g751jy")
      (mkHost "aarch64-linux" "axel-pi4")
    ];

    nixosModules = {
      spotify-inhibit-sleepd = modules/spotify-inhibit-sleepd;
    };

    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      iosevka-custom = pkgs.callPackage packages/iosevka-custom.nix {};
      gfm-preview = pkgs.callPackage packages/gfm-preview {};
      git-absorb = pkgs.callPackage packages/git-absorb {};
      texlive-nix-pm = pkgs.callPackage packages/texlive-nix-pm {};
      conan = pkgs.callPackage packages/conan.nix {};
    });
  };
}
