{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils }: {
    nixosConfigurations = let
      mkHost = system: name: {
        inherit name;
        value = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
              nix.registry.nixpkgs.flake = nixpkgs; # Pin nixpkgs flake
              networking.hostName = name;
              # Extend nixpkgs with packages from this flake
              nixpkgs.overlays = [ (final: prev: self.packages.${system}) ];
            }
            nixpkgs.nixosModules.notDetected
            ./configuration.nix
            (./modules/hosts + "/${name}")
          ];
        };
      };
    in builtins.listToAttrs [
      (mkHost "x86_64-linux" "axel-t450")
      (mkHost "x86_64-linux" "axel-g751jy")
      (mkHost "aarch64-linux" "axel-pi4")
    ];
  } // flake-utils.lib.eachDefaultSystem (system:
    let pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        iosevka-custom = pkgs.callPackage ./packages/iosevka-custom.nix {};

        # Needs JavaFX which is not packaged by openjdk8
        conan = pkgs.callPackage ./packages/conan { jre = pkgs.jdk11; };
      };
    }
  );
}
