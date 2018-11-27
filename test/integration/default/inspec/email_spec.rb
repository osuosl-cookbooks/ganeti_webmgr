describe file('/opt/ganeti_webmgr/config/config.yml') do
  it { should exist }
  its('content') { should match(/^DEFAULT_FROM_EMAIL: noreply@osuosl.org$/) }
end
