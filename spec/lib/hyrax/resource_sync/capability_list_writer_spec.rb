# frozen_string_literal: true
RSpec.describe Hyrax::ResourceSync::CapabilityListWriter do
  let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
  let(:rs) { 'http://www.openarchives.org/rs/terms/' }

  let(:resource_list) { 'http://example.com/resourcelist.xml' }
  let(:change_list) { 'http://example.com/changelist.xml' }
  let(:description) { 'http://example.com/resourcesync_description.xml' }
  let(:xml) { Nokogiri::XML.parse(subject) }

  subject do
    described_class.new(resource_list_url: resource_list,
                        change_list_url: change_list,
                        description_url: description).write
  end

  it "has url to the capability list" do
    description_href = xml.xpath('/x:urlset/rs:ln[@rel="up"]/@href', 'x' => sitemap, 'rs' => rs).map(&:value)
    expect(description_href).to eq [description]

    capability = xml.xpath('/x:urlset/rs:md/@capability', 'x' => sitemap, 'rs' => rs).map(&:value)
    expect(capability).to eq ["capabilitylist"]

    url = xml.xpath('//x:url[1]/x:loc', 'x' => sitemap).text
    expect(url).to eq resource_list
    capability = xml.xpath('//x:url[1]/rs:md/@capability', 'x' => sitemap, 'rs' => rs).map(&:value)
    expect(capability).to eq ["resourcelist"]

    url = xml.xpath('//x:url[2]/x:loc', 'x' => sitemap).text
    expect(url).to eq change_list
    capability = xml.xpath('//x:url[2]/rs:md/@capability', 'x' => sitemap, 'rs' => rs).map(&:value)
    expect(capability).to eq ["changelist"]
  end
end
