# frozen_string_literal: true

RSpec.shared_examples 'a Hyrax::Resource indexer' do
  subject(:indexer)  { indexer_class.new(resource: the_resource) }
  let(:the_resource) { defined?(resource) ? resource : Hyrax::Resource.new }
  let(:ids)          { ['id1', 'id2'] }

  describe '#to_solr' do
    before { the_resource.alternate_ids = ids }
    it 'indexes alternate_ids' do
      expect(indexer.to_solr)
        .to include(alternate_ids_sm: a_collection_containing_exactly(*ids))
    end
  end
end

RSpec.shared_examples 'a permission indexer' do
  subject(:indexer) { indexer_class.new(resource: the_resource) }
  let(:the_resource) do
    if defined?(resource)
      Hyrax::VisibilityWriter.new(resource: resource)
          .assign_access_for(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      resource.permission_manager.edit_groups = edit_groups
      resource.permission_manager.edit_users  = edit_users
      resource.permission_manager.read_users  = read_users
      resource.permission_manager.acl.save
      resource
    else
      FactoryBot.valkyrie_create(:hyrax_work, :public,
                                 read_users: read_users,
                                 edit_groups: edit_groups,
                                 edit_users: edit_users)
    end
  end
  let(:edit_groups) { [:managers] }
  let(:edit_users)  { [FactoryBot.create(:user)] }
  let(:read_users)  { [FactoryBot.create(:user)] }

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
  subject(:indexer)  { indexer_class.new(resource: the_resource) }
  let(:the_resource) { defined?(resource) ? resource : FactoryBot.build(:hyrax_work) }

  describe '#to_solr' do
    it 'indexes visibility' do
      expect(indexer.to_solr).to include(visibility_ssi: 'restricted')
    end

    context 'when resource is public' do
      before do
        Hyrax::VisibilityWriter.new(resource: the_resource)
          .assign_access_for(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end

      it 'indexes as open' do
        expect(indexer.to_solr).to include(visibility_ssi: 'open')
      end
    end
  end
end

RSpec.shared_examples 'a Basic metadata indexer' do
  subject(:indexer) { indexer_class.new(resource: the_resource) }
  let(:the_resource) { defined?(resource) ? resource : resource_class.new }

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
    before { attributes.each { |k, v| the_resource.set_value(k, v) } }
    it 'indexes basic metadata' do
      expect(indexer.to_solr)
        .to include(keyword_sim:   a_collection_containing_exactly(*attributes[:keyword]),
                    subject_tesim: a_collection_containing_exactly(*attributes[:subject]),
                    subject_sim:   a_collection_containing_exactly(*attributes[:subject]))
    end
  end
end

RSpec.shared_examples 'a Collection indexer' do
  subject(:indexer) { indexer_class.new(resource: the_resource) }
  let(:the_resource) { defined?(resource) ? resource : FactoryBot.valkyrie_create(:hyrax_collection) }

  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'

  describe '#to_solr' do
    it 'indexes generic type' do
      expect(indexer.to_solr)
        .to include(generic_type_sim: a_collection_containing_exactly('Collection'))
    end

    it 'indexes thumbnail' do
      expect(indexer.to_solr)
        .to include(thumbnail_path_ss: include('assets/collection', '.png'))
    end
  end
end

RSpec.shared_examples 'a Core metadata indexer' do
  subject(:indexer) { indexer_class.new(resource: the_resource) }
  let(:titles)      { ['Comet in Moominland', 'Finn Family Moomintroll'] }
  let(:the_resource) { defined?(resource) ? resource : Hyrax::Work.new }

  describe '#to_solr' do
    before { the_resource.title = titles }
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
