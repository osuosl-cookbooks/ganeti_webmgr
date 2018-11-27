describe port(80) do
  it { should be_listening }
end

describe http('http://localhost', enable_remote_worker: true) do
  its('status') { should eq 302 }
  its('headers.Location') { should eq 'http://localhost/accounts/login/?next=/' }
end

describe http('http://localhost/accounts/login', enable_remote_worker: true) do
  its('status') { should eq 200 }
  its('body') { should contain 'About Ganeti Web Manager' }
end
