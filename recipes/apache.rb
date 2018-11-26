include_recipe 'apache2::default'
include_recipe 'apache2::mod_wsgi'

gwm = node['ganeti_webmgr']

env = {
  'GWM_CONFIG_DIR' => gwm['config_dir'].to_s,
  'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
}

python_path = ::File.join(gwm['install_dir'], 'lib', 'python2.6', 'site-packages')
wsgi_path = ::File.join(python_path, 'ganeti_webmgr', 'ganeti_web', 'wsgi.py')
django_admin = ::File.join(gwm['install_dir'], 'bin', 'django-admin.py')

python_execute 'collect_static' do
  command "#{django_admin} collectstatic --noinput"
  environment env
  user node['ganeti_webmgr']['user']
  group node['ganeti_webmgr']['group']
end

if gwm['https_enabled']
  template_name = 'gwm_apache_vhost_https.conf.erb'
  server_port = if gwm['apache']['server_port'] == 80
                  443
                else
                  gwm['apache']['server_port']
                end
else
  template_name = 'gwm_apache_vhost.conf.erb'
  server_port = gwm['apache']['server_port']
end

web_app gwm['application_name'] do
  template template_name
  server_aliases gwm['apache']['server_aliases']
  cookbook 'ganeti_webmgr'
  server_name gwm['apache']['server_name']
  server_port server_port
  app gwm
  processes gwm['apache']['processes']
  threads gwm['apache']['threads']
  wsgi_process_group 'ganeti_webmgr'
  wsgi_path wsgi_path
  python_path python_path
  notifies :reload, 'service[apache2]'
end
