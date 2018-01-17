RSpec.describe Hyrax::BatchUploadChangeSet do
  subject(:change_set) { described_class.new(work, depositor: user.user_key) }

  let(:work) { GenericWork.new }
  let(:user) { build(:user) }

  describe "#primary_terms" do
    subject { change_set.primary_terms }

    it { is_expected.to eq [:creator, :keyword, :rights_statement] }
    it { is_expected.not_to include(:title) }
  end

  describe "#secondary_terms" do
    subject { change_set.secondary_terms }

    it { is_expected.not_to include(:title) } # title is per file, not per form
  end

  describe ".model_name" do
    subject { described_class.model_name }

    it "has a route_key" do
      expect(subject.route_key).to eq 'batch_uploads'
    end
    it "has a param_key" do
      expect(subject.param_key).to eq 'batch_upload_item'
    end
  end

  describe "#to_model" do
    subject { change_set.to_model }

    it "returns itself" do
      expect(subject.to_model).to be_kind_of described_class
    end
  end

  describe "#fields" do
    subject { change_set.fields.keys }

    it do
      is_expected.to match_array ['creator',
                                  'keyword',
                                  'rights_statement',
                                  'created_at',
                                  'updated_at',
                                  'depositor',
                                  'date_uploaded',
                                  'date_modified',
                                  'proxy_depositor',
                                  'on_behalf_of',
                                  "edit_groups", "edit_users", "read_groups", "read_users",
                                  'label',
                                  'relative_path',
                                  'contributor',
                                  'description',
                                  'license',
                                  'publisher',
                                  'date_created',
                                  'subject',
                                  'language',
                                  'identifier',
                                  'related_url',
                                  'source',
                                  'resource_type',
                                  'based_near',
                                  'arkivo_checksum',
                                  'admin_set_id',
                                  'member_of_collection_ids',
                                  'member_ids',
                                  'thumbnail_id',
                                  'representative_id']
    end
  end
end
