RSpec.describe Hyrax::GrantEditToMembersJob do
  [true, false].each do |use_valkyrie|
    context "when use_valkyrie is #{use_valkyrie}" do
      let(:depositor) { create(:user) }
      let(:work) { build(:work) }
      let(:file_set_ids) { ['xyz123abc', 'abc789zyx'] }

      before do
        allow_any_instance_of(described_class).to receive(:file_set_ids).with(work).and_return(file_set_ids)
      end

      it 'loops over FileSet IDs, spawning a job for each' do
        file_set_ids.each do |file_set_id|
          expect(Hyrax::GrantEditJob).to receive(:perform_now).with(file_set_id, depositor.user_key, use_valkyrie).once
        end
        described_class.perform_now(work, depositor.user_key, use_valkyrie: use_valkyrie)
      end
    end
  end
end
