describe runit_service('flashpolicy') do
  it { should be_running }
  it { should be_installed }
  it { should be_enabled }
end
describe port(843) do
  it { should be_listening }
end
