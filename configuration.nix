{
  modulesPath,
  lib,
  pkgs,
  homepage,
  leaflet-hugo-sync,
  ...
}:
let
  leaflet-sync-bin = leaflet-hugo-sync.packages.x86_64-linux.default;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  
  services.openssh.enable = true;

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.wget
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuC5sHe8hegmrgEKntLTArMn/O6m8IOKHxtgAsHHcF1 mar.kimmina@gmail.com"
  ];

  users.users.root = {
    extraGroups = [ "podman" ];
  };

  # Homepage build service
  systemd.services.homepage-build = {
    description = "Build homepage with leaflet-sync";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "homepage";
    };

    path = [ pkgs.hugo leaflet-sync-bin ];

    script = ''
      set -ex
      
      WORK_DIR=/var/lib/homepage
      OUT_DIR=/var/www/homepage
      
      # Copy source from nix store to writable directory (including hidden files)
      rm -rf $WORK_DIR/*
      rm -rf $WORK_DIR/.*  2>/dev/null || true
      cp -r ${homepage}/. $WORK_DIR/
      chmod -R u+w $WORK_DIR
      cd $WORK_DIR
      
      # Run leaflet-sync (fetches from network)
      leaflet-hugo-sync
      
      # Build hugo site
      mkdir -p $OUT_DIR
      hugo --minify --destination $OUT_DIR
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/www/homepage 0755 root root -"
  ];

  services.nginx = {
    enable = true;
    virtualHosts."mariuskimmina.com" = {
      root = "/var/www/homepage";
      forceSSL = true;
      enableACME = true;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "mar.kimmina@gmail.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "24.05";
}
