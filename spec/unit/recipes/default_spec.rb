require_relative '../../spec_helper'

describe 'ganeti_webmgr::default' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.automatic['fqdn'] = 'itsganeti.com'
          node.automatic['ipaddress'] = '0.0.0.0'
        end.converge(described_recipe)
      end
      include_context 'common'

      before do
        stub_data_bag_item('ganeti_webmgr', 'passwords').and_return(
          'db_password' => 'apassword',
          'secret_key' => 'asecretkey',
          'web_mgr_api_key' => 'anapikey',
          'superusers' => [
            {
              'username' => 'supaman',
              'email' => 'supaman@supa.com',
              'password' => 'supapw',
            },
          ]
        )
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it do
        expect(chef_run).to install_python_runtime('2')
      end

      it do
        expect(chef_run).to install_package(['libffi-devel', 'openssl-devel'])
      end

      it do
        expect(chef_run).to create_group('ganeti_webmgr').with(system: true)
      end

      it do
        expect(chef_run).to create_user('ganeti_webmgr').with(
          home: '/opt/ganeti_webmgr',
          group: 'ganeti_webmgr',
          system: true
        )
      end

      it do
        expect(chef_run).to lock_user('ganeti_webmgr').with(
          home: '/opt/ganeti_webmgr',
          group: 'ganeti_webmgr',
          system: true
        )
      end

      it do
        expect(chef_run).to addormodify_selinux_policy_fcontext('/opt/ganeti_webmgr(/.*)?').with(
          secontext: 'httpd_sys_rw_content_t'
        )
      end

      it do
        expect(chef_run).to create_directory('/opt/ganeti_webmgr_src').with(
          owner: 'ganeti_webmgr',
          group: 'ganeti_webmgr',
          recursive: true
        )
      end

      it do
        expect(chef_run).to create_directory('/opt/ganeti_webmgr').with(
          owner: 'ganeti_webmgr',
          group: 'ganeti_webmgr',
          recursive: true
        )
      end

      it do
        expect(chef_run).to create_python_virtualenv('/opt/ganeti_webmgr').with(
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr',
          pip_version: '9.0.3'
        )
      end

      it do
        expect(chef_run).to install_python_package([]).with(
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr'
        )
      end

      it do
        expect(chef_run).to install_python_package('pycparser').with(
          version: '2.14',
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr'
        )
      end

      it do
        expect(chef_run).to sync_git('/opt/ganeti_webmgr_src').with(
          repository: 'https://github.com/osuosl/ganeti_webmgr',
          revision: 'develop',
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr'
        )
      end

      it do
        expect(chef_run.git('/opt/ganeti_webmgr_src')).to notify('execute[install ganeti_webmgr]').to(:run).immediately
      end

      it do
        expect(chef_run).to_not run_execute('install ganeti_webmgr')
      end

      it do
        expect(chef_run).to create_directory('/opt/ganeti_webmgr/config').with(
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr',
          recursive: true
        )
      end

      it do
        expect(chef_run).to create_template('/opt/ganeti_webmgr/config/config.yml').with(
          source: 'config.yml.erb',
          owner: 'ganeti_webmgr',
          group: 'ganeti_webmgr',
          mode: '0644',
          variables: hash_including(
            rapi_connect_timeout: 60,
            db_pass: 'apassword',
            secret_key: 'asecretkey',
            web_mgr_api_key: 'anapikey'
          )
        )
      end

      it do
        expect(chef_run).to enable_runit_service('vncauthproxy').with(
          options: {
            'port' => '8888',
            'ip' => '0.0.0.0',
            'install_dir' => '/opt/ganeti_webmgr',
          }
        )
      end

      it do
        expect(chef_run).to enable_runit_service('flashpolicy').with(
          options: {
            'install_dir' => '/opt/ganeti_webmgr',
          }
        )
      end

      it do
        expect(chef_run).to run_python_execute('bootstrap_superuser').with(
          sensitive: true,
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr',
          environment: {
            'GWM_CONFIG_DIR' => '/opt/ganeti_webmgr/config',
            'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
          },
          command: <<-EOS
    /opt/ganeti_webmgr/bin/django-admin.py createsuperuser --noinput --username=supaman --email supaman@supa.com
    /opt/ganeti_webmgr/bin/python -c \"from django.contrib.auth.models import User;u=User.objects.get(username='supaman');u.set_password('supapw');u.save();\"
          EOS
        )
      end

      it do
        expect(chef_run).to run_python_execute('collect_static').with(
          command: '/opt/ganeti_webmgr/bin/django-admin.py collectstatic --noinput',
          environment: {
            'GWM_CONFIG_DIR' => '/opt/ganeti_webmgr/config',
            'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
          },
          user: 'ganeti_webmgr',
          group: 'ganeti_webmgr'
        )
      end

      it do
        expect(chef_run).to create_directory('/opt/ganeti_webmgr/whoosh_index').with(
          owner: 'apache',
          group: 'apache'
        )
      end

      it do
        expect(chef_run).to run_python_execute('update haystack whoosh index').with(
          command: '/opt/ganeti_webmgr/bin/django-admin.py update_index',
          environment: {
            'GWM_CONFIG_DIR' => '/opt/ganeti_webmgr/config',
            'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
          },
          user: 'apache',
          group: 'apache'
        )
      end

      context 'migrate is true' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p) do |node|
            node.normal['ganeti_webmgr']['migrate'] = true
          end.converge(described_recipe)
        end

        it 'converges successfully' do
          expect { chef_run }.to_not raise_error
        end

        it do
          expect(chef_run).to run_python_execute('run_syncdb').with(
            command: '/opt/ganeti_webmgr/bin/django-admin.py syncdb --noinput',
            environment: {
              'GWM_CONFIG_DIR' => '/opt/ganeti_webmgr/config',
              'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
            },
            user: 'ganeti_webmgr',
            group: 'ganeti_webmgr'
          )
        end

        it do
          expect(chef_run).to run_python_execute('run_migration').with(
            command: '/opt/ganeti_webmgr/bin/django-admin.py migrate',
            environment: {
              'GWM_CONFIG_DIR' => '/opt/ganeti_webmgr/config',
              'DJANGO_SETTINGS_MODULE' => 'ganeti_webmgr.ganeti_web.settings',
            },
            user: 'ganeti_webmgr',
            group: 'ganeti_webmgr'
          )
        end
      end
    end
  end
end
