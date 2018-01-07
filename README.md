# Abar Templates

AbarCloud Openshift templates and image-streams.

## Release
To create/update a single `ImageStream` and related `BuildConfig` run:
```sh
make kibana/6/imagestream.yml
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