Feature: As an authenticate and authorized
  user when viewing my dashboard I see all 
  the objects I have access to 

  Scenario: I am on the homepage and want to upload
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
#    And I follow "contribute_link"
#    Then I should see "Add files..."
#    Then I should see "Start upload"
    
  Scenario: I am on the homepage
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    Then I should see "My Files"
#    And I should see "Creator"
#    And I should see "Contributor"
#    And I should see "Title"
#    And I should see "Creator"
#    And I should see "Date Created"
#    And I should see "Date Published"
#    And I should see "Format"
#    And I should see "Type"
#    And I should see "Collection"
#    And I should see "Selected Items"
#    And I should see "Search History"
#    And I should see "Sort by:"
#    And I should see "Show:"
#    And I should see "per page"
#    And I should see "Name"
#    And I should see "ID"
#    And I should see "Date Created"
#    And I should see "Owner"

   Scenario: Upload a file, with metadata and check facets
    Given I am logged in as "contentauthor@psu.edu"
    When I am on the "ingest" page 
    And I attach the file "spec/fixtures/image.jp2" to "files[]"
    And I press "Start upload"
#    Then I should see "The file image.jp2 has been saved"
#    And I follow "my dashboard"     
#    Then I should see "Browse"
#    Then I should see "Contributor"
#    Then I should see "contributor1"
#    Then I should see "Date Created"
#    Then I should see "4/16/2012"
#    Then I should see "Tag"
#    Then I should see "abc123"
#    Then I should see "Publisher"
#    Then I should see "publisher1"
#    Then I should see "Subject"
#    Then I should see "subject1"
#    Then I should see "Based Near"
#    Then I should see "State College"
