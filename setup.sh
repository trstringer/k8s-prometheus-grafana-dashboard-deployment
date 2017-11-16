#!/bin/bash

update_helm() {
    echo "Updating Helm repositories"
    helm repo update
}

install_prometheus() {
    PROM_RELEASE_NAME=monitoring
    NAMESPACE=$1

    echo "Installing the Prometheus Helm chart"
    helm install -f prometheus_values.yaml \
        --name $PROM_RELEASE_NAME \
        --namespace $NAMESPACE stable/prometheus

    PROM_POD_PREFIX="$PROM_RELEASE_NAME-prometheus-server"
    DESIRED_POD_STATE=Running

    ATTEMPTS=30
    SLEEP_TIME=10

    ITERATION=0
    while [[ $ITERATION -lt $ATTEMPTS ]]; do
        echo "Is the prometheus server pod ($PROM_POD_PREFIX-*) running? (attempt $(( $ITERATION + 1 )) of $ATTEMPTS)"

        kubectl get po -n $NAMESPACE --no-headers |
            awk '{print $1 " " $3}' |
            grep $PROM_POD_PREFIX |
            grep -q $DESIRED_POD_STATE

        if [[ $? -eq 0 ]]; then
            echo "$PROM_POD_PREFIX-* is $DESIRED_POD_STATE"
            break
        fi

        ITERATION=$(( $ITERATION + 1 ))
        sleep $SLEEP_TIME
    done
}

install_grafana() {
    GF_RELEASE_NAME=dashboard
    NAMESPACE=$1

    echo "Installing the Grafana Helm chart"
    helm install --name $GF_RELEASE_NAME --namespace $NAMESPACE stable/grafana

    GF_POD_PREFIX="$GF_RELEASE_NAME-grafana"
    DESIRED_POD_STATE=Running

    ATTEMPTS=30
    SLEEP_TIME=10

    ITERATION=0
    while [[ $ITERATION -lt $ATTEMPTS ]]; do
        echo "Is the grafana pod ($GF_POD_PREFIX-*) running? (attempt $(( $ITERATION + 1 )) of $ATTEMPTS)"

        kubectl get po -n $NAMESPACE --no-headers |
            awk '{print $1 " " $3}' |
            grep $GF_POD_PREFIX |
            grep -q $DESIRED_POD_STATE

        if [[ $? -eq 0 ]]; then
            echo "$GF_POD_PREFIX-* is $DESIRED_POD_STATE"
            break
        fi

        ITERATION=$(( $ITERATION + 1 ))
        sleep $SLEEP_TIME
    done
}

NAMESPACE=default

update_helm
install_prometheus $NAMESPACE
install_grafana $NAMESPACE

# sleep for a few seconds just to give the grafana instance some buffer time
sleep 5
GF_POD_NAME=$(kubectl get po -n $NAMESPACE -l "component=grafana" -o jsonpath="{.items[0].metadata.name}")
GF_PORT=3000
echo "Forwarding Grafana port $GF_PORT to localhost in a background job"
kubectl port-forward $GF_POD_NAME $GF_PORT:$GF_PORT &

echo "Creating the Prometheus datasource in Grafana"
./create_datasource.sh

echo "Creating the Kubernetes dashboard in Grafana"
./create_dashboard.sh

echo "Navigate to localhost:3000 to login to Grafana"

echo ""
read -n1 -r -p "Press any key to stop port forwarding and complete setup..."

kill %1
exit
