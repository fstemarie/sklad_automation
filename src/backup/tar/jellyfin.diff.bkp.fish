#! /usr/bin/fish

set src "/srv/jellyfin" # Variable qui contient le chemin du dossier de sauvegarde
set dst "/l/backup/sklad/jellyfin" # Variable qui contient le chemin du dossier de destination
set container (basename $src) # Variable qui contient le nom du container à arrêter et redémarrer pendant la sauvegarde
set arch "$dst/jellyfin.diff.tar.zst" # Variable qui contient le chemin de l'archive à créer, avec un nom basé sur la date et l'heure
set snar "$dst/jellyfin.diff.snar" # Variable qui contient le chemin du fichier de snapshot pour les sauvegardes différentielles
set log "/var/log/automation/jellyfin.tar.log" # Variable qui contient le chemin du fichier de log

source (status dirname)/../../log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
source (status dirname)/../../tools.fish # inclut le fichier tools.fish pour utiliser les fonctions d'outils génériques

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status filename)" ]]
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

# Cette ligne fait la difference entre une sauvegarde incrementale et une sauvegarde différentielle, en utilisant le fichier de snapshot de la sauvegarde complète précédente pour ne sauvegarder que les fichiers qui ont changé depuis la dernière sauvegarde complète
# Le fichier snar contient la liste des fichiers et leur état lors de la sauvegarde
# Donc, si on veut une sauvegarde différentielle, on doit utiliser le fichier de snapshot de la sauvegarde complète précédente pour ne sauvegarder que les fichiers qui ont changé depuis la dernière sauvegarde complète
# Si on utilisait le fichier de snapshot de la sauvegarde différentielle précédente, nous aurions une sauvegarde incrémentale
info "Copie le fichier de snapshot de la sauvegarde complète précédente pour l'utiliser comme base pour la sauvegarde différentielle"
cp -f "$dst/jellyfin.full.snar" "$snar" 2>&1 | tee -a $log

# Arrête le container s'il est en cours d'exécution pour éviter les problèmes de fichiers ouverts pendant la sauvegarde
if is_container_running $container
    info "Arrêt du container $container_name"
    set restart_container
    stop_container $container # Si le container est en cours d'exécution, on le stoppe et on garde en mémoire le fait qu'on l'a stoppé pour pouvoir le redémarrer plus tard
    if test $status -eq 0
        success "Container $container arrêté avec succès"
    else
        error "Impossible de stopper le container $container_name"
        exit 1
    end
end

# Creation de l'archive
info "Creation de l'archive $arch"
tar --create --zstd \
    --listed-incremental "$snar" \
    --exclude 'cache' --exclude 'log' --exclude '.aspnet' \
    --file "$arch" \
    --directory (dirname $src) \
    (basename $src) 2>&1 | tee -a $log
# Verifie que la commande tar s'est bien exécutée
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué"
    exit 1
end
success "La sauvegarde a réussi"

# Redémarre le container s'il avait été arrêté précédemment
if set -q restart_container
    info "Démarrage du container $container_name"
    start_container $container # Si la variable restart_container est définie, cela signifie que le container était en cours d'exécution avant d'être arrêté, donc on le redémarre
    if test $status -eq 0
        success "Container $container_name démarré avec succès"
    else
        error "Impossible de démarrer le container $container_name"
    end
end

# Supprime le fichier de snapshot de la sauvegarde différentielle qui ne sera jamais utilisé
info "Suppression du snapshot de la sauvegarde différentielle"
sudo rm -f "$snar" 2>&1 | tee -a $log