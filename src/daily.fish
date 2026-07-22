#! /usr/bin/fish

# Source le script de notification en fonction de l'environnement d'exécution
source /home/francois/development/automation/src/tools/notify.fish 2> /dev/null
or source /data/automation/tools/notify.fish 2> /dev/null

# S'assure que la variable d'environnement soit effacee a la fin du script
function on_exit --on-event fish_exit
    set -Ue __WARNINGS__
end

cd (status dirname)
set scripts \
    "backup/restic/development.bkp.fish" \
    "backup/restic/home.bkp.fish" \
    "backup/tar/development.diff.bkp.fish" \
    "backup/tar/home.diff.bkp.fish" \
    "backup/tar/jellyfin.diff.bkp.fish" \
    "backup/rsync/audio.bkp.fish" \
    "backup/rclone/mirror.bkp.fish" \
    "./duckdns.fish"

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

notify "💾 sklad.home daily backup report" (string join '\n' $notifications)
