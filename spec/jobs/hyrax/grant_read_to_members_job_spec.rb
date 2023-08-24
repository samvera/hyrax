# frozen_string_literal: true
RSpec.describe Hyrax::GrantReadToMembersJob, perform_enqueued: [Hyrax::GrantReadToMembersJob] do
  let(:depositor) { FactoryBot.create(:user) }

  context "when using active fedora", :active_fedora do
    let(:work) { FactoryBot.create(:work_with_files) }

    it 'loops over FileSet IDs, spawning a job for each' do
      work.member_ids.each do |file_set_id|
        expect(Hyrax::GrantReadJob).to receive(:perform_now).with(file_set_id, depositor.user_key, use_valkyrie: false).once
      end

      described_class.perform_later(work, depositor.user_key)
    end
  end

  context "when using valkyrie", valkyrie_adapter: :test_adapter  do
    let(:file_set1) { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:file_set2) { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, member_ids: [file_set1.id, file_set2.id]) }

    it 'loops over FileSet IDs, spawning a job for each' do
      work.member_ids.each do |file_set_id|
        expect(Hyrax::GrantReadJob).to receive(:perform_now).with(file_set_id, depositor.user_key, use_valkyrie: true).once
      end

      described_class.perform_later(work, depositor.user_key)
    end
  end
end
