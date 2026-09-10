# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/add_to_collections'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::AddToCollections do
  subject(:step)   { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { FactoryBot.build(:hyrax_work) }

  describe '#call' do
    let(:collections) do
      [FactoryBot.valkyrie_create(:hyrax_collection),
       FactoryBot.valkyrie_create(:hyrax_collection)]
    end

    let(:collection_ids) { collections.map(&:id) }

    it 'is a success' do
      expect(step.call(change_set)).to be_success
    end

    it 'adds given collections' do
      expect(step.call(change_set, collection_ids: collection_ids).value!)
        .to have_attributes member_of_collection_ids: contain_exactly(*collection_ids)
    end

    context 'when resource already has collections' do
      let(:resource) { build(:hyrax_work, :as_member_of_multiple_collections) }

      it 'does not override collection membership' do
        expect(step.call(change_set).value!)
          .to have_attributes(
            member_of_collection_ids: contain_exactly(*resource.member_of_collection_ids)
          )
      end

      it 'adds new collections to existing ones' do
        expected = resource.member_of_collection_ids + collection_ids

        expect(step.call(change_set, collection_ids: collection_ids).value!)
          .to have_attributes(member_of_collection_ids: contain_exactly(*expected))
      end
    end

    context 'when work already belongs to a single membership collection' do
      before do
        allow_any_instance_of(Hyrax::MultipleMembershipChecker) # rubocop:disable RSpec/AnyInstance
          .to receive(:check).with(any_args).and_return('VIOLATION')
      end

      it 'is a failure' do
        expect(step.call(change_set, collection_ids: collection_ids)).to be_failure
      end
    end

    context 'when the resource is a collection' do
      let(:resource) { FactoryBot.build(:hyrax_collection) }

      before do
        allow_any_instance_of(Hyrax::MultipleMembershipChecker) # rubocop:disable RSpec/AnyInstance
          .to receive(:check).with(any_args).and_return('VIOLATION')
      end

      it 'skips the multiple membership check' do
        expect(step.call(change_set, collection_ids: collection_ids)).to be_success
      end

      context 'with a form class outside the PcdmCollectionForm hierarchy' do
        let(:change_set) { form_class.new(resource: resource) }
        let(:form_class) do
          Class.new(Hyrax::Forms::ResourceForm) do
            property :member_of_collection_ids, default: [], type: Valkyrie::Types::Array

            def self.name
              'CustomCollectionForm'
            end
          end
        end

        it 'skips the multiple membership check' do
          expect(step.call(change_set, collection_ids: collection_ids)).to be_success
        end
      end
    end
  end
end
