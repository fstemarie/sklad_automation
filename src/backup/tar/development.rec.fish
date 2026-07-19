#! /usr/bin/fish

set src "/l/backup/development" # Variable qui contient le chemin du dossier à sauvegarder
set dst "/home/francois/development" # Variable qui contient le chemin du dossier de destination où les sauvegardes seront stockées
set full_arch "$src/development.full.tar.zst" # Variable qui contient le chemin complet du fichier d'archive à restaurer, en prenant le plus récent
set diff_arch "$src/development.diff.tar.zst" # Variable qui contient le chemin de l'archive à créer, avec un nom basé sur la date et l'heure

source /data/automation/tools/log.fish 2> /dev/null # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
source /home/francois/development/automation/src/tools/log.fish 2> /dev/null

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

# Si l'archive n'existe pas, affiche une erreur et quitte le script
info "Vérification de l'existence de l'archive"
if test -f "$arch"
    success "Archive trouvée : $arch"
else
    error "Archive introuvable"
    exit 1
end

# Si la destination existe déjà, alors on ajoute un timestamp au nom pour éviter la perte de données
info "Vérification de l'existence de la destination"
set original_dst "$dst"
while test -d "$dst"
    set dst "$original_dst."(date +%s)
    if not test -d "$dst"
        warning "La destination existe déjà. Nous ajoutons un timestamp pour éviter la perte de données"
        break
    end
end
# Cree la destination
info "Création de la destination"
mkdir -p "$dst"
if test $status -eq 0
    success "La destination a été créée avec succès"
else
    error "Impossible de créer la destination"
    exit 1
end

# Restauration de l'archive complete
info "Restauration de l'archive complète $full_arch"
tar --extract --verbose --zstd \
    --file "$full_arch" \
    --directory "$dst" \
    --strip 1 2>&1 | tee -a "$log"
if test $pipestatus[1] -ne 0
    error "La restauration de l'archive complète a échouée"
    exit 1
end
success "La restauration de l'archive complète a réussie"

if test -f "$diff_arch"
    info "Restauration de l'archive différentielle $diff_arch"
    tar --extract --verbose --zstd \
        --file "$diff_arch" \
        --directory "$dst" \
        --strip 1 2>&1 | tee -a "$log"
    if test $pipestatus[1] -ne 0
        error "La restauration de l'archive différentielle a échouée"
        exit 1
    end
    success "La restauration de l'archive différentielle a réussie"
end
