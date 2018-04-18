PCF and product tiles Concourse Pipelines:
---

### CAUTION: Pivotal does not provide support for these pipelines. If you find anything broken, then please submit PR's.


### PCF Installation on vSphere Only

-	This pipeline is based on the [vSphere reference architecture](http://docs.pivotal.io/pivotalcf/1-10/refarch/vsphere/vsphere_ref_arch.html)
-	Pre-requisites for using this pipeline are:
	-	4 Networks (One for each of the Infrastructure, Deployment, Services and Dynamic Services)
	-	3 AZ's (vSphere Clusters and/or Resource Pools)
	- Shared storage (Ephemeral and Persistent)
	-	DNS with wildcard domains

**IMPORTANT: If the above vSphere settings do not match your setup, please fork this repository and modify the `tasks/config-opsdir/task.sh` and update the networks and AZ's JSON accordingly**

-----------------------------------------------------------------------------

Following is an example on how to `fly` a pipeline:

```
>	fly -t concourse-[ENV] login -c https://<CONCOURSE-URL> -k
>	fly -t concourse-[ENV] set-pipeline -p install-pcf -c ./pipelines/install/pipeline.yml -l ./pipelines/install/params.yml
>	fly -t concourse-[ENV] unpause-pipeline -p install-pcf
```

![](./pipelines/images/pipeline_new.png)

List of pipelines available in this repository are:
---

-	[New Install of PCF (OM/ERT)](./pipelines/install)
-	[Reinstall of PCF (OM/ERT)](./pipelines/reinstall)
-	[Isolation Segments Installation](./pipelines/tiles/isolation-segments) [**WIP**]
-	[RabbitMQ Installation](./pipelines/tiles/rabbitmq)
-	[Redis Installation](./pipelines/tiles/redis)
-	[Spring Cloud Services Installation](./pipelines/tiles/spring-cloud-services)
-	[MySQL-v1 Installation](./pipelines/tiles/mysql)
-	[MySQL-v2 Installation](./pipelines/tiles/mysql-v2)
-	[PCF Metrics Installation](./pipelines/tiles/pcf-metrics)
- [Healthwatch](./pipelines/tiles/healthwatch)
- [Splunk Nozzle](./pipelines/tiles/splunk-nozzle)
- [New Relic Nozzle](./pipelines/tiles/new-relic-nozzle)
- [New Relic Service Broker](./pipelines/tiles/new-relic-service-broker)
- [Spring Cloud Data Flow](./pipelines/tiles/spring-cloud-data-flow)
-	[Single Signon Installation](./pipelines/tiles/single-signon) [**WIP**]
-	[Upgrade Buildpacks](./pipelines/upgrade-buildpack)
-	[Upgrade Tile](./pipelines/upgrade-tile)
