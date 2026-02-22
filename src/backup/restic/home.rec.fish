#! /usr/bin/fish

# Append date to destination name to avoid data loss
set dst "$HOME/home."(date +%s)

source (status dirname)/../../log.fish
source /data/config/restic/restic.fish

echo "

-------------------------------------
[[ Running $script ]]
"(date -Iseconds)"
-------------------------------------
"

if test -z "$RESTIC_REPOSITORY"
    error "RESTIC_REPOSITORY empty. Cannot proceed"
    exit 1
end

if test -z "$RESTIC_PASSWORD_FILE"; or not test -f "$RESTIC_PASSWORD_FILE"
    error "RESTIC_PASSWORD_FILE empty or does not exist. Cannot proceed"
    exit 1
end

# if target destination does not exist, create it
if test ! -d "$dst"
    echo "Creating non-existing destination"
    mkdir -p "$dst"
    if test $status -ne 0
        echo (set_color brred)"[ERROR] Cannot create missing destination. Exiting..." >&2
        exit 1
    end
end

# Recover data from archive
restic restore latest \
    --tag=home \
    --target "$dst"
if test $status -ne 0
    echo (set_color brred)"[ERROR] Could not restore snapshot" >&2
    exit 1
end
echo "Snapshot restoration successful"
