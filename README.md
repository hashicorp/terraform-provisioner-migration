# Provisioner migration examples

If you're currently using one of the four builtin vendor provisioners:
chef, habitat, puppet, or salt-masterless, this repository has some
basic examples to help you migrate off of these to the core provisioners
of local-exec, remote-exec, and the file provisioner.

The examples in this repository are not meant to be exhaustive, but 
to help you get your configurations into a state to remove dependencies
on these deprecated components.
