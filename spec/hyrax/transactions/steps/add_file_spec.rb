# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::AddFile, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:file_set)     { FactoryBot.valkyrie_create(:hyrax_file_set) }

  it 'gives success' do
    expect(step.call(file_set)).to be_success
  end

  context 'with uploaded files' do
    let(:uploaded_file) { FactoryBot.create(:uploaded_file) }

    it 'attaches files to the file_set' do
      pending('Getting the uploaded file to attach correctly')
      expect(step.call(file_set, uploaded_file: uploaded_file).value!)
        .to have_attached_files(be_original_file)
    end
  end
end
