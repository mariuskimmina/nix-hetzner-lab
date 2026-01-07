{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  
  inputs.homepage = {
    url = "github:mariuskimmina/homepage";
    flake = false;
  };
  inputs.leaflet-hugo-sync.url = "github:mariuskimmina/leaflet-hugo-sync";

  outputs =
    {
      nixpkgs,
      disko,
      homepage,
      leaflet-hugo-sync,
      ...
    }:
    {
      nixosConfigurations.hetzner-lab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit homepage leaflet-hugo-sync; };
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./hardware-configuration.nix
        ];
      };
    };
}
