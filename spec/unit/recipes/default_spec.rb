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
      it 'creates the application directory' do
        expect(chef_run).to create_directory(
          '/opt/ganeti_webmgr_src'
        ).with(
          owner: nil,
          group: nil
        )
      end
      it 'clones the gwm git repo' do
        expect(chef_run).to sync_git(
          '/opt/ganeti_webmgr_src'
        ).with(
          repository: 'https://github.com/osuosl/ganeti_webmgr'
        )
      end
      it 'prints out a log' do
        expect(chef_run).to write_log(
          'Installing additional system packages for Ganeti Web Manager'
        )
      end
      it 'installs required packages' do
        expect(chef_run).to install_package(
          'libffi-devel'
        )
        expect(chef_run).to install_package(
          'openssl-devel'
        )
      end
      it 'runs the ./scripts/setup.sh script' do
        expect(chef_run).to run_execute(
          'install_gwm'
        ).with(
          command: './scripts/setup.sh -D sqlite -d /opt/ganeti_webmgr',
          cwd: '/opt/ganeti_webmgr_src',
          user: nil,
          group: nil
        )
      end
      it  'generates configuration file from template' do
        expect(chef_run).to create_template(
          '/opt/ganeti_webmgr/config/config.yml'
        ).with(
          source: 'config.yml.erb',
          owner: nil,
          group: nil,
          mode: '0644',
        )
      end
      it 'does not run syncdb --noinput' do
        expect(chef_run).to_not run_execute(
          'run_syncdb'
        )
      end
      it 'does not run migration' do
        expect(chef_run).to_not run_execute(
          'run_migration'
        )
      end
      it 'logs setting up the vncauthproxy script' do
        expect(chef_run).to write_log(
          'Setting up vncauthproxy runit script'
        )
      end
      it 'starts service vncauthproxy' do
        expect(chef_run).to enable_runit_service(
          'vncauthproxy'
        )
      end
      it 'starts service flashpolicy' do
        expect(chef_run).to enable_runit_service(
          'flashpolicy'
        )
      end
    end
  end
end
