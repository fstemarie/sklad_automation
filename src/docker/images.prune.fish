#! /usr/bin/env fish

source /home/francois/development/automation/src/tools/log.fish
or source /data/automation/tools/log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log

echo "

-------------------------------------
[[ Running images.prune.fish ]]
 "(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

docker image prune -a -f 2>&1 | tee -a "$log"