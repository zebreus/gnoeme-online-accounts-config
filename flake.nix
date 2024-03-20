{
  description = "Extracting the config file format from gnome-online-accounts";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, flake-utils, home-manager, ... }:
    (flake-utils.lib.eachDefaultSystem (system:
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

        nixosConfigurations.test1 = {
          system = "x86_64-linux";
          modules = [
            (import ./tests/test.nix)
          ];
        };

        packages.tests = pkgs.writeShellScriptBin "tests" ''
          #!${pkgs.bash}/bin/bash

          OUT=$(mktemp -d)

          function expectSuccess {
            local testname="$1"

            local output="$(echo -e ":lf .\n:te\ntests.''${testname}" | nix repl 2>&1 | grep -v tcsetattr | grep -v 'showing error traces')"
            
            if [[ "$output" == *"error"* ]]; then
              printf "\e[1m\e[31m☒\e[0m Test $testname failed\n" >> $OUT/$testname.out
              echo "$output" >> $OUT/$testname.out
              return 1
            fi

            printf "\e[1m\e[32m☑\e[0m Test $testname passed\n" >> $OUT/$testname.out
          }

          function expectFailure {
            local testname="$1"

            local output="$(echo -e ":lf .\n:te\ntests.''${testname}" | nix repl --show-trace 2>&1 | grep -v tcsetattr | grep -v 'showing error traces')"
            
            if [[ "$output" != *"error"* ]]; then
              printf "\e[1m\e[31m☒\e[0m Test $testname failed\n" >> $OUT/$testname.out
              echo "$output" >> $OUT/$testname.out
              return 1
            fi

            printf "\e[1m\e[32m☑\e[0m Test $testname passed\n" >> $OUT/$testname.out
          }

          expectSuccess "nothing" &
          expectFailure "missingProvider" &
          expectSuccess "sanityCheck" &
          expectSuccess "enableAccountTest" &
          expectSuccess "nameWorks" &
          expectSuccess "mailAccountTest" &
          expectSuccess "emailAccountEnablesModule" &
          expectFailure "exchangeAccountFailsWithoutHost" &

          while true; do
            wait -n || {
              code="$?"
              ([[ $code = "127" ]] && exit 0 || exit "$code")
              break
            }
          done;

          cat $OUT/*.out
           
        '';

      }
    )) // {
      tests = builtins.foldl' (acc: test: acc // test) { } (builtins.map
        (name: {
          ${name} = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs { system = "x86_64-linux"; };
            modules = [
              { home.stateVersion = "23.11"; home.username = "test"; home.homeDirectory = "/home/test"; }
              (import ./module.nix)
              (import (./tests + "/${name}.nix"))
            ];
          };
        }) [ "missingProvider" "nothing" "sanityCheck" "enableAccountTest" "nameWorks" "mailAccountTest" "emailAccountEnablesModule" "exchangeAccountFailsWithoutHost" ]);



      nixosModules.default = { ... }: {
        home-manager.sharedModules = [ (import ./module.nix) ];
      };
    };
}
