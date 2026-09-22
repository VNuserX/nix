{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;

    package = pkgs.ollama;          # CPU only

    loadModels = [
      "qwen2.5-coder:1.5b"
    ];
  };
}
