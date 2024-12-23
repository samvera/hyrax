# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::AdminSetUpdate do
  subject(:tx)     { described_class.new }
  let(:admin_set)  { FactoryBot.valkyrie_create(:hyrax_admin_set) }
  let(:change_set) { Hyrax::Forms::AdministrativeSetForm.new(admin_set) }
  let(:user)       { FactoryBot.create(:user) }
  let(:xmas)       { DateTime.parse('2022-12-25 11:30') }

  before { allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'sets attributes' do
      change_set.title = 'new admin set title'

      expect(tx.call(change_set).value!)
        .to have_attributes(title: contain_exactly('new admin set title'))
    end
  end
end
