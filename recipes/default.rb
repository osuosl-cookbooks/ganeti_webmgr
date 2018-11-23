#
# Cookbook Name:: ganeti_webmgr
# Recipe:: default
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
# limitations under the License.

python_runtime '2.7'

include_recipe 'git'
include_recipe 'build-essential::default'

package node['ganeti_webmgr']['packages']

# Make sure the directory for GWM exists before we try to clone to it
directory node['ganeti_webmgr']['path'] do
  owner node['ganeti_webmgr']['owner']
  group node['ganeti_webmgr']['group']
  recursive true
  action :create
end

no_clone = node.chef_environment == 'vagrant' &&
           ::File.directory?(::File.join(node['ganeti_webmgr']['path'], '.git'))

# the install dir *is* the virtualenv
install_dir = node['ganeti_webmgr']['install_dir']
directory install_dir

python_virtualenv install_dir do
  pip_version '18.0'
end

db_driver =
  case node['ganeti_webmgr']['database']['engine'].split('.').last
  when 'mysql'
    'MySQL-python'
  when 'psycopg2', 'postgresql_psycopg2'
    'psycopg2'
  else
    []
  end

python_package db_driver

# clone the repo so we can run setup.sh to install
git node['ganeti_webmgr']['path'] do
  repository node['ganeti_webmgr']['repository']
  revision node['ganeti_webmgr']['revision']
  user node['ganeti_webmgr']['owner']
  group node['ganeti_webmgr']['group']
  not_if { no_clone }
  notifies :run, 'python_execute[install ganeti_webmgr]', :immediately
end

# The first value is for our custom config directory
# the second is for django-admin.py
env = {
  'GWM_CONFIG_DIR' => node['ganeti_webmgr']['config_dir'].to_s,
  'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
}

python_execute 'install ganeti_webmgr' do
  action :nothing
  command '-m pip install .'
  cwd node['ganeti_webmgr']['path']
end

passwords = data_bag_item(
  node['ganeti_webmgr']['databag'],
  node['ganeti_webmgr']['databag_item']
)

db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']
secret_key = node['ganeti_webmgr']['secret_key'] || passwords['secret_key']
web_mgr_api_key = node['ganeti_webmgr']['web_mgr_api_key'] || passwords['web_mgr_api_key']

config_file = ::File.join(node['ganeti_webmgr']['config_dir'], 'config.yml')

directory node['ganeti_webmgr']['config_dir']

template config_file do
  source 'config.yml.erb'
  owner node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  mode '0644'
  variables(
    app: node['ganeti_webmgr'],
    rapi_connect_timeout: node['ganeti_webmgr']['rapi_connect_timeout'],
    db_pass: db_pass,
    secret_key: secret_key,
    web_mgr_api_key: web_mgr_api_key
  )
end

# get the path to the files we need to run commands
venv = install_dir
venv_bin = ::File.join(venv, 'bin')
django_admin = ::File.join(venv_bin, 'django-admin.py')

# syncdb using django-admin.py
python_execute 'run_syncdb' do
  command "#{django_admin} syncdb --noinput"
  environment env
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  only_if { node['ganeti_webmgr']['migrate'] }
end

# migrate using django-admin.py
python_execute 'run_migration' do
  command "#{django_admin} migrate"
  environment env
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  only_if { node['ganeti_webmgr']['migrate'] }
end

# run vncauthproxy setup
include_recipe 'runit'
runit_service 'vncauthproxy' do
  options(
    'port' => node['ganeti_webmgr']['vncauthproxy']['port'],
    'ip' => node['ganeti_webmgr']['vncauthproxy']['ip'],
    'install_dir' => node['ganeti_webmgr']['install_dir']
  )
end

runit_service 'flashpolicy' do
  options(
    'install_dir' => node['ganeti_webmgr']['install_dir']
  )
  only_if { node['ganeti_webmgr']['vncauthproxy']['flashpolicy_enabled'] }
end
