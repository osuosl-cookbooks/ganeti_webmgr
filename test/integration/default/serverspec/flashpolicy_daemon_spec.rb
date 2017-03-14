require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe 'install and start the flashpolicy daemon' do
  describe service('flashpolicy') do
    it { should be_running }
  end
  describe port(843) do
    it { should be_listening }
  end
end
