default['ganeti_webmgr']['path'] = "/opt/ganeti_webmgr_src"
default['ganeti_webmgr']['user'] = nil
default['ganeti_webmgr']['group'] = nil

default['ganeti_webmgr']['repository'] = "https://github.com/osuosl/ganeti_webmgr"
default['ganeti_webmgr']['revision'] = "develop"

case node['platform']
when 'redhat', 'centos', 'fedora', 'amazon', 'scientific'
  default['ganeti_webmgr']['packages'] = ['libffi-devel']
when 'debian', 'ubuntu'
  default['ganeti_webmgr']['packages'] = ['libffi-dev']
else
  default['ganeti_webmgr']['packages'] = []
end

default['ganeti_webmgr']['install_dir'] = '/opt/ganeti_webmgr'
default['ganeti_webmgr']['config_dir'] = '/opt/ganeti_webmgr/config'

default['ganeti_webmgr']['static_root'] = '/opt/ganeti_webmgr/collected_static'
default['ganeti_webmgr']['static_url'] = '/static'

default['ganeti_webmgr']['debug'] = false
default['ganeti_webmgr']['migrate'] = false
default['ganeti_webmgr']['site_domain'] = node['fqdn']

default['ganeti_webmgr']['haystack_whoosh_path'] = '/opt/ganeti_webmgr/whoosh_index'

default['ganeti_webmgr']['database']['engine'] = nil
# Load the DB Credentials using the databag as defaults.
default['ganeti_webmgr']['database']['name'] = nil
default['ganeti_webmgr']['database']['user'] = nil
default['ganeti_webmgr']['database']['password'] = nil
default['ganeti_webmgr']['database']['host'] = nil
default['ganeti_webmgr']['database']['port'] = nil

default['ganeti_webmgr']['superusers'] = []

default['ganeti_webmgr']['host'] = node['fqdn']
default['ganeti_webmgr']['port'] = 8000

default['ganeti_webmgr']['hostsfile'] = {}

default['ganeti_webmgr']['vnc_proxy'] = "#{node['fqdn']}:8888"

default['nginx']['default_site_enabled'] = false

default['ganeti_webmgr']['application_name'] = 'ganeti_webmgr'
default['ganeti_webmgr']['apache']['server_name'] = node['hostname']
default['ganeti_webmgr']['apache']['user'] = nil
default['ganeti_webmgr']['apache']['group'] = nil
default['ganeti_webmgr']['apache']['server_aliases'] = [node['fqdn']]

default['ganeti_webmgr']['apache']['processes'] = 4
default['ganeti_webmgr']['apache']['threads'] = 1

# secrets

default['ganeti_webmgr']['secret_key'] = nil
default['ganeti_webmgr']['web_mgr_api_key'] = nil

default['ganeti_webmgr']['db_server']['user'] = nil
default['ganeti_webmgr']['db_server']['password'] = nil

# VNC AuthProxy
default['ganeti_webmgr']['vncauthproxy']['port'] = "8888"
default['ganeti_webmgr']['vncauthproxy']['ip'] = "0.0.0.0"

default['ganeti_webmgr']['vncauthproxy']['flashpolicy_enabled'] = true

