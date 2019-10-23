passwords = data_bag_item('percona', 'mysql')
db_host = node['ganeti_webmgr']['database']['host']
db_port = node['ganeti_webmgr']['database']['port']
#server_user = node['ganeti_webmgr']['db_server']['user'] || passwords['db_server']['user']
server_user = 'root'
server_password = node['ganeti_webmgr']['db_server']['password'] || passwords['root']
db_user = node['ganeti_webmgr']['database']['user']
#db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']
db_pass = 'vagrant'

node.default['mariadb']['server_root_password'] = server_password
node.default['mariadb']['use_default_repository'] = true

#include_recipe 'mariadb::server'
include_recipe 'osl-mysql::server'
build_essential 'gwm_test'

#mysql2_chef_gem_mariadb 'default'
mysql2_chef_gem 'default' do
    provider Chef::Provider::Mysql2ChefGem::Percona
    action :install
end

connection_info = {
  host: db_host,
  user: server_user || 'root',
  password: server_password
}

#mysql_database 'gwm_db' do
mysql_database node['ganeti_webmgr']['database']['name'] do
  connection connection_info
  action :create
end

#mysql_database_user 'gwm_user' do
mysql_database_user db_user do
  #database_name 'gwm_db'
  database_name node['ganeti_webmgr']['database']['name']
  password db_pass
  host '172.17.%'
  connection connection_info
  #privileges [:all]
  action [:create, :grant]
end

include_recipe 'certificate::wildcard'
