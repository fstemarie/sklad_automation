#! /usr/bin/fish

set src "/data/automation" # Variable qui contient le chemin du dossier à sauvegarder
set dst "/l/backup/sklad/automation"  # Variable qui contient le chemin du dossier de destination où les sauvegardes seront stockées
set arch "$dst/automation."(date +%Y%m%dT%H%M%S | tr -d :-)".tar.zst"  # Variable qui contient le chemin complet du fichier d'archive à créer, avec un nom basé sur la date et l'heure actuelles
set log "/var/log/automation/automation.tar.log" # Variable qui contient le chemin du fichier de log où les messages d'information et d'erreur seront enregistrés
set nb_max 5 # Variable qui contient le nombre maximum de sauvegardes à conserver, utilisée pour supprimer les anciennes sauvegardes si nécessaire

source (status dirname)/../../log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
source (status dirname)/../../tools.fish # inclut le fichier tools.fish pour utiliser les fonctions d'outils génériques

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Running "(status filename)" ]]
"(date -Iseconds)" 
-------------------------------------
" | tee -a $log

info "Sauvegarde du dossier $src vers $dst" true

#region Vérifie que la source existe et vérifie que la destination existe
# Si le dossier source n'existe pas, alors il n'y a rien à sauvegarder
info "Vérification de l'existence du dossier source et du dossier de destination"
if test -d "$src"
    success "Le dossier source existe"
else
    error "Le dossier source n'existe pas" true
    exit 1
end

# Si le dossier de destination n'existe pas, le créer
if test -d "$dst"
    success "Le dossier de destination existe"
else
    info "Création du dossier de destination manquant"
    mkdir -p "$dst"
    if test $status -eq 0
        success "Dossier de destination créé avec succès"
    else
        error "Ne peut pas créer le dossier de destination manquant." true
        exit 1
    end
end
#endregion

# Creation de l'archive
info "Creation de l'archive $arch" true
tar --create --verbose --zstd \
    --file "$arch" \
    --directory (dirname $src) \
    (basename $src) 2>&1 | tee -a $log
# Vérifie si la commande tar a réussi
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué" true
    exit 1
end
success "La sauvegarde a réussi" true

#Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes
info "Suppression des anciennes sauvegardes"
delete_old_backups "$dst/automation.*.tar.zst" $nb_max
if test $status -eq 0
    success "Anciennes sauvegardes supprimées avec succès"
else
    error "Impossible de supprimer les anciennes sauvegardes"
end
