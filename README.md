# Provisioner Migration Guide

Configuration management tools install and manage software on a machine that already exists. Terraform is
not a configuration management tool, but can create machines that you then use with configuration
management.

In order to migrate from using the now-deprecated vendor-specific provisioners (`chef`, `habitat`, `puppet`, or `salt-masterless`), you'll need to modify your configuration to remove the reliance on these provisioners.

This guide focuses on migrating from your current approach to a similar one using the native `file` and 
`remote-exec` provisioners. However, there are other, preferred, approaches to initializing resources rather than using `provisioner` blocks, including leveraging Packer, cloud-init, providers or user_data for initalizing your instances. You can find out more about these approaches on [HashiCorp Learn](https://learn.hashicorp.com/terraform).

## Running configuration management on the remote machine

The vendor-specific provisioners install a configuration management agent on the remote machine,
and (if applicable) copy local files to the remote instance to be used for configuration management.
In this guide, we will use the `salt-masterless` provisioner as an example to replace with native
provisioners.

> The process described in this guide is how to run configuration management _on_ the remote machine, but if you are not yet in this scenario, it's highly encouraged you seek other ways to manage your machines. For example, one option is you can run configuration management using `local-exec` to run configuration management on your own machine rather than on the remote. This removes the need for the permissive network access required in order to make `remote-exec` connections.

There are a few steps to running configuration management on your remote machine:

1. Install any necessary software for running your configuration management (`remote-exec`)
1. Copy your configuration to the remote instance (`file`)
1. Execute your configuration management tooling (`remote-exec`)

You may choose to combine the `remote-exec` steps into one block, but the essentials remain the same.


## Example: Replacing `salt-masterless` with `file` and `remote-exec`

In our example code, we will replace the following provisioner with the combination of `remote-exec` and `file`:

```terraform
provisioner "salt-masterless" {
   local_state_tree  = "${path.root}/salt"
   remote_state_tree = "/srv/salt"
}
```

We are assuming you are replacing this provisioner that is already functioning, meaning you have a working `connection` block and are able to access your remote instance with simple `remote-exec` commands. In the example in this repository, the necessary network infrastructure enabling this is broken out into a separate module to make our example code easier to read.

The [`local_state_tree`](https://www.terraform.io/docs/provisioners/salt-masterless.html#local_state_tree) is the path of your [local state tree](https://docs.saltstack.com/en/latest/ref/states/highstate.html#the-salt-state-tree), the collection of SLS (.sls) files Salt will use. The `remote_state_tree` is where the state tree will be on the target server.

We need to get our local state tree onto the remote instance. We will do that by using the `file` provisioner:

```
provisioner "file" {
  source      = "${path.root}/salt"
  destination = "/tmp/salt"
}
```

Note that we are putting the state tree into a temporary location, but we can move it in the later `remote-exec` step.

Now that our .sls files will be on the instance, our `remote-exec` block will do the rest of the work:

- Install and bootstrap Salt
- Set-up the remote state tree (moving from /tmp to its remote location)
- Run Salt

```terraform
provisioner "remote-exec" {
  inline = [
    "curl -L https://bootstrap.saltstack.com | sudo sh",    # Install and bootstrap salt
    "sudo rm -rf /srv/salt", # Remove directory /srv/salt to ensure it is clear
    "sudo mv /tmp/salt /srv/salt", # Move state tree from temporary directory to /srv/salt
    "sudo salt-call --local  state.highstate --file-root=/srv/salt --pillar-root=/srv/pillar --retcode-passthrough -l info"     # Run salt-call
  ]
}
```

You can mimic other options provided by the `salt-masterless` provisioner by modifying these core components of using the `file` and `remote-exec` provisioner.