{ pkgs, ... }:

{
  services.llama-cpp = {
    package = pkgs.unstable.llama-cpp.override {
      cudaSupport = true;
    };

    settings = [
      "--ctx-size"
      "8192"
      "--parallel"
      "1"
      "--flash-attn"
      "auto"
      "--n-gpu-layers"
      "auto"
      "--jinja"
      "--metrics"
    ];
  };
}
