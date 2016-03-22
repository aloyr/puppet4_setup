#!/bin/bash
echo "creating puppet group and user"
useradd -r -g puppet puppet
echo "prepping server..."
rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum install -y puppet{-agent,server}
echo 'PATH="$PATH:/opt/puppetlabs/bin"' > /etc/profile.d/puppet.sh
/opt/puppetlabs/bin/puppet module install saz-timezone
/opt/puppetlabs/bin/puppet module install puppetlabs-puppetdb
/opt/puppetlabs/bin/puppet module install spotify-puppetexplorer
if [ $(grep puppet /etc/hosts | wc -l) -eq 0 ]; then
  sed -i.bak 's/'$(hostname)'/puppet puppetdb '$(hostname)'/' /etc/hosts
fi

echo "running puppet for the 1st time..."
/opt/puppetlabs/bin/puppet resource service puppetserver.service ensure=running enable=true
/opt/puppetlabs/bin/puppet agent -t

echo "setting up puppetdb"
FOLDER="$(/opt/puppetlabs/bin/puppet config print codedir)/environments/production/modules/common_setup/manifests"
mkdir -p $FOLDER
FILE="$FOLDER/init.pp"
if [ ! -f $FILE ]; then
  cat << 'EOT' > $FILE
class common_setup {
  if $is_puppetserver {
    class {'common_setup::puppetdb': }
  }
}
EOT
fi

FILE="$FOLDER/puppetdb.pp"
if [ ! -f $FILE ]; then
  cat << 'EOT' > $FILE
class common_setup::puppetdb {
  class {'puppetdb': 
    listen_address => '0.0.0.0',
  }
  class {'puppetdb::master::config': }
}
EOT
fi

FILE="$FOLDER/puppetexplorer.pp"
if [ ! -f $FILE ]; then
  cat << 'EOT' > $FILE
class common_setup::puppetexplorer {
  class {'puppetexplorer': }
}
EOT
fi

FOLDER="$(/opt/puppetlabs/bin/puppet config print codedir)/environments/production/modules/common_setup/lib/facter"
mkdir -p $FOLDER
FILE="$FOLDER/is_puppetserver.rb"
if [ ! -f $FILE ]; then
  cat << 'EOT' > $FILE
require 'facter'

# Default for non-Linux nodes
#
Facter.add(:is_puppetserver) do
    setcode do
        nil
    end
end

# Linux
#
Facter.add(:is_puppetserver) do
    confine :kernel  => :linux
    setcode do
        FileTest.exists?("/etc/puppetlabs/puppetserver")
    end
end
EOT
fi

echo "creating site manifest..."
FOLDER="$(/opt/puppetlabs/bin/puppet config print codedir)/environments/production/manifests"
FILE="$FOLDER/site.pp"
if [ ! -f $FILE ]; then
  cat << 'EOT' > $FILE
node 'default' {
  class {'common_setup': }
}
EOT
fi

echo "re-running puppet agent"
/opt/puppetlabs/bin/puppet agent -t
/opt/puppetlabs/bin/puppetdb ssl-setup -f
useradd -g puppetdb puppetdb
/opt/puppetlabs/bin/puppet agent -t
systemctl daemon-reload
systemctl enable puppetserver.service
systemctl restart puppetserver.service

echo "setting up puppet explorer"
FOLDER="$(/opt/puppetlabs/bin/puppet config print codedir)/environments/production/modules/common_setup/manifests"
FILE="$FOLDER/init.pp"
if [ $(grep puppetexplorer $FILE | wc -l) -eq 0 ]; then
  sed -i.bak 's/\(class.*common_setup::puppetdb.*\)/\1\n    class {'"'"'common_setup::puppetexplorer'"'"': }/g' $FILE
  /opt/puppetlabs/bin/puppet agent -t
fi
