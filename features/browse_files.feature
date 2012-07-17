Feature: Browse files 

  Scenario: Browse via Fixtures 
    Given I load scholarsphere fixtures
    When I go to the home page
    And I follow "test"
    Then I should see "Displaying all 4 items"
    When I follow "Test Document PDF"
    Then I should see "Download"
    But I should not see "Edit"
