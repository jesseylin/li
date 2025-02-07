{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

  outputs = inputs @ {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;

    julia-version = "1.10.2";
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    julia-sha256 = {
      # TODO: find the right hashes for x86 linux and aarch64 linux, only the
      # aarch64-darwin one is right atm
      x86_64-linux = "0n9k8wyr2nqk7pwc8c17zxzmfb3a366y701ln8p9r07rdr319ih0";
      aarch64-linux = "0r635c6dhm4bsz99iv1vbklj9r9pqb98yjkds8i7zndcaddk250a";
      aarch64-darwin = "107akhvh5ki0py8klliq8gm9c9ah5qvcwmmz8p8x4m2vf8vj4ff7";
    };
    overridenAttrs = system: let
      pkgs = pkgsFor.${system};
    in rec {
      version = julia-version;
      src = with pkgs;
        {
          x86_64-linux = fetchurl {
            url = "https://julialang-s3.julialang.org/bin/linux/x64/${lib.versions.majorMinor version}/julia-${version}-linux-x86_64.tar.gz";
            sha256 = julia-sha256.x86_64-linux;
          };
          aarch64-linux = fetchurl {
            url = "https://julialang-s3.julialang.org/bin/linux/aarch64/${lib.versions.majorMinor version}/julia-${version}-linux-aarch64.tar.gz";
            sha256 = julia-sha256.aarch64-linux;
          };
          aarch64-darwin = fetchurl {
            url = "https://julialang-s3.julialang.org/bin/mac/aarch64/${lib.versions.majorMinor version}/julia-${version}-macaarch64.tar.gz";
            sha256 = julia-sha256.aarch64-darwin;
          };
        }
        .${system}
        or (throw "Unsupported system: ${system}");
    };
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        overlays = [(final: prev: {julia-bin = prev.julia-bin.overrideAttrs (overridenAttrs system);})];
        config.allowUnfree = true;
      });
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
  in {
    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          julia-bin
          dvc-with-remotes
        ];
      };
    });
  };
}
