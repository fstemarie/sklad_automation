#! /usr/bin/fish

set domains falarie
set token d05499d5-3208-4b85-8bf2-be3ebbdc3ec2
set refresh_url "https://www.duckdns.org/update"
set log "/var/log/automation/duckdns.log" # Variable qui contient le chemin du fichier de log où les messages d'information et d'erreur seront enregistrés

source /home/francois/development/automation/src/tools/log.fish 2>/dev/null
or source /data/automation/tools/log.fish 2>/dev/null

echo "


-------------------------------------
[[ Execution de "(status basename)" ]] 
"(date -Iseconds)"
-------------------------------------
" | tee -a "$log"

info "Refreshing duckdns domains"
for domain in $domains
	set fulldomain $domain.duckdns.org
	set response (
		curl -s -k -G -o - \
			-d "token=$token" \
			-d "domains=$domain" \
			$refresh_url
	)

	echo $refresh_url
	echo $response 
	if test "$response" = "OK"
		success "Domain $fulldomain was successfully refreshed"
	else if test "$response" = "KO"
		error "There was an error while attempting to refresh $fulldomain"
	else
		error "Something weird happened while attempting to refresh $fulldomain"
	end
end
