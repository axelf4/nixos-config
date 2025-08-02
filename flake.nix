{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
  };

  outputs = inputs@{ self, nixpkgs }: let
    inherit (nixpkgs) lib;
    mkHost = name: lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = builtins.attrValues self.nixosModules ++ [
        {
          system.configurationRevision = lib.mkIf (self ? rev) self.rev;
          nix.channel.enable = false;
          networking.hostName = name;
          # Extend nixpkgs with packages from this flake
          nixpkgs.config.packageOverrides = pkgs: self.packages.${pkgs.stdenv.system} or {};
        }
        ./configuration.nix
        modules/hosts/${name}
      ];
    };
    hosts = builtins.attrNames (builtins.readDir modules/hosts);
  in {
    nixosConfigurations = lib.genAttrs hosts mkHost;

    nixosModules = {
      spotify-inhibit-sleepd = modules/spotify-inhibit-sleepd;
    };

    packages = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        iosevka-custom = pkgs.callPackage packages/iosevka-custom.nix {};
        gfm-preview = pkgs.callPackage packages/gfm-preview {};
        git-absorb = pkgs.callPackage packages/git-absorb {};
        texlive-nix-pm = pkgs.callPackage packages/texlive-nix-pm {};
        spotify-mix-playlists = pkgs.callPackage packages/spotify-mix-playlists {};
      });
  };
}
