## Refer to the /pipelines README for more instructions

Now you can execute the following commands:

* `fly -t lite login`
* `fly -t lite set-pipeline -p pcf -c ./pipelines/new-setup/pipeline.yml -l ./pipelines/params.yml`
* `fly -t lite unpause-pipeline -p pcf`

![](./pipelines/images/pipeline.png)
