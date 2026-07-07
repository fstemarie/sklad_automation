# Verifie si un conteneur docker est en cours d'exécution en fonction de son nom
function is_container_running -a container_name \
    --description 'Check if a docker container is running'
    set result (docker container ps --filter="name=$container_name" --format='{{.Names}}') | grep -q "$container_name"
    return (test -n "$result") # Retourne vrai si le résultat n'est pas vide, donc si le conteneur est en cours d'exécution
end

# Arrête un conteneur docker en fonction de son nom
function stop_container -a container_name \
    --description 'Arrete un container'
    docker container stop "$container_name" # Arrête le container
    set stop_status $status
    if test $stop_status -eq 0
        docker wait "$container_name" > /dev/null # Attendre que le container soit complètement arrêté avant de continuer
    end
    return $stop_status
end

# Demarre un conteneur docker en fonction de son nom
function start_container -a container_name \
    --description 'Demarre un container'
    docker container start "$container_name" > /dev/null
    return $status
end
