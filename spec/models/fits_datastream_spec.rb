require 'spec_helper'

describe FitsDatastream, type: :model, unless: $in_travis do
  describe 'image' do
    before(:all) do
      @file = GenericFile.create { |gf| gf.apply_depositor_metadata('blah') }
      Hydra::Works::AddFileToGenericFile.call(@file, File.open(fixture_file_path('world.png')), :original_file)
      CurationConcerns::CharacterizationService.run(@file)
    end
    it 'has a format label' do
      expect(@file.format_label).to eq ['Portable Network Graphics']
    end
    it 'has a mime type' do
      expect(@file.mime_type).to eq 'image/png'
    end
    it 'has a file size' do
      expect(@file.file_size).to eq ['4218']
    end
    it 'has a last modified timestamp' do
      expect(@file.last_modified).to_not be_empty
    end
    it 'has a filename' do
      expect(@file.filename).to_not be_empty
    end
    it 'has a checksum' do
      expect(@file.original_checksum).to eq ['28da6259ae5707c68708192a40b3e85c']
    end
    it 'has a height' do
      expect(@file.height).to eq ['50']
    end
    it 'has a width' do
      expect(@file.width).to eq ['50']
    end

    let(:datastream) { @file.characterization }
    let(:xml) { datastream.ng_xml }
    let(:namespace) { { 'ns' => 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output' } }

    it 'makes the fits XML' do
      expect(xml.xpath('//ns:imageWidth/text()', namespace).inner_text).to eq '50'
    end
  end

  describe 'video' do
    before(:all) do
      @file = GenericFile.create { |gf| gf.apply_depositor_metadata('blah') }
      Hydra::Works::AddFileToGenericFile.call(@file, File.open(fixture_file_path('sample_mpeg4.mp4')), :original_file)
      CurationConcerns::CharacterizationService.run(@file)
    end
    it 'has a format label' do
      expect(@file.format_label).to eq ['ISO Media, MPEG v4 system, version 2']
    end
    it 'has a mime type' do
      expect(@file.mime_type).to eq 'video/mp4'
    end
    it 'has a file size' do
      expect(@file.file_size).to eq ['245779']
    end
    it 'has a last modified timestamp' do
      expect(@file.last_modified).to_not be_empty
    end
    it 'has a filename' do
      expect(@file.filename).to_not be_empty
    end
    it 'has a checksum' do
      expect(@file.original_checksum).to eq ['dc77a8de8c091c19d86df74280f6feb7']
    end
    it 'has a width' do
      expect(@file.width).to eq ['190']
    end
    it 'has a height' do
      expect(@file.height).to eq ['240']
    end
    it 'has a sample_rate' do
      expect(@file.sample_rate).to eq ['32000']
    end
    it 'has a duration' do
      expect(@file.duration).to eq ['4.97 s']
    end
    it 'has a frame_rate' do
      expect(@file.frame_rate.count).to eq 1
      expect(@file.frame_rate[0].to_f).to eq 30.0
    end
  end

  describe 'pdf' do
    before do
      @myfile = GenericFile.create { |gf| gf.apply_depositor_metadata('blah') }
      Hydra::Works::AddFileToGenericFile.call(@myfile, File.open(fixture_file_path('test4.pdf')), :original_file)
      # characterize method saves
      CurationConcerns::CharacterizationService.run(@myfile)
    end

    it 'returns expected results after a save' do
      expect(@myfile.file_size).to eq ['218882']
      expect(@myfile.original_checksum).to eq ['5a2d761cab7c15b2b3bb3465ce64586d']

      expect(@myfile.characterization_terms[:format_label]).to eq ['Portable Document Format']
      expect(@myfile.characterization_terms[:mime_type]).to eq 'application/pdf'
      expect(@myfile.characterization_terms[:file_size]).to eq ['218882']
      expect(@myfile.characterization_terms[:original_checksum]).to eq ['5a2d761cab7c15b2b3bb3465ce64586d']
      expect(@myfile.characterization_terms.keys).to include(:last_modified, :filename)

      expect(@myfile.title).to include('Microsoft Word - sample.pdf.docx')
      expect(@myfile.filename).to eq 'test4.pdf'

      expect(@myfile.format_label).to eq ['Portable Document Format']
      expect(@myfile.title).to include('Microsoft Word - sample.pdf.docx')
      expect(@myfile.extracted_text.content).to eq("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nMicrosoft Word - sample.pdf.docx\n\n\n \n \n\n \n\n \n\n \n\nThis PDF file was created using CutePDF. \n\nwww.cutepdf.com")
    end
  end

  describe 'm4a' do
    before do
      @myfile = GenericFile.create { |gf| gf.apply_depositor_metadata('blah') }
      Hydra::Works::AddFileToGenericFile.call(@myfile, File.open(fixture_file_path('spoken-text.m4a')), :original_file)
      # characterize method saves
      CurationConcerns::CharacterizationService.run(@myfile)
    end

    it 'returns expected content for full text' do
      expect(@myfile.extracted_text.content).to eq("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nLavf56.15.102")
    end
  end
end
