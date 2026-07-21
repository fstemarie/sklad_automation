#! /usr/bin/fish

set src "/l/backup/" # Variable qui contient le chemin du dossier à sauvegarder
set dst "filelu:/backup/sklad" # Variable qui contient le chemin du dossier de destination où les sauvegardes seront stockées
set log "/var/log/automation/mirror.rclone.bkp.log" # Variable qui contient le chemin du fichier de log où les messages d'information et d'erreur seront enregistrés

# inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
source /home/francois/development/automation/src/tools/log.fish 2> /dev/null
or source /data/automation/tools/log.fish 2> /dev/null

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)" 
-------------------------------------
" | tee -a "$log"

info "Sauvegarde du dossier $src vers $dst"

# Vérifie que la source existe et vérifie que la destination existe
# Si le dossier source n'existe pas, alors il n'y a rien à sauvegarder
info "Vérification de l'existence du dossier source"
if test -d "$src"
    success "Le dossier source existe"
else
    error "Le dossier source n'existe pas"
    exit 1
end

# Transfer rclone
info "Transfer des fichiers par rclone"
rclone sync \
    --verbose --progress --combined - \
    --update --delete-excluded --fast-list \
    "$src" "$dst" &| tee -a "$log"
# Vérifie si la commande rclone a réussi
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué"
    exit 1
end
success "La sauvegarde a réussi"
