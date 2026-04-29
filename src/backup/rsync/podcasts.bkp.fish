#! /usr/bin/fish

# add bedroom to ~/.ssh/config
set src "/l/audio/podcasts/"
set dst "bedroom:/media/256gb/podcasts/"
set log "/var/log/automation/podcasts.rsync.trx.log"

# inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
if test (status dirname) = "/data/automation"
    source /data/automation/tools/log.fish
else
    source /home/francois/development/automation/src/tools/log.fish
end

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)" 
-------------------------------------
" | tee -a $log

info "Transfer du dossier $src vers $dst"

# Vérifie que la source existe et vérifie que la destination existe
# Si le dossier source n'existe pas, alors il n'y a rien à sauvegarder
info "Vérification de l'existence du dossier source"
if test -d "$src"
    success "Le dossier source existe"
else
    error "Le dossier source n'existe pas"
    exit 1
end

# Transfer rsync
info "Transfer des fichiers par rsync"
umask 0133
rsync \
    --archive --verbose --delete --progress \
    --itemize-changes --human-readable --stats \
    --no-compress --ignore-existing \
    --size-only --recursive --chmod u=rw,go=r \
    --mkpath --exclude='How Did This Get Made - Matinee Monday' \
    "$src" "$dst" 2>&1 | tee -a $log
# Vérifie si la commande tar a réussi
if test $pipestatus[1] -ne 0
    error "Le transfer a échoué"
    exit 1
end
success "Le transfer a réussi"
