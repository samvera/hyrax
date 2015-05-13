require 'spec_helper'

describe CreateDerivativesJob do
  before do
    @ffmpeg_enabled = Sufia.config.enable_ffmpeg
    Sufia.config.enable_ffmpeg = true
    @generic_file = GenericFile.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') }
  end

  after do
    Sufia.config.enable_ffmpeg = @ffmpeg_enabled
  end

  subject { CreateDerivativesJob.new(@generic_file.id) }

  describe 'thumbnail generation' do
    before do
      @generic_file.add_file(File.open(fixture_path + '/' + file_name), path: 'content', original_name: file_name, mime_type: mime_type)
      allow_any_instance_of(GenericFile).to receive(:mime_type).and_return(mime_type)
      @generic_file.save!
    end
    context 'with a video (.avi) file', unless: ENV['TRAVIS'] == 'true' do
      let(:mime_type) { 'video/avi' }
      let(:file_name) { 'countdown.avi' }

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'generates a thumbnail on job run', unless: ENV['TRAVIS'] == 'true' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).to have_content
        expect(@generic_file.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an audio (.wav) file', unless: ENV['TRAVIS'] == 'true' do
      let(:mime_type) { 'audio/wav' }
      let(:file_name) { 'piano_note.wav' }

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'does not generate a thumbnail on job run', unless: ENV['TRAVIS'] == 'true' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).not_to have_content
      end
    end

    context 'with an image (.jp2) file' do
      let(:mime_type) { 'image/jp2' }
      let(:file_name) { 'image.jp2' }

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      it 'generates a thumbnail on job run' do
        subject.run
        @generic_file.reload
        expect(@generic_file.thumbnail).to have_content
        expect(@generic_file.thumbnail.mime_type).to eq('image/jpeg')
      end
    end

    context 'with an office document (.docx) file', unless: ENV['TRAVIS'] == 'true' do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
      let(:file_name) { 'charter.docx' }

      it 'lacks a thumbnail' do
        expect(@generic_file.thumbnail).not_to have_content
      end

      ## TODO - Needs refactoring after sufia is broken up
      # it 'generates a thumbnail on job run' do
      #   subject.run
      #   @generic_file.reload
      #   expect(@generic_file.thumbnail).to have_content
      #   expect(@generic_file.thumbnail.mime_type).to eq('image/jpeg')
      # end
    end
  end

  describe 'audiovisual transcoding' do
    before do
      @generic_file.add_file(File.open(fixture_path + '/' + file_name), path: 'content', original_name: file_name, mime_type: mime_type)
      allow_any_instance_of(GenericFile).to receive(:mime_type).and_return(mime_type)
      @generic_file.save!
    end
    context 'with a video (.avi) file', unless: ENV['TRAVIS'] == 'true' do
      let(:mime_type) { 'video/avi' }
      let(:file_name) { 'countdown.avi' }

      it 'transcodes to webm and mp4',unless: ENV['TRAVIS'] == 'true' do
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.attached_files['webm']
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('video/webm')

        derivative2 = reloaded.attached_files['mp4']
        expect(derivative2).not_to be_nil
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('video/mp4')
      end
    end

    context 'with an audio (.wav) file', unless: ENV['TRAVIS'] == 'true' do
      let(:mime_type) { 'audio/wav' }
      let(:file_name) { 'piano_note.wav' }

      it 'transcodes to mp3 and ogg', unless: ENV['TRAVIS'] == 'true' do
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.attached_files['mp3']
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mime_type).to eq('audio/mpeg')

        derivative2 = reloaded.attached_files['ogg']
        expect(derivative2).not_to be_nil
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end

    describe 'with an mp3 file' do
      # Uncomment when this is no longer pending
      # before do
      #   @generic_file.add_file(File.open(fixture_path + '/sufia/sufia_test5.mp3'), 'content', 'sufia_test5.mp3')
      #   @generic_file.save!
      # end

      #Need a way to do this in hydra-derivatives
      it 'should copy the content to the mp3 datastream and transcode to ogg', skip: true do
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.attached_files['mp3']
        expect(derivative.content.size).to eq(reloaded.content.content.size)
        expect(derivative.mime_type).to eq('audio/mpeg')

        derivative2 = reloaded.attached_files['ogg']
        expect(derivative2.content).not_to be_nil
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end

    describe 'with an ogg file' do
      # Uncomment when this is no longer pending
      # before do
      #   @generic_file.add_file(File.open(fixture_path + '/Example.ogg'), 'content', 'Example.ogg')
      #   @generic_file.save!
      # end

      #Need a way to do this in hydra-derivatives
      it 'should copy the content to the ogg datastream and transcode to mp3', skip: true do
        subject.run
        reloaded = @generic_file.reload
        derivative = reloaded.attached_files['mp3']
        expect(derivative).not_to be_nil
        expect(derivative.content).not_to be_nil
        expect(derivative.mimeType).to eq('audio/mpeg')

        derivative2 = reloaded.attached_files['ogg']
        expect(derivative2).not_to be_nil
        expect(derivative2.content.size).to eq(reloaded.content.content.size)
        expect(derivative2.mime_type).to eq('audio/ogg')
      end
    end
  end
end
