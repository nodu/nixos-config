#Order 3-3
{ config, pkgs, lib, currentSystem, currentSystemName, ... }:
let
  #TODO? Add var and if flags for i3 or wayland
in
{
  nix = {
    # use unstable nix so we can access flakes
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  nixpkgs.config.permittedInsecurePackages = [
    #add due to failing update
    "electron-24.8.6"
  ];

  # enable pulseaudio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  sound.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Define your hostname.
  networking.hostName = "Workstation";

  # Set your time zone.
  # time.timeZone = "America/Los_Angeles";
  time.timeZone = "America/Phoenix";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.enableIPv6 = false;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  console.useXkbConfig = true;
  # services.spotifyd.enable = true;
  # Setup i3wm/sddm
  services.xserver = {
    enable = true;
    layout = "us";
    # dpi = 220;
    xkbOptions = "ctrl:nocaps";

    # desktopManager = {
    #   xterm.enable = false;
    #   wallpaper.mode = "fill";
    # };
    #
    displayManager = {
      setupCommands = ''
        ${pkgs.xorg.xrandr}/bin/xrandr --newmode "2256x1504_60.00"  287.00  2256 2424 2664 3072  1504 1507 1517 1559 -hsync +vsync
        ${pkgs.xorg.xrandr}/bin/xrandr --addmode Virtual1 2256x1504_60.00
        ${pkgs.xorg.xrandr}/bin/xrandr --output Virtual1 --mode 2256x1504_60.00
      '';
      defaultSession = "sway";
      sddm.enable = true;
      # sddm.enableHidpi = true;
      sessionPackages = with pkgs; [ sway ];
      # AARCH64: For now, on Apple Silicon, we must manually set the
      # display resolution. This is a known issue with VMware Fusion.
      # commented out for x86
      # sessionCommands = ''
      #   ${pkgs.xorg.xset}/bin/xset r rate 200 40
      # '';
    };

    windowManager = {
      i3.enable = true;
    };
  };
  # services.xserver.videoDrivers = ["amdgpu"];
  # boot.initrd.kernelModules = ["amdgpu"];
  #Wayland requirements
  security.polkit.enable = true;
  hardware.opengl.enable = true;

  services.nfs.server.enable = false;
  services.nfs.server.exports = ''
    /export 192.168.179.0/24(rw,fsid=0,no_subtree_check,insecure,anonuid=1000,anongid=100,crossmnt,all_squash)
  '';

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  # Manage fonts. We pull these from a secret directory since most of these
  # fonts require a purchase.
  fonts = {
    fontDir.enable = true;

    fonts = [
      pkgs.fira-code
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    xclip

    # For hypervisors that support auto-resizing, this script forces it.
    # I've noticed not everyone listens to the udev events so this is a hack.
    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
  ] ++ lib.optionals (currentSystemName == "vm-aarch64") [
    # This is needed for the vmware user tools clipboard to work.
    # You can test if you don't need this by deleting this and seeing
    # if the clipboard sill works.
    gtkmm3
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
