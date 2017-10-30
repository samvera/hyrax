RSpec.describe GenericWorkChangeSet do
  subject(:change_set) { described_class.new(work) }

  let(:work) { GenericWork.new }

  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
  end

  describe "#fields" do
    subject { change_set.fields.keys }

    # rubocop:disable RSpec/ExampleLength
    it do
      is_expected.to eq ["created_at", "updated_at", "depositor", "title",
                         "date_uploaded", "date_modified", "admin_set_id",
                         "state", "proxy_depositor", "on_behalf_of",
                         "arkivo_checksum", "member_of_collection_ids",
                         "member_ids", "thumbnail_id", "representative_id",
                         "label", "relative_path", "resource_type", "creator",
                         "contributor", "description", "keyword", "license",
                         "rights_statement",
                         "publisher", "date_created", "subject", "language",
                         "identifier", "related_url", "source", "based_near"]
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe "#primary_terms" do
    subject { change_set.primary_terms }

    it { is_expected.to eq [:title, :creator, :keyword, :rights_statement] }
  end

  describe "#secondary_terms" do
    subject { change_set.secondary_terms }

    it do
      is_expected.not_to include(:title, :creator, :keyword,
                                 :visibilty, :visibility_during_embargo,
                                 :embargo_release_date, :visibility_after_embargo,
                                 :visibility_during_lease, :lease_expiration_date,
                                 :visibility_after_lease, :collection_ids)
    end
  end

  describe "#permissions" do
    let(:work) do
      GenericWork.new(edit_users: ['bob'],
                      read_users: ['lynda'],
                      edit_groups: ['librarians'],
                      read_groups: ['patrons'])
    end

    before do
      change_set.prepopulate!
    end

    it "has them" do
      expect(change_set.permissions[0].agent_name).to eq 'bob'
      expect(change_set.permissions[0].type).to eq 'person'
      expect(change_set.permissions[0].access).to eq 'edit'
    end
  end
end
