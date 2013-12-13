# spec/support/fixture_helpers.rb
module FixtureHelpers
  def find_or_create_file_fixtures
    handles = [:public_pdf, :public_mp3, :public_wav]
    fixtures = []
    handles.each {|handle| fixtures << FactoryGirl.create(handle) }
    return fixtures
  end
end

