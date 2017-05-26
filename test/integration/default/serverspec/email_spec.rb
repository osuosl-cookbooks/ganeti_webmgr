require 'serverspec'

describe file('/opt/ganeti_webmgr/config/config.yml') do
  it { should exist }
  it { should contain 'noreply@osuosl.org' }
end
