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
    "backup/restic/development.bkp.fish" \
    "backup/restic/home.bkp.fish" \
    "backup/tar/development.bkp.fish" \
    "backup/tar/home.bkp.fish" \
    "backup/tar/jellyfin.diff.bkp.fish" \
    "backup/rsync/audio.bkp.fish" \
    "backup/rsync/mirror.bkp.fish"

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

notify "💾 sklad.home daily backup report" (string join '\n' $notifications)
