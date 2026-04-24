#! /usr/bin/fish

set src "/home/francois/development" # Variable qui contient la source a sauvegarder
set log "/var/log/automation/development.restic.bkp.log" # Variable qui contient la destination ou ecrire le log

# inclut le fichier log.fish pour utiliser les fonctions d'écriture de log
if test (status dirname) = "/data/automation"
    source /data/automation/tools/log.fish
else
    source /home/francois/development/automation/src/tools/log.fish
end

# Ecrit l'entete du log pour cette execution du script
echo "

-------------------------------------
[[ Execution de "(status basename)" ]]
"(date -Iseconds)"
-------------------------------------
" | tee -a $log

#region Verifie que les variables d'environnement nécessaires sont définies et valides
# Verifie que la variable d'environnement RESTIC_REPOSITORY est définie et n'est pas vide
info "Vérification de la variable d'environnement RESTIC_REPOSITORY"
if test -n "$RESTIC_REPOSITORY"
    success "RESTIC_REPOSITORY est definie"
else
    error "RESTIC_REPOSITORY est non defini"
    exit 1
end
# Verifie que le fichier de mot de passe existe et n'est pas vide
info "Vérification de la variable d'environnement RESTIC_PASSWORD_FILE"
if test -n "$RESTIC_PASSWORD_FILE"; and test -e "$RESTIC_PASSWORD_FILE"
    success "RESTIC_PASSWORD_FILE est definie et existe"
else
    error "RESTIC_PASSWORD_FILE vide ou n'existe pas"
    exit 1
end
# Verifie que le dossier source existe
info "Vérification de l'existence du dossier source"
if test -d "$src"
    success "Le dossier source existe"
else
    error "Le dossier source n'existe pas"
    exit 1
end
#endregion

#region Crée un snapshot avec restic en excluant les dossiers et fichiers qui ne sont pas nécessaires
info "Creation du snapshot restic"
pushd "$src"
restic backup \
    --host=$hostname \
    --tag=development \
    --exclude='.venv' \
    --exclude='node_modules' \
    .  2>&1 | tee -a $log
# Vérifie si la commande backup a réussi
if test $pipestatus[1] -ne 0
    error "La sauvegarde a échoué"
    exit 1
end
popd
success "La sauvegarde a réussi"
#endregion

#region Supprime les snapshots plus anciens que 4 semaines en gardant au moins un snapshot par semaine
info "Effacement des snapshots"
restic forget \
    --host=$hostname \
    --tag=development \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 2>&1 | tee -a $log
# Vérifie si la commande forget a réussi
if test $pipestatus[1] -ne 0
    error "La suppression des snapshots a échouée"
    exit 1
end
success "La suppression des snapshots a réussie"
#endregion