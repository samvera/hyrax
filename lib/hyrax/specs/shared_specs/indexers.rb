# frozen_string_literal: true

RSpec.shared_examples 'a Hyrax::Resource indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:ids)         { ['id1', 'id2'] }
  let(:resource)    { Hyrax::Resource.new(alternate_ids: ids) }

  describe '#to_solr' do
    it 'indexes alternate_ids' do
      expect(indexer.to_solr)
        .to include(alternate_ids_sm: a_collection_containing_exactly(*ids))
    end
  end
end

RSpec.shared_examples 'a permission indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:edit_groups) { [:managers] }
  let(:edit_users)  { [FactoryBot.create(:user)] }
  let(:read_users)  { [FactoryBot.create(:user)] }

  let(:resource) do
    FactoryBot.valkyrie_create(:hyrax_work, :public,
                               read_users: read_users,
                               edit_groups: edit_groups,
                               edit_users: edit_users)
  end


  describe '#to_solr' do
    it 'indexes read permissions' do
      expect(indexer.to_solr)
        .to include(Hydra.config.permissions.read.group => ['public'],
                    Hydra.config.permissions.read.individual => read_users.map(&:user_key))
    end

    it 'indexes edit permissions' do
      expect(indexer.to_solr)
        .to include(Hydra.config.permissions.edit.group => edit_groups.map(&:to_s),
                    Hydra.config.permissions.edit.individual => edit_users.map(&:user_key))
    end
  end
end

RSpec.shared_examples 'a visibility indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:resource)    { FactoryBot.build(:hyrax_work) }

  describe '#to_solr' do
    it 'indexes visibility' do
      expect(indexer.to_solr).to include(visibility_ssi: 'restricted')
    end

    context 'when resource is public' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

      it 'indexes as open' do
        expect(indexer.to_solr).to include(visibility_ssi: 'open')
      end
    end
  end
end

RSpec.shared_examples 'a Basic metadata indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:resource)    { resource_class.new(**attributes) }

  let(:attributes) do
    {
      keyword: ['comic strip'],
      subject: ['moomins', 'snorks']
    }
  end

  let(:resource_class) do
    Class.new(Hyrax::Work) do
      include Hyrax::Schema(:basic_metadata)
    end
  end

  describe '#to_solr' do
    it 'indexes basic metadata' do
      expect(indexer.to_solr)
        .to include(keyword_sim: a_collection_containing_exactly(*attributes[:keyword]),
                    subject_tesim: a_collection_containing_exactly(*attributes[:subject]),
                    subject_sim:   a_collection_containing_exactly(*attributes[:subject]))
    end
  end
end

RSpec.shared_examples 'a Collection indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:resource)    { Hyrax::PcdmCollection.new }

  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'

  describe '#to_solr' do
    it 'indexes generic type' do
      expect(indexer.to_solr)
        .to include(generic_type_sim: a_collection_containing_exactly('Collection'))
    end
  end
end

RSpec.shared_examples 'a Core metadata indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:titles)      { ['Comet in Moominland', 'Finn Family Moomintroll'] }
  let(:resource)    { Hyrax::Work.new(title: titles) }

  describe '#to_solr' do
    it 'indexes title as text' do
      expect(indexer.to_solr)
        .to include(title_tesim: a_collection_containing_exactly(*titles))
    end

    it 'indexes title as string' do
      expect(indexer.to_solr)
        .to include(title_sim: a_collection_containing_exactly(*titles))
    end
  end
end
