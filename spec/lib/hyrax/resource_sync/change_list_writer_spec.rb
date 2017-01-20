require 'spec_helper'

RSpec.describe Hyrax::ResourceSync::ChangeListWriter do
  let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }

  let(:public_collection) { create(:public_collection) }
  let(:public_work) { create(:public_generic_work) }
  let(:file_set) { create(:file_set, :public) }

  let(:capability_list) { 'http://example.com/capabilityList.xml' }
  before do
    # These private items should not show up.
    create(:private_collection)
    create(:work)

    # Sleep in between to ensure modified dates are different
    public_collection
    sleep(1)
    public_work
    sleep(1)
    file_set
  end

  subject { described_class.new(resource_host: 'example.com', capability_list_url: capability_list).write }
  let(:xml) { Nokogiri::XML.parse(subject) }

  it "has a list of resources" do
    capability = xml.xpath('//rs:ln/@href', 'rs' => "http://www.openarchives.org/rs/terms/").text
    expect(capability).to eq capability_list

    expect(location(1)).to eq "http://example.com/concern/file_sets/#{file_set.id}"
    expect(change(1)).to eq "created"

    expect(location(2)).to eq "http://example.com/concern/generic_works/#{public_work.id}"
    expect(change(2)).to eq "created"

    expect(location(3)).to eq "http://example.com/collections/#{public_collection.id}"
    expect(change(3)).to eq "created"

    expect(xml.xpath('//x:url', 'x' => sitemap).count).to eq 3
  end

  def change(n)
    query(n, 'rs:md/@change', 'rs' => "http://www.openarchives.org/rs/terms/")
  end

  def location(n)
    query(n, 'x:loc')
  end

  def query(n, part, ns = {})
    xml.xpath("//x:url[#{n}]/#{part}", ns.merge('x' => sitemap)).text
  end
end
