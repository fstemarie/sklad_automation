#! /usr/bin/fish

# Source le script de notification en fonction de l'environnement d'exécution
source /home/francois/development/automation/src/tools/notify.fish
or source /data/automation/tools/notify.fish

# S'assure que la variable d'environnement soit effacee a la fin du script
function on_exit --on-event fish_exit
    set -Ue __WARNINGS__
end

cd (status dirname)
set scripts \
    "backup/tar/appdaemon.bkp.fish" \
    "backup/tar/jackett.bkp.fish" \
    "backup/tar/jellyfin.full.bkp.fish" \
    "backup/tar/mosquitto.bkp.fish" \
    "backup/tar/nodered.bkp.fish" \
    "backup/tar/qbittorrent.bkp.fish"

for script in $scripts
    set -Ue __WARNINGS__
    if $script
        if not set -Uq __WARNINGS__
            set -a notifications "🟢 $script"
        else
            set -a notifications "⚠️ $script"
        end
    else
        set -a notifications "🟥 $script"
    end
end
restic prune --cleanup-cache

notify "💾 sklad.home monthly backup report" (string join '\n' $notifications)

