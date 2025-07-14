





```
apiVersion: v1
kind: Namespace
metadata:
  name: green
  labels:
    k8s.ovn.org/primary-user-defined-network: ""
```





```
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: namespace-scoped
  namespace: green
spec:
  topology: Layer2
  layer2:
    role: Primary
    subnets:
      - 203.203.0.0/16
    ipam:
      lifecycle: Persistent
```


`oc get pods -ngreen webserver -ojsonpath="{@.metadata.annotations.k8s.\.v1\.cni\.cncf\.io\/network-status}" | jq`

`virtctl console -ngreen vm-a`

`virtctl migratre -ngreen vm-b`

