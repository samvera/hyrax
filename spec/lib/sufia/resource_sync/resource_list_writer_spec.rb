require 'spec_helper'

RSpec.describe Sufia::ResourceSync::ResourceListWriter do
  let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
  let!(:private_collection) { create(:private_collection) }
  let!(:public_collection) { create(:public_collection) }
  let!(:public_work) { create(:public_generic_work) }
  let!(:private_work) { create(:work) }
  let!(:file_set) { create(:file_set, :public) }
  let(:capability_list) { 'http://example.com/capabilityList.xml' }

  subject { described_class.new(resource_host: 'example.com', capability_list_url: capability_list).write }
  let(:xml) { Nokogiri::XML.parse(subject) }

  it "has two urls" do
    first_url = xml.xpath('//x:url[1]/x:loc', 'x' => sitemap).text
    second_url = xml.xpath('//x:url[2]/x:loc', 'x' => sitemap).text
    third_url = xml.xpath('//x:url[3]/x:loc', 'x' => sitemap).text
    expect(first_url).to eq "http://example.com/collections/#{public_collection.id}"
    expect(second_url).to eq "http://example.com/concern/generic_works/#{public_work.id}"
    expect(third_url).to eq "http://example.com/concern/file_sets/#{file_set.id}"
    expect(xml.xpath('//x:url', 'x' => sitemap).count).to eq 3
  end
end
