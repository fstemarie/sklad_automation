#! /usr/bin/fish

# Source le script de notification en fonction de l'environnement d'exécution
if test (status dirname) = "/data/automation"
    source /data/automation/notify.sh
else
    source /home/francois/development/automation/src/notify.fish
end

# S'assure que la variable d'environnement soit effacee a la fin du script
function on_exit --on-event fish_exit
    set -Ue __WARNINGS__
end

cd (status dirname)
set scripts \
    # "backup/restic/appdaemon.bkp.fish" \
    "backup/restic/mosquitto.bkp.fish" \
    "backup/restic/nodered.bkp.fish" \
    "backup/tar/appdaemon.bkp.fish" \
    "backup/tar/jackett.bkp.fish" \
    "backup/tar/jellyfin.full.bkp.fish" \
    "backup/tar/mosquitto.bkp.fish" \
    "backup/tar/nodered.bkp.fish" \
    "backup/tar/qbittorrent.bkp.fish"

restic unlock
for script in $scripts
    set -Ue __WARNINGS__
    if $script
        if set -Uq __WARNINGS__
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

