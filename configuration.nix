{
  modulesPath,
  lib,
  pkgs,
  homepage,
  ...
}:
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

  # Build hugo site as a derivation
  systemd.services.homepage-build = {
    description = "Build homepage";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -ex
      WORK_DIR=$(mktemp -d)
      OUT_DIR=/var/www/homepage
      
      cp -r ${homepage}/. $WORK_DIR/
      chmod -R u+w $WORK_DIR
      cd $WORK_DIR
      
      ${pkgs.hugo}/bin/hugo --minify --destination $OUT_DIR
      
      rm -rf $WORK_DIR
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
