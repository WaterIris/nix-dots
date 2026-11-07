{ config, lib, ... }:
{
    programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
            add_newline = false;
            directory = {
                truncation_length = 5;
                truncate_to_repo = false;
                style = "blue";
            };
            hostname = {
                ssh_symbol = " ";
                format = "[$ssh_symbol$hostname](green) in ";
                ssh_only = false;
            };
            python = {
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
        };

        history = {
            size = 10000;
            path = "${config.xdg.dataHome}/zsh/history";
        };
    };
}
