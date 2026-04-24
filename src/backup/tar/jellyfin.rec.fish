#! /usr/bin/fish

set src "/l/backup/sklad/jellyfin" # Variable qui contient le chemin vers le dossier de sauvegarde
set dst "/srv/jellyfin" # Variable qui contient le chemin vers le dossier de destination de la sauvegarde
set arch (command ls -1dr $src/jellyfin.*.tar.zst | head -n1) # Variable qui contient le chemin vers l'archive de sauvegarde la plus récente

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
    --same-owner \
    --same-permissions \
    --file "$arch" \
    --directory "$dst" \
    --strip 1 2>&1 | tee -a $log
if test $pipestatus[1] -ne 0
    error "La restauration a échouée"
    exit 1
end
success "La restauration a réussie"

