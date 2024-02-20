# frozen_string_literal: true

# These shared specs test various aspects of valkyrie based indexers by calling the #to_solr method.
# All tests require two variables to be set in the caller using let statements:
#   * indexer_class - class of the indexer being tested
#   * resource - a Hyrax::Resource that defines attributes and values consistent with the indexer
#
# NOTE: It is important that the resource has required values that the indexer #to_solr customizations expects to be available.
RSpec.shared_examples 'a Hyrax::Resource indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    resource.alternate_ids = ids
  end
  subject(:indexer)  { indexer_class.new(resource: resource) }
  let(:ids)          { ['id1', 'id2'] }

  describe '#to_solr' do
    it 'indexes base resource fields' do
      expect(indexer.to_solr)
        .to include(has_model_ssim: resource.to_rdf_representation,
                    human_readable_type_tesim: resource.human_readable_type,
                    alternate_ids_sim: a_collection_containing_exactly(*ids))
    end
  end
end

RSpec.shared_examples 'a permission indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for these tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    Hyrax::VisibilityWriter.new(resource: resource)
        .assign_access_for(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    resource.permission_manager.edit_groups = edit_groups
    resource.permission_manager.edit_users  = edit_users
    resource.permission_manager.read_users  = read_users
    resource.permission_manager.acl.save
  end
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:edit_groups) { [:managers] }
  let(:edit_users)  { [FactoryBot.create(:user)] }
  let(:read_users)  { [FactoryBot.create(:user)] }

  describe '#to_solr' do
    it 'indexes read permissions' do
      expect(indexer.to_solr)
        .to include(Hydra.config.permissions.read.group => [Hyrax.config.public_user_group_name],
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
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    # optionally can pass in default_visibility by setting it with a let statement if your application changes the default; Hyrax defines this as 'restricted'
    # See samvera/hyrda-head hydra-access-controls/app/models/concerns/hydra/access_controls/access_rights.rb for possible VISIBILITY_TEXT_VALUE_...'
  end
  subject(:indexer)  { indexer_class.new(resource: resource) }

  describe '#to_solr' do
    it 'indexes default visibility as restricted or passed in default' do
      expected_value = defined?(default_visibility) ? default_visibility : 'restricted'
      expect(indexer.to_solr).to include(visibility_ssi: expected_value)
    end

    context 'when resource is public' do
      before do
        Hyrax::VisibilityWriter.new(resource: resource)
          .assign_access_for(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end

      it 'indexes as open' do
        expect(indexer.to_solr).to include(visibility_ssi: 'open')
      end
    end
  end
end

RSpec.shared_examples 'a thumbnail indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
  end
  subject(:indexer)  { indexer_class.new(resource: resource) }
  let(:thumbnail_path) { '/downloads/foo12345?file=thumbnail' }

  before do
    allow(indexer.thumbnail_path_service).to receive(:call).and_return(thumbnail_path)
  end

  describe '#to_solr' do
    it 'indexes a thumbnail path' do
      expect(indexer.to_solr).to include(thumbnail_path_ss: thumbnail_path)
    end
  end
end

RSpec.shared_examples 'a location indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    resource.based_near = based_near
  end
  subject(:indexer)  { indexer_class.new(resource: resource) }
  let(:based_near) { ["https://sws.geonames.org/4254679/"] }
  let(:based_near_label) { ["Bloomington, Indiana, United States"] }

  before do
    allow(Hyrax.config.location_service).to receive(:full_label).with(based_near[0]).and_return(based_near_label[0])
  end

  describe '#to_solr' do
    it 'indexes locations' do
      expect(indexer.to_solr).to include(based_near_tesim: based_near, based_near_label_tesim: based_near_label)
    end
  end
end

RSpec.shared_examples 'a Core metadata indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: The resource's class is expected to have or inherit `include Hyrax::Schema(:core_metadata)`
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    resource.title = titles
  end
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:titles)      { ['Comet in Moominland', 'Finn Family Moomintroll'] }

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

RSpec.shared_examples 'a Basic metadata indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: The resource's class is expected to to have or inherit `include Hyrax::Schema(:basic_metadata)`
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Resource' unless defined?(resource) && resource.kind_of?(Hyrax::Resource)
    attributes.each { |k, v| resource.set_value(k, v) }
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  it_behaves_like 'a location indexer'

  let(:attributes) do
    {
      date_created: ['tuesday'],
      keyword: ['comic strip'],
      related_url: ['http://example.com/moomin'],
      resource_type: ['book'],
      subject: ['moomins', 'snorks']
    }
  end

  describe '#to_solr' do
    it 'indexes basic metadata' do
      expect(indexer.to_solr)
        .to include(date_created_tesim: a_collection_containing_exactly(*attributes[:date_created]),
                    keyword_sim: a_collection_containing_exactly(*attributes[:keyword]),
                    related_url_tesim: a_collection_containing_exactly(*attributes[:related_url]),
                    resource_type_tesim: a_collection_containing_exactly(*attributes[:resource_type]),
                    resource_type_sim: a_collection_containing_exactly(*attributes[:resource_type]),
                    subject_tesim: a_collection_containing_exactly(*attributes[:subject]),
                    subject_sim: a_collection_containing_exactly(*attributes[:subject]))
    end
  end
end

RSpec.shared_examples 'a File Set indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for permission tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::FileSet' unless defined?(resource) && resource.kind_of?(Hyrax::FileSet)
    # optionally can pass in default_visibility by setting it with a let statement if your application changes the default; Hyrax defines this as 'restricted'
    # See samvera/hyrda-head hydra-access-controls/app/models/concerns/hydra/access_controls/access_rights.rb for possible VISIBILITY_TEXT_VALUE_...'
  end
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:file_ids)          { ['fileid1', 'fileid2'] }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a Basic metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'
  it_behaves_like 'a thumbnail indexer'

  describe '#to_solr' do
    it 'indexes generic type' do
      expect(indexer.to_solr)
        .to include(generic_type_sim: a_collection_containing_exactly('FileSet'))
    end

    it 'indexed file ids' do
      expect(indexer.to_solr)
        .to include(file_ids_ssim: a_collection_containing_exactly(*ids))
    end

    it 'indexes representative id' do
      expect(indexer.to_solr)
        .to include(hasRelatedMediaFragment_ssim: a_collection_containing_exactly(an_instance_of(String)))
    end

    it 'indexes thumbnail id' do
      expect(indexer.to_solr)
        .to include(hasRelatedImage_ssim: a_collection_containing_exactly(an_instance_of(String)))
    end

    it 'indexes depositor' do
      expect(indexer.to_solr)
        .to include(depositor_ssim: [resource.depositor],
                    depositor_tesim: [resource.depositor])
    end
  end
end

RSpec.shared_examples 'a Work indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for permission tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::Work' unless defined?(resource) && resource.kind_of?(Hyrax::Work)
    # optionally can pass in default_visibility by setting it with a let statement if your application changes the default; Hyrax defines this as 'restricted'
    # See samvera/hyrda-head hydra-access-controls/app/models/concerns/hydra/access_controls/access_rights.rb for possible VISIBILITY_TEXT_VALUE_...'
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'
  it_behaves_like 'a thumbnail indexer'

  describe '#to_solr' do
    it 'indexes representative id' do
      expect(indexer.to_solr)
        .to include('hasRelatedMediaFragment_ssim': a_collection_containing_exactly(an_instance_of(String)))
    end

    it 'indexes thumbnail id' do
      expect(indexer.to_solr)
        .to include('hasRelatedImage_ssim': a_collection_containing_exactly(an_instance_of(String)))
    end
  end
end

RSpec.shared_examples 'a Collection indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for permission tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::PcdmCollection' unless defined?(resource) && resource.kind_of?(Hyrax::PcdmCollection)
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'
  it_behaves_like 'a thumbnail indexer'

  describe '#to_solr' do
    it 'indexes collection type gid' do
      expect(indexer.to_solr)
        .to include(collection_type_gid_ssim: a_collection_containing_exactly(an_instance_of(String)))
    end

    it 'indexes generic type' do
      expect(indexer.to_solr)
        .to include(generic_type_sim: a_collection_containing_exactly('Collection'))
    end

    it 'indexes member_of_collection_ids' do
      expect(indexer.to_solr)
        .to include(member_of_collection_ids_ssim: resource.member_of_collection_ids)
    end

    it 'indexes depositor' do
      expect(indexer.to_solr)
        .to include(depositor_ssim: [resource.depositor],
                    depositor_tesim: [resource.depositor])
    end
  end
end

RSpec.shared_examples 'an Administrative Set indexer' do
  before do
    raise 'indexer_class must be set with `let(:indexer_class)`' unless defined? indexer_class
    # NOTE: resource must be persisted for permission tests to pass
    raise 'resource must be set with `let(:resource)` and is expected to be a kind of Hyrax::AdministrativeSet' unless defined?(resource) && resource.kind_of?(Hyrax::AdministrativeSet)
  end
  subject(:indexer) { indexer_class.new(resource: resource) }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
  it_behaves_like 'a permission indexer'
  it_behaves_like 'a visibility indexer'

  describe '#to_solr' do
    it 'indexes collection type gid' do
      expect(indexer.to_solr)
        .to include(collection_type_gid_ssim: a_collection_containing_exactly(an_instance_of(String)))
    end

    it 'indexes generic type' do
      expect(indexer.to_solr)
        .to include(generic_type_sim: a_collection_containing_exactly('Admin Set'))
    end

    it 'indexes thumbnail' do
      expect(indexer.to_solr)
        .to include(thumbnail_path_ss: include('assets/collection', '.png'))
    end

    it 'indexes creator' do
      expect(indexer.to_solr)
        .to include(creator_ssim: [resource.creator],
                    creator_tesim: [resource.creator])
    end
  end
end
