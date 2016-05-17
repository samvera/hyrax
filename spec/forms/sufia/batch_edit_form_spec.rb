require 'spec_helper'

describe Sufia::Forms::BatchEditForm do
  let(:model) { GenericWork.new }
  let(:work1) { create :generic_work, title: ["title 1"], keyword: ["abc"], creator: ["Wilma"], language: ['en'], contributor: ['contributor1'], description: ['description1'], rights: ['rights1'], subject: ['subject1'], identifier: ['id1'], based_near: ['based_near1'], related_url: ['related_url1'] }
  let(:work2) { create :generic_work, title: ["title 2"], keyword: ["123"], creator: ["Fred"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar'], contributor: ['contributor2'], description: ['description2'], rights: ['rights2'], subject: ['subject2'], identifier: ['id2'], based_near: ['based_near2'], related_url: ['related_url2'] }
  let(:batch) { [work1.id, work2.id] }
  let(:form) { described_class.new(model, ability, batch) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }

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
                            :related_url] }
  end

  describe "#model" do
    it "combines the models in the batch" do
      expect(form.model.creator).to eq ["Wilma", "Fred"]
      expect(form.model.contributor).to eq ["contributor1", "contributor2"]
      expect(form.model.description).to eq ["description1", "description2"]
      expect(form.model.keyword).to eq ["abc", "123"]
      expect(form.model.rights).to eq ["rights1", "rights2"]
      expect(form.model.publisher).to eq ["Rand McNally"]
      expect(form.model.subject).to eq ["subject1", "subject2"]
      expect(form.model.language).to eq ["en"]
      expect(form.model.identifier).to eq ["id1", "id2"]
      expect(form.model.based_near).to eq ["based_near1", "based_near2"]
      expect(form.model.related_url).to eq ["related_url1", "related_url2"]
    end
  end
end
