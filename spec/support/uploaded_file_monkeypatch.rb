# Monkey patch UploadedFile so that it responds to read (same as ActionDispatch::Http::UploadedFile). Required by RestClient when posting to fedora.
class Rack::Test::UploadedFile
  def read(*args)
    @tempfile.read(*args)
  end
end
