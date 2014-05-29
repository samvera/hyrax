require 'spec_helper'

describe Worthwhile::UrlHelper do
  before do
    GenericWork.destroy_all
  end
  let(:profile) { ["{\"datastreams\":{}}"] }
  let(:work) { GenericWork.create!(pid: 'sufia:123') }
  let(:document) { SolrDocument.new("id"=>"sufia:123", "has_model_ssim"=>["info:fedora/afmodel:GenericWork"], 'object_profile_ssm' => profile) }
  subject { helper.url_for_document document }

  it "draws the default thumbnail" do
    expect(subject).to eq "/concern/generic_works/123"
  end
end

