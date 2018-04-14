# Abar Templates

AbarCloud OpenShift templates and image-streams.

## How to customize?
To customize a template and publish in your project:

1. Fork this repository.
2. Set your namespace (i.e. project name) and repository URL in `.makerc.dist`
3. Customize any of the templates.
4. Make sure you are logged in via [`oc` CLI](https://docs.abarcloud.com/management/cli-login.html).
5. Use `make` to upload the template (e.g. `redis`) to your project.
   ```sh
   make redis/
   ```
6. From AbarCloud dashboard > Add to Project, find your template e.g. by searching it's name.  
   Notice the **Namespace: my-project** in template description, to find your customized version.

* After pushing your changes you must manually `Start build`

#### Make is not installed?
If `make` utility is not installed by default on your OS, install it:
* For [Ubuntu](https://askubuntu.com/a/272020), or [CentOS/RHEL](https://stackoverflow.com/a/1539224) 
* For [Windows](http://gnuwin32.sourceforge.net/packages/make.htm)

## Development
To create all Templates, BuildConfigs and (customized) ImageStreams in your own namespace (i.e. project) copy `.makerc.dist` as `.makerc` and specify your project name, repository URL and the branch.

## Release
To create/update a single `ImageStream` and related `BuildConfig` run:
```sh
make kibana/latest/imagestream.yml
```
To create/update a single `Template` run:
```sh
make redis/redis-single-node.yml
```

To create/update all `ImageStream`s and `BuildConfig`s run:
```sh
make imagestreams
```

To create/update all `Template`s run:
```sh
make templates
```

### MIT License
AbarCloud loves open-source and contributing back to the community.
