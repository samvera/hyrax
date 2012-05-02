Feature: Uploading files via web form
  In order to add file to my collections
  As an authorized user
  I want to upload files with a web form

  Scenario: Getting to the ingest screen
    Given I am logged in as "contentauthor@psu.edu"
    When I follow "upload" 
    Then I should see "Add files.."
    And I should see "Start upload"
    And I should see "Cancel upload"
    And I should see a file chooser button 
    #And I should see a "Add More Files" button 
    #And I should see a "Add More Descriptions" button 
    #And I should see a "Upload" button 

  Scenario: Upload a file, no metadata
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I attach the file "test_support/fixtures/image.jp2" to "files[]"
    And I press "Start upload"

   @javascript
   Scenario: Upload a file, multiple files
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I attach the file "test_support/fixtures/image.jp2" to "files[]"
    And I attach the file "test_support/fixtures/libra-oa_1.foxml.xml" to "files[]"
    And I press "Start upload"
    #this really should check to make sure we forward eventually

#  Scenario: Upload a file, with metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I attach the file "test_support/fixtures/image.jp2" to "files[]"
#    And I press "Start upload"
#    #And I should see "You have successfully uploaded files"
#    And I should see "My Files"
#    And I should see "New Upload"
#    And I should see "Add Descriptions"

#  Scenario: Submit metadata, no file
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
#    And I fill in "Dan Ran" for "generic_file_creator"
#    And I fill in "My Title!" for "generic_file_title"
#    And I press "Upload"
#    Then I should see "You must specify a file to upload"
#   
#  # difference between add and upload is that add
#  # just tests the button to display more fields
#  # upload tests the submission of the data 
#  @javascript
#  Scenario: Add more files
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I press "additional_files_submit"
#    And I attach the file "test_support/fixtures/image.jp2" to "Filedata_"
#    And I attach the file "test_support/fixtures/small_file.txt" to "Filedata_2"
#    And I press "additional_files_submit"
#    And I attach the file "test_support/fixtures/empty_file.txt" to "Filedata_3"
#    #Then the "file_count" field: within #file_count should contain "2"
#
#  @javascript
#  Scenario: Upload multiple files 
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I press "Add files..."
#    And I attach a file "test_support/fixtures/image.jp2" to the dynamically created "files[]"
#    And I attach a file "test_support/fixtures/small_file.txt" to the dynamically created "files[]"
#    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
#    And I fill in "Dan Ran" for "generic_file_creator"
#    And I fill in "Dan's Book" for "generic_file_title"
#    And I press "Start upload"
#    Then I should see "The file image.jp2 has been saved"
#    Then I should see "The file small_file.txt has been saved"
#
#
#  @javascript
#  Scenario: Add More metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    #And I press "additional_md_submit"
#    #And I select "Publisher" from "metadata_key_2"
#    #And I fill in "Pendant" for "metadata_value_2"
#    #And I press "additional_md_submit"
#    #And I select "Description" from "metadata_key_3"
#    #And I fill in "We going global." for "metadata_value_3"
#
#  @javascript
#  Scenario: Upload More metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I attach a file "test_support/fixtures/image.jp2" to the dynamically created "#Filedata_"
#    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
#    And I fill in "Dan Ran" for "generic_file_creator"
#    And I fill in "Dan's Book" for "generic_file_title"
#    #And I select "Creator" from "metadata_key_1"
#    #And I fill in "Dan Coughlin" for "metadata_value_1"
#    #And I press "additional_md_submit"
#    #And I select "Publisher" from "metadata_key_2"
#    #And I fill in "Pendant" for "metadata_value_2"
#    #And I press "additional_md_submit"
#    #And I select "Description" from "metadata_key_3"
#    #And I fill in "We going global." for "metadata_value_3"
#    And I press "Upload"
#    Then I should see "The file image.jp2 has been saved"
#
#  @javascript
#  Scenario: Upload multiple files and more metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "ingest" page 
#    And I press "additional_files_submit"
#    And I attach a file "test_support/fixtures/image.jp2" to the dynamically created "#Filedata_"
#    And I attach a file "test_support/fixtures/small_file.txt" to the dynamically created "#Filedata_2"
#    And I fill in "Mike Motorcycle" for "generic_file_contributor" 
#    And I fill in "Dan Ran" for "generic_file_creator"
#    And I fill in "Dan's Book" for "generic_file_title"
#    #And I select "Creator" from "metadata_key_1"
#    #And I fill in "Dan Coughlin" for "metadata_value_1"
#    #And I press "additional_md_submit"
#    #And I select "Publisher" from "metadata_key_2"
#    #And I fill in "Pendant" for "metadata_value_2"
#    #And I press "additional_md_submit"
#    #And I select "Description" from "metadata_key_3"
#    #And I fill in "We going global." for "metadata_value_3"
#    And I press "Upload"
#    Then I should see "The file image.jp2 has been saved"
#    Then I should see "The file small_file.txt has been saved"
