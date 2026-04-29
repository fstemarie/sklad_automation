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
    "backup/restic/automation.bkp.fish" \
    "backup/restic/config.bkp.fish" \
    "docker/iot.update.fish" \
    "docker/media.update.fish" \
    "docker/pirateisland.update.fish" \
    "docker/images.purge.fish"

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

notify "💾 sklad.home weekly backup report" (string join '\n' $notifications)
