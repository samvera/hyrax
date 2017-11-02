# frozen_string_literals: true

RSpec.describe Hyrax::RevertFileChangeSetPersister do
  describe '#revert_content', skip: 'Fix after versioning is done.' do
    let(:file_set) { create_for_repository(:file_set, user: user) }
    let(:file1)    { "small_file.txt" }
    let(:version1) { "version1" }
    let(:restored_content) { file_set.reload.original_file }

    before do
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :inline
      actor.create_content(fixture_file_upload(file1))
      actor.create_content(fixture_file_upload('hyrax_generic_stub.txt'))
      ActiveJob::Base.queue_adapter = original_adapter
      actor.file_set.reload
    end

    it "restores the first versions's content and metadata" do
      actor.revert_content(version1)
      expect(restored_content.original_name).to eq file1
    end
  end
end
