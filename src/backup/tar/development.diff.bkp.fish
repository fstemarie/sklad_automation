#! /usr/bin/fish

set src "/home/francois/development" # La source a sauvegarder
set dst "/l/backup/development" # La destination de la sauvegarde, doit être un dossier existant ou qui peut être créé
set full_arch "$dst/development.full.tar.zst" # Variable qui contient le chemin de l'archive à créer, avec un nom basé sur la date et l'heure
set full_snar "$dst/development.full.snar" # Variable qui contient le chemin du fichier de snapshot 
set diff_arch "$dst/development.diff.tar.zst" # Variable qui contient le chemin de l'archive à créer, avec un nom basé sur la date et l'heure
set diff_snar "$dst/development.diff.snar" # Variable qui contient le chemin du fichier de snapshot
set log "/var/log/automation/development.tar.diff.bkp.log" # Le fichier de log, doit être un fichier existant ou qui peut être créé
set nb_max 5 # Le nombre maximum d'archives à conserver, les plus anciennes seront supprimées

source /data/automation/tools/log.fish # fonctions d'écriture de log
source /home/francois/development/automation/src/tools/log.fish

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
# Verifie que la sauvegarde complète précédente existe, sinon il n'y a pas de base pour faire une sauvegarde différentielle
info "Vérification de l'existence de l'archive complete précédente"
if test -L "$full_arch"; and test -f "$full_snar"
    success "L'archive complète précédente existe"
else
    error "L'archive complète précédente n'existe pas. Impossible de continuer"
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
cp -f "$full_snar" "$diff_snar" 2>&1 | tee -a "$log"

# Creation de l'archive
info "Creation de l'archive $diff_arch"
tar --create --zstd \
    --listed-incremental "$diff_snar" \
    --exclude '.venv' --exclude 'node_modules' --exclude '.git' \
    --file "$diff_arch" \
    --directory (dirname "$src") \
    (basename "$src") 2>&1 | tee -a "$log"
# Verifie que la commande tar s'est bien exécutée
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué"
    exit 1
end
success "La sauvegarde a réussi"

# Supprime le fichier de snapshot de la sauvegarde différentielle qui ne sera jamais utilisé
info "Suppression du snapshot de la sauvegarde différentielle"
sudo rm -f "$diff_snar" 2>&1 | tee -a "$log"
if test $pipestatus[1] -eq 0
    success "La suppression a réussi"
else
    warning "La suppression a échoué"
end
