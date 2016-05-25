describe Sufia::Forms::CollectionForm do
  describe "#terms" do
    subject { described_class.terms }

    it { is_expected.to eq [:resource_type,
                            :title,
                            :creator,
                            :contributor,
                            :description,
                            :keyword,
                            :rights,
                            :publisher,
                            :date_created,
                            :subject,
                            :language,
                            :representative_id,
                            :thumbnail_id,
                            :identifier,
                            :based_near,
                            :related_url,
                            :visibility] }
  end

  let(:collection) { build(:collection) }
  let(:form) { described_class.new(collection) }

  describe "#rendered_terms" do
    subject { form.rendered_terms }

    it { is_expected.to eq [
      :title,
      :creator,
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
      :resource_type
    ] }
  end
end
