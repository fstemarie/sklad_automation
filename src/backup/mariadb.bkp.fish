#! /usr/bin/fish

set dst "/l/backup/sklad/mariadb"
set arch "$dst/mariadb."(date +%Y%m%dT%H%M%S | tr -d :-)".sql.gz"
set log "/var/log/automation/mariadb.tar.zst"
set nb_max 5
set secret_file "/home/francois/.secrets/mariadb-backup.fish"

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

# Lit le mot de passe dans une variable
if test -e "$secret_file"
    info "Lecture du mot de passe"
    set user "backup"
    read password < $secret_file
    if test $status -ne 0
        error "Ne peut pas lire le mot de passe"
        exit 1
    end
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

# Creation de l'archive
info "Creation de l'archive $arch" true
docker exec mariadb mariadb-dump \
    --user=$user \
    --password=$password \
    --all-databases | zstd > "$arch"
# Vérifie que la création de l'archive a réussi
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué"
    exit 1
end
success "La sauvegarde a réussi"

#Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes
info "Suppression des anciennes sauvegardes"
delete_old_backups "$dst/mariadb.*.tar.zst" $nb_max
if test $status -eq 0
    success "Anciennes sauvegardes supprimées avec succès"
else
    error "Impossible de supprimer les anciennes sauvegardes"
end
