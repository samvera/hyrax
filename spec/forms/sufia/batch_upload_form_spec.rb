describe Sufia::BatchUploadForm do
  let(:model) { GenericWork.new }
  let(:form) { described_class.new(model, ability) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }

  describe "#primary_terms" do
    subject { form.primary_terms }
    it { is_expected.to eq [:creator, :keyword, :rights] }
  end

  describe "#secondary_terms" do
    subject { form.primary_terms }
    it "doesn't have title" do
      expect(subject).not_to include(:title)
    end
  end

  describe ".model_name" do
    subject { described_class.model_name }
    it "has a route_key" do
      expect(subject.route_key).to eq 'batch_uploads'
    end

    it "has a param_key" do
      derp = subject
      derp.param_key
      expect(subject.param_key).to eq 'generic_work'
    end
  end

  describe "#to_model" do
    subject { form.to_model }
    it "returns itself" do
      expect(subject.to_model).to be_kind_of described_class
    end
  end

  describe "#terms" do
    subject { form.terms }
    it { is_expected.to eq [:creator,
                            :contributor,
                            :description,
                            :keyword,
                            :rights,
                            :publisher,
                            :date_created,
                            :subject,
                            :language,
                            :identifier,
                            :based_near,
                            :related_url,
                            :representative_id,
                            :thumbnail_id,
                            :files,
                            :visibility_during_embargo,
                            :embargo_release_date,
                            :visibility_after_embargo,
                            :visibility_during_lease,
                            :lease_expiration_date,
                            :visibility_after_lease,
                            :visibility,
                            :ordered_member_ids,
                            :collection_ids] }
  end
end
