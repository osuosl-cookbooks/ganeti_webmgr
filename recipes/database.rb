#
# Cookbook Name:: ganeti_webmgr
# Recipe:: database
#
# Copyright 2013 Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and

# Recipe to do database agnostic boostrapping
# Creates a database, and a database user

passwords = Chef::EncryptedDataBagItem.load('ganeti_webmgr', 'passwords')

db_host = node['ganeti_webmgr']['database']['host']
db_port = node['ganeti_webmgr']['database']['port']

server_user = node['ganeti_webmgr']['db_server']['user'] || passwords['db_server']['user']
server_password = node['ganeti_webmgr']['db_server']['password'] || passwords['db_server']['password']

db_user = node['ganeti_webmgr']['database']['user']
db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']

mysql_connection_info = {
  host: db_host,
  port: db_port,
  username: server_user || 'root',
  password: server_password
}

# postgres example not tested:
postgresql_connection_info = {
  host: db_host,
  username: server_user || 'postgres',
  password: server_password
}

case node['ganeti_webmgr']['database']['engine'].split('.').last
when 'mysql'
  include_recipe 'osl-mysql::client'
  include_recipe 'database::mysql'
  db_provider = Chef::Provider::Database::Mysql
  db_user_provider = Chef::Provider::Database::MysqlUser
  connection_info = mysql_connection_info
when 'psycopg2', 'postgresql_psycopg2'
  include_recipe 'postgresql'
  include_recipe 'database::postgres'
  db_provider = Chef::Provider::Database::Postgresql
  db_user_provider = Chef::Provider::Database::PostgresqlUser
  connection_info = postgresql_connection_info
end

log "Creating Database with name #{node['ganeti_webmgr']['database']['name']}"
database node['ganeti_webmgr']['database']['name'] do
  provider db_provider
  connection connection_info
  action :create
end

# Create our user
database_user db_user do
  provider db_provider
  connection connection_info
  database_name node['ganeti_webmgr']['database']['name']
  password db_pass
  action :create
end

# Give our user permissions to the DB
database_user db_user do
  provider db_user_provider
  connection connection_info
  database_name node['ganeti_webmgr']['database']['name']
  privileges [:all]
  action :grant
end
