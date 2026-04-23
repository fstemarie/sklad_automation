#! /usr/bin/fish

set src "/l/audio/podcasts/"
# add bedroom to ~/.ssh/config
set dst "bedroom:/media/256gb/podcasts/"
set log "/var/log/automation/podcasts.rsync.log"
set script (status basename)

# inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
if test (status dirname) = "/data/automation"
    source /data/automation/log.fish
else
    source /home/francois/development/automation/src/log.fish
end

umask 0122

echo "


-------------------------------------
[[ Running $script ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a $log

# if the source folder doesn't exist, then there is nothing to backup
if test ! -d "$src"
    log "Source folder does not exist"
    exit 1
end
info "Source folder: $src"

info "Gathering remote file list"
set lsremote (ssh -o ConnectTimeout=5 bedroom find \"/media/256gb/podcasts/How Did This Get Made_\" -type f -printf \"%f\n\")
info "Gathering local file list"
set lslocal (find "/l/audio/podcasts/How Did This Get Made_/" -type f -printf "%f\n")
info "Comparing lists"
printf "%s\n" $lsremote $lslocal | sort | uniq -u
set diff (printf "%s\n" $lsremote $lslocal | sort | uniq -u | wc -l)
if test $diff -eq 0
    info "No files to transfer. Exiting early"
    if set -q podcasts_comm
        set podcasts_comm "NODIFFS"
    end
    exit 0
end

info "Transfering files"
begin
    rsync \
        --verbose \
        --ignore-existing \
        --size-only \
        --recursive \
        --chmod u=rwX,go=rX \
        --mkpath \
        --exclude='How Did This Get Made - Matinee Monday' \
        "$src" "$dst"
    set -g ret $status
end 2>&1 | tee -a $log
if test $ret -ne 0
    log "There was an error during the transfer"
    exit 1
end
log "Transfer was successful"

if set -q podcasts_comm
    set podcasts_comm "DIFFS"
end