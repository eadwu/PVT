{ stdenv
, buildPythonPackage
, isPy3k
, fetchPypi
, python
, six
, scipy
, numpy
, pillow
, pytorch
, lib
}:
let
  cpython = "cp${python.sourceVersion.major}${python.sourceVersion.minor}";

  sha256 = {
    cp37 = "04zvr4xd312inq50a8m44ircd86a2qpbgwqagaf6b1s3xzgml6hd";
  }."${cpython}" or (throw "Unsupported CPython version, ${cpython}");
in
buildPythonPackage rec {
  pname = "torchvision";
  version = "0.7.0";
  disabled = !isPy3k;

  format = "wheel";

  src = fetchPypi {
    inherit pname version format;
    inherit sha256;

    python = cpython;
    abi =
      if cpython == "cp38"
      then cpython
      else "${cpython}m";
    platform = "manylinux1_x86_64";
  };

  propagatedBuildInputs = [
    six
    scipy
    numpy
    pillow
    pytorch
  ];

  meta = {
    description = "PyTorch vision library";
    homepage = "https://pytorch.org/";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
}
