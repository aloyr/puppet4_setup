# puppet4_setup

Purpose
=======

This script sets up a starting Puppet 4.x server, also configuring PuppetDB and Spotify's PuppetExplorer.

Additionally, it provides an easy way to configure puppet clients with the latest version of puppet off of puppetlabs' repositories. This works for OSX, debian, rhel and fedora like OSs.

To install clients, use the following:

```
curl -s https://raw.githubusercontent.com/aloyr/puppet4_setup/master/puppet_client_setup.bash -o ${HOME}/puppet_client_setup.bash && chmod +x ${HOME}/puppet_client_setup.bash && sudo ${HOME}/puppet_client_setup.bash
```
