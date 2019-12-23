name             'ganeti_webmgr'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
source_url       'https://github.com/osuosl-cookbooks/ganeti_webmgr'
issues_url       'https://github.com/osuosl-cookbooks/ganeti_webmgr/issues'
license          'Apache-2.0'
chef_version     '>= 14.0'
description      'Installs/Configures Ganeti Web Manager'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.1.0'

depends          'apache2', '~> 4.0.0'
depends          'build-essential'
depends          'chef_nginx'
depends          'git'
depends          'hostsfile'
depends          'openssl'
depends          'poise-python'
# runit >= 5.0.0 requires chef >= 14. This allows backward-compatible with chef 13
depends          'runit', '~> 4.3.1'
depends          'selinux_policy'
depends          'sqlite'

supports         'centos', '~> 6.0'
