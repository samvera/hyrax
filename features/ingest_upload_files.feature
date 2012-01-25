Feature: Uploading files via web form
  In order to add file to my collections
  As an authorized user
  I want to upload files with a web form

  Scenario: Getting to the ingest screen
    Given I am logged in as "contentauthor@psu.edu"
#    When I click "Upload" 
#    Then I should see "Ingest tool"
#    And I should see "upload files"
#    And I should see "metadata"
#    And I should see a button with label "choose file"
#    And I should see a button with label "Upload"
#
#  Scenario: Upload a file, no metadata
#    Given I am logged in as "contentauthor@psu.edu"
#    When I am on the "Ingest" page 
#    And I attach the file "test_support/fixtures/world.png" to "Filedata[]"
#    And I press "Upload"
#    Then I should see "The file world.png has been saved"
#
#  Scenario: Upload a file, with metadata
#
#  Scenario: Submit metadata, no file
