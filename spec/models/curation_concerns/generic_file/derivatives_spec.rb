require 'spec_helper'

describe CurationConcerns::GenericFile do
  let(:generic_file) { GenericFile.create { |gf| gf.apply_depositor_metadata('jcoyne@example.com') } }

  before do
    file = File.open(File.join(fixture_path, file_name), 'r')
    Hydra::Works::UploadFileToGenericFile.call(generic_file, file)
    allow_any_instance_of(Hydra::Works::GenericFile::Base).to receive(:mime_type).and_return(mime_type)
    generic_file.save!
  end

  describe 'image derivative' do
    let(:mime_type) { 'image/jp2' }
    let(:file_name) { 'image.jp2' }
    it 'only makes one thumbnail' do
      expect(generic_file).to receive(:transform_file).once
      generic_file.create_derivatives
    end
  end

  describe 'pdf derivative' do
    let(:mime_type) { 'application/pdf' }
    let(:file_name) { 'test.pdf' }
    it 'only makes one thumbnail' do
      expect(generic_file).to receive(:transform_file).once
      generic_file.create_derivatives
    end
  end

  describe 'office derivative' do
    let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
    let(:file_name) { 'charter.docx' }
    it 'only makes one thumbnail' do
      expect(generic_file).to receive(:transform_file).once
      generic_file.create_derivatives
    end
  end

  describe 'audiovisual transcoding', unless: $in_travis do
    context 'with a video (.avi) file' do
      let(:mime_type) { 'video/avi' }
      let(:file_name) { 'countdown.avi' }

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

    context 'with an audio (.wav) file' do
      let(:mime_type) { 'audio/wav' }
      let(:file_name) { 'piano_note.wav' }

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

    context 'with an mp3 file' do
      let(:mime_type) { 'audio/mpeg' }
      let(:file_name) { 'test5.mp3' }

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

    context 'with an ogg file' do
      let(:mime_type) { 'audio/ogg' }
      let(:file_name) { 'Example.ogg' }

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
