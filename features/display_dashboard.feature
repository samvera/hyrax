Feature: As an authenticate and authorized
  user when viewing my dashboard I see all 
  the objects I have access to 

  Scenario: I am on the homepage and want to view my dashboard 
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    Then I should see "Dashboard"

  Scenario: I am on the homepage and I want to search my dashboard
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    When I fill in "dashboard_search" with "dash search"
    When I press "dashboard_submit"
    Then I should see "Dashboard"
    And I should see "You searched for: dash search"
    Then the "search-field-header" field should not contain "dash search"

  Scenario: I am on the dashboard and want to upload files
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    And I follow "Upload File(s)" 
    Then I should see "Upload"

  Scenario: I am on the dashboard and want to search SS
    Given I am logged in as "contentauthor@psu.edu"
    And I follow "my dashboard" 
    When I fill in "search-field-header" with "ss search"
    When I press "search-submit-header"
    Then I should see "You searched for: ss search"
    Then I should not see "Dashboard"
    Then the "search-field-header" field should contain "ss search"

