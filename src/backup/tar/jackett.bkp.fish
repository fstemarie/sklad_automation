#! /usr/bin/fish

set src "/srv/jackett" # La source a sauvegarder
set dst "/l/backup/sklad/jackett" # La destination de la sauvegarde, doit être un dossier existant ou qui peut être créé
set container (basename $src) # Variable qui contient le nom du container à arrêter et redémarrer pendant la sauvegarde
set arch "$dst/jackett."(date +%Y%m%dT%H%M%S | tr -d :-)".tar.zst" # Le nom de l'archive
set log "/var/log/automation/jackett.tar.log" # Le fichier de log, doit être un fichier existant ou qui peut être créé
set nb_max 5 # Le nombre maximum d'archives à conserver, les plus anciennes seront supprimées

if test (status dirname) = "/data/automation"
    source /data/automation/tools/log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
    source /data/automation/tools/containers.fish # inclut le fichier tools.fish pour utiliser les fonctions d'outils génériques
else
    source /home/francois/development/automation/src/tools/log.fish
    source /home/francois/development/automation/src/tools/containers.fish
end

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a $log

#region Vérifie que la source existe et vérifie que la destination existe
# Si le dossier source n'existe pas, alors il n'y a rien à sauvegarder
info "Vérification de l'existence du dossier source et du dossier de destination"
if test -d "$src"
    success "Le dossier source existe"
else
    error "Le dossier source n'existe pas. Impossible de continuer"
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
        error "Ne peut pas créer le dossier de destination manquant."
        exit 1
    end
end
#endregion

# Arrête le container s'il est en cours d'exécution pour éviter les problèmes de fichiers ouverts pendant la sauvegarde
if is_container_running $container
    info "Arrêt du container $container_name"
    set restart_container # Variable qui indique si le container doit être redémarré après la sauvegarde
    stop_container $container 
    if test $status -eq 0
        success "Container $container arrêté avec succès"
    else
        error "Impossible de stopper le container $container_name"
        exit 1
    end
end

# Creation de l'archive
info "Creation de l'archive $arch"
tar --create --verbose --zstd \
    --file "$arch" \
    --exclude 'log.txt*' --exclude 'updater.txt*' --exclude='DataProtection' \
    --directory (dirname $src) \
    (basename $src)  2>&1 | tee -a $log
# Vérifie si la commande tar a réussi, si ce n'est pas le cas, log une erreur et quitte le script
if test $pipestatus[1] -ne 0
    error "Echec de la sauvegarde"
    exit 1
end
success "La sauvegarde a réussi"

# Redémarre le container s'il avait été arrêté précédemment
if set -q $restart_container
    info "Démarrage du container $container_name"
    start_container $container # Si la variable restart_container est définie, cela signifie que le container était en cours d'exécution avant d'être arrêté, donc on le redémarre
    if test $status -eq 0
        success "Container $container_name démarré avec succès"
    else
        error "Impossible de démarrer le container $container_name"
    end
end

#Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes
info "Suppression des anciennes sauvegardes"
delete_old_backups "$dst/jackett.*.tar.zst" $nb_max
if test $status -eq 0
    success "Anciennes sauvegardes supprimées avec succès"
else
    warning "Impossible de supprimer les anciennes sauvegardes"
end
