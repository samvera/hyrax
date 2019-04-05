# frozen_string_literal: true
require 'spec_helper'
require 'wings'
require 'wings/active_fedora_converter'

RSpec.describe Wings::ActiveFedoraConverter, :clean_repo do
  subject(:converter) { described_class.new(resource: resource) }
  let(:adapter)       { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:attributes)    { { id: id } }
  let(:id)            { 'moomin_id' }
  let(:resource)      { work.valkyrie_resource }
  let(:work)          { GenericWork.new(attributes) }

  describe '#convert' do
    it 'returns the ActiveFedora model' do
      expect(converter.convert).to eq work
    end

    context 'with attributes' do
      let(:attributes) do
        FactoryBot.attributes_for(:generic_work)
      end

      it 'repopulates the attributes' do
        expect(converter.convert).to have_attributes(attributes)
      end

      it 'populates reflections'
    end

    context 'with an embargo' do
      let(:work) { FactoryBot.create(:embargoed_work) }

      it 'repopulates the embargo' do
        expect(converter.convert).to have_attributes(embargo_id: work.embargo_id)
      end
    end

    context 'with a lease' do
      let(:work) { FactoryBot.create(:leased_work) }

      it 'repopulates the lease' do
        expect(converter.convert).to have_attributes(lease_id: work.lease_id)
      end
    end

    context 'with a generic work with _id attributes' do
      let(:work) { FactoryBot.create(:work_with_representative_file, with_admin_set: true) }
      before do
        work.thumbnail_id = work.representative_id
      end

      it 'repopulates the _id attributes' do
        expect(converter.convert).to have_attributes(
          representative_id: work.representative_id,
          thumbnail_id: work.thumbnail_id,
          access_control_id: work.access_control_id,
          admin_set_id: work.admin_set_id
        )
      end
    end

    context 'with relationships' do
      subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

      let(:resource) { subject.build }

      context 'for member_of_collections' do
        let(:pcdm_object) { collection1 }

        let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }
        let(:collection2) { build(:public_collection_lw, id: 'col2', title: ['Collection 2']) }
        let(:collection3) { build(:public_collection_lw, id: 'col3', title: ['Collection 3']) }

        before do
          collection1.member_of_collections = [collection2, collection3]
          collection1.save!
        end

        it 'converts member_of_collection_ids back to af_object' do
          expect(converter.convert.member_of_collections.map(&:id)).to match_array [collection2.id, collection3.id]
        end
      end

      context 'for members' do
        let(:pcdm_object) { work1 }

        let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }
        let(:work2)       { build(:work, id: 'wk2', title: ['Work 2']) }
        let(:work3)       { build(:work, id: 'wk3', title: ['Work 3']) }

        before do
          work1.ordered_members = [work2, work3]
          work1.save!
        end

        it 'converts member_of_collection_ids back to af_object' do
          expect(converter.convert.members.map(&:id)).to match_array [work3.id, work2.id]
        end

        it 'preserves order across conversion' do
          expect(converter.convert.ordered_member_ids).to eq [work2.id, work3.id]
        end
      end
    end
  end
end
