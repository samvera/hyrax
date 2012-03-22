Feature: As an authenticate and authorized
  user when viewing my dashboard I see all 
  the objects I have access to 

  Scenario: I am on the homepage and want to upload
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    When I press "upload_file"
    Then I should see "Upload Files"

  Scenario: I am on the homepage
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    Then I should see "Browse"
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
