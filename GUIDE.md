# Migration Guide: Using Configuration Management with Terraform

Configuration management tools install and manage software on a machine that already exists. Terraform is
not a configuration management tool, but can create machines that you then use with configuration
management.

In order to migrate from using the now-deprecated vendor-specific provisioners (Chef, Puppet, Habitat, and
Salt-Masterless), you'll need to modify your configuration to remove the reliance on these provisioners.

This guide focuses on migrating from your current approach to a similar one using the native `file` and 
`remote-exec` provisioners. However, there are other, preferred, approaches to initializing resources rather than using `provisioner` blocks, including leveraging Packer, cloud-init, providers or user_data for initalizing your instances. You can find out more about these approaches at HashiCorp Learn.

## Running configuration management on the remote machine

The vendor-specific provisioners install a configuration management agent on the remote machine,
and (if applicable) copy local files to the remote instance to be used for configuration management.
In this guide, we will use the `salt-masterless` provisioner as an example to replace with native
provisioners.

### Using `file` and `remote-exec` to run configuration management

There are a few steps to running configuration management on your remote machine:

1. Install any necessary software for running your configuration management (`remote-exec`)
1. Copy your configuration to the remote instance (`file`)
1. Execute your configuration management tooling (`remote-exec`)

