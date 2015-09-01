require 'spec_helper'

describe BatchUpdateJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:batch) { Batch.create }

  let!(:file) do
    GenericFile.new(batch: batch) do |file|
      file.apply_depositor_metadata(user)
      file.save!
    end
  end

  let!(:file2) do
    GenericFile.new(batch: batch) do |file|
      file.apply_depositor_metadata(user)
      file.save!
    end
  end

  describe "#perform" do
    let(:title) { { file.id => ['File One'], file2.id => ['File Two'] } }
    let(:metadata) do
      { read_groups_string: '', read_users_string: 'archivist1, archivist2',
        tag: [''] }.with_indifferent_access
    end

    let(:visibility) { nil }

    let(:job) { described_class.perform_now(user.user_key, batch.id, title, metadata, visibility) }

    it "updates file metadata" do
      expect(job).to eq true
      expect(file.reload.title).to eq ['File One']
    end

    context "when user does not have permission to edit all of the files" do
      before do
        expect_any_instance_of(User).to receive(:can?).with(:edit, file).and_return(true)
        expect_any_instance_of(User).to receive(:can?).with(:edit, file2).and_return(false)
      end
      it "does not run" do
        expect(job).to eq false
      end
    end
  end
end
