#!/bin/bash

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly ORANGE='\033[38;5;214m'
readonly NC='\033[0m' # No Color
readonly RUN_DIR=$(pwd)

ENVIRONMENT=${ENVIRONMENT:-develop}
DRYRUN=${DRYRUN:-}
BASE_DOMAIN=${BASE_DOMAIN:-}
CLUSTER_NAME=${CLUSTER_NAME:-}
GITOPS_OPERATOR_VERSION=1.14.0


wait_for_gitops_csv() {
    local i=0
    STATUS=$(oc get csv openshift-gitops-operator.v${GITOPS_OPERATOR_VERSION} -n openshift-operators -o jsonpath='{.status.phase}')
    until [ "$STATUS" == "Succeeded" ]
    do
        echo -e "${GREEN}Waiting for openshift-gitops-operator csv to install.${NC}"
        sleep 5
        ((i=i+1))
        if [ $i -gt 200 ]; then
            echo -e "🚨${RED}Failed waiting for openshift-gitops-operator csv never Succeeded?.${NC}"
            exit 1
        fi
        STATUS=$(oc get csv openshift-gitops-operator.v${GITOPS_OPERATOR_VERSION} -n openshift-operators -o jsonpath='{.status.phase}')
    done
}

wait_for_argocd() {
    local i=0
    ARGOCD_URL=https://$(oc -n openshift-gitops get route global-policy-server -o custom-columns=ROUTE:.spec.host --no-headers)
    HOST=${ARGOCD_URL}/healthz
    until [ $(curl -k -s -o /dev/null -w %{http_code} ${HOST}) = "200" ]
    do
        echo "🌴 Waiting for 200 response from ${HOST}"
        sleep 10
        HOST=${ARGOCD_URL}/healthz
        ((i=i+1))
        if [ $i -gt 100 ]; then
            echo -e "🚨${RED}Failed - argocd ${HOST} never ready.${NC}"
            exit 1
        fi
    done
}

boostrap() {
    if [ -z "$DRYRUN" ]; then
        echo -e "${GREEN}Ignoring - bootstrap - dry run set${NC}"
        return
    fi

    echo "🌴 Running bootstrap ..."

    oc apply -k gitops/bootstrap
    wait_for_gitops_csv
    oc apply -k gitops/bootstrap

    if [ "$?" != 0 ]; then
      echo -e "🚨${RED}Failed - to run boostrap ?${NC}"
      exit 1
    else
      echo "🌴 boostrap ran OK"
    fi

    wait_for_argocd
}

storage_class() {
    if [ -z "$DRYRUN" ]; then
        echo -e "${GREEN}Ignoring - storage_class - dry run set${NC}"
        return
    fi

    echo "🌴 Running storage_class..."

    local i=0
    oc get sc/lvms-vgsno
    until [ "$?" == 0 ]
    do
        echo -e "${GREEN}Waiting for 0 rc from oc commands.${NC}"
        ((i=i+1))
        if [ $i -gt 100 ]; then
            echo -e "🕱${RED}Failed - oc never ready?.${NC}"
            exit 1
        fi
        sleep 5
        oc get sc/lvms-vgsno
    done
    oc annotate sc/lvms-vgsno storageclass.kubernetes.io/is-default-class=true
    oc annotate sc/gp3-csi storageclass.kubernetes.io/is-default-class-
    if [ "$?" != 0 ]; then
        echo -e "🕱${RED}Failed to annotate sc ?${NC}"
        exit 1
    fi
    echo "🌴 storage_class ran OK"
}

wait_for_openshift_api() {
    local i=0
    HOST=https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:6443/healthz
    until [ $(curl -k -s -o /dev/null -w %{http_code} ${HOST}) = "200" ]
    do
        echo -e "${GREEN}Waiting for 200 response from openshift api ${HOST}.${NC}"
        sleep 5
        ((i=i+1))
        if [ $i -gt 100 ]; then
            echo -e "🕱${RED}Failed - OpenShift api ${HOST} never ready?.${NC}"
            exit 1
        fi
    done
}

wait_for_machine_config() {
    local i=0
    oc get mc 99-kubens-master 2>&1>/dev/null
    until [ "$?" == 0 ]
    do
        echo -e "${GREEN}Waiting for MachineConfig to be applied.${NC}"
        sleep 5
        ((i=i+1))
        if [ $i -gt 300 ]; then
            echo -e "🕱${RED}Failed - MachineConfig 99-kubens-master never found?.${NC}"
            exit 1
        fi
        oc get mc 99-kubens-master 2>&1>/dev/null
    done
}

app_of_apps() {
    if [ -z "$DRYRUN" ]; then
        echo -e "${GREEN}Ignoring - app_of_apps - dry run set${NC}"
        return
    fi

    echo "🌴 Running app_of_apps..."

    oc apply -f gitops/app-of-apps/${ENVIRONMENT}-app-of-apps.yaml

    wait_for_machine_config

    echo "🌴 app_of_apps ran OK"
}

usage() {
  cat <<EOF 2>&1
usage: $0 [ -d ]

Fix SNO Instance Id's
        -d     do it ! no dry run - else we print out whats going to happen and any non desructive lookups

Optional arguments if not set in environment:

        -e     ENVIRONMENT - cluster environment (or export ENVIRONMENT env var)
        -b     BASE_DOMAIN - openshift base domain (or export BASE_DOMAIN env var)
        -c     CLUSTER_NAME - openshift cluster name (or export CLUSTER_NAME env var)
        -k     KUBECONFIG - full path to the kubeconfig file

This script is rerunnable.

Environment Variables:
    Optionally if not set on command line:

        ENVIRONMENT
        BASE_DOMAIN
        CLUSTER_NAME
        KUBECONFIG

EOF
  exit 1
}


all() {
    echo "🌴 ENVIRONMENT set to $ENVIRONMENT"
    echo "🌴 BASE_DOMAIN set to $BASE_DOMAIN"
    echo "🌴 CLUSTER_NAME set to $CLUSTER_NAME"
    echo "🌴 KUBECONFIG set to $KUBECONFIG"

    wait_for_openshift_api
    boostrap
    app_of_apps
    storage_class
}

while getopts db:c:e:k: opts; do
  case $opts in
    b)
      BASE_DOMAIN=$OPTARG
      ;;
    c)
      CLUSTER_NAME=$OPTARG
      ;;
    d)
      DRYRUN="--no-dry-run"
      ;;
    e)
      ENVIRONMENT=$OPTARG
      ;;
    k)
      KUBECONFIG=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

shift `expr $OPTIND - 1`

# Check for EnvVars
[ -z "$BASE_DOMAIN" ] && echo "🕱 Error: must supply BASE_DOMAIN in env or cli" && exit 1
[ -z "$CLUSTER_NAME" ] && echo "🕱 Error: must supply CLUSTER_NAME in env or cli" && exit 1
[ -z "$ENVIRONMENT" ] && echo "🕱 Error: must supply ENVIRONMENT in env or cli" && exit 1
[ -z "$KUBECONFIG" ] && [ -z "KUBECONFIG" ] && echo "🕱 Error: KUBECONFIG not set in env or cli" && exit 1

all

echo -e "\n🌻${GREEN}SNO ACM Reconfigured OK.${NC}🌻\n"
exit 0