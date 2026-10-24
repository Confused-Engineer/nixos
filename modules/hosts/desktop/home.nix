# desktop-only home-manager additions for david, on top of the shared
# modules/users/david.nix.
{ inputs, self, ... }:
{
  flake.modules.nixos.desktop.home-manager.users.david =
    { pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        streamcontroller # the Stream Deck lives on this machine
        steam
        inputs.hermes-agent.homeManagerModules.default
      ];

      custom.steam.shaderThreads = 12;

      # Hermes agent: `hermes` CLI + the Hermes Desktop app (launcher entry).
      # State lives in ~/.hermes; run `hermes setup` once to pick a provider.
      # The gateway/backend service (services.hermes-agent) is left off until
      # there's a secrets file for its API keys.
      programs.hermes-agent = {
        enable = true;
        desktop.enable = true;
      };

      # The GA104 (desktop GPU) HDMI audio card reports all three HDMI ports as
      # "available" at once, so WirePlumber's profile-restore is unreliable across
      # logins/resume and keeps falling back away from the correct HDMI1 output,
      # requiring a manual fix in pavucontrol. Force it back on every pipewire
      # start and every resume from sleep.
      systemd.user.services.fix-hdmi-audio-profile = {
        Unit = {
          Description = "Pin GA104 HDMI audio card to the correct HDMI1 profile";
          After = [
            "pipewire.service"
            "wireplumber.service"
            "sleep.target"
          ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = toString (
            pkgs.writeShellScript "fix-hdmi-audio-profile" ''
              card="alsa_card.pci-0000_09_00.1"
              profile="output:hdmi-stereo"
              for i in $(seq 1 20); do
                ${pkgs.pulseaudio}/bin/pactl list cards short | grep -q "$card" && break
                sleep 0.5
              done
              ${pkgs.pulseaudio}/bin/pactl set-card-profile "$card" "$profile"
            ''
          );
        };
        Install.WantedBy = [
          "pipewire.service"
          "sleep.target"
        ];
      };
    };
}
