# frozen_string_literal: true

RSpec.describe Hyrax::Transactions::Steps::SyncRedirectPaths do
  subject(:step) { described_class.new }

  let(:resource_id) { 'res-1' }
  let(:entry_class) { Struct.new(:path, keyword_init: true) }
  let(:resource_class) do
    Struct.new(:id, :redirects)
  end
  let(:resource) { resource_class.new(resource_id, redirects) }
  let(:redirects) { [entry_class.new(path: '/handle/1'), entry_class.new(path: '/handle/2')] }

  before do
    allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
    allow(Flipflop).to receive(:redirects?).and_return(true)
    Hyrax::RedirectPath.delete_all
  end

  describe '#call' do
    context 'when feature is fully enabled and resource has redirects' do
      it 'replaces existing rows for the resource with the current redirect set' do
        Hyrax::RedirectPath.create!(path: '/old', resource_id: resource_id)
        result = step.call(resource)
        expect(result).to be_success
        paths = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:path)
        expect(paths).to contain_exactly('/handle/1', '/handle/2')
      end
    end

    context 'when a path is already claimed by another resource' do
      before { Hyrax::RedirectPath.create!(path: '/handle/1', resource_id: 'other-record') }

      it 'returns Failure with a redirect_path_collision tag' do
        result = step.call(resource)
        expect(result).to be_failure
        expect(result.failure.first).to eq(:redirect_path_collision)
      end
    end

    context 'when the config is off' do
      before { allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false) }

      it 'is a no-op (returns Success without touching the table)' do
        expect(Hyrax::RedirectPath).not_to receive(:transaction)
        expect(step.call(resource)).to be_success
      end
    end

    context 'when the Flipflop is off' do
      before { allow(Flipflop).to receive(:redirects?).and_return(false) }

      it 'is a no-op (returns Success without touching the table)' do
        expect(Hyrax::RedirectPath).not_to receive(:transaction)
        expect(step.call(resource)).to be_success
      end
    end

    context 'when the resource has no redirects attribute' do
      let(:resource_class) { Struct.new(:id) }
      let(:resource) { resource_class.new(resource_id) }

      it 'is a no-op' do
        expect(step.call(resource)).to be_success
      end
    end

    context "when the resource's redirects haven't changed since the last sync" do
      let(:original_created_at) { 1.day.ago.change(usec: 0) }

      before do
        Hyrax::RedirectPath.create!(path: '/handle/1', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
        Hyrax::RedirectPath.create!(path: '/handle/2', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
      end

      it 'leaves existing rows untouched (preserves created_at)' do
        result = step.call(resource)
        expect(result).to be_success

        rows = Hyrax::RedirectPath.where(resource_id: resource_id).order(:path)
        expect(rows.pluck(:path)).to eq %w[/handle/1 /handle/2]
        expect(rows.pluck(:created_at)).to all(eq(original_created_at))
      end
    end

    context "when the resource's redirects differ in order only" do
      let(:original_created_at) { 1.day.ago.change(usec: 0) }
      let(:redirects) do
        # Same paths as the existing rows, just listed in reverse order on the resource.
        [entry_class.new(path: '/handle/2'), entry_class.new(path: '/handle/1')]
      end

      before do
        Hyrax::RedirectPath.create!(path: '/handle/1', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
        Hyrax::RedirectPath.create!(path: '/handle/2', resource_id: resource_id, created_at: original_created_at, updated_at: original_created_at)
      end

      it 'recognizes the set is unchanged and leaves rows untouched' do
        result = step.call(resource)
        expect(result).to be_success
        expect(Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:created_at))
          .to all(eq(original_created_at))
      end
    end
  end
end
