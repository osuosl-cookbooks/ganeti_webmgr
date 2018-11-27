#
# Cookbook Name:: ganeti_webmgr
# Recipe:: boostrap_user
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

venv = node['ganeti_webmgr']['install_dir']
venv_bin = ::File.join(venv, 'bin')
python = ::File.join(venv_bin, 'python')
django_admin = ::File.join(venv_bin, 'django-admin.py')

# Use the attributes to bootstrap users if set, otherwise use databag users
users = node['ganeti_webmgr']['superusers']
unless users.any?
  passwords = data_bag_item('ganeti_webmgr', 'passwords')
  users = passwords['superusers'] || []
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
    user node['ganeti_webmgr']['user']
    group node['ganeti_webmgr']['group']
    environment node['ganeti_webmgr']['env']
  end
end
