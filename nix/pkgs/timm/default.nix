{ stdenv
, lib
, buildPythonPackage
, isPy3k
, fetchPypi
, pytorch
, torchvision
, pyyaml
}:

buildPythonPackage rec {
  pname = "timm";
  version = "0.3.2";
  disabled = !isPy3k;

  format = "wheel";

  src = fetchPypi {
    inherit pname version format;
    sha256 = "sha256-wVmO9hwkbjiDWmuDSBHcuNYq5WtkTNVNw++VZcg4eHU=";

    python = "py3";
  };

  propagatedBuildInputs = [
    pytorch
    torchvision
    pyyaml
  ];

  meta = {
    description = "PyTorch Image Models";
    homepage = "https://rwightman.github.io/pytorch-image-models/";
    license = lib.licenses.asl20; # Apache License 2.0
    platforms = [ "x86_64-linux" ];
  };
}
