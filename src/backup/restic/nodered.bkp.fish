#! /usr/bin/fish

set src "/srv/nodered"
set base (basename "$src")
set log "/var/log/automation/nodered.restic.log"
set script (status basename)

source (status dirname)/../../log.fish
source /data/config/restic/restic.fish

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
info "Source folder: $src"

if test -z "$RESTIC_REPOSITORY"
    error "RESTIC_REPOSITORY empty. Cannot proceed"
    exit 1
end

if test -z "$RESTIC_PASSWORD_FILE"; or not test -f "$RESTIC_PASSWORD_FILE"
    error "RESTIC_PASSWORD_FILE empty or does not exist. Cannot proceed"
    exit 1
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

info "Creating restic snapshot"
pushd "$src"
restic backup \
    --tag=nodered \
    --exclude='node_modules' --exclude='.git' --exclude='.npm' \
    .  2>&1 | tee -a $log
if test $status -ne 0
    error "There was an error during the snapshot"
    exit 1
end
popd
log "Snapshot created successfully"

# Restart the container
if set -q restart
    info "Restarting container $container"
    docker container start "$container" > /dev/null
    if test $status -ne 0
        error "Unable to start container $container"
    end
end

info "Forgetting snapshots"
restic forget \
    --tag=nodered \
    --keep-last=3 2>&1 | tee -a $log
if test $status -ne 0
    error "Unable to forget snapshots"
    exit 1
end
info "Snapshots forgotten successfully"
