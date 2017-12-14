RSpec.describe Hyrax::FileSetChangeSet do
  subject(:change_set) { described_class.new(FileSet.new) }

  describe '#terms' do
    it 'returns a list' do
      expect(subject.terms).to eq(
        [:resource_type, :title, :creator, :contributor, :description, :keyword,
         :license, :publisher, :date_created, :subject, :language, :identifier,
         :based_near, :related_url,
         :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
         :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
         :visibility]
      )
    end

    it "doesn't contain fields that users shouldn't be allowed to edit" do
      # date_uploaded is reserved for the original creation date of the record.
      expect(subject.terms).not_to include(:date_uploaded)
    end
  end

  describe "field initialization" do
    before do
      change_set.prepopulate!
    end
    it 'initializes multivalued fields' do
      expect(subject.title).to eq ['']
    end
  end

  describe "#version_list" do
    subject { change_set.version_list }

    it { is_expected.to be_kind_of Hyrax::VersionListPresenter }
  end
end
