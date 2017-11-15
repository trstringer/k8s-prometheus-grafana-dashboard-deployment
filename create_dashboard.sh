#!/bin/bash

K8S_SECRET_NAME=dashboard-grafana
GF_USER_NAME=$(kubectl get secret $K8S_SECRET_NAME -o jsonpath="{.data.grafana-admin-user}" | base64 --decode)
GF_PASSWORD=$(kubectl get secret $K8S_SECRET_NAME -o jsonpath="{.data.grafana-admin-password}" | base64 --decode)
# DS_URL is currently localhost from k8s port-forwarding to test this locally
GF_URL=localhost:3000

DB_RAW=$(cat << EOF
{
    "dashboard": $(curl -sL "https://grafana.com/api/dashboards/315/revisions/3/download" | ./sanitize_dashboard.py),
    "overwrite": false
}
EOF
)

curl \
    -X POST \
    --user "$GF_USER_NAME:$GF_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "$DB_RAW" \
    "$GF_URL/api/dashboards/db"
