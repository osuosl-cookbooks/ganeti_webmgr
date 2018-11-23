# Make sure our settings in Django are set correctly to mysql
node.override['ganeti_webmgr']['database']['engine'] = 'django.db.backends.mysql'

passwords = data_bag_item('ganeti_webmgr', 'passwords')
db_host = node['ganeti_webmgr']['database']['host']
db_port = node['ganeti_webmgr']['database']['port']
server_user = node['ganeti_webmgr']['db_server']['user'] || passwords['db_server']['user']
server_password = node['ganeti_webmgr']['db_server']['password'] || passwords['db_server']['password']
db_user = node['ganeti_webmgr']['database']['user']
db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']

node.default['mariadb']['server_root_password'] = server_password
node.default['mariadb']['use_default_repository'] = true

include_recipe 'mariadb::server'
include_recipe 'build-essential'

mysql2_chef_gem_mariadb 'default'

connection_info = {
  host: db_host,
  port: db_port,
  username: server_user || 'root',
  password: server_password,
}

mysql_database node['ganeti_webmgr']['database']['name'] do
  connection connection_info
end

mysql_database_user db_user do
  connection connection_info
  database_name node['ganeti_webmgr']['database']['name']
  privileges [:all]
  password db_pass
  action [:create, :grant]
end
