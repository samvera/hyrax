RSpec.describe Hyrax::Forms::BatchEditForm do
  let(:model) { GenericWork.new }
  let(:work1) do
    create :generic_work,
           title: ["title 1"],
           keyword: ["abc"],
           creator: ["Wilma"],
           language: ['en'],
           contributor: ['contributor1'],
           description: ['description1'],
           rights: ['rights1'],
           subject: ['subject1'],
           identifier: ['id1'],
           based_near: ['based_near1'],
           related_url: ['related_url1']
  end

  # Using a different work type in order to show that the form supports
  # batches containing multiple types of works
  let(:work2) do
    RareBooks::Atlas.create!(
      title: ["title 2"],
      keyword: ["123"],
      creator: ["Fred"],
      publisher: ['Rand McNally'],
      language: ['en'],
      resource_type: ['bar'],
      contributor: ['contributor2'],
      description: ['description2'],
      rights: ['rights2'],
      subject: ['subject2'],
      identifier: ['id2'],
      based_near: ['based_near2'],
      related_url: ['related_url2']
    )
  end

  let(:batch) { [work1.id, work2.id] }
  let(:form) { described_class.new(model, ability, batch) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }

  describe "#terms" do
    subject { form.terms }
    it do
      is_expected.to eq [:creator,
                         :contributor,
                         :description,
                         :keyword,
                         :resource_type,
                         :rights,
                         :publisher,
                         :date_created,
                         :subject,
                         :language,
                         :identifier,
                         :based_near,
                         :related_url]
    end
  end

  describe "#model" do
    it "combines the models in the batch" do
      expect(form.model.creator).to match_array ["Wilma", "Fred"]
      expect(form.model.contributor).to match_array ["contributor1", "contributor2"]
      expect(form.model.description).to match_array ["description1", "description2"]
      expect(form.model.keyword).to match_array ["abc", "123"]
      expect(form.model.resource_type).to match_array ["bar"]
      expect(form.model.rights).to match_array ["rights1", "rights2"]
      expect(form.model.publisher).to match_array ["Rand McNally"]
      expect(form.model.subject).to match_array ["subject1", "subject2"]
      expect(form.model.language).to match_array ["en"]
      expect(form.model.identifier).to match_array ["id1", "id2"]
      expect(form.model.based_near).to match_array ["based_near1", "based_near2"]
      expect(form.model.related_url).to match_array ["related_url1", "related_url2"]
    end
  end

  describe ".build_permitted_params" do
    subject { described_class.build_permitted_params }
    it do
      is_expected.to eq [{ creator: [] },
                         { contributor: [] },
                         { description: [] },
                         { keyword: [] },
                         { resource_type: [] },
                         { rights: [] },
                         { publisher: [] },
                         { date_created: [] },
                         { subject: [] },
                         { language: [] },
                         { identifier: [] },
                         { based_near: [] },
                         { related_url: [] },
                         { permissions_attributes: [:type, :name, :access, :id, :_destroy] },
                         :on_behalf_of,
                         :version,
                         :visibility_during_embargo,
                         :embargo_release_date,
                         :visibility_after_embargo,
                         :visibility_during_lease,
                         :lease_expiration_date,
                         :visibility_after_lease,
                         :visibility]
    end
  end
end
