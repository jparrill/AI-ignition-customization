#!/bin/bash

AI_IMAGE_LIST_FILE=./ai_image_list
ICSP_FILE=./ICSP.yaml
PULL_SECRET=/home/kni/ipv6/pull_secret.json
EXTERNAL_REG=quay.io
INTERNAL_REG=bm-cluster-1-hyper.e2e.bos.redhat.com:5000
TOTAL_IMAGES=$(cat ${AI_IMAGE_LIST_FILE}| wc -l)
COUNTER=1

function create_ICSP_header() {
	cat <<EOF > ${ICSP_FILE}
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: redhat-icsp-gen
spec:
  repositoryDigestMirrors:	
EOF
}

function add_ICSP_entry() {
	# Add new entry on ICSP file
	IMG_SRC=${1}
	IMG_DST=${2}
	cat <<EOF >> ${ICSP_FILE}
  - mirrors:
    - ${IMG_DST}
    source: ${IMG_SRC}
EOF
}

function sync_images() {
	# Sync Container Images with source file
	for image in $(cat ${AI_IMAGE_LIST_FILE}); do
		echo "IMAGE: ${image##*/} (${COUNTER}/${TOTAL_IMAGES})"
		#HASH=$(sudo skopeo inspect docker://${image} | jq ".Digest" | tr -d '"')
		SRC=${image}
		DEST=$(echo $SRC | sed s/${EXTERNAL_REG}/${INTERNAL_REG}/g)
		echo "sudo skopeo copy --all --authfile ${PULL_SECRET} --dest-tls-verify=false docker://${SRC} docker://${DEST}"
		add_ICSP_entry ${SRC} ${DEST}
		COUNTER=$((COUNTER+1))
		echo
	done
}

create_ICSP_header
sync_images
