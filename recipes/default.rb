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

python_runtime '2' do
  provider :system
end

include_recipe 'git'
build_essential 'install packages for compiling C programs'
include_recipe 'selinux_policy::install'

package node['ganeti_webmgr']['packages']

# the install dir *is* the virtualenv
install_dir = node['ganeti_webmgr']['install_dir']

# Create gwm user/group
group node['ganeti_webmgr']['group'] do
  system true
end

user node['ganeti_webmgr']['user'] do
  home install_dir
  group node['ganeti_webmgr']['group']
  system true
  action [:create, :lock]
end

selinux_policy_fcontext "#{install_dir}(/.*)?" do
  secontext 'httpd_sys_rw_content_t'
end

# Make sure the directory for GWM exists before we try to clone to it
directory node['ganeti_webmgr']['path'] do
  owner node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  recursive true
  action :create
end

directory install_dir do
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  recursive true
end

python_virtualenv install_dir do
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  pip_version '9.0.3'
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

# Install db driver (if needed)
python_package db_driver do
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
end

# We need this specific version to work with python2.6
python_package 'pycparser' do
  version '2.14'
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
end

# clone the repo so we can install
git node['ganeti_webmgr']['path'] do
  repository node['ganeti_webmgr']['repository']
  revision node['ganeti_webmgr']['revision']
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  notifies :run, 'execute[install ganeti_webmgr]', :immediately
end

# Install GWM deps using pip directly
# NOTE: this does not work with python_execute due to python2.6 issues
execute 'install ganeti_webmgr' do
  action :nothing
  command "/opt/ganeti_webmgr/bin/pip install --cache-dir #{install_dir}/.cache/pip ."
  cwd node['ganeti_webmgr']['path']
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
end

passwords = data_bag_item(
  node['ganeti_webmgr']['databag'],
  node['ganeti_webmgr']['databag_item']
)

db_pass = node['ganeti_webmgr']['database']['password'] || passwords['db_password']
secret_key = node['ganeti_webmgr']['secret_key'] || passwords['secret_key']
web_mgr_api_key = node['ganeti_webmgr']['web_mgr_api_key'] || passwords['web_mgr_api_key']

config_file = ::File.join(node['ganeti_webmgr']['config_dir'], 'config.yml')

directory node['ganeti_webmgr']['config_dir'] do
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  recursive true
end

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
python = ::File.join(venv_bin, 'python')
django_admin = ::File.join(venv_bin, 'django-admin.py')
python_path = ::File.join(node['ganeti_webmgr']['install_dir'], 'lib', 'python2.6', 'site-packages')
wsgi_path = ::File.join(python_path, 'ganeti_webmgr', 'ganeti_web', 'wsgi.py')

# syncdb using django-admin.py
python_execute 'run_syncdb' do
  command "#{django_admin} syncdb --noinput"
  environment node['ganeti_webmgr']['env']
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
  only_if { node['ganeti_webmgr']['migrate'] }
end

# migrate using django-admin.py
python_execute 'run_migration' do
  command "#{django_admin} migrate"
  environment node['ganeti_webmgr']['env']
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

# Use the attributes to bootstrap users if set, otherwise use databag users
users =
  if node['ganeti_webmgr']['superusers'].empty? && passwords['superusers'].nil?
    []
  elsif node['ganeti_webmgr']['superusers'].empty?
    passwords['superusers']
  else
    node['ganeti_webmgr']['superusers']
  end

users.each do |user|
  username = user['username']
  email = user['email']
  password = user['password']

  python_execute 'bootstrap_superuser' do
    command <<-EOS
    #{django_admin} createsuperuser --noinput --username=#{username} --email #{email}
    #{python} -c \"from django.contrib.auth.models import User;u=User.objects.get(username='#{username}');u.set_password('#{password}');u.save();\"
    EOS
    sensitive true
    user node['ganeti_webmgr']['user']
    group node['ganeti_webmgr']['group']
    environment node['ganeti_webmgr']['env']
  end
end

include_recipe 'apache2::default'
include_recipe 'apache2::mod_wsgi'
include_recipe 'apache2::mod_ssl' if node['ganeti_webmgr']['https_enabled']

python_execute 'collect_static' do
  command "#{django_admin} collectstatic --noinput"
  environment node['ganeti_webmgr']['env']
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
end

web_app node['ganeti_webmgr']['application_name'] do
  template 'gwm_apache_vhost.conf.erb'
  server_aliases node['ganeti_webmgr']['apache']['server_aliases']
  server_name node['ganeti_webmgr']['apache']['server_name']
  server_port node['ganeti_webmgr']['apache']['server_port']
  app node['ganeti_webmgr']
  processes node['ganeti_webmgr']['apache']['processes']
  threads node['ganeti_webmgr']['apache']['threads']
  wsgi_process_group 'ganeti_webmgr'
  wsgi_path wsgi_path
  python_path python_path
  notifies :reload, 'service[apache2]'
end

directory node['ganeti_webmgr']['haystack_whoosh_path'] do
  owner node['apache']['user']
  group node['apache']['group']
end

python_execute 'update haystack whoosh index' do
  command "#{django_admin} update_index"
  environment node['ganeti_webmgr']['env']
  user node['apache']['user']
  group node['apache']['group']
end
