# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'
require 'wings/value_mapper'

RSpec.describe Wings::FileConverterService do
  let(:af_fileset) { build(:file_set, id: 'fsn1', title: ['AF Fileset']) }
  let(:resource)   { Wings::ModelTransformer.new(pcdm_object: af_fileset).build }

  let(:file_identifier) { 'af_fileid' }
  let(:file_name) { 'picture.jpg' }
  let(:content) { 'hello world' }
  let(:date_created) { Date.parse 'Fri, 08 May 2015 08:00:00 -0400 (EDT)' }
  let(:date_modified) { Date.parse 'Sat, 09 May 2015 09:00:00 -0400 (EDT)' }
  let(:byte_order) { 'little-endian' }
  let(:mime_type) { 'application/jpg' }

  let!(:af_file) { set_attrs_on_af_file(Hydra::PCDM::File.new) }
  let(:file_metadata) { FileMetadata.new(attrs_for_file_metadata) }

  describe '#convert_and_add_file_to_resource' do
    before { af_file }

    it 'adds the file to the resource' do
      described_class.convert_and_add_file_to_resource(af_file, resource)
      expect(resource.file_metadata.size).to eq 1
      resource_file_metadata = resource.file_metadata.first
      expect(resource_file_metadata.file_name).to eq [file_name]
      expect(resource_file_metadata.content).to eq [content]
      expect(resource_file_metadata.date_created).to eq [date_created]
      expect(resource_file_metadata.date_modified).to eq [date_modified]
      expect(resource_file_metadata.byte_order).to eq [byte_order]
      expect(resource_file_metadata.mime_type).to eq [mime_type]
    end
  end

  describe '#convert_and_add_file_to_af_object' do
    before do
      af_file
      file_metadata
    end

    it 'adds the file to the af_object' do
      described_class.convert_and_add_file_to_af_object(file_metadata, af_fileset)
      expect(af_fileset.files.size).to eq 1
      file = af_fileset.files.first
      expect(file.file_name).to eq [file_name]
      expect(file.content).to eq content
      expect(file.date_created).to eq [date_created]
      expect(file.date_modified).to eq [date_modified]
      expect(file.byte_order).to eq [byte_order]
      expect(file.mime_type).to eq mime_type
    end
  end

  private

    def set_attrs_on_af_file(af_file)
      af_file.file_name = [file_name]
      af_file.content = [content]
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
      attrs[:content] = Wings::ValueMapper.for([content]).result
      attrs[:date_created] = Wings::ValueMapper.for([date_created]).result
      attrs[:date_modified] = Wings::ValueMapper.for([date_modified]).result
      attrs[:byte_order] = Wings::ValueMapper.for([byte_order]).result
      attrs[:mime_type] = Wings::ValueMapper.for([mime_type]).result
      attrs
    end
end
