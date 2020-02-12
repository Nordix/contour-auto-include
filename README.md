# ovl/contour-auto-include

Manages the `includes:` list in Contour `HTTPProxy` objects that
defines a "vhost". This allows applications that handles paths in the
URL to be deployed (and removed) independently. The problem is
outlined in;

* https://github.com/projectcontour/contour/issues/2206



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
of the top object.

HTTPProxy objects without these labels are ignored by contour-auto-include.

