# Using the Google Compute Engine Provisioner

This [Beaker](https://github.com/puppetlabs/beaker) provisioner manages instances from pre-existing [Google Compute Engine](https://cloud.google.com/compute) images.

Currently supported [GCE images](https://cloud.google.com/compute/docs/images#os-compute-support) include:
  * Debian
  * CentOS
  * Red Hat Enterprise Linux

## Prerequisites

  * A [Google Compute Engine project](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
  * An active [service account](https://cloud.google.com/compute/docs/access/service-accounts)
    to your Google Compute Engine project, along with the following
    information:
    * The service account **private key file** (named xxx-privatekey.p12).
    * The service account **email address** (named xxx@developer.gserviceaccount.com).
    * The service account **password**.
    * A **ssh keypair**, [set up for GCE](https://developers.google.com/compute/docs/console#sshkeys)
      * Load the private key into your `ssh-agent` prior to running Beaker (or
        leave off a password, but this is not recommended)
      * Name the pair `google_compute_engine`
        * You can tell Beaker to use a different public key by setting `BEAKER_gce_ssh_public_key` to the path of your public key file
      * Place the [public key](https://git-scm.com/book/gr/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key) in your Google Compute Engine [project metadata](https://cloud.google.com/compute/docs/storing-retrieving-metadata)
        * `key`: `sshKeys`
        * `value` is the contents of your `google_compute.pub` with `google_compute:` _prepended_, eg: `google_compute:ssh-rsaAAA(...) user@machine.local`

## Setting Up Beaker

You are now ready to set up the Beaker [nodeset](https://github.com/puppetlabs/beaker-rspec#typical-workflow) for your GCE instances

### Example GCE Hosts File

  ```yaml
  HOSTS:
    debian-7-master:
      roles:
        - server
        - master
        - agent
      platform: debian-7-x86_64
      hypervisor: google
      # The GCE image name to use
      image: debian-7-XXXX

    centos-6-agent:
      roles:
        - agent
      platform: el-6-x86_64
      hypervisor: google
      # The GCE image name to use
      image: centos-6-XXXX
      # The GCE Machine type to use
      gce_machine_type: n1-highmem-2

    redhat-7-agent:
      roles:
        - agent
      platform: el-7-x86_64
      hypervisor: google
      # The GCE image name to use
      image: redhat-7-XXXX

  CONFIG:
    type: aio

    # Optional: The number of seconds to attempt execution and then quit
    timeout: 10

    # You don't have to specify this if you set the environment variable
    # BEAKER_gce_project
    gce_project: google-compute-project-name

    # Service account key
    #
    # If not defined, this key will try to be found at
    #  $HOME/.beaker/gce/project-name.p12
    #
    # You can also specify the key using the environment variable
    # BEAKER_gce_keyfile
    gce_keyfile: /path/to/*****-privatekey.p12

    # This is almost always the same!
    #
    # You don't have to specify this unless you have a custom 'gce_password'
    #
    # You can also specify this by setting the environment variable
    # BEAKER_gce_password
    gce_password: notasecret

    # Service account email
    #
    # You don't have to specify this if you set the environment variable
    # BEAKER_gce_email
    gce_email: *********@developer.gserviceaccount.com
  ```

Google Compute cloud instances and disks are deleted after test runs, but it is
up to the owner of the Google Compute Engine project to ensure that any zombie
instances/disks are properly removed should Beaker fail during cleanup.

**NOTE:** If zombie resources are left in GCE the code helps you identify runs
that have not been cleaned up by prefixing all of the assets with the **same**
identifier that follows the pattern of `beaker-TIMESTAMP`.

### Tips and Tricks

To most easily use this plugin with GCE projects, you may want to do the following:

1. `mkdir -p $HOME/.beaker/gce`
2. `cd $HOME/.beaker/gce`
3. Add the following to a file named `config` with your values in place

   ```bash
   export BEAKER_gce_ssh_public_key="$HOME/.beaker/gce/rsa.pub"
   export BEAKER_gce_project='my-beaker-tests'
   export BEAKER_gce_keyfile="$HOME/.beaker/Beaker_Testing.p12"
   export BEAKER_gce_email='myuser@my-beaker-tests.iam.gserviceaccount.com'
   ```

4. Copy your testing account `p12` file into `$HOME/.beaker/gce/Beaker_Testing.p12`
5. Run your test after running `source $HOME/.beaker/gce/config`
