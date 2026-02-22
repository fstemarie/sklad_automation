#! /usr/bin/fish

set dst "$HOME/development"

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

# Append date to name to avoid data loss
if test -d "$dst"
    echo "Destination already exists"

    set old "$dst"
    set dst "$old."(date +%s)
    while test -d "$dst"
        sleep 2
        set dst "$old."(date +%s)
    end
end

# Create non-existing destination
echo "Creating non-existing destination" only_echo
mkdir -p "$dst"
if test $status -ne 0
    echo (set_color brred)"[ERROR] Cannot create missing destination. Exiting..." >&2
    exit 1
end

# Recover data from archive
restic restore latest \
    --tag=development \
    --target "$dst"
if test $status -ne 0
    echo (set_color brred)"[ERROR] Could not restore snapshot" >&2
    exit 1
end
echo "Snapshot restoration successful"
