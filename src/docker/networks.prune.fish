#! /usr/bin/env fish

source /home/francois/development/automation/src/tools/log.fish 2> /dev/null
or source /data/automation/tools/log.fish 2> /dev/null # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log

echo "

-------------------------------------
[[ Running networks.prune.fish ]]
 "(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

docker network prune -f 2>&1 | tee -a "$log"