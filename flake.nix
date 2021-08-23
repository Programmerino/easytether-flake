{
  description = "EasyTether";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  inputs.flake-utils.url = "github:numtide/flake-utils";


  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem ["x86_64-linux" "i686-linux"] (system:
      let
        pkgs = import nixpkgs { 
          inherit system;
        };
        version = "0.8.9";
        name = "EasyTether";
        amd64 = "http://www.mobile-stream.com/beta/ubuntu/20.04/easytether_${version}_amd64.deb";
        amd64_hash = "sha256-QCvPqtQeita845BGZ4YSw9QhAMxeeXpJJglJhTz9wC4=";
        i386 = "http://www.mobile-stream.com/beta/ubuntu/20.04/easytether_${version}_i386.deb";
        i386_hash = "0biv6cvv70qm6aby9kz6avaxs1m4jwrqkaa8jg8ig68pambazwwc";
      in rec {
          defaultPackage = pkgs.stdenv.mkDerivation {
              inherit name;
              inherit version;

              src = pkgs.fetchurl { url = (if system == "x86_64-linux" then amd64 else i386); sha256 = (if system == "x86_64-linux" then amd64_hash else i386_hash); };

              nativeBuildInputs = [
                  pkgs.autoPatchelfHook
                  pkgs.bluezFull.out
                  pkgs.openssl.out
              ];

              unpackPhase = "true";
              
              installPhase = ''
                mkdir -p $out
                mkdir temp
                ${pkgs.dpkg}/bin/dpkg -x $src tmp
                mv ./tmp/usr/bin $out
                mv ./tmp/usr/share/doc/easytether $out/doc
              '';
          };

          nixosModules.easytether = {config, ...}: {
            environment.systemPackages = [ defaultPackage ];
            systemd.packages = [ defaultPackage ];

            systemd.services."easytether-usb@" = {
              path = [ defaultPackage ];
              description = "EasyTether USB service";


              serviceConfig = {
                Type = "simple";
                ExecStart = "${defaultPackage}/bin/easytether-usb -d %f";
              };
              wantedBy = [ "default.target" ];
            };

            config.services.udev.extraRules = config.services.udev.extraRules ++ ''
            
            ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", ENV{INTERFACE}=="255/66/1", TAG+="systemd", ENV{SYSTEMD_WANTS}="easytether-usb@%N.service"
            '';
          };
      }
    );
}
