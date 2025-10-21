# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'hyrax/specs/shared_specs/simple_work'

RSpec.describe Hyrax::Transactions::Steps::AddFileSets, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  it 'gives success' do
    expect(step.call(work)).to be_success
  end

  context 'with uploaded files' do
    let(:uploaded_files) { FactoryBot.create_list(:uploaded_file, 16) }
    before { allow(Hyrax::WorkUploadsHandler).to receive(:new).and_call_original }

    it 'attaches file_sets for the files' do
      expect(step.call(work, uploaded_files: uploaded_files).value!)
        .to have_file_set_members(be_persisted, be_persisted, be_persisted, be_persisted,
                                  be_persisted, be_persisted, be_persisted, be_persisted,
                                  be_persisted, be_persisted, be_persisted, be_persisted,
                                  be_persisted, be_persisted, be_persisted, be_persisted)
      expect(Hyrax::WorkUploadsHandler).to have_received(:new).once
    end
  end
  context 'with file_set_limit set' do
    subject(:step) { described_class.new(file_set_batch_size: 5) }

    let(:uploaded_files) { FactoryBot.create_list(:uploaded_file, 16) }
    before { allow(Hyrax::WorkUploadsHandler).to receive(:new).and_call_original }

    it 'attaches file_sets for the files' do
      expect(step.call(work, uploaded_files: uploaded_files).value!)
        .to have_file_set_members(be_persisted, be_persisted, be_persisted, be_persisted,
                                  be_persisted, be_persisted, be_persisted, be_persisted,
                                  be_persisted, be_persisted, be_persisted, be_persisted,
                                  be_persisted, be_persisted, be_persisted, be_persisted)
      expect(Hyrax::WorkUploadsHandler).to have_received(:new).exactly(4).times
    end
  end
end
