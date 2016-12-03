require 'spec_helper'

RSpec.describe Hyrax::ResourceSync::ResourceListWriter do
  let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
  let!(:private_collection) { create(:private_collection) }
  let!(:public_collection) { create(:public_collection) }
  let!(:public_work) { create(:public_generic_work) }
  let!(:private_work) { create(:work) }
  let!(:file_set) { create(:file_set, :public) }
  let(:capability_list) { 'http://example.com/capabilityList.xml' }

  subject { described_class.new(resource_host: 'example.com', capability_list_url: capability_list).write }
  let(:xml) { Nokogiri::XML.parse(subject) }

  it "has a list of resources" do
    capability = xml.xpath('//rs:ln/@href', 'rs' => "http://www.openarchives.org/rs/terms/").text
    expect(capability).to eq capability_list
    expect(query(1)).to eq "http://example.com/collections/#{public_collection.id}"
    expect(query(2)).to eq "http://example.com/concern/generic_works/#{public_work.id}"
    expect(query(3)).to eq "http://example.com/concern/file_sets/#{file_set.id}"
    expect(xml.xpath('//x:url', 'x' => sitemap).count).to eq 3
  end

  def query(n)
    xml.xpath("//x:url[#{n}]/x:loc", 'x' => sitemap).text
  end
end
