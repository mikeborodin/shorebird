{
  description = "Shorebird";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
    packages = {
      # Define the package explicitly for the aarch64-darwin system
      aarch64-darwin = let
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
      in
        pkgs.stdenv.mkDerivation {
          pname = "shorebird";
          version = "1.3.5";
          src = ./bin/shorebird;
          unpackPhase = "true";

          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/shorebird
            chmod +x $out/bin/shorebird
          '';

          meta = with pkgs.lib; {
            description = "Shorebird for macOS";
            license = licenses.mit;
          };
        };
         # Define the package for x86_64-windows
        x86_64-windows = let
            pkgs = import nixpkgs { system = "x86_64-windows"; };
          in
            pkgs.stdenv.mkDerivation {
              pname = "shorebird";
              version = "1.3.5";

              src = ./bin/shorebird.bat; # Prebuilt batch file for Windows

              unpackPhase = "true";

              installPhase = ''
                mkdir -p $out/bin
                cp $src $out/bin/shorebird.bat
              '';

              meta = with pkgs.lib; {
                description = "Shorebird for Windows";
                license = licenses.mit;
              };
            };
    };

    defaultPackage.aarch64-darwin = self.packages.aarch64-darwin;
    defaultPackage.x86_64-windows = self.packages.x86_64-windows;
  };
}
