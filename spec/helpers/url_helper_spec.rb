require 'spec_helper'

describe Worthwhile::UrlHelper do
  before do
    GenericWork.destroy_all
  end
  let(:profile) { ["{\"datastreams\":{}}"] }
  let(:work) { GenericWork.create!(pid: 'sufia:123') }
  let(:document) { SolrDocument.new("id"=>"sufia:123", "has_model_ssim"=>["info:fedora/afmodel:GenericWork"], 'object_profile_ssm' => profile) }
  subject { helper.url_for_document document }

  it { should eq "/concern/generic_works/123" }

  context "when document is a Worthwhile::GenericFile" do
    let(:document) { Worthwhile::GenericFile.new pid: 'foo:123' }
    it { should eq "/concern/generic_files/123" }
  end
end

