#!/bin/bash

function initialize() {
  # Some color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m'
  # Internal file locations
  ATTESTOR_PUBLIC_KEY_FILE=$(mktemp)
  ATTESTATION_PAYLOAD=$(mktemp)
  ATTESTATION_SIGNATURE=$(mktemp)
  # Required software that MUST be installed
  requiredPackages=("curl" "jq" "sed" "gcloud" "gpg2" "java")
  # Required gcloud components
  requiredGcloudComponents=("beta") 
  # Provide usage data
  sendAnalytics=true
  # Does user want to do Binary Authorization
  binaryAuthorizationEnabled=false
  # Attestor Id if the user wants to perform Binary Authorization
  attestorId=
  # Attestor Service Account key file location
  attestorKeyFile=
  # Detect arguments
  detectArgs=
  # Fully qualified Image Digest (ie, image_path@image_digest)
  imageDigest=
  # Dcoker image with tag
  imageTag=
  # Attestor public key fingerprint
  attestorFingerprint=
  # Are we using PGP to sign the payload
  usePGP=true
  # Attestor PGP private key used to sign attestation payload
  attestorPgpPrivateKeyFile=
  # PKIX key location in KMS
  pkixLocation=
  # PKIX key ring name in KMS
  pkixKeyRing=
  # PKIX key name in KMS
  pkixKey=
  # PKIX key version in KMS
  pkixKeyVersion=
}

function exitFatal() {
  msg="${1}"
  echo "FATAL error encountered: ${msg}"
  echo "EXITING"
  exit 127
}

function usage() {
  echo "Usage:" 
  echo "Synopsys Detect options:"
  # Display Synopsys Detect help
  /bin/bash <(curl -s https://detect.synopsys.com/detect.sh) -hv
  echo " "
  echo "In addition, the following may be specified:"
  echo "    --binary.authorization.attestor.id <attestorId>"
  echo "        attestorId        The Id of the Attestor setup to generate attestations for Black Duck."
  echo "                          If present, the following arguments MUST be specified:"
  echo "                              --detect.policy.check.fail.on.severities"
  echo "                              --binary.authorization.image.path"
  echo "                              --binary.authorization.attestor.key.file"
  echo "                              If using PGP encryption, the following arguments are applicable:"
  echo "                                  --binary.authorization.attestor.pgp.private.key.file"
  echo "                                  Also, the following environment variable is applicable:"
  echo "                                  PRIVATE_KEY_PASSWD    Password used to access the private key"
  echo "                                                        specified in --binary.authorization.attestor.private.key.file"
  echo "                              If usng PKIX encryption, the following arguments are applicable:"
  echo "                                  --binary.authorization.attestor.pkix.location"
  echo "                                  --binary.authorization.attestor.pkix.key.ring"
  echo "                                  --binary.authorization.attestor.pkix.key.name"
  echo "                                  --binary.authorization.attestor.pkix.key.version"
  echo " "
  echo "    --binary.authorization.image.path <dockerImagePath>"
  echo "        dockerImagePath    The docker path and tag of the image to be attested."
  echo " "
  echo "    --binary.authorization.attestor.key.file <keyFileLocation>"
  echo "        keyFileLocation   The location (relative to '/workspace') where the key file of the service account for the attestor was generated"
  echo " "
  echo "    --binary.authorization.attestor.pgp.private.key.file <pgpPrivateKeyFileLocation>"
  echo "        pgpPrivateKeyFileLocation    The location (relattive to '/workspace') where the PGP private key of the attestor is placed"
  echo " "
  echo "    --binary.authorization.attestor.pkix.location <location>"
  echo "        location    The location of the PKIX key in KMS"
  echo " "
  echo "    --binary.authorization.attestor.pkix.key.ring <keyRing>"
  echo "        keyRing    The name of the PKIX key ring in KMS"
  echo " "
  echo "    --binary.authorization.attestor.pkix.key.name <key>"
  echo "        key    The name of the key to use to sign the payload"
  echo " "
  echo "    --binary.authorization.attestor.pkix.key.version <version>"
  echo "        version    The version of the PKIX key in KMS to use for signing"
  echo " "
  echo "    --disableAnalytics"
  echo "        Do not send integration usage statistics"
}

function isArgValue() {
  if [ -z "${1}" ]; then
    false
  elif [[ "${1}" == --* ]]; then
    false
  else
    true
  fi
}

function parseArgs() {
  echo "Parsing argument list: $@"
  while [[ $# -ge 1 ]]; do
    case "${1}" in
      --binary.authorization.attestor.id)
        shift
        if isArgValue "${1}" ; then
          attestorId=${1}
          binaryAuthorizationEnabled=true
        else
          exitFatal "Value required for --binary.authorization.attestor.id"
        fi
        ;;
      --binary.authorization.attestor.key.file)
        shift
        if isArgValue "${1}" ; then
          attestorKeyFile=${1}
        else
          exitFatal "Value required for --binary.authorization.attestor.key.file"
        fi
        ;;
      --binary.authorization.attestor.pgp.private.key.file)
        shift
        if isArgValue "${1}" ; then
          attestorPgpPrivateKeyFile=${1}
        else
          exitFatal "Value required for --binary.authorization.attestor.pgp.private.key.file"
        fi
        ;;
      --binary.authorization.attestor.pkix.location)
        shift
        if isArgValue "${1}" ; then
          pkixLocation=${1}
          usePGP=false
          # Add 'alpha' to the list of required gcloud components
          requiredGcloudComponents+=("alpha")
        else
          exitFatal "Value required for --binary.authorization.attestor.pkix.location"
        fi
        ;;
      --binary.authorization.attestor.pkix.key.ring)
        shift
        if isArgValue "${1}" ; then
          pkixKeyRing=${1}
        else
          exitFatal "Value required for --binary.authorization.attestor.pkix.key.ring"
        fi
        ;;
      --binary.authorization.attestor.pkix.key.name)
        shift
        if isArgValue "${1}" ; then
          pkixKey=${1}
        else
          exitFatal "Value required for --binary.authorization.attestor.pkix.key.name"
        fi
        ;;
      --binary.authorization.attestor.pkix.key.version)
        shift
        if isArgValue "${1}" ; then
          pkixKeyVersion=${1}
        else
          exitFatal "Value required for --binary.authorization.attestor.pkix.key.version"
        fi
        ;;
      --binary.authorization.image.path)
        shift
        if isArgValue "${1}" ; then
          imageTag=${1}          
        else
          exitFatal "Value required for --binary.authorization.image.path"
        fi
        ;;
      --disableAnalytics)
        sendAnalytics=false
        ;;
      -hv)
        usage
        exitFatal "Not enough parameters"
        ;;
      *)
        if isArgValue "${2}" ; then
          detectArgs="${detectArgs} ${1}=${2}"
        else
          exitFatal "Value required for Synopsys Detect arguement ${1}"
        fi
        shift
        ;;
    esac
    shift
  done
}

function isEncryptionArgsSatisfied() {
  returnVal=false
  if ${usePGP} ; then
    if [[ ! -z "${attestorPgpPrivateKeyFile}" &&
          -n "${PRIVATE_KEY_PASSWD}" ]]; then
      returnVal=true
    fi
  else
    if [[ ! -z "${pkixLocation}" &&
          ! -z "${pkixKeyRing}" &&
          ! -z "${pkixKey}" &&
          ! -z "${pkixKeyVersion}" ]]; then
      returnVal=true
    fi
  fi
  
  ${returnVal}
}

function isDependentArgsSatisfied() {
  if [ ! -z "${attestorId}" ]; then
    # If there is an attestor Id present, Detect MUST be passed --detect.policy.check.fail.on.severities
    if [[ ${detectArgs} == *--detect.policy.check.fail.on.severities* && 
          ! -z "${attestorKeyFile}" &&
          isEncryptionArgsSatisfied &&
          ! -z "${imageTag}" ]]; then
      true
    else
      false
    fi
  else
    true
  fi
}

function isToolsPresent() {
  returnVal=true
  if ${binaryAuthorizationEnabled} ; then
    for package in ${requiredPackages[@]}; do
      printf "Searching for ${package} \t ... \t" 
      packagePath=$(which "${package}")
      if [ -z "${packagePath}" ]; then
        printf "${RED}NOT FOUND${NC}\n"
        returnVal=false
      else
        printf "${GREEN}FOUND (${packagePath})${NC}\n"
      fi
    done
  fi
  
  ${returnVal}
}

function checkGcloudComponents() {
  returnVal=true
  # Cache the current state of gcloud components
  gcloudComponents=$(gcloud components list --format=json --quiet 2>/dev/null)
  for component in ${requiredGcloudComponents[@]}; do
    printf "\tSearching for ${component} \t ... \t"
    state=$(echo "${gcloudComponents}" | jq -r --arg COMPONENT "${component}" '.[] | select(.id == $COMPONENT) | .state.name')
    if [ "${state}" == "Installed" ]; then
      printf "${GREEN}${state}${NC}\n"
    else
      printf "${RED}${state}${NC}\n"
      printf "\t\tAttempting to install \t ... \t"
      gcloud components install "${component}" --quiet 2>/dev/null
      if [ $? -ne 0 ]; then
        printf "${RED}FAILED${NC}\n"
        returnVal=false
      else
        printf "${GREEN}PASSED${NC}\n"
      fi
    fi
  done
  
  ${returnVal}
}

function gatherExternalData() {
  returnVal=true
  
  if ${binaryAuthorizationEnabled} ; then 
    printf "Using Encryption type \t ... \t"
    if ${usePGP} ; then
      printf "${GREEN}PGP${NC}\n"
    else
      printf "${GREEN}PKIX${NC}\n"
    fi
     
    printf "Authorizing gcloud service account \t ... \t"
    gcloud auth activate-service-account --key-file "${attestorKeyFile}" 2>/dev/null
    saEmail=$(cat "${attestorKeyFile}" | jq -r '.client_email')
    if [ $? -ne 0 ]; then
      printf "${RED}FAILED (${saEmail})${NC}\n"
      returnVal=false
    else
      printf "${GREEN}PASSED (${saEmail})${NC}\n"
    fi
    
    printf "Running 'gcloud components update' \t ... \t"
    gcloud components update --quiet 2>/dev/null
    if [ $? -ne 0 ]; then
      printf "${RED}FAILED${NC}\n"
      returnVal=false
    else
      printf "${GREEN}PASSED${NC}\n"
    fi
    
    printf "Check required gcloud components\n"
    if ! checkGcloudComponents ; then
      returnVal=false
    fi
    
    if ${usePGP} ; then
      printf "Gather attestor data \t ... \t"
      attestorRawData=$(gcloud --format=json beta container binauthz attestors describe "${attestorId}" | jq  '.userOwnedDrydockNote | select(.publicKeys | length >= 1) | .publicKeys[]')
      if [ ! -z "${attestorRawData}" ]; then
        if [ -a "${ATTESTOR_PUBLIC_KEY_FILE}" ]; then
          rm -rf "${ATTESTOR_PUBLIC_KEY_FILE}"
        fi
        echo -e $(echo `jq '.asciiArmoredPgpPublicKey' <<< "${attestorRawData}"` | sed -e 's/"//g') > "${ATTESTOR_PUBLIC_KEY_FILE}"
        attestorFingerprint=$(echo `jq -r '.id' <<< "${attestorRawData}"` )
        if [[ -z "${attestorFingerprint}" || ! -s "${ATTESTOR_PUBLIC_KEY_FILE}" ]]; then
          printf "${RED}FAILED${NC}\n"
          returnVal=false
        else
          printf "${GREEN}PASSED${NC}\n"
        fi
      else
        printf "${RED}FAILED${NC}\n"
        returnVal=false
      fi
    fi
    
    printf "Gather image digest data \t ... \t"
    imageDigest=$(gcloud --format=json container images describe "${imageTag}" | jq -r '.image_summary.fully_qualified_digest')
    if [ -z "${imageDigest}" ]; then
      printf "${RED}FAILED${NC}\n"
      returnVal=false
    else
      printf "${GREEN}PASSED${NC}\n"
    fi
    
    if ${usePGP} ; then
      printf "Import attestor PGP private key \t ... \t"
      echo "${PRIVATE_KEY_PASSWD}" | gpg2 --batch --yes --passphrase-fd 0 --import "${attestorPgpPrivateKeyFile}" > /dev/null 2>&1 
      if [ $? -ne 0 ]; then
        printf "${RED}FAILED${NC}\n"
        returnVal=false
      else
        printf "${GREEN}PASSED${NC}\n"
      fi
    fi
  fi

  ${returnVal}  
}

function signAndCreateAttestation() {
  if ${usePGP} ; then
    if [ -a "${ATTESTATION_SIGNATURE}" ]; then
      rm -rf "${ATTESTATION_SIGNATURE}"
    fi
    # Create the signature
    echo "${PRIVATE_KEY_PASSWD}" | gpg2 --armor --pinentry-mode loopback --passphrase-fd 0 --output "${ATTESTATION_SIGNATURE}" --sign "${ATTESTATION_PAYLOAD}"   
    # Generate attestation
    gcloud beta container binauthz attestations create --artifact-url="${imageDigest}" --attestor="${attestorId}" --signature-file="${ATTESTATION_SIGNATURE}" --pgp-key-fingerprint="${attestorFingerprint}"
  else
    # Using PKIX
    gcloud alpha container binauthz attestations sign-and-create --artifact-url="${imageDigest}" --attestor="${attestorId}" --keyversion-location="${pkixLocation}" --keyversion-keyring="${pkixKeyRing}" --keyversion-key="${pkixKey}" --keyversion="${pkixKeyVersion}"
  fi
}

function generateAttestation() {
  detectReturn=$1
  if ! ${binaryAuthorizationEnabled} ; then
    return
  fi
  printf "Generating Attestation \t ... \t"
  if [ ${detectReturn} -eq 0 ]; then
    # Generate payload
    if [ -a "${ATTESTATION_PAYLOAD}" ]; then
      rm -rf "${ATTESTATION_PAYLOAD}"
    fi
    gcloud beta container binauthz create-signature-payload --artifact-url="${imageDigest}" > "${ATTESTATION_PAYLOAD}"
    # Sign payload and create attestation
    signAndCreateAttestation
    printf "${GREEN}PASSED${NC}\n"
  elif [ ${detectReturn} -eq 3 ]; then
    printf "${RED}FAILED (Black Duck Policy failure triggered)${NC}\n"
  else
    printf "${RED}FAILED (Synopsys Detect returned error ${detecReturn})${NC}\n"
  fi
}

function sendAnalytics() {
  if "${sendAnalytics}" ; then
    return
  fi
}

function main() {
  # Parse the arguments passed
  parseArgs $@
  
  # Ensure argument dependencies are met
  if ! isDependentArgsSatisfied ; then
    usage
    exitFatal "Arugment dependencies not satisfied"
  fi
  
  # Ensure necessary tools are present
  if ! isToolsPresent ; then
    exitFatal "Required tools NOT present, please contact Synopsys Support immediately"
  fi
  
  # Gather required external data, if necessary
  if ! gatherExternalData ; then
    exitFatal "Failed to gather external data"
  fi
  
  # Run Synopsys Detect
  if [ -z "${detectArgs}" ]; then
     usage
     exitFatal "Not enough arguments" 
  fi
  /bin/bash <(curl -s https://detect.synopsys.com/detect.sh) "${detectArgs}"
  
  # Send the return value from Detect to determone if an attestation needs to be generated
  generateAttestation $?
  
  sendAnalytics
}

initialize
main $@
