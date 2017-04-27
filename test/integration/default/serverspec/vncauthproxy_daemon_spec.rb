require 'serverspec'
set :backend, :exec

describe 'install and start the vncauthproxy daemon' do
  describe service('vncauthproxy') do
    it { should be_running }
  end
  # this will fail if you change the port
  # in the attributes
  describe port(8888) do
    it { should be_listening }
  end
end
