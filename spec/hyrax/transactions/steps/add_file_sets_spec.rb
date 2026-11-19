# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::AddFileSets, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  it 'gives success' do
    expect(step.call(work)).to be_success
  end

  context 'with uploaded files' do
    let(:uploaded_files) { FactoryBot.create_list(:uploaded_file, 4) }

    it 'attaches file_sets for the files' do
      expect(step.call(work, uploaded_files: uploaded_files).value!)
        .to have_file_set_members(be_persisted, be_persisted,
                                  be_persisted, be_persisted)
    end
  end

  context 'with a copy of the work read before another upload attached a file set' do
    let(:uploaded_files) { FactoryBot.create_list(:uploaded_file, 1) }
    let(:other_upload) { FactoryBot.create(:uploaded_file) }

    it 'keeps the other file set and returns the work with both' do
      stale_work = work.dup
      Hyrax::WorkUploadsHandler.new(work: work).add(files: [other_upload]).attach

      expect(step.call(stale_work, uploaded_files: uploaded_files).value!.member_ids.size).to eq(2)
      expect(Hyrax.query_service.find_by(id: work.id).member_ids.size).to eq(2)
    end
  end
end
