#! /usr/bin/fish

set pjdir "/home/francois/development/containers/iot"
set log "/var/log/automation/iot.update.log"
set script (status basename)

if test (status dirname) = "/data/automation"
    source /data/automation/tools/log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
else
    source /home/francois/development/automation/src/tools/log.fish
end

echo "

-------------------------------------
[[ Running iot.update.fish ]]
 "(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

if test ! -d "$pjdir"
    error "non-existing project directory. Cannot proceed"
    exit 1
end

info "Updating containers"
pushd "$pjdir"
docker compose pull 2>&1 | tee -a "$log"
if test $status -ne 0
    error "There was an error during the update"
    exit 1
end

info "Restarting containers"
docker compose up -d 2>&1 | tee -a "$log"
if test $status -ne 0
    error "There was an error while restarting containers"
    exit 1
end
popd
