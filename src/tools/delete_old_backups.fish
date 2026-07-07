
function delete_old_backups -a dst pattern nb_max \
    --description 'Supprime les anciennes sauvegardes en gardant au maximum $nb_max sauvegardes'
    set files (string match -ie "$pattern" $dst/* | path sort -r) # Récupère la liste des fichiers correspondant au pattern, triés par ordre décroissant
    if not test -d "$dst"
        return 1
    end
    if test (count $files) -gt $nb_max
        set low_index (math $nb_max + 1) # Calcule l'index du premier fichier à supprimer, qui est égal au nombre maximum de fichiers à garder + 2
        set files $files[$low_index..-1]
        command rm -vf -- $files
        return $pipestatus[1]
    else
        return 0 # Pas de fichiers à supprimer, tout va bien
    end
end
