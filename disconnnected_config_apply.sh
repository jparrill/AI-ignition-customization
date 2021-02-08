TOKEN="sha256~hewIlJBbbwxYmduOaODjgDa7DRWDWh18XRWDRTv8pg0"
ASSISTED_SERVICE_IP="assisted-installer-ui.apps.mgmt-hub.e2e.bos.redhat.com"
ASSISTED_SERVICE_PORT="80"
IGNITION_FOLDER='ignition_files'
DISCV_IGN_TMPL_FILENAME='discovery-ignition_template.json'
CLUST_IGN_TMPL_FILENAME='cluster-ignition_template.json'
IMAGE_IGN_TMPL_FILENAME='image-ignition_template.json'
CLUSTER_ID="${1}"

if [[ -z ${CLUSTER_ID} ]];then
	echo "I need a Cluster ID"
	exit -1
fi

function collect_ignition_info() {
	export REGISTRY_CERT_FILENAME='domain.crt'
	export REGISTRY_CONF_FILENAME='registry.conf'
	export REGISTRY_CONF=$(cat ${IGNITION_FOLDER}/files/${REGISTRY_CONF_FILENAME} | base64 -w 0)
	export REGISTRY_CERT=$(cat ${IGNITION_FOLDER}/files/${REGISTRY_CERT_FILENAME} | base64 -w 0)
	export SSH_PUB="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC8OmP4e1JCDFrhe7hYyVjLvz1glDsNiJKfoQtirTjL2vcFIgy2maZnL7sOx9i0uc3KjLUVXMKSLPlOjOXaMtv+dK/QvLguR1eHyiO7cV0iArBJCLqiCQj7V95rLAkieMZJyp5S9/XfDZx1m4Eq020iBeFB3QnSBQRL9s3wbom6m6LZvKsT84FuoFPQvCHKa3Ar3uGrJeQX4+7+S47/Td0/IntGCN10ujgIxc0ALA8wlmP3WM9CtkFRh/Wh8gaaCviM57BYNtyoiZGD3jZ3jx3U+vxPXUSx7UjG1hrSRmQE63BOxbJsisVcSmZTyGbl7EGBnTJLms5V9/Adn0059+DLj9RQks+nYFO9V0gBIixCqmUXhLn+cyxZXVtXznJkRhLgP0hJCkxoBNlj/so7p869LXXekPtV5nCKcA3R0uZdTJW5U4VMLYp3zI0aFuB2lmeuoxIAvRt0PFGyqi6J8u+osLLpWsj5US1uN5Rw4Yb8W8HlxV+Hpm4u/QzUQlRVoUs= root@devscripts2ipv6.e2e.bos.redhat.com"
	export MAC="de:ad:be:ef:00:11" 
	export IP="1001:db9::10"
	export GW="1001:db9::1"
	export MASK="64"
	export DNS="1001:db9::1"
	export MODE="full-iso"
}

function fill_ignition_templates() {
	envsubst < ${IGNITION_FOLDER}/templates/${DISCV_IGN_TMPL_FILENAME} > discovery-ignition.json
	envsubst < ${IGNITION_FOLDER}/templates/${CLUST_IGN_TMPL_FILENAME} > cluster-ignition.json
	envsubst < ${IGNITION_FOLDER}/templates/${IMAGE_IGN_TMPL_FILENAME} > image-ignition.json
}

function apply_cluster_modifications (){
	# Modify Cluster Config
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $TOKEN" \
		--data @discovery-ignition.json \
		--request PATCH \
		"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/discovery-ignition"

	# Set the HTTP proxy
	curl \
		--header 'Content-Type: application/json' \
		--header "Authorization: Bearer $TOKEN" \
		--data @cluster-ignition.json \
		--request PATCH \
		"http://${ASSISTED_SERVICE_IP}:${ASSISTED_SERVICE_PORT}/api/assisted-install/v1/clusters/${CLUSTER_ID}"

	# Set RSA for ssh and ip
	curl \
		--header 'Content-Type: application/json' \
		--header "Authorization: Bearer $TOKEN" \
		--data @image-ignition.json \
		--request POST \
		"http://${ASSISTED_SERVICE_IP}:${ASSISTED_SERVICE_PORT}/api/assisted-install/v1/clusters/${CLUSTER_ID}/downloads/image"

	# Check Cluster Config
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $TOKEN" \
		--request GET \
		"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID" | jq
}

collect_ignition_info
fill_ignition_templates
apply_cluster_modifications
