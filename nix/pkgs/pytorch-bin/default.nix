{ stdenv
, lib
, buildPythonPackage
, isPy3k
, fetchPypi
, pythonOlder
, python
, cffi
, click
, numpy
, pyyaml
, pillow
, six
, future
, tensorflow-tensorboard
, protobuf
, openmpi
, typing
, requests
, addOpenGLRunpath
, typing-extensions
}:
let
  cpython = "cp${python.sourceVersion.major}${python.sourceVersion.minor}";
  sha256 = {
    cp37 = "0xhwv68j8gvahfzcp43bqp2x71iwv6zjhkw2f1hb82xps40mrml7";
  }."${cpython}" or (throw "Unsupported CPython version, ${cpython}");
in
buildPythonPackage rec {
  pname = "pytorch";
  version = "1.6.0";
  disabled = !isPy3k;

  format = "wheel";

  src = fetchPypi {
    pname = "torch";
    inherit version format;
    inherit sha256;

    python = cpython;
    abi =
      if cpython == "cp38"
      then cpython
      else "${cpython}m";
    platform = "manylinux1_x86_64";
  };

  nativeBuildInputs = [ addOpenGLRunpath ];

  propagatedBuildInputs = [
    cffi
    click
    numpy
    pyyaml
    # openmpi support
    openmpi
    # the following are required for tensorboard support
    pillow
    six
    future
    tensorflow-tensorboard
    protobuf
    # other?
    requests

    typing-extensions
  ] ++ lib.optional (pythonOlder "3.5") typing;

  dontStrip = true;
  dontPatchELF = true;

  postFixup =
    let
      base_lib_paths = [
        stdenv.cc.cc.lib
      ];

      rpath = lib.makeLibraryPath base_lib_paths;
    in
    ''
      rrPathArr=(
        "$out/${python.sitePackages}/torch/lib"
        "$out/${python.sitePackages}/torch"
        "$out/${python.sitePackages}/caffe2/python"
        "${rpath}"
      )

      # The the bash array into a colon-separated list of RPATHs.
      rrPath=$(IFS=$':'; echo "''${rrPathArr[*]}")
      echo "patching with the following rpath: $rrPath"

      find $out/${python.sitePackages} -type f -executable | while read lib; do
        echo "patching $lib..."
        chmod a+rx "$lib"
        patchelf --set-rpath "$rrPath" "$lib"
        addOpenGLRunpath "$lib"
      done
    '';

  pythonImportsCheck = [
    "torch"
    "torch.nn"
    "torch.nn.functional"
    # "torch.Tensor"
    # Tensor Attributes
    "torch.autograd"
    "torch.cuda"
    "torch.distributed"
    "torch.distributions"
    "torch.hub"
    "torch.jit"
    "torch.nn.init"
    "torch.onnx"
    "torch.optim"
    # Quantization
    # Distributed RPC Framework
    "torch.random"
    "torch.sparse"
    # "torch.Storage"
    "torch.utils.bottleneck"
    "torch.utils.checkpoint"
    "torch.utils.cpp_extension"
    "torch.utils.data"
    "torch.utils.dlpack"
    "torch.utils.model_zoo"
    "torch.utils.tensorboard"
    # Type Info
    # Named Tensors
    # Named Tensors operator coverage
    # torch.__config__
  ];

  meta = with lib; {
    description = "Open source, prototype-to-production deep learning platform";
    homepage = https://pytorch.org/;
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
}
