RSpec.describe Hyrax::GenericTypeIndexer do
  let(:admin_set) { build(:admin_set) }
  let(:work) { build(:work) }
  let(:collection) { build(:collection) }
  let(:fs) { build(:file_set) }

  context "when the object is an AdminSet" do
    let(:as_service) { described_class.new(resource: admin_set) }

    subject(:as_solr_document) { as_service.to_solr }

    it "indexes generic_type as Admin Set" do
      expect(as_solr_document.fetch(:generic_type_sim)).to eq 'Admin Set'
    end
  end

  context "when the object is a Collection" do
    let(:col_service) { described_class.new(resource: collection) }

    subject(:col_solr_document) { col_service.to_solr }

    it "does not index generic_type as Collection" do
      expect(col_solr_document.fetch(:generic_type_sim)).to eq 'Collection'
    end
  end

  context "when the object is a Work" do
    let(:work_service) { described_class.new(resource: work) }

    subject(:work_solr_document) { work_service.to_solr }

    it "does not index generic_type as Work" do
      expect(work_solr_document.fetch(:generic_type_sim)).to eq 'Work'
    end
  end

  context "when the object is a Fileset" do
    let(:fs_service) { described_class.new(resource: fs) }

    subject(:fs_solr_document) { fs_service.to_solr }

    it "does not index generic_type" do
      expect(fs_solr_document.keys).to eq []
    end
  end

  context "when the object is a some ofther Valkyrie::Resource" do
    let(:service) { described_class.new(resource: Valkyrie::Resource.new) }

    subject(:solr_document) { service.to_solr }

    it "does not index generic_type" do
      expect(solr_document.keys).to eq []
    end
  end
end
