# frozen_string_literal: true

# NOTE: This has been marked ActiveFedora only because the queries the class utilizes relies only on
#   AF methods (for example, `lib/hyrax/resource_sync/change_list_writer.rb#L39`). If this fuctionality
#   is missing in Valkyrie, this class will have to be reworked to include Valkyrie methods.
RSpec.describe Hyrax::ResourceSync::ChangeListWriter, :active_fedora, :clean_repo do
  let(:sitemap) { 'http://www.sitemaps.org/schemas/sitemap/0.9' }
  let(:public_collection) { create(:public_collection) }
  let(:public_work) { create(:public_generic_work) }
  let(:file_set) { create(:file_set, :public) }
  let(:capability_list) { 'http://example.com/capabilityList.xml' }
  let(:xml) { Nokogiri::XML.parse(subject) }
  let(:url_list) { xml.xpath('//x:url', 'x' => sitemap) }
  let(:instance) do
    described_class.new(resource_host: 'example.com',
                        capability_list_url: capability_list)
  end
  let(:namespaces) do
    {
      'rs' => "http://www.openarchives.org/rs/terms/",
      'x' => sitemap
    }
  end
  let(:capability_element) { xml.xpath('//rs:ln/@href', 'rs' => "http://www.openarchives.org/rs/terms/") }
  # The creation and modified dates are used in order to determine whether or
  # not the status is "created" or "updated"
  # This avoids any potential delays/conflicts when testing against Solr and
  # Fedora within the testing environment
  # @see Hyrax::ResourceSync::ChangeListWriter#build_resource
  let(:file_set_status) do
    file_set.create_date.to_i == file_set.modified_date.to_i ? 'created' : 'updated'
  end
  let(:public_work_status) do
    public_work.create_date.to_i == public_work.modified_date.to_i ? 'created' : 'updated'
  end
  let(:public_collection_status) do
    public_collection.create_date.to_i == public_collection.modified_date.to_i ? 'created' : 'updated'
  end

  subject { instance.write }

  context "without resources" do
    it "has a list of resources" do
      expect(url_list).to be_empty
    end
  end

  context "when resources exist" do
    before do
      # These private items should not show up.
      build(:private_collection_lw)
      create(:work)

      public_collection
      public_work
      file_set
    end

    it "has a list of resources" do
      expect(capability_element.text).to eq capability_list
      locations = location_elements(namespaces).map(&:text)
      expect(locations).to include "http://example.com/concern/file_sets/#{file_set.id}"
      expect(locations).to include "http://example.com/concern/generic_works/#{public_work.id}"
      expect(locations).to include "http://example.com/collections/#{public_collection.id}"
      changed = changed_elements(namespaces).map(&:value)
      expect(changed).to match_array([public_collection_status, public_work_status, file_set_status])

      expect(url_list.count).to eq 3
    end
  end

  def changed_elements(namespaces = {})
    query("rs:md/@change", namespaces)
  end

  def location_elements(namespaces = {})
    query("x:loc", namespaces)
  end

  def query(part, ns = {})
    xml.xpath("//x:url/#{part}", ns)
  end
end
