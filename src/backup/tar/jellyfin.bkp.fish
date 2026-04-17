#! /usr/bin/fish

set src "/srv/jellyfin"
set dst "/l/backup/sklad/jellyfin"
set arch "$dst/jellyfin."(date +%Y%m%dT%H%M%S)".tar.zst"
set snar "$dst/jellyfin.full.snar"
set log "/var/log/automation/jellyfin.tar.log"
set nb_max 1
set dir (dirname "$src")
set base (basename "$src")
set script (status basename)

rm -f $log 2>&1 > /dev/null
source (status dirname)/../../log.fish

echo "

-------------------------------------
[[ Running $script ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a $log

# if the source folder doesn't exist, then there is nothing to backup
if test ! -d "$src"
    error "Source folder does not exist. Cannot proceed"
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

# stop the container
set container (docker container ps --filter="name=$base" --format='{{.Names}}')
if contains "$container" "$base"
    set -g restart
    info "Stopping container $container"
    docker container stop "$container" > /dev/null
    if test $status -ne 0
        error "Unable to stop container $container"
        exit 1
    end
    docker wait "$container" > /dev/null
end

# It's a new full backup, so remove the old snapshot files
info "Removing snapshot files"
rm -f "$dst/jellyfin.*.snar" 2>&1 | tee -a $log

# Create a full backup of jellyfin that can be used as a basis for future differential backups
info "Creating archive"
tar --create --zstd \
    --listed-incremental="$snar" \
    --exclude={'cache', 'log', '.aspnet'} \
    --file="$arch" \
    --directory="$dir" "$base" 2>&1 | tee -a $log
if test $status -ne 0
    error "Backup unsuccessful"
    exit 1
end
log "The backup was successful"

info "Removing differential backup"
rm -f "$dst/jellyfin.diff.tar.zst" 2>&1 | tee -a $log

info "Creating hard link to the full backup"
ln -f "$arch" "$dst/jellyfin.full.tar.zst" 2>&1 | tee -a $log

if set -q restart
    info "Restarting container $container"
    docker container start "$container" > /dev/null
    if test $status -ne 0
        error "Unable to start container $container"
    end
end

#Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes
info "Suppression des anciennes sauvegardes"
delete_old_backups "$dst/automation.*.tar.zst" $nb_max
if test $status -eq 0
    success "Anciennes sauvegardes supprimées avec succès"
else
    error "Impossible de supprimer les anciennes sauvegardes"
end
