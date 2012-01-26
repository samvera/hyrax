Feature: Uploading files via web form
  In order to add file to my collections
  As an authorized user
  I want to upload files with a web form

  Scenario: Getting to the ingest screen
    Given I am logged in as "contentauthor@psu.edu"
    When I follow "Upload" 
    Then I should see "Ingest Tool"
    And I should see "Upload Files"
    And I should see "Metadata"
    And I should see a file chooser button 
    And I should see a "Upload" button 

  Scenario: Upload a file, no metadata
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I attach the file "test_support/fixtures/image.jp2" to "generic_file_Filedata[]"
    And I press "Upload"
#    Then I should see "The file world.png has been saved"
#
#  Scenario: Upload a file, with metadata
#
#  Scenario: Submit metadata, no file
