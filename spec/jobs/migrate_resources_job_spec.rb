# frozen_string_literal: true

require 'freyja/persister'
RSpec.describe MigrateResourcesJob, clean: true do
  before do
    ActiveJob::Base.queue_adapter = :test
    FactoryBot.create(:group, name: "public")
  end

  after do
    clear_enqueued_jobs
  end

  let(:account)        { create(:account_with_public_schema) }
  let(:af_file_set)       { create(:file_set, title: ['TestFS']) }

  let!(:af_admin_set) do
    as = AdminSet.new(title: ['AF Admin Set'])
    as.save
    AdminSet.find(as.id)
  end

  describe '#perform' do
    it "migrates admin sets to valkyrie", active_fedora_to_valkyrie: true do
      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_admin_set.id.to_s)).to be_nil

      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      switch!(account)
      MigrateResourcesJob.perform_now

      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_admin_set.id.to_s)).to be_present
    end

    it "migrates a file set by its id", active_fedora_to_valkyrie: true do
      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_file_set.id.to_s)).to be_nil

      ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
      switch!(account)
      MigrateResourcesJob.perform_now(ids: [af_file_set.id])

      expect(Valkyrie::Persistence::Postgres::ORM::Resource.find_by(id: af_file_set.id.to_s)).to be_present
    end
  end
end
