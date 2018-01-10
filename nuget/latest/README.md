# abar-nuget

This project provides a NuGet feed based on [this](https://github.com/Daniel15/simple-nuget-server/) and [this](https://github.com/sunsided/docker-nuget). It runs on top of the official [nginx](https://github.com/docker-library/docs/tree/master/nginx) image.

NuGet packages currently are allowed to have a maximum size of 50 MB on upload.

## Deploying on AbarCloud

1. Login to AbarCloud dashboard and browse to your project.
2. Click on Add to Project and under Technologies, click on Data Stores.
3. Click on nuget, fill in the form, and click on Create.
4. Click on Continue to overview, you'll need the following details to use NuGet:
- Goto Applications > Routes to get the NuGet URL, which uses SSL.
- Goto Applications > Deployments > nuget > Environment to get the NuGet API key.

## Building the image

To build the image named `nuget`, execute the following command:

```bash
docker build -t nuget .
```

At build time, a random API key is generated and printed out to the console. Note that this implies that every new image has a different *default* API key.

## Running the image

To run a container off the `nuget` image, execute the following command:

```bash
docker run -d -p 80:8080 \
           -e NUGET_API_KEY=ABC \
           -v /tmp/db:/var/www/db \
           -v /tmp/packagefiles:/var/www/packagefiles \
           nuget
```

Note that some NuGet clients might be picky about the port, so be sure to have your feed available on either port `80` or `443`, e.g. by having a reverse proxy in front on the container.

### Environment configuration

* `NUGET_API_KEY` sets the NuGet feed's API key to your own private key
* `BASE_URL` sets the base path of the feed, e.g. `/nuget` if it is available under `https://your.tld/nuget/`

### Exported volumes

* `/var/www/db` contains the SQLite database
* `/var/www/packagefiles` contains uploaded the NuGet packages

## NuGet configuration

In order to push a package to your new NuGet feed, use the following command:

```bash
nuget push -Source https://url.to/your/feed/ -ApiKey <your secret> path/to/package.nupkg
```

Deleting package version `<Version>` of package `<Package>` is done using

```bash
nuget delete -Source https://url.to/your/feed/ -ApiKey <your secret> <Package> <Version>
```

Listing packages including prereleases can be done using

```bash
nuget list -Source https://url.to/your/feed/ -Prerelease
```

If you don't already have a `NuGet.config` file, you can create it as follows:
```
<?xml version="1.0" encoding="utf-8"?>
<configuration>
</configuration>
```

You can then add your feed to a specific `NuGet.config` file using:

```bash
nuget sources add -Name "Your Feed's Name" -Source https://url.to/your/feed/ -ConfigFile NuGet.config
```

In order to store the API key in a specific `NuGet.config` file you can use:

```bash
nuget setapikey -Source https://url.to/your/feed/ -ConfigFile NuGet.config
```

This will create or update the `apikeys` section of your configuration file. Make sure to not check anything sensitive into source control.

In both cases, if you omit the `-ConfigFile <file>` option, your user configuration file will be used.

## License

This project is licensed under the MIT license. See the `LICENSE` file for more information.
