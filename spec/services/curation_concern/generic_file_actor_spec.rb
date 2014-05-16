require 'spec_helper'

describe Worthwhile::CurationConcern::GenericFileActor do
  let(:user) { FactoryGirl.create(:user) }
  let(:parent) { FactoryGirl.create_curation_concern(:generic_work, user) }
  let(:file_path) { __FILE__ }
  let(:mime_type) { 'application/x-ruby'}
  let(:file) { Rack::Test::UploadedFile.new(file_path, mime_type, false)}
  let(:file_content) { File.read(file_path)}
  let(:title) { Time.now.to_s }
  let(:attributes) {
    { file: file, title: title, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
  }

  subject {
    Worthwhile::CurationConcern::GenericFileActor.new(generic_file, user, attributes)
  }

  describe '#create' do
    let(:generic_file) { Worthwhile::GenericFile.new.tap {|gf| gf.batch = parent } }
    let(:reloaded_generic_file) {
      generic_file.class.find(generic_file.pid)
    }
    context 'with a file' do
      it 'succeeds if attributes are given' do
        
        s2 = double('characterize job')
        allow(CharacterizeJob).to receive(:new).and_return(s2)
        expect(Sufia.queue).to receive(:push).with(s2).once

        expect {
          expect(subject.create).to be_true
        }.to change { parent.reload.generic_files.count }.by(1)

        reloaded_generic_file.batch.should == parent
        reloaded_generic_file.to_s.should == title
        reloaded_generic_file.filename.should == File.basename(__FILE__)

        expect(reloaded_generic_file.to_solr[Hydra.config[:permissions][:read][:group]]).to eq(['registered'])
      end
    end

    it 'failure returns false' do
      Worthwhile::CurationConcern::GenericFileActor.any_instance.should_receive(:save).and_return(false)
      subject.stub(:update_file).and_return(true)
      subject.create.should be_false
    end
  end

  describe '#update' do
    let(:generic_file) { FactoryGirl.create(:file_with_work, user: user) }

    it do
      s2 = double('characterize job')
      allow(CharacterizeJob).to receive(:new).and_return(s2)
      expect(Sufia.queue).to receive(:push).with(s2).once

      expect(subject.update).to be_true
      expect(generic_file.title).to eq [title]
      expect(generic_file.to_s).to eq title
      expect(generic_file.content.content).to eq file_content
    end

    it 'failure returns false' do
      Worthwhile::CurationConcern::GenericFileActor.any_instance.should_receive(:save).and_return(false)
      subject.update.should be_false
    end
  end

  describe '#rollback' do
    let(:attributes) {
      { version: version }
    }
    let(:version) { generic_file.versions.last.version_id }
    let(:generic_file) { FactoryGirl.create(:file_with_work, user: user, content: file) }
    let(:file) { Rack::Test::UploadedFile.new(__FILE__, 'text/plain', false) }
    let(:new_file) { worthwhile_fixture_file_upload('files/image.png', 'image/png', false)}
    before(:each) do
      # I need to make an update
      updated_attributes = { file: new_file}
      s2 = double('characterize job')
      allow(CharacterizeJob).to receive(:new).and_return(s2)
      expect(Sufia.queue).to receive(:push).with(s2).once
      actor = Worthwhile::CurationConcern::GenericFileActor.new(generic_file, user, updated_attributes)
      actor.update
    end
    it do
      expect {
        expect(subject.rollback).to be_true
      }.to change { subject.curation_concern.content.mimeType }.from('image/png').to(mime_type)
    end

    it 'failure returns false' do
      generic_file.should_receive(:save).and_return(false)
      subject.rollback.should be_false
    end
  end
end
