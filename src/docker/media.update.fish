#! /usr/bin/fish

set pjdir "/home/francois/development/containers/media"
set log "/var/log/automation/media.update.log"
set script (status basename)

source /home/francois/development/automation/src/tools/log.fish 2> /dev/null
or source /data/automation/tools/log.fish 2> /dev/null # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log

echo "

-------------------------------------
[[ Running media.update.fish ]]
 "(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

if test ! -d "$pjdir"
    error "non-existing project directory. Cannot proceed"
    exit 1
end

info "Updating containers"
pushd "$pjdir"
docker compose pull &| tee -a "$log"
if test $status -ne 0
    error "There was an error during the update"
    exit 1
end

info "Restarting containers"
docker compose up -d &| tee -a "$log"
if test $status -ne 0
    error "There was an error while restarting containers"
    exit 1
end
popd
