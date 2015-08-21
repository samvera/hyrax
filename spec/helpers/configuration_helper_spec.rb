require 'spec_helper'

describe Blacklight::ConfigurationHelperBehavior do
  describe 'creator facet' do
    before do
      allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    end
    let(:field) { 'creator_sim' }
    subject { helper.facet_field_label field }
    it { should eq 'Creator' }
  end
end
