{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rofi
  ];

  environment.etc."rofi/themes/android_notification.rasi".text = ''
    configuration {
        transparency: "real";
    }

    * {
        background-color: #00000000;
        text-color: #bbbbbb;
    }

    window {
        background-color: #171717ed;
    }

    mainbox {
        background-color: #00000000;
    }

    inputbar {
        background-color: #00000000;
    }

    prompt {
        background-color: #00000000;
    }

    entry {
        background-color: #00000000;
    }

    listview {
        background-color: #00000000;
    }

    element {
        background-color: #00000000;
        text-color: #686868;
    }

    element selected {
        background-color: #45454f99;
        text-color: #8f8f8f;
    }
  '';
}
