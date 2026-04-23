#! /usr/bin/fish

set src /l/audio/files # Variable qui contient le chemin du dossier à sauvegarder
set dst "francois@rsync.filelu.com:/audio/" # Variable qui contient le chemin du dossier de destination où les sauvegardes seront stockées
set log "/var/log/automation/audio.rsync.tar.log" # Variable qui contient le chemin du fichier de log où les messages d'information et d'erreur seront enregistrés
set secret_file "/home/francois/.secrets/filelu" # Variable qui contient le chemin du fichier qui contient le mot de passe de filelu

# inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
if test (status dirname) = "/data/automation"
    source /data/automation/log.fish
else
    source /home/francois/development/automation/src/log.fish
end

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de  "(status basename)" ]]
"(date -Iseconds)" 
-------------------------------------
" | tee -a $log

info "Sauvegarde du dossier $src vers $dst" true

# Vérifie que la source existe et vérifie que la destination existe
# Si le dossier source n'existe pas, alors il n'y a rien à sauvegarder
info "Vérification de l'existence du dossier source et du dossier de destination"
if test -d "$src"
    success "Le dossier source existe"
else
    error "Le dossier source n'existe pas" true
    exit 1
end

# Transfer rsync
info "Transfer des fichiers par rsync"
sshpass -f $secret_file rsync --verbose \
    --itemize-changes --human-readable --stats \
    --partial --archive -e 'ssh -p 2222' \
    "$src" \
    "$dst" 2>&1 | tee -a $log
# Vérifie si la commande tar a réussi
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué" true
    exit 1
end
success "La sauvegarde a réussi" true
