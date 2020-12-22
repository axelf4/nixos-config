{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

  outputs = inputs@{ self, nixpkgs }: {
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
            }
            nixpkgs.nixosModules.notDetected
            ./configuration.nix
            (./modules/hosts + "/${name}")
          ];
          specialArgs = { inherit inputs; };
        };
      };
    in builtins.listToAttrs [
      (mkHost "x86_64-linux" "axel-t450")
    ];
  };
}
