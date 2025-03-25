# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::FileSetUpdate do
  subject(:tx)     { described_class.new }
  let(:file_set)   { FactoryBot.valkyrie_create(:hyrax_file_set, title: 'image.jpg') }
  let(:change_set) { Hyrax::Forms::AdministrativeSetForm.new(file_set) }
  let(:user)       { FactoryBot.create(:user) }
  let(:xmas)       { DateTime.parse('2022-12-25 11:30') }

  before { allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'sets attributes' do
      change_set.title = 'new file title'

      expect(tx.call(change_set).value!)
        .to have_attributes(title: contain_exactly('new file title'))
    end
  end
end
