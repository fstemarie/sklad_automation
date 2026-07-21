#! /usr/bin/env fish

if test (status dirname) = "/data/automation"
    source /data/automation/tools/log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
else
    source /home/francois/development/automation/src/tools/log.fish
end

echo "

-------------------------------------
[[ Running images.purge.fish ]]
 "(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

docker image prune -a -f 2>&1 | tee -a "$log"