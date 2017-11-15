#!/bin/bash

# the point of this script is to make create a prometheus
# datasource in a grafana instance. this script is
# idempotent, so it can be run multiple times (it uses
# the datasource name to determine whether or not it
# exists in the grafana instance)

# this script has a handfull of assumptions/requirements
#   - k8s port forwarding to grafana pod
#   - prometheus helm release is named `monitoring`   
#   - grafana helm release is named `dashboard`

K8S_SECRET_NAME=dashboard-grafana
GF_USER_NAME=$(kubectl get secret $K8S_SECRET_NAME -o jsonpath="{.data.grafana-admin-user}" | base64 --decode)
GF_PASSWORD=$(kubectl get secret $K8S_SECRET_NAME -o jsonpath="{.data.grafana-admin-password}" | base64 --decode)
# DS_URL is currently localhost from k8s port-forwarding to test this locally
GF_URL=localhost:3000

DS_TYPE=prometheus
DS_NAME=prometheus1

PROM_URL=http://monitoring-prometheus-server

echo retrieving current data sources...
CURRENT_DS_LIST=$(curl -s --user "$GF_USER_NAME:$GF_PASSWORD" "$GF_URL/api/datasources")
echo $CURRENT_DS_LIST | grep -q "\"name\":\"$DS_NAME\""
if [[ $? -eq 0 ]]; then
    echo data source $DS_NAME already exists
    echo $CURRENT_DS_LIST | python -m json.tool
    exit 0
fi

echo data source $DS_NAME does not exist, creating...
DS_RAW=$(cat << EOF
{
    "name": "$DS_NAME",
    "type": "$DS_TYPE",
    "url": "$PROM_URL",
    "access": "proxy"
}
EOF
)

curl \
    -X POST \
    --user "$GF_USER_NAME:$GF_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "$DS_RAW" \
    "$GF_URL/api/datasources"
