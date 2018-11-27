describe port(80) do
  it { should be_listening }
end

describe port(443) do
  it { should be_listening }
end

describe http('http://localhost', enable_remote_worker: true) do
  its('status') { should eq 302 }
  its('headers.Location') { should match %r{https://(?:[0-9]{1,3}\.){3}[0-9]{1,3}} }
end

describe http('http://localhost/accounts/login', enable_remote_worker: true) do
  its('status') { should eq 302 }
  its('headers.Location') { should match %r{https://(?:[0-9]{1,3}\.){3}[0-9]{1,3}/accounts/login} }
end

describe http('https://localhost/accounts/login', enable_remote_worker: true, ssl_verify: false) do
  its('status') { should eq 200 }
  its('body') { should contain 'About Ganeti Web Manager' }
end
