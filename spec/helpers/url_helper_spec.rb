require 'spec_helper'

describe Worthwhile::UrlHelper do
  include Blacklight::SolrHelper

  def blacklight_config
    CatalogController.blacklight_config
  end

  before do
    GenericWork.destroy_all
  end
  let(:work) { GenericWork.create!(pid: 'sufia:123') }
  let(:document) { get_solr_response_for_doc_id(work.pid).last }
  subject { helper.url_for_document document }

  it "draws the default thumbnail" do
    expect(subject).to eq "/concern/generic_works/sufia:123"
  end
end

