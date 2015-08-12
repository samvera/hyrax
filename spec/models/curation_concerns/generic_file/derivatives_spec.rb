require 'spec_helper'

describe CurationConcerns::GenericFile::Derivatives do
  before do
    @ffmpeg_enabled = CurationConcerns.config.enable_ffmpeg
    CurationConcerns.config.enable_ffmpeg = true
  end

  after do
    CurationConcerns.config.enable_ffmpeg = @ffmpeg_enabled
  end


  describe 'audiovisual transcoding' do
    before do
      file = File.open(File.join(fixture_path, file_name), 'r')
      Hydra::Works::UploadFileToGenericFile.call(generic_file, file)
      allow_any_instance_of(Hydra::Works::GenericFile::Base).to receive(:mime_type).and_return(mime_type)
      generic_file.save!
    end

    context 'with a video (.avi) file', unless: $in_travis do
      let(:mime_type) { 'video/avi' }
      let(:file_name) { 'countdown.avi' }
      let(:generic_file) { GenericFile.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') } }

      it 'transcodes to webm and mp4' do
        generic_file.create_derivatives
        derivative = generic_file.webm
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('video/webm')

        derivative2 = generic_file.mp4
        expect(derivative2).not_to be_nil
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('video/mp4')
      end
    end

    context 'with an audio (.wav) file', unless: $in_travis do
      let(:mime_type) { 'audio/wav' }
      let(:file_name) { 'piano_note.wav' }
      let(:generic_file) { GenericFile.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') } }

      it 'transcodes to mp3 and ogg' do
        generic_file.create_derivatives
        derivative = generic_file.mp3
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('audio/mpeg')

        derivative2 = generic_file.ogg
        expect(derivative2).not_to be_nil
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end

    context 'with an mp3 file', unless: $in_travis do
      let(:mime_type) { 'audio/mpeg' }
      let(:file_name) { 'test5.mp3' }
      let(:generic_file) { GenericFile.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') } }

      xit 'should copy the content to the mp3 datastream and transcode to ogg' do
        generic_file.create_derivatives
        derivative = generic_file.mp3

        expect(derivative.size).to eq(generic_file.original_file.size)
        expect(derivative.mime_type).to eq('audio/mpeg')
        derivative2 = generic_file.ogg
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end

    context 'with an ogg file', unless: $in_travis do
      let(:mime_type) { 'audio/ogg' }
      let(:file_name) { 'Example.ogg' }
      let(:generic_file) { GenericFile.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') } }

      xit 'should copy the content to the ogg datastream and transcode to mp3' do
        generic_file.create_derivatives
        derivative = generic_file.mp3
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('audio/mpeg')

        derivative2 = generic_file.ogg
        expect(derivative2).not_to be_nil
        expect(derivative2.size).to eq(generic_file.original_file.size)
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end
  end
end
