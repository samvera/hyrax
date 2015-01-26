# spec/support/fixture_helpers.rb
module FixtureHelpers
  def create_file_fixtures(depositor = 'archivist1@example.com')
    handles = [:public_pdf, :public_mp3, :public_wav]
    handles.map { |handle| FactoryGirl.create(handle, depositor: depositor) }
  end
end
