# beaker-google

Beaker library to use the Google hypervisor

# How to use this wizardry

This is a gem that allows you to use hosts with [Google Compute](https://cloud.google.com/compute) hypervisor with [Beaker](https://github.com/voxpupuli/beaker).

Beaker will automatically load the appropriate hypervisors for any given hosts file, so as long as your project dependencies are satisfied there's nothing else to do. No need to `require` this library in your tests.

## With Beaker 4.x

As of Beaker 4.0, all hypervisor and DSL extension libraries have been removed and are no longer dependencies. In order to use a specific hypervisor or DSL extension library in your project, you will need to include them alongside Beaker in your Gemfile or project.gemspec. E.g.

```ruby
# Gemfile
gem 'beaker', '~>4.0'
gem 'beaker-google'
# project.gemspec
s.add_runtime_dependency 'beaker', '~>4.0'
s.add_runtime_dependency 'beaker-google'
```

## Authentication

You must be authenticated to Google Compute Engine to be able to use `beaker-google`. Authentication is attempted in two different ways, and the first that succeeds is used.

- Using the environment variable [`GOOGLE_APPLICATION_CREDENTIALS`](https://cloud.google.com/docs/authentication/production#passing_variable), which points to a file containing the credentials for a GCP service account, created by `gcloud iam service-accounts keys create` (or equivalent).
- Using [Application Default Credentials](https://cloud.google.com/docs/authentication/production).

## Configuration

The behavior of this library can be configured using either the beaker host configuration file, or environment variables.

| configuration option | required | default | description                                                                                                                           |
| -------------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| gce_project          | true     |         | The ID of the Google GCP project to host resources.                                                                                   |
| gce_zone             | true     |         | The zone to place compute instances in. The region is calculated from the zone name.                                                  |
| gce_network          | false    | Default | The name of the network to attach to instances. If the project uses the default network, this and `gce_subnetwork` can be left empty. |
| gce_subnetwork       | false    | Default | THe name of the subnetwork to attach to the instances network interface. If the Default network is not used, this must be supplied.   |

|
|gce_ssh_private_key|false|$HOME/.ssh/google_compute_engine|The file path of the private key to use to connect to instances. If using the key created by the gcloud tool, this can be left blank.|
|gce_ssh_public_key|false|<gce_ssh_private_key>.pub|The file path of the public key to upload to the instance. If left blank, attempt to use the file at `gce_ssh_private_key` with a `.pub` extension.|
|gce_machine_type|false|e2-standard-4|The machine type to use for the instance. If the `BEAKER_gce_machine_type` environment variable is set, it will be used for all hosts.|
|volume_size|false|Source Image disk's size|The size of the boot disk for the image. If unset, the disk will be the same size as the image's boot disk. Provided size must be equal to or larger than the image's disk size.|
|image|true or `family`||The image to use for creating this instance. It can be either in the form `{project}/{image}` to use an image in a different project, or `{image}`, which will look for the image in `gce_project`.|
|family|true or `image`||The image family to use for creating this instance. It can be either in the form `{project}/{family}` to use an image from a family in a different project, or `{family}`, which will look for the image family in `gce_project`. The latest non-deprecated image in the family will be used.|

All the variables in the list can be set in the Beaker host configuration file, or the ones starting with `gce_` can be overridden by environment variables in the form `BEAKER_gce_...`. i.e. To override the `gce_machine_type` setting in the environment, set `BEAKER_gce_machine_type`.

# Contributing

Please refer to voxpupuli/beaker's [contributing](https://github.com/voxpupuli/beaker/blob/master/CONTRIBUTING.md) guide.
