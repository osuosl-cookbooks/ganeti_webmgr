name             'ganeti_webmgr'
maintainer       'Oregon State University'
maintainer_email 'chance@osuosl.org'
license          'All rights reserved'
description      'Installs/Configures Ganeti Web Manager'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.4.14'
source_url       'https://github.com/osuosl-cookbooks/ganeti_webmgr'
issues_url       'https://github.com/osuosl-cookbooks/ganeti_webmgr/issues'
depends          'apt'
depends          'build-essential'
depends          'python'
depends          'git'
depends          'nginx'
depends          'openssl'
depends          'osl-mysql'
depends          'postgresql'
depends          'sqlite'
depends          'database'
depends          'hostsfile'
depends          'apache2'
depends          'runit'
depends          'yum', '> 3.0.0'
supports         'centos','~> 6.0'
supports         'centos','~> 7.0'

