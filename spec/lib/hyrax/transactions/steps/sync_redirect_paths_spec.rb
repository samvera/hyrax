# frozen_string_literal: true

RSpec.describe Hyrax::Transactions::Steps::SyncRedirectPaths do
  subject(:step) { described_class.new }

  let(:resource_id) { 'res-1' }
  let(:resource_class) do
    Struct.new(:id, :redirects)
  end
  let(:resource) { resource_class.new(resource_id, redirects) }
  let(:redirects) { [{ 'path' => '/handle/1' }, { 'path' => '/handle/2' }] }
  let(:uuid_url) { "/concern/generic_works/#{resource_id}" }

  before do
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
    # Stub the UUID-URL helper to avoid real-route dependency in tests.
    allow(step).to receive(:permanent_path_for).and_return(uuid_url)
    Hyrax::RedirectPath.delete_all
  end

  describe '#call' do
    context 'when feature is fully enabled and resource has redirects' do
      it 'replaces existing rows for the resource with the current redirect set' do
        Hyrax::RedirectPath.create!(source_path: '/old', target_path: uuid_url, resource_id: resource_id)
        result = step.call(resource)
        expect(result).to be_success
        paths = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:source_path)
        expect(paths).to contain_exactly('/handle/1', '/handle/2')
      end

      it 'sets target_path to the UUID URL when no display flag is set' do
        step.call(resource)
        targets = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:target_path).uniq
        expect(targets).to eq([uuid_url])
      end

      it 'sets all rows display=false when no entry is flagged' do
        step.call(resource)
        flags = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:display)
        expect(flags).to all(be false)
      end
    end

    context 'when one entry is marked as the display URL' do
      let(:redirects) do
        [
          { 'path' => '/handle/1', 'display' => true },
          { 'path' => '/handle/2' }
        ]
      end

      it 'sets every row target_path to the display entry path' do
        step.call(resource)
        targets = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:target_path).uniq
        expect(targets).to eq(['/handle/1'])
      end

      it 'marks only the display entry display=true' do
        step.call(resource)
        rows = Hyrax::RedirectPath.where(resource_id: resource_id).order(:source_path).pluck(:source_path, :display)
        expect(rows).to eq([['/handle/1', true], ['/handle/2', false]])
      end
    end

    context 'when the display flag is removed from a previously-display alias' do
      let(:redirects) do
        # Same two paths as the existing rows, but neither is display now.
        [
          { 'path' => '/handle/1' },
          { 'path' => '/handle/2' }
        ]
      end

      before do
        Hyrax::RedirectPath.create!(source_path: '/handle/1', target_path: '/handle/1',
                                    display: true, resource_id: resource_id)
        Hyrax::RedirectPath.create!(source_path: '/handle/2', target_path: '/handle/1',
                                    display: false, resource_id: resource_id)
      end

      it 'reverts all target_path values to the UUID URL' do
        step.call(resource)
        targets = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:target_path).uniq
        expect(targets).to eq([uuid_url])
      end

      it 'clears the display flag on all rows' do
        step.call(resource)
        flags = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:display)
        expect(flags).to all(be false)
      end
    end

    context 'when the display flag is transferred to a different alias' do
      let(:redirects) do
        [
          { 'path' => '/handle/1' },
          { 'path' => '/handle/2', 'display' => true }
        ]
      end

      before do
        Hyrax::RedirectPath.create!(source_path: '/handle/1', target_path: '/handle/1',
                                    display: true, resource_id: resource_id)
        Hyrax::RedirectPath.create!(source_path: '/handle/2', target_path: '/handle/1',
                                    display: false, resource_id: resource_id)
      end

      it 'updates every row target_path to the new display entry path' do
        step.call(resource)
        targets = Hyrax::RedirectPath.where(resource_id: resource_id).pluck(:target_path).uniq
        expect(targets).to eq(['/handle/2'])
      end

      it 'moves the display flag to the new entry' do
        step.call(resource)
        rows = Hyrax::RedirectPath.where(resource_id: resource_id).order(:source_path).pluck(:source_path, :display)
        expect(rows).to eq([['/handle/1', false], ['/handle/2', true]])
      end
    end

    context 'when a path is already claimed by another resource' do
      before { Hyrax::RedirectPath.create!(source_path: '/handle/1', target_path: '/handle/1', resource_id: 'other-record') }

      it 'returns Failure with a redirect_path_collision tag' do
        result = step.call(resource)
        expect(result).to be_failure
        expect(result.failure.first).to eq(:redirect_path_collision)
      end
    end

    context 'when the underlying redirects table query raises StatementInvalid' do
      before do
        allow(Hyrax::RedirectPath).to receive(:where)
          .and_raise(ActiveRecord::StatementInvalid, 'PG::UndefinedTable: relation "hyrax_redirect_paths" does not exist')
        allow(Hyrax.logger).to receive(:error)
      end

      it 'returns Failure with a redirect_path_sync_error tag and logs the error' do
        result = step.call(resource)
        expect(result).to be_failure
        expect(result.failure.first).to eq(:redirect_path_sync_error)
        expect(Hyrax.logger).to have_received(:error).with(/sync_redirect_paths failed/)
      end
    end

    context 'when the redirects feature is inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

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
        Hyrax::RedirectPath.create!(source_path: '/handle/1', target_path: uuid_url, resource_id: resource_id,
                                    created_at: original_created_at, updated_at: original_created_at)
        Hyrax::RedirectPath.create!(source_path: '/handle/2', target_path: uuid_url, resource_id: resource_id,
                                    created_at: original_created_at, updated_at: original_created_at)
      end

      it 'leaves existing rows untouched (preserves created_at)' do
        result = step.call(resource)
        expect(result).to be_success

        rows = Hyrax::RedirectPath.where(resource_id: resource_id).order(:source_path)
        expect(rows.pluck(:source_path)).to eq %w[/handle/1 /handle/2]
        expect(rows.pluck(:created_at)).to all(eq(original_created_at))
      end
    end

    context "when the resource's redirects differ in order only" do
      let(:original_created_at) { 1.day.ago.change(usec: 0) }
      let(:redirects) do
        # Same paths as the existing rows, just listed in reverse order on the resource.
        [{ 'path' => '/handle/2' }, { 'path' => '/handle/1' }]
      end

      before do
        Hyrax::RedirectPath.create!(source_path: '/handle/1', target_path: uuid_url, resource_id: resource_id,
                                    created_at: original_created_at, updated_at: original_created_at)
        Hyrax::RedirectPath.create!(source_path: '/handle/2', target_path: uuid_url, resource_id: resource_id,
                                    created_at: original_created_at, updated_at: original_created_at)
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
