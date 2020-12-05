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
end
