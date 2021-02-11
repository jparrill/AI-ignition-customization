TOKEN="sha256~hewIlJBbbwxYmduOaODjgDa7DRWDWh18XRWDRTv8pg0"
ASSISTED_SERVICE_IP="assisted-installer-ui.apps.mgmt-hub.e2e.bos.redhat.com"
ASSISTED_SERVICE_PORT="80"
IGNITION_FOLDER='ignition_files'
INTERNAL_REGISTRY="bm-cluster-1-hyper.e2e.bos.redhat.com:5000"
HTTP_PROXY=""
INGRESS_VIP='2620:52:0:1303::4'
API_VIP='2620:52:0:1303::3'
DISCV_IGN_TMPL_FILENAME='discovery-ignition_template.json'
CLUST_IGN_TMPL_FILENAME='cluster-ignition_template.json'
IMAGE_IGN_TMPL_FILENAME='image-ignition_template.json'
IMG_SNO_IGN_TMP_FILENAME='sno_image-ignition_template.json'
CLUSTER_ID="${1:-$CLUSTER_ID}"
BUILD="${PWD}/build"
SNO=true

if [[ -z ${CLUSTER_ID} ]];then
	echo "I need a Cluster ID"
	exit -1
fi

if [[ ! -d "${BUILD}" ]];then
	mkdir -p ${BUILD}
else
	rm -rf ${BUILD}/*
fi

function collect_ignition_info() {
	export CLUSTER_ID=${CLUSTER_ID}
	export INTERNAL_REGISTRY=${INTERNAL_REGISTRY}
	export REGISTRY_CERT_FILENAME='domain.crt'
	export REGISTRY_CONF_FILENAME='registry.conf'
	export INGRESS_VIP="${INGRESS_VIP}"
	export API_VIP="${API_VIP}"
	export HTTP_PROXY="${HTTP_PROXY}"
	export HTTPS_PROXY="${HTTP_PROXY}"
	export SSH_PUB="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCaTNKY08frGZjQLyS5hHPqAGRV3kbYkahoK4pJ1jpiBX2TxjgzmSCuhCKFkCwRPwDhUu1kTJ4XEFX7wA2P0df7asPkkdipvbesV8ySrLutjZToMxuE30lKjmQ6z960knYk2P3B/gK5dNabjPfStHdp3NO3KgBEku1qcE+oGpzxtnltmU8DWkx8/1Dg9jnvvSgOlTIeTNNQ8mSjmFy6QpaUW1esikWh9Bn0GEdI4Z0d4jUIKTlaAYdNNFy3ps5lz6L6udCXdPx5NzMePjyXsl4Pwsops8Wzb9sZmvPWyz45rmL7fA1rnyZPQ6et1ZBXy7er4SJIwgXMmM3b/4XgCFGjqegPtQVtK1rH38ODIXRwCQlmCbClFQCMIR6nUn6wWCv5kcC9An7c9jg5Zjwu9g/umM0hQs1HX4nFGhg6AXyuD6jjbmrugKEO1NTjG9pKB+G6OSbbwrbydyd1ZonbrhTvN1rFSrKA+nKX2bseZDZh4ikBU4CPMpEG/F1AqBMlIyk= kni@bm-cluster-1-hyper.e2e.bos.redhat.com"
	if [[ "${SNO}" == true ]]; then
		export INGRESS_VIP="2620:52:0:1303::6"
		export API_VIP="2620:52:0:1303::6"
		export MAC="a0:36:9f:6c:0c:10" 
		export IP="2620:52:0:1303::6"
		export GW="2620:52:0:1303::1"
		export MASK="64"
		export DNS="2620:52:0:1303::1"
	fi
	export MODE="full-iso"
}

function fill_ignition_templates() {
	# Rendering Files
	envsubst < ${IGNITION_FOLDER}/files/${REGISTRY_CONF_FILENAME} > ${BUILD}/${REGISTRY_CONF_FILENAME}
	cp ${IGNITION_FOLDER}/files/${REGISTRY_CERT_FILENAME} ${BUILD}/${REGISTRY_CERT_FILENAME}
	export REGISTRY_CONF=$(cat ${BUILD}/${REGISTRY_CONF_FILENAME} | base64 -w 0)
	export REGISTRY_CERT=$(cat ${BUILD}/${REGISTRY_CERT_FILENAME} | base64 -w 0)

	# Rendering Templates
	envsubst < ${IGNITION_FOLDER}/templates/${DISCV_IGN_TMPL_FILENAME} > ${BUILD}/discovery-ignition.json
	envsubst < ${IGNITION_FOLDER}/templates/${CLUST_IGN_TMPL_FILENAME} > ${BUILD}/cluster-ignition.json
	if [[ "${SNO}" == true ]]; then
		envsubst < ${IGNITION_FOLDER}/templates/${IMG_SNO_IGN_TMP_FILENAME} > ${BUILD}/image-ignition.json
	else
		envsubst < ${IGNITION_FOLDER}/templates/${IMAGE_IGN_TMPL_FILENAME} > ${BUILD}/image-ignition.json
	fi
}

function apply_cluster_modifications (){
	# Modify Cluster Config
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $TOKEN" \
		--data @${BUILD}/discovery-ignition.json \
		--silent \
		--request PATCH \
		"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/discovery-ignition"

	# Set the HTTP proxy
	curl \
		--header 'Content-Type: application/json' \
		--header "Authorization: Bearer $TOKEN" \
		--data @${BUILD}/cluster-ignition.json \
		--silent \
		--request PATCH \
		"http://${ASSISTED_SERVICE_IP}:${ASSISTED_SERVICE_PORT}/api/assisted-install/v1/clusters/${CLUSTER_ID}"

	# Set RSA for ssh and ip
	curl \
		--header 'Content-Type: application/json' \
		--header "Authorization: Bearer $TOKEN" \
		--data @${BUILD}/image-ignition.json \
		--silent \
		--request POST \
		"http://${ASSISTED_SERVICE_IP}:${ASSISTED_SERVICE_PORT}/api/assisted-install/v1/clusters/${CLUSTER_ID}/downloads/image"

	# Check Cluster Config
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $TOKEN" \
		--silent \
		--request GET \
		"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID" | jq
}

collect_ignition_info
fill_ignition_templates
apply_cluster_modifications
