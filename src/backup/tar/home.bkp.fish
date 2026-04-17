#! /usr/bin/fish

set src "$HOME"
set dst "/l/backup/sklad/home"
set arch "$dst/home."(date +%Y%m%dT%H%M%S | tr -d :-)".tgz"
set log "/var/log/automation/home.tar.log"
set nb_max 5
set dir (dirname "$src")
set base (basename "$src")
set script (status basename)

source (status dirname)/../../log.fish

echo "

-------------------------------------
[[ Running $script ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a $log

# if the source folder doesn't exist, then there is nothing to backup
if test ! -d "$src"
    error "Source folder does not exist"
    exit 1
end

# if the destination folder does not exist, create it
if test ! -d "$dst"
    log "Creating non-existing destination"
    mkdir -p "$dst"
    if test $status -ne 0
        error "Cannot create missing destination. Exiting..."
        exit 1
    end
end

info "Creating archive $arch"
tar --create --verbose --gzip \
    --file="$arch" \
    --exclude={'development', '.cache', '.vscode*', '.npm'} \
    --exclude={'.local', '.pyenv', '.dotnet', '.git', '.docker/buildx'} \
    --exclude={'fish_history', '.gnupg/S.gpg-agent*', '.gnupg/*.bak'} \
    --directory="$dir" "$base"  2>&1 | tee -a $log
if test $status -ne 0
    error "Backup unsuccessful"
    exit 1
end
log "The backup was successful"

#Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes
info "Suppression des anciennes sauvegardes"
delete_old_backups "$dst/automation.*.tar.zst" $nb_max
if test $status -eq 0
    success "Anciennes sauvegardes supprimées avec succès"
else
    error "Impossible de supprimer les anciennes sauvegardes"
end
