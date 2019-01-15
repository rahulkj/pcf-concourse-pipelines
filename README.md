PCF product tiles Concourse Pipelines:
---

> **CAUTION:** Pivotal does not provide support for these pipelines.
> If you find anything broken, then please submit a PR.

### Pipelines available in this repository are:

This repository provides the pipelines for the products listed in the following table.

The pipeline for the tiles is common and is located [here](./pipelines/install-product)

| PRODUCT | VERSION | PIPELINE LOCATION |
| -- | -- | -- |
| All tiles | any | [Install Product Tile](./pipelines/install-product)
|	Upgrade Buildpacks | any | [Upgrade Buildpacks](./pipelines/upgrade-buildpack)


Use the template to write your own pipeline. [Install Product Tile Template](./pipelines/install-product)

## Before you begin

- Copy the [params-template.yml](./pipelines/install-product/params-template.yml) file to a new folder, for ex:
```
mkdir -p sandbox/healthwatch
cp ./pipelines/install-product/params-template.yml sandbox/healthwatch/params.yml
```

- Edit the `params.yml` and add the details for the product, and the version details. You can ignore the `product_config` section and fetch the details by running the `generate-config-product` job once the tile has been staged via the pipeline

- Update the information in the [globals.yml](./pipelines/globals.yml)

- Store all the secrets in the credential manager used by concourse (credhub or vault)

---
### Following is an example on how to `fly` a pipeline:

```
>	fly -t concourse-[ENV] login -c https://<CONCOURSE-URL> -k
>	fly -t concourse-[ENV] set-pipeline -p healthwatch \
        -c ./pipelines/install-product/pipeline.yml \
        -l ./sandbox/healthwatch/params.yml \
        -l ./pipelines/globals.yml
>	fly -t concourse-[ENV] unpause-pipeline -p healthwatch
```

![](./images/pipeline.png)

If you wish to use your own docker images in the `task.yml` files, then the original docker file is located under the `ci` folder. [ci/Dockerfile](./ci/Dockerfile)
