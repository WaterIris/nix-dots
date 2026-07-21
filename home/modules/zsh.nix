{ config, lib, ... }:
{
    programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
            add_newline = false;
            palette = "tokyonight_night";
            directory = {
                truncation_length = 5;
                truncate_to_repo = false;
                style = "blue";
            };
            character = {
                success_symbol = "[❯](#bb9af7)";
                error_symbol = "[❯](#f7768e)";
            };
            hostname = {
                ssh_symbol = " ";
                format = "[$ssh_symbol$hostname](green) in ";
                ssh_only = false;
            };
            git_branch = {
                symbol = " ";
                format = "[$symbol$branch](mauve) ";
            };
            git_status = {
                format = "$staged$modified$renamed$conflicted$ahead_behind";
                staged = "[+$count ](green)";
                modified = "[!$count ](yellow)";
                renamed = "[»$count ](blue)";
                deleted = "[-$count ](red)";
                untracked = "[?$count ](sapphire)";
                stashed = "[≡$count ](lavender)";
                conflicted = "[✖$count ](red bold)";
                ahead = "[⇡$count ](teal)";
                behind = "[⇣$count ](peach)";
                diverged = "[⇕$ahead_count⇣$behind_count ](mauve)";
            };
            python = {
                format = "[\\($version\\)](flamingo) ";
                symbol = " ";
            };
            nix_shell = {
                symbol = "󱄅 ";
            };
            cmd_duration = {
                min_time = 1000;
            };

            format = lib.concatStrings [
                "$python"
                    "$directory"
                    "$git_branch"
                    "$git_status"
                    "$cmd_duration"
                    "$line_break"
                    "$character"
            ];

            palettes.tokyonight_night = {
                crust = "#16161e";
                mantle = "#16161e";
                base = "#1a1b26"; # git branch bg

                    surface0 = "#292e42";
                surface1 = "#3b4261";
                surface2 = "#414868";

                overlay0 = "#565f89";
                overlay1 = "#737aa2";
                overlay2 = "#9aa5ce";

                text = "#c0caf5";
                subtext0 = "#a9b1d6";
                subtext1 = "#c0caf5";
                flamingo = "#ff9e64";
                pink = "#f7768e";
                mauve = "#bb9af7";
                red = "#f7768e";
                maroon = "#f7768e";
                peach = "#ff9e64";
                yellow = "#e0af68";
                green = "#9ece6a";
                teal = "#7dcfff";
                sky = "#7dcfff";
                sapphire = "#7aa2f7"; # dir fg
                    blue = "#7aa2f7";
                lavender = "#bb9af7"; # git branch fg
            };
        };
    };

    programs.fzf = {
        enable = true;
        enableZshIntegration = true;
    };

    programs.eza = {
        enable = true;
        enableZshIntegration = true;
    };

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;
        silent = true;
    };
    programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
    };
    programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        initContent = ''
            bindkey -e
            '';

        shellAliases = {
            cd = "z";
            vi = "nvim";
            ls = "eza --color=never";
            ll = "eza -alh";
            tree = "eza --tree";
            tt = "~/.config/tmux/script.sh";

        };
        history = {
            size = 10000;
            path = "${config.xdg.dataHome}/zsh/history";
        };
    };
}
