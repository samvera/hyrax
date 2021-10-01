# frozen_string_literal: true

RSpec.describe Hyrax::Forms::PcdmCollectionForm do
  subject(:form)   { described_class.new(collection) }
  let(:collection) { Hyrax::PcdmCollection.new }

  describe '.required_fields' do
    it 'lists required fields' do
      expect(described_class.required_fields)
        .to contain_exactly(:title, :collection_type_gid, :depositor)
    end
  end

  describe '#primary_terms' do
    it 'gives "title" as a primary term' do
      expect(form.primary_terms).to contain_exactly(:title, :description)
    end
  end
end
