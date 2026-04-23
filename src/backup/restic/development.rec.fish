#! /usr/bin/fish

# Note: Ce script est destiné à être utilisé à des fins de récupération. Il ne remplacera pas les données existantes, mais créera plutôt un nouveau répertoire avec un horodatage. Cela vous permet de conserver plusieurs versions de votre répertoire de développement et d'éviter toute perte de données accidentelle.
set dst "/home/francois/development" # Destination finale pour la restauration. Un timestamp sera ajouté si ce dossier existe déjà pour éviter les conflits de noms
set log "/var/log/automation/development.restic.rec.log" # Variable qui contient la destination ou ecrire le log

# inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
if test (status dirname) = "/data/automation"
    source /data/automation/log.fish
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

#region Verifie que les variables d'environnement nécessaires sont définies et valides
# Verifie que la variable d'environnement RESTIC_REPOSITORY est défini et n'est pas vide
info "Vérification de la variable d'environnement RESTIC_REPOSITORY"
if test -n "$RESTIC_REPOSITORY"
    success "RESTIC_REPOSITORY est defini"
else
    error "RESTIC_REPOSITORY est non defini"
    exit 1
end
# Verifie que le fichier de mot de passe existe et n'est pas vide
if test -n "$RESTIC_PASSWORD_FILE"; and test -e "$RESTIC_PASSWORD_FILE"
    success "RESTIC_PASSWORD_FILE est defini et existe"
else
    error "RESTIC_PASSWORD_FILE vide ou n'existe pas"
    exit 1
end
#endregion

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

# Recupere les données de l'archive
info "Recuperation du snapshot restic"
restic restore latest \
    --host $hostname \
    --tag development \
    --target "$dst"
if test $pipestatus[1] -ne 0
    error "La restauration du snapshot a échoué"
    exit 1
end
success "La restauration du snapshot a réussi"
