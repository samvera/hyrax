require 'spec_helper'

describe CopyPermissionsJob do
  let(:user) { FactoryGirl.create(:user) }
  context 'for valid pid' do
    let(:generic_work) { FactoryGirl.create(:generic_work, user: user) }
    let(:another_user) { FactoryGirl.create(:user) }
    let(:generic_file_1) { FactoryGirl.create(:generic_file, user: user) }
    let(:generic_file_2) { FactoryGirl.create(:generic_file, user: user) }

    before do
      generic_work.edit_users += [another_user]
      generic_work.generic_files = [generic_file_1, generic_file_2]
      generic_work.save
    end
    subject { described_class.new(generic_work.id) }

    it 'applies group/editors permissions to attached files' do
      expect(generic_work.generic_files).to eq [generic_file_1, generic_file_2]
      expect(generic_work.edit_users).to eq [user.user_key, another_user.user_key]
      expect(generic_file_1.edit_users).to eq [user.user_key]
      expect(generic_file_2.edit_users).to eq [user.user_key]
      generic_work.save

      subject.run

      generic_work.reload.generic_files.each do |file|
        expect(file.edit_users).to eq [user.user_key, another_user.user_key]
      end
    end
  end

  describe 'an open access work' do
    let(:generic_work) { FactoryGirl.create(:work_with_files) }
    subject { described_class.new(generic_work.id) }

    it 'copies visibility to its contained files' do
      generic_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      generic_work.save
      expect(generic_work.generic_files.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.run
      generic_work.reload.generic_files.each do |file|
        expect(file.visibility).to eq 'open'
      end
    end
  end
end
