require_relative '../../spec_helper'

describe 'ganeti_webmgr::default' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      before do
        allow(Chef::EncryptedDataBagItem).to receive(:load).with('ganeti_webmgr', 'passwords').and_return(
          id: 'passwords',
          db_password: 'vagrant',
          secret_key: 'asdf',
          web_mgr_api_key: '12345',
          db_server: {
            'password' => 'rootpass'
          }
        )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
    end
  end
end
