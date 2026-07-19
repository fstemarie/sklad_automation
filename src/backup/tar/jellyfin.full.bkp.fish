#! /usr/bin/fish

set src "/l/containers/jellyfin" # La source a sauvegarder
set dst "/l/backup/jellyfin" # La destination de la sauvegarde, doit être un dossier existant ou qui peut être créé
set container (basename "$src") # Variable qui contient le nom du container à arrêter et redémarrer pendant la sauvegarde
set arch "$dst/jellyfin."(date +%Y%m%dT%H%M%S)".tar.zst" # Le nom de l'archive
set snar "$dst/jellyfin.full.snar" # Variable qui contient le chemin du fichier de snapshot pour les sauvegardes incrémentielles
set log "/var/log/automation/jellyfin.tar.log" # Le fichier de log, doit être un fichier existant ou qui peut être créé
set nb_max 5 # Le nombre maximum d'archives à conserver, les plus anciennes seront supprimées

source /home/francois/Documents/development/automation/src/tools/log.fish
or source /data/automation/tools/log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log

source /home/francois/Documents/development/automation/src/tools/containers.fish
or source /data/automation/tools/containers.fish # inclut le fichier tools.fish pour utiliser les fonctions d'outils génériques

source /home/francois/Documents/development/automation/src/tools/delete_old_backups.fish # inclut le fichier delete_old_backups.fish pour utiliser les fonctions de suppression des anciennes sauvegardes
or source /data/automation/tools/delete_old_backups.fish # inclut le fichier delete_old_backups.fish pour utiliser les fonctions de suppression des anciennes sauvegardes

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

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

# C'est une nouvelle sauvegarde complète, donc on supprime les anciens fichiers de snapshot
info "Suppression du fichier de snapshot"
rm -f "$dst/jellyfin.*.snar" 2>&1 > /dev/null
info "Suppression du lien symlink vers la sauvegarde complète précédente"
rm -f "$dst/jellyfin.full.tar.zst" 2>&1 | tee -a "$log"
info "Suppression de la sauvegarde différentielle"
rm -f "$dst/jellyfin.diff.tar.zst" 2>&1 | tee -a "$log"

# Arrête le container s'il est en cours d'exécution pour éviter les problèmes de fichiers ouverts pendant la sauvegarde
if is_container_running $container
    info "Arrêt du container $container_name"
    stop_container $container # Si le container est en cours d'exécution, on le stoppe et on garde en mémoire le fait qu'on l'a stoppé pour pouvoir le redémarrer plus tard
    if test $status -eq 0
        success "Container $container arrêté avec succès"
        function restart_container --on-event fish_exit
            # Redémarre le container s'il avait été arrêté précédemment
            info "Démarrage du container $container_name"
            start_container $container # Si la variable restart_container est définie, cela signifie que le container était en cours d'exécution avant d'être arrêté, donc on le redémarre
            if test $status -eq 0
                success "Container $container_name démarré avec succès"
            else
                error "Impossible de démarrer le container $container_name"
            end
        end
    else
        error "Impossible de stopper le container $container_name"
        exit 1
    end
end

# Creation de l'archive
info "Creation de l'archive $arch"
tar --create --zstd \
    --listed-incremental "$snar" \
    --exclude 'cache' --exclude='metadata' --exclude 'log' --exclude 'transcoding-temp' --exclude '.aspnet' --exclude '.cache' \
    --exclude 'data/data' --exclude '.aspnet' --exclude '.cache' \
    --file "$arch" \
    --directory (dirname "$src") \
    (basename "$src") 2>&1 | tee -a "$log"
# Vérifie que la création de l'archive a réussi
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué"
    exit 1
end
success "La sauvegarde a réussi"

# Crée un lien symbolique vers la sauvegarde complète 
info "Creation d'un lien symbolique vers la sauvegarde complète"
ln -s "$arch" "$dst/jellyfin.full.tar.zst" 2>&1 | tee -a "$log"
if test $status -ne 0
    warning "La création du lien symbolique a échoué"
end
success "La création du lien symbolique a réussi"

#Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes
info "Suppression des anciennes sauvegardes"
delete_old_backups "$dst" "jellyfin.*.tar.zst" $nb_max
if test $status -eq 0
    success "La suppression des anciennes sauvegardes a réussi"
else
    warning "La suppression des anciennes sauvegardes a échoué"
end
