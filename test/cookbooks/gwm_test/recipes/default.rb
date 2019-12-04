passwords = data_bag_item('ganeti_webmgr', 'passwords')
db_host = node['ganeti_webmgr']['database']['host']
server_user = node['ganeti_webmgr']['db_server']['user'] || passwords['db_server']['user']
server_password = node['ganeti_webmgr']['db_server']['password'] || passwords['db_server']['password']
db_user = node['ganeti_webmgr']['database']['user']
db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']

node.default['mariadb']['server_root_password'] = server_password
node.default['mariadb']['use_default_repository'] = true

build_essential 'gwm'

mariadb_server_install 'default' do
  password server_password
  version '10.1' # required for CentOS 6
  action [:install, :create]
end

package 'MariaDB-devel'

mariadb_database node['ganeti_webmgr']['database']['name'] do
  host db_host
  user server_user
  password server_password
end

mariadb_user db_user do
  database_name node['ganeti_webmgr']['database']['name']
  ctrl_password server_password
  password db_pass
  host 'localhost'
  action [:create, :grant]
end

include_recipe 'certificate::wildcard'
