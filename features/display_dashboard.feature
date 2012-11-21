Feature: As an authenticate and authorized
  user when viewing my dashboard I see all 
  the objects I have access to 

  Scenario: I am on the homepage and want to view dashboard 
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "dashboard" 
    Then I should see "Dashboard"

  Scenario: I am on the homepage and I want to search dashboard
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "dashboard" 
    When I fill in "dashboard_search" with "dash search"
    When I press "dashboard_submit"
    Then I should see "Dashboard"
    And I should see "You searched for: dash search"
    Then the "search-field-header" field should not contain "dash search"

  Scenario: I am on the dashboard and want to upload files
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "dashboard" 
    And I follow "Upload File(s)" 
    Then I should see "Upload"

  Scenario: I am on the dashboard and want to search SS
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "dashboard" 
    When I fill in "search-field-header" with "ss search"
    When I press "search-submit-header"
    Then I should see "You searched for: ss search"
    Then I should not see "Dashboard"
    Then the "search-field-header" field should contain "ss search"

 @javascript
  Scenario: I have files on my dashboard I should see icons 
    Given I load sufia fixtures
    And I am logged in as "archivist1@example.com"
    And I follow "dashboard"
    Then I should see "Test Document Text"
    Given I follow "Delete"
    Then I should see "The file has been deleted"

