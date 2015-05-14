require 'spec_helper'

describe CopyPermissionsJob do

  let(:user) { FactoryGirl.create(:user) }
  let(:another_user) { FactoryGirl.create(:user) }
  let(:generic_work) { FactoryGirl.create(:generic_work, user: user ) }
  let(:generic_file_1) { FactoryGirl.create(:generic_file, depositor: user) } 
  let(:generic_file_2) { FactoryGirl.create(:generic_file, depositor: user) } 

  context 'for valid pid' do
    before(:each) do
      generic_work.edit_users += [another_user]

      generic_work.generic_files = [generic_file_1, generic_file_2]
      
      generic_work.save

    end

    it 'should apply group/editors permissions to attached files' do

      expect(generic_work.generic_files).to eq [generic_file_1, generic_file_2]
      expect(generic_work.edit_users).to eq [user.user_key, another_user.user_key]
      expect(generic_file_1.edit_users).to eq [user.user_key]
      expect(generic_file_2.edit_users).to eq [user.user_key]
      generic_work.save

      CopyPermissionsJob.new(generic_work.id).run

      generic_work.reload.generic_files.each do |file|
        expect(file.edit_users).to eq [user.user_key, another_user.user_key]
      end
    end
  end

  describe "an open access work" do
    let(:work) { FactoryGirl.create(:work_with_files) }
    subject { CopyPermissionsJob.new(work.id) }

    it "should have no content at the outset" do
      expect(work.generic_files.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it "should copy visibility to its contained files" do
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.save
      subject.run
      work.reload.generic_files.each do |file|
        expect(file.visibility).to eq 'open'
      end
    end
  end
end
