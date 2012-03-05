Feature: Uploading files via web form
  In order to add file to my collections
  As an authorized user
  I want to upload files with a web form

#  Scenario: Getting to the ingest screen
#    Given I am logged in as "contentauthor@psu.edu"
#    When I follow "Upload" 
#    Then I should see "Ingest Tool"
#    And I should see "Upload Files"
#    And I should see "Metadata"
#    And I should see a file chooser button 
#    And I should see a "Upload" button 
#
#  Scenario: Upload a file, no metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
#    And I press "Upload"
#    Then I should see "The file image.jp2 has been saved"

#  Scenario: Upload a file, with metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I attach the file "test_support/fixtures/image.jp2" to "Filedata[]"
#    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
#    And I fill in "Dan Ran" for "generic_file_creator"
#    And I fill in "Dan's Book" for "generic_file_title"
#    #And I select "" from 
#    And I press "Upload"
#    Then I should see "The file image.jp2 has been saved"
#
#  Scenario: Submit metadata, no file
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
#    And I fill in "Dan Ran" for "generic_file_creator"
#    And I fill in "My Title!" for "generic_file_title"
#    And I press "Upload"
#    Then I should see "You must specify a file to upload"
   
#  difference between add and upload is that add
#  just tests the button to display more fields
#  upload tests the submission of the data 
#  @javascript
#  Scenario: Add more files
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I press "additional_files_submit"
#    And I attach the file "test_support/fixtures/image.jp2" to "Filedata_"
#    And I attach the file "test_support/fixtures/small_file.txt" to "Filedata_2"
#    And I press "additional_files_submit"
#    And I attach the file "test_support/fixtures/empty_file.txt" to "Filedata_3"
    #Then the "file_count" field: within #file_count should contain "2"

  @javascript
  Scenario: Upload multiple files 
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I press "additional_files_submit"
    And I attach the javascript file "/Users/dmc186/workspace/rb/gamma/test_support/fixtures/image.jp2" to "#Filedata_"
    And I attach the javascript file "/Users/dmc186/workspace/rb/gamma/test_support/fixtures/small_file.txt" to "#Filedata_2"
    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
    And I fill in "Dan Ran" for "generic_file_creator"
    And I fill in "Dan's Book" for "generic_file_title"
    And I press "Upload"
    Then show me the page
    Then I should see "The file image.jp2 has been saved"
    Then I should see "The file small_file.txt has been saved"


#  @javascript
#  Scenario: Add More metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I press "Add More Descriptions"
#    Then I should see "word" within "#more_descriptions" 
#  Scenario: Upload More metadata
