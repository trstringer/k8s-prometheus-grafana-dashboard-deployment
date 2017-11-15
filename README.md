# Prometheus/Grafana/Dashboard to Kubernetes

1. `$ helm install --name monitoring -f prometheus_values.yaml stable/prometheus`
1. `$ helm install --name dashboard stable/grafana`
1. Wait for the Prometheus server and Grafana pods to come up
1. `$ kubectl port-forward <dashboard-grafana*_pod> 3000:3000`
1. `$ ./create_datasource.sh` (creates the Prometheus datasource in the Grafana instance)
1. `$ ./create_dashboard.sh` (pulls down the [grafana.com Kubernetes dashboard](https://grafana.com/dashboards/315))
1. Navigate to `localhost:3000` in your browser
1. Use login username `admin` and to retrieve the password run `$ kubectl get secret dashboard-grafana -o jsonpath="{.data.grafana-user-password}" | base64 --decode` as the password
1. View the Kubernetes dashboard
