PCF product tiles Concourse Pipelines:
---

### CAUTION: Pivotal does not provide support for these pipelines. If you find anything broken, then please submit a PR.

-----------------------------------------------------------------------------

Following is an example on how to `fly` a pipeline:

```
>	fly -t concourse-[ENV] login -c https://<CONCOURSE-URL> -k
>	fly -t concourse-[ENV] set-pipeline -p install-redis -c ./pipelines/tiles/redis/pipeline.yml -l ./var-files/tiles/sandbox/redis/params.yml
>	fly -t concourse-[ENV] unpause-pipeline -p install-pcf
```

![](./pipelines/images/pipeline_new.png)

List of pipelines available in this repository are:
---

-	[Isolation Segments Installation](./pipelines/tiles/isolation-segments) [**WIP**]
-	[RabbitMQ Installation](./pipelines/tiles/rabbitmq)
-	[Redis Installation](./pipelines/tiles/redis)
-	[Spring Cloud Services Installation](./pipelines/tiles/spring-cloud-services)
-	[MySQL-v1 Installation](./pipelines/tiles/mysql)
-	[MySQL-v2 Installation](./pipelines/tiles/mysql-v2)
-	[PCF Metrics Installation](./pipelines/tiles/pcf-metrics)
- [Healthwatch](./pipelines/tiles/healthwatch)
- [Splunk Nozzle](./pipelines/tiles/splunk-nozzle)
- [New Relic Nozzle](./pipelines/tiles/newrelic-nozzle)
- [New Relic Service Broker](./pipelines/tiles/newrelic-service-broker)
- [Spring Cloud Data Flow](./pipelines/tiles/spring-cloud-dataflow)
-	[Single Signon Installation](./pipelines/tiles/single-signon) [**WIP**]
-	[Upgrade Buildpacks](./pipelines/upgrade-buildpack)
-	[Upgrade Tile](./pipelines/upgrade-tile)
