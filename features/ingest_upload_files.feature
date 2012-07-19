Feature: Uploading files via web form
  In order to add file to my collections
  As an authorized user
  I want to upload files with a web form

  Scenario: Getting to the ingest screen
    Given I am logged in as "contentauthor@psu.edu"
    When I follow "upload" 
    Then show me the page 
    Then I should see "Select files"
    And I should see "Start upload"
    And I should see "Cancel upload"
    And I should see a file chooser button

   @javascript
   Scenario: Upload a file without checking terms of service
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I attach the file "spec/fixtures/image.jp2" to "files[]"
    And I attach the file "spec/fixtures/libra-oa_1.foxml.xml" to "files[]"
    And I press "Start upload"
    Then I should see "You must accept the terms of service!"
