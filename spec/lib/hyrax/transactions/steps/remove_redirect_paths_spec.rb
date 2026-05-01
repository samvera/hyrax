# frozen_string_literal: true

RSpec.describe Hyrax::Transactions::Steps::RemoveRedirectPaths do
  subject(:step) { described_class.new }

  let(:resource_id) { 'res-1' }
  let(:resource_class) { Struct.new(:id) }
  let(:resource) { resource_class.new(resource_id) }

  before do
    allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
    Hyrax::RedirectPath.delete_all
  end

  describe '#call' do
    context 'when the resource has rows in the table' do
      before do
        Hyrax::RedirectPath.create!(path: '/handle/1', resource_id: resource_id)
        Hyrax::RedirectPath.create!(path: '/handle/2', resource_id: 'other-record')
      end

      it 'deletes only the resource\'s rows and returns Success' do
        result = step.call(resource)
        expect(result).to be_success
        expect(Hyrax::RedirectPath.where(resource_id: resource_id)).to be_empty
        expect(Hyrax::RedirectPath.where(resource_id: 'other-record').count).to eq(1)
      end
    end

    context 'when the config is off' do
      before { allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false) }

      it 'is a no-op (returns Success without touching the table)' do
        expect(Hyrax::RedirectPath).not_to receive(:where)
        expect(step.call(resource)).to be_success
      end
    end
  end
end
