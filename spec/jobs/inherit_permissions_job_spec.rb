RSpec.describe InheritPermissionsJob do
  let(:user) { create(:user) }
  let(:file_set) { create_for_repository(:file_set, user: user) }

  context "when edit people change" do
    let(:work) { create_for_repository(:work, user: user, edit_users: ['abc@123.com'], member_ids: [file_set.id]) }

    it 'copies permissions to its contained files' do
      # files have the depositor as the edit user to begin with
      expect(file_set.edit_users).to eq [user.to_s]

      described_class.perform_now(work)
      reloaded = Hyrax::Queries.find_by(id: work.id)
      reloaded.file_sets.each do |file|
        expect(file.edit_users).to match_array [user.to_s, "abc@123.com"]
      end
    end

    context "when people should be removed" do
      let(:file_set) { create_for_repository(:file_set, user: user, edit_users: ['remove_me']) }

      it 'copies permissions to its contained files' do
        # files have the depositor as the edit user to begin with
        expect(file_set.edit_users).to match_array [user.to_s, "remove_me"]

        described_class.perform_now(work)
        reloaded = Hyrax::Queries.find_by(id: work.id)
        reloaded.file_sets.each do |file|
          expect(file.edit_users).to match_array [user.to_s, "abc@123.com"]
        end
      end
    end
  end

  context "when read people change" do
    let(:work) { create_for_repository(:work, user: user, read_users: ['abc@123.com'], member_ids: [file_set.id]) }

    it 'copies permissions to its contained files' do
      # files have the depositor as the edit user to begin with
      expect(file_set.read_users).to eq []

      described_class.perform_now(work)
      reloaded = Hyrax::Queries.find_by(id: work.id)
      reloaded.file_sets.each do |file|
        expect(file.read_users).to match_array ["abc@123.com"]
        expect(file.edit_users).to match_array [user.to_s]
      end
    end
  end

  context "when read groups change" do
    let(:work) { create_for_repository(:work, user: user, read_groups: ['my_read_group'], member_ids: [file_set.id]) }

    it 'copies permissions to its contained files' do
      # files have the depositor as the edit user to begin with
      expect(file_set.read_groups).to eq []

      described_class.perform_now(work)
      reloaded = Hyrax::Queries.find_by(id: work.id)
      reloaded.file_sets.each do |file|
        expect(file.read_groups).to match_array ["my_read_group"]
        expect(file.edit_users).to match_array [user.to_s]
      end
    end
  end

  context "when edit groups change" do
    let(:work) { create_for_repository(:work, user: user, edit_groups: ['my_edit_group'], member_ids: [file_set.id]) }

    it 'copies permissions to its contained files' do
      # files have the depositor as the edit user to begin with
      expect(file_set.read_groups).to eq []

      described_class.perform_now(work)
      reloaded = Hyrax::Queries.find_by(id: work.id)
      reloaded.file_sets.each do |file|
        expect(file.edit_groups).to match_array ["my_edit_group"]
        expect(file.edit_users).to match_array [user.to_s]
      end
    end
  end
end
