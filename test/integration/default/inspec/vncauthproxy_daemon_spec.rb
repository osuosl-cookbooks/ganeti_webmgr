describe runit_service('vncauthproxy') do
  it { should be_running }
  it { should be_installed }
  it { should be_enabled }
end
describe port(8888) do
  it { should be_listening }
end
