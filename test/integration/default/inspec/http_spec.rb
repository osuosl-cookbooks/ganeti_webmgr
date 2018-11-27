describe port(80) do
  it { should be_listening }
end

describe http('http://localhost', enable_remote_worker: true) do
  its('status') { should eq 302 }
  its('headers.Location') { should eq 'http://localhost/accounts/login/?next=/' }
end

describe http('http://localhost/accounts/login', enable_remote_worker: true) do
  its('status') { should eq 200 }
  its('body') { should match(/About Ganeti Web Manager/) }
end

# Simulate logging into GWM using curl
gwm_command =
  # 1. Get initial cookie for curl
  # 2. Grab CSRF token
  # 3. Try logging into the site with token
  'curl -so /dev/null -c c.txt -b c.txt http://localhost/accounts/login/ && ' \
  'token=$(grep csrftoken c.txt | cut -f7) && ' \
  'curl -H \'Referer: http://localhost/accounts/login/\' -c c.txt -b c.txt -d ' \
	'"csrfmiddlewaretoken=${token}&username=admin&password=admin&next=%2F" -v -L ' \
  'http://localhost/accounts/login/ 2>&1'

describe command(gwm_command) do
  its('stdout') { should match(/You do not have access to any virtual machines/) }
  its('stdout') { should match(/You are logged in as.*\n.*admin/) }
end
