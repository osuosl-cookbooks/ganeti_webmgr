#
# Cookbook Name:: ganeti_webmgr
# Recipe:: mysql
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

# This Recipe should only be run in a development environment because
# it installs MySQL locally, and adjusts a few MySQL settings.
# Please use the default recipe in combination with the database recipe
# if you need to create a database and user for GWM

# Make sure our settings in Django are set correctly to mysql
node.override['ganeti_webmgr']['database']['engine'] = 'django.db.backends.mysql'
# install mysql server
include_recipe 'osl-mysql::server'

directory node['mysql']['data_dir'] do
  mode '0755'
end

# Run the rest of our setup for GWM
include_recipe 'ganeti_webmgr::database'
include_recipe 'ganeti_webmgr::default'
