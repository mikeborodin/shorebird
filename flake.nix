{
  description = "shorebird nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system: 
    let
      pkgs = import nixpkgs { inherit system; };
      # dart = pkgs.dart;
    in
    rec {
      packages = {
        default = pkgs.stdenv.mkDerivation {
          pname = "shorebird";
          version = "?";
          src = ./.;

          buildInputs = [ ];

          buildPhase = ''
     #        export PUB_CACHE=$TMPDIR/.pub-cache
     #        dart pub get
	    # # avoding codesign issue when building on macOS:
     #        export PATH="$PATH:/usr/bin"
     #        dart compile exe bin/main.dart -o fvm 
         mkdir -p $out/bin
         cp bin/shorebird $out/bin/shorebird
          '';

          # installPhase = ''
          #   mkdir -p $out/bin
          #   cp bin/shorebird $out/bin/
          # '';

          meta = with pkgs.lib; {
            description = "shorebird";
            license = licenses.mit;
          };
        };
      };
    }
  );
}
