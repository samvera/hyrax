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
    And I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
    And I press "Upload"
    Then I should see "The file image.jp2 has been saved"

  Scenario: Upload a file, with metadata
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
    And I fill in "Dan Ran" for "generic_file_creator"
    And I fill in "Dan's Book" for "generic_file_title"
    #And I select "" from 
    And I press "Upload"
    Then I should see "The file image.jp2 has been saved"

  Scenario: Submit metadata, no file
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
    And I fill in "Dan Ran" for "generic_file_creator"
    And I fill in "My Title!" for "generic_file_title"
    And I press "Upload"
    Then I should see "You must specify a file to upload"
   
#  difference between add and upload is that add
#  just tests the button to display more fields
#  upload tests the submission of the data 
#  Scenario: Add more files
#  Scenario: Upload multiple files 
#  Scenario: Add More metadata
#  Scenario: Upload More metadata
