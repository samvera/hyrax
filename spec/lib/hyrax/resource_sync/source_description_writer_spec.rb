# frozen_string_literal: true
RSpec.describe Hyrax::ResourceSync::SourceDescriptionWriter do
  let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
  let(:rs) { 'http://www.openarchives.org/rs/terms/' }
  let(:capability_list) { 'http://example.com/capabilityList.xml' }
  let(:xml) { Nokogiri::XML.parse(subject) }

  subject { described_class.new(capability_list_url: capability_list).write }

  it "has url to the capability list" do
    capability = xml.xpath('/x:urlset/rs:md/@capability', 'x' => sitemap, 'rs' => rs).map(&:value)
    expect(capability).to eq ["description"]

    url = xml.xpath('//x:url[1]/x:loc', 'x' => sitemap).text
    expect(url).to eq capability_list
    capability = xml.xpath('//x:url[1]/rs:md/@capability', 'x' => sitemap, 'rs' => rs).map(&:value)
    expect(capability).to eq ["capabilitylist"]
  end
end
