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

      context 'for files' do
        let(:pcdm_object) { fileset1 }

        let(:fileset1) { build(:file_set, id: 'fs1', title: ['Fileset 1']) }
        let(:file) { set_attrs_on_af_file(fileset1.files.build) }

        let(:file_identifier) { 'af_fileid' }
        let(:file_name) { 'picture.jpg' }
        let(:content) { 'hello world' }
        let(:date_created) { Date.parse 'Fri, 08 May 2015 08:00:00 -0400 (EDT)' }
        let(:date_modified) { Date.parse 'Sat, 09 May 2015 09:00:00 -0400 (EDT)' }
        let(:byte_order) { 'little-endian' }
        let(:mime_type) { 'application/jpg' }

        before do
          fileset1.save
          file.save
        end

        it 'converts member_of_collection_ids back to af_object' do
          expect(converter.convert.files.map(&:id)).to match_array [file.id]
        end
      end
    end
  end

  private

  def set_attrs_on_af_file(af_file)
    af_file.file_name = [file_name]
    af_file.content = content
    af_file.date_created = [date_created]
    af_file.date_modified = [date_modified]
    af_file.byte_order = [byte_order]
    af_file.mime_type = [mime_type]
    af_file
  end

  def attrs_for_file_metadata
    attrs = {}
    attrs[:file_identifiers] = Wings::ValueMapper.for([file_identifier]).result
    attrs[:file_name] = Wings::ValueMapper.for([file_name]).result
    attrs[:content] = Wings::ValueMapper.for(content).result
    attrs[:date_created] = Wings::ValueMapper.for([date_created]).result
    attrs[:date_modified] = Wings::ValueMapper.for([date_modified]).result
    attrs[:byte_order] = Wings::ValueMapper.for([byte_order]).result
    attrs[:mime_type] = Wings::ValueMapper.for([mime_type]).result
    attrs
  end

end
