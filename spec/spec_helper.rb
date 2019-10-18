require 'chefspec'
require 'chefspec/berkshelf'

CENTOS_6 = {
  platform: 'centos',
  version: '6',
}.freeze

ALL_PLATFORMS = [
  CENTOS_6,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

shared_context 'common' do
  before do
    stub_command('/usr/sbin/httpd -t')
    stub_data_bag_item('ganeti_webmgr', 'passwords')
      .and_return(
        db_password: 'db_password',
        secret_key: 'secret_key',
        web_mgr_api_key: 'web_mgr_api_key',
        db_server: 'db_server'
      )
  end
end
