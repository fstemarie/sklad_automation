#! /usr/bin/fish

set src "/l/backup/sklad/development" # Variable qui contient le chemin du dossier à sauvegarder
set dst "$HOME/development" # Variable qui contient le chemin du dossier de destination où les sauvegardes seront stockées
set arch (command ls -1dr $src/development.*.tar.zst | head -n1) # Variable qui contient le chemin complet du fichier d'archive à restaurer, en prenant le plus récent

if test (status dirname) = "/data/automation"
    source /data/automation/log.fish # inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
else
    source /home/francois/development/automation/src/log.fish
end

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a $log

# Si l'archive n'existe pas, affiche une erreur et quitte le script
info "Verification de l'existence de l'archive"
if test -f "$arch"
    success "Archive trouvée : $arch"
else
    error "Archive introuvable"
    exit 1
end

# Si la destination existe déjà, alors on ajoute un timestamp au nom pour éviter la perte de données
info "Verification de l'existence de la destination"
set original_dst "$dst"
while test -d "$dst"
    set dst "$original_dst."(date +%s)
    if not test -d "$dst"
        warning "La destination existe déjà. Nous ajoutons un timestamp pour éviter la perte de données"
        break
    end
end
# Cree la destination
info "Creation de la destination"
mkdir -p "$dst"
if test $status -eq 0
    success "La destination a été créée avec succès"
else
    error "Impossible de créer la destination"
    exit 1
end

# Restauration de l'archive
info "Restauration de l'archive $arch"
tar --extract --verbose --zstd \
    --file "$arch" \
    --directory "$dst" \
    --strip 1 2>&1 | tee -a $log
if test $status -ne 0
    error "La restauration a échoué"
    exit 1
end
success "La restauration a réussi"
