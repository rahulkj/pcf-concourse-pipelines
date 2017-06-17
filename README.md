NOTES:
------

-	This pipeline is based on the [vSphere reference architecture](http://docs.pivotal.io/pivotalcf/1-10/refarch/vsphere/vsphere_ref_arch.html)
-	Pre-requisites for using this pipeline are:
	-	4 Networks (One for each of the Infrastucture, Deployment, Services and Dynamic Services)
	-	Minimum of 3 AZ's
	-	DNS with wildcard domains

<span style="color:red">IMPORTANT: If the above vSphere settings do not match your setup, please fork this repository and modify the `tasks/config-opsdir/task.sh` and update the networks and AZ's JSON accordingly</span>

Refer to the /pipelines [README](./pipelines/README.md) for more instructions
-----------------------------------------------------------------------------

Now you can execute the following commands:

-	`fly -t lite login -c https://<CONCOURSE-URL>:8080`
-	`fly -t lite set-pipeline -p pcf -c ./pipelines/new-setup/pipeline.yml -l ./pipelines/new-setup/params.yml`
-	`fly -t lite unpause-pipeline -p pcf`

![](./pipelines/images/pipeline_new.png)

Supported pipelines
-------------------

-	[New Install of PCF (OM/ERT)](./pipelines/new-setup)
-	[New Install of PCF with JMX Bridge](./pipelines/new-setup-with-jmx-bridge)
-	[Reinstall of PCF (OM/ERT)](./pipelines/reinstall)
-	[Isolation Segments Installation](./pipelines/config-tile/isolation-segments)
-	[RabbitMQ Installation](./pipelines/config-tile/rabbitmq)
-	[Upgrade Buildpacks](./pipelines/upgrade-buildpack)
-	[Upgrade Tile](./pipelines/upgrade-tile)
