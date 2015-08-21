module Features
  module FixtureFileUpload
    # Can't just call this fixture_file_upload due to name conflicts.
    def curation_concerns_fixture_file_upload(path, content_type = 'text/plain', binary = false)
      Rack::Test::UploadedFile.new(fixture_file_path(path), content_type, binary)
    end

    def fixture_file(path)
      File.open(fixture_file_path(path))
    end

    def fixture_file_path(path)
      File.join(CurationConcerns::Engine.root.to_s, 'spec/fixtures', path)
    end
  end
end
