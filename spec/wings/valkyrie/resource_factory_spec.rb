# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'wings'

RSpec.describe Wings::Valkyrie::ResourceFactory, :active_fedora do
  subject(:factory) { described_class.new(adapter: adapter) }
  let(:adapter)     { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:work)        { GenericWork.new }

  describe '#to_resource' do
    it 'returns a valkyrie_resource for the object' do
      expect(factory.to_resource(object: work)).to be_a Valkyrie::Resource
    end
  end

  describe '#from_resource' do
    let(:resource) { work.valkyrie_resource }

    it 'returns an ActiveFedora object' do
      expect(factory.from_resource(resource: resource)).to be_a GenericWork
    end

    context 'with a FileSet' do
      let(:resource) { file_set.valkyrie_resource }
      let(:file_set) { FileSet.new }

      it 'returns an ActiveFedora object' do
        expect(factory.from_resource(resource: resource)).to be_a FileSet
      end
    end

    context 'with a FileMetadata' do
      let(:resource) { Hyrax::FileMetadata.new }

      it 'is a Hydra::PCDM::File' do
        expect(factory.from_resource(resource: resource)).to be_a Hydra::PCDM::File
      end

      context 'when it has a file identifier' do
        let(:resource) { Hyrax::FileMetadata.new(file_identifier: file.id) }
        let(:storage_adapter) { Valkyrie::StorageAdapter.find(:test_disk) }

        let(:file) do
          io = fixture_file_upload('/world.png', 'image/png')
          file_set = FactoryBot.valkyrie_create(:hyrax_file_set)
          storage_adapter.upload(file: io, resource: file_set, original_filename: 'test-world.png')
        end

        it 'returns an ActiveFedora::Base with the existing file' do
          expect(factory.from_resource(resource: resource))
            .to have_attributes(file_identifier: contain_exactly(file.id))
        end

        it 'still resolves for a missing identifier' do
          resource = Hyrax::FileMetadata.new(file_identifier: 'disk://made-up.png')

          expect(factory.from_resource(resource: resource))
            .to have_attributes(file_identifier: contain_exactly('disk://made-up.png'))
        end

        it 'still resolves for a missing adapter' do
          resource = Hyrax::FileMetadata.new(file_identifier: 'unknown://uh-oh.png')

          expect(factory.from_resource(resource: resource))
            .to have_attributes(file_identifier: contain_exactly('unknown://uh-oh.png'))
        end
      end
    end
  end
end
