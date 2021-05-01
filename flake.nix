{
  description = "PVT";

  # General repositories
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; };
  inputs.flake-compat = { type = "github"; owner = "edolstra"; repo = "flake-compat"; flake = false; };

  outputs = { self, nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      config = { allowUnfree = true; };
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit config system; overlays = [ self.overlay ]; });
    in
    {

      overlay = final: prev:
        with final; {

          cudatoolkit = final.cudatoolkit_11;
          cudnn = final.cudnn_cudatoolkit_11;
          nccl = prev.nccl.override { cudatoolkit = final.cudatoolkit_11; };

        };

      devShell = forAllSystems (system:
        let
          pkgSet = nixpkgsFor.${system};

          packageOverrides = final: prev:
            with pkgSet; with final; {

              # Packages

              tensorflow-tensorboard_2 = prev.tensorflow-tensorboard_2.overridePythonAttrs (oldAttrs:
                rec {
                  version = "2.4.0a20201029";
                  format = "wheel";

                  src = fetchPypi {
                    inherit version format;
                    pname = "tb_nightly";
                    sha256 = "12w2pf1r8jqrxxdafv1q7mwxfhbfymxvp01n639mwsjd8kjphgni";

                    python = "py3";
                  };

                  propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [ astunparse tensorboard-plugin-wit typing-extensions ];
                });

              pytorch = final.pytorch-bin.override {
                # tensorflow-tensorboard = tensorflow-tensorboard_2;
              };

              torchvision = final.torchvision-bin;

              timm = callPackage ./nix/pkgs/timm { };

              # Binaries

              pytorch-bin = callPackage ./nix/pkgs/pytorch-bin { };

              torchvision-bin = callPackage ./nix/pkgs/torchvision-bin { };

            };

          defaultPackageSet = ps: with ps;
            [
              pytorch
              torchvision
              timm # 0.3.2
            ];

          env =
            ((pkgSet.python37.override { inherit packageOverrides; })
              .withPackages (ps: defaultPackageSet ps))
            .override {
              makeWrapperArgs = [ "--prefix LD_LIBRARY_PATH : ${pkgSet.cudnn}/lib" ];
            };
        in
        pkgSet.mkShell {
          PYTHON_ENV = env.out;
          buildInputs = [ env ];
        });

    };
}
