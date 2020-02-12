# contour-auto-include

Manages the `includes:` list in Contour `HTTPProxy` objects that
defines a "vhost". This allows applications that handles paths in the
URL to be deployed (and removed) independently. The problem is
outlined in;

* https://github.com/projectcontour/contour/issues/2206

Install with;
```
kubectl apply -f https://github.com/Nordix/contour-auto-include/raw/master/contour-auto-include.yaml
```

## Labels

`contour-auto-include` will only handle `HTTPProxy` objects with
defined labels;

```
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: kahttp-vhost
  labels:
    example.com/vhost: "yes"
spec:
  virtualhost:
    fqdn: kahttp.com
    tls:
      secretName: contour-secret
  includes:
    - name: kahttp-default
---
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: kahttp-default
  labels:
    example.com/parent: kahttp-vhost
spec:
  routes:
    - conditions:
      - prefix: /
      services:
        - name: kahttp-ipv4
          port: 80
```

The `example.com/vhost: "yes"` makes contour-auto-include recognise
this as a "top" object to handle. The `example.com/parent: kahttp-vhost`
in the sub-object makes contour-auto-include add this in the include: array
of the top object. The prefix "example.com/" can be altered in the manifest.

HTTPProxy objects without these labels are ignored by contour-auto-include.


## Implementation

The [contour-auto-include.sh](image/bin/contour-auto-include.sh)
script can be executed outside a POD to update the `includes:` arrays.

```
$ ./image/bin/contour-auto-include.sh

 contour-auto-include.sh --


 Commands;

  env
    Print environment.

  get_path_objects [--namespace=default] <parent>
    Get path objects for a parent.
  get_top_objects
    Get top objects from all namespaces in form "namespace/name".
  emit_include_list [--namespace=default] <top-object>
    Emit an "includes:" array for a given top-object

  update [--interval=<secons>]
    Update the "includes:" array in all vhost objects.
    If --interval is specified this command will not return but update
    continuously with the given interval.
```

