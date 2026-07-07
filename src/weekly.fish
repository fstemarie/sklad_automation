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
    "docker/iot.update.fish" \
    "docker/media.update.fish" \
    "docker/pirateisland.update.fish" \
    "docker/images.purge.fish"

restic unlock
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

notify "💾 sklad.home weekly backup report" (string join '\n' $notifications)
