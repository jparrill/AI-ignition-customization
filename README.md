# AI-ignition-customization

On Image Mirroring step
- You need to modify:
    - PULL_SECRET=`<Path to your PULL_SECRET FILE>`
    - INTERNAL_REG=`<LOCAL REGISTRY_URL>:<LOCAL REGISTRY_PORT>`

On Cluster and Image modification step
- You need to modify:
    - `ignition_files/files/domain.crt`: With the concrete registry Certificate
    ```
    cp /opt/registry/certs/domain.crt ./ignition_files/files/domain.crt
    ```
    - `ignition_files/files/registry.conf`: With the destination registry name
    ```
    sed -i s/local.registry:5000/<REGISTRY_URL>:<REGISTRY_PORT>/g ./ignition_files/files/registry.conf
    ```


- To Mirror all the images against your local registry
```
bash image_sync.sh
```

- To execute the API calls agains your IPv6 AI instance
```
bash disconnnected_config_apply.sh 89deb009-331b-440e-9d82-f2efb0e28b66
```
