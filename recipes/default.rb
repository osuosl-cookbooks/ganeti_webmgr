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

include_recipe "python"
include_recipe "git"

# Make sure the directory for GWM exists before we try to clone to it
directory node['ganeti_webmgr']['path'] do
  owner node['ganeti_webmgr']['owner']
  group node['ganeti_webmgr']['group']
  recursive true
  action :create
end

no_clone = node.chef_environment == "vagrant" &&
  ::File.directory?(::File.join(node['ganeti_webmgr']['path'], '.git'))

# clone the repo so we can run setup.sh to install
git node['ganeti_webmgr']['path'] do
  repository node['ganeti_webmgr']['repository']
  revision node['ganeti_webmgr']['revision']
  user node['ganeti_webmgr']['owner']
  group node['ganeti_webmgr']['group']
  # not_if { no_clone }
end

# The first value is for our custom config directory
# the second is for django-admin.py
env = {
  "GWM_CONFIG_DIR" => node['ganeti_webmgr']['config_dir'].to_s ,
  "DJANGO_SETTINGS_MODULE" => "ganeti_webmgr.ganeti_web.settings"
}

log "Installing additional system packages for Ganeti Web Manager"
node['ganeti_webmgr']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

db_driver = case node['ganeti_webmgr']['database']['engine'].split('.').last
when "mysql"
  include_recipe "mysql::client"
  'mysql'
when "psycopg2", "postgresql_psycopg2"
  'postgres'
when "sqlite3"
  'sqlite'
else
  log "node['ganeti_webmgr']['database']['engine'] needs to be set!" do
    level :fatal
  end
end

# the install dir *is* the virtualenv
install_dir = node['ganeti_webmgr']['install_dir']

# use setup.sh to install GWM
execute "install_gwm" do
  command "./scripts/setup.sh -D #{db_driver} -d #{install_dir}"
  cwd node['ganeti_webmgr']['path']
  environment env
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  creates node['ganeti_webmgr']['install_dir']
  action :nothing
end

ruby_block "setup_runner" do
  block {}
  action :run
  notifies :run, "execute[install_gwm]"
end

passwords = Chef::EncryptedDataBagItem.load("ganeti_webmgr", "passwords")

db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']
secret_key = node['ganeti_webmgr']['secret_key'] || passwords['secret_key']
web_mgr_api_key = node['ganeti_webmgr']['web_mgr_api_key'] || passwords['web_mgr_api_key']

config_file = ::File.join(node['ganeti_webmgr']['config_dir'], 'config.yml')

directory node['ganeti_webmgr']['config_dir'] do
  owner node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  recursive true
end

template config_file do
  source "config.yml.erb"
  owner node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  mode "0644"
  variables({
    :app => node['ganeti_webmgr'],
    :db_pass => db_pass,
    :secret_key =>  secret_key,
    :web_mgr_api_key => web_mgr_api_key
  })
end

# these would work better as resources or library files,
# but this works fine for now

# get the path to the files we need to run commands
venv = install_dir
venv_bin = ::File.join(venv, 'bin')
django_admin = ::File.join(venv_bin, 'django-admin.py')

# syncdb using django-admin.py
execute "run_syncdb" do
  command "#{django_admin} syncdb --noinput"
  environment env
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  only_if { !!node['ganeti_webmgr']['migrate'] }
end

# migrate using django-admin.py
execute "run_migration" do
  command "#{django_admin} migrate"
  environment env
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  only_if { !!node['ganeti_webmgr']['migrate'] }
end

# run vncauthproxy setup
log "Setting up vncauthproxy runit script"

include_recipe "runit"
runit_service "vncauthproxy" do
  options({
    'port' => node['ganeti_webmgr']['vncauthproxy']['port'],
    'ip' => node['ganeti_webmgr']['vncauthproxy']['ip'],
    'install_dir' => node['ganeti_webmgr']['install_dir']
  })
end

if node['ganeti_webmgr']['vncauthproxy']['flashpolicy_enabled']
  runit_service "flashpolicy" do
    options({
      'install_dir' => node['ganeti_webmgr']['install_dir']
    })
  end
end


