{
  description = "Extracting the config file format from gnome-online-accounts";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      rec {
        pkgs = import nixpkgs { inherit system; };
        formatter = pkgs.nixpkgs-fmt;

        name = "extract-config";
        packages.extract-config = (with pkgs; stdenv.mkDerivation
          rec {
            pname = "extract-config";
            version = "3.48.0";

            src = ./.;

            buildInputs = [
              makeWrapper
            ];

            installPhase = ''
              mkdir -p $out/bin
              cp extractConfigSchema.sh $out/bin/${pname}
              cp processSchema.ts $out/bin
              chmod a+x $out/bin/${pname}


              wrapProgram "$out/bin/${pname}" --prefix PATH : ${lib.makeBinPath [jq gnused deno git nixpkgs-fmt]} --set version ${version}
              chmod a+x $out/bin/${pname}
            '';

            meta.mainProgram = pname;
          });
        packages.default = packages.extract-config;
      }
    );
}
