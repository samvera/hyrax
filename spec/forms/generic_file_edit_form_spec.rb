require 'spec_helper'

describe CurationConcerns::Forms::GenericFileEditForm do
  subject { described_class.new(GenericFile.new) }

  describe '#terms' do
    it 'returns a list' do
      expect(subject.terms).to eq([:resource_type, :title, :creator, :contributor, :description, :tag,
                                   :rights, :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url])
    end

    it "doesn't contain fields that users shouldn't be allowed to edit" do
      # date_uploaded is reserved for the original creation date of the record.
      expect(subject.terms).not_to include(:date_uploaded)
    end
  end

  it 'initializes multivalued fields' do
    expect(subject.title).to eq ['']
  end

  describe '.model_attributes' do
    let(:params) { ActionController::Parameters.new(title: ['foo'], description: [''], 'permissions_attributes' => { '2' => { 'access' => 'edit', '_destroy' => 'true', 'id' => 'a987551e-b87f-427a-8721-3e5942273125' } }) }
    subject { described_class.model_attributes(params) }

    it 'changes only the title' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['permissions_attributes']).to eq('2' => { 'access' => 'edit', 'id' => 'a987551e-b87f-427a-8721-3e5942273125', '_destroy' => 'true' })
    end
  end
end
