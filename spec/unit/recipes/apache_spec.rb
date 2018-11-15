require_relative '../../spec_helper'

describe 'ganeti_webmgr::apache' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
    end
  end
end
