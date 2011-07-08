Feature: HTML validity
  In order to verify that the application in HTML5 valid
  As a user
  I want to the pages to conform to the W3C HTML5 validation
  
  Scenario: Home page (unauthenticated)
    When I am on the home page
    Then the page should be HTML5 valid
    
  Scenario: Home page (authenticated)
    Given I am logged in as "archivist1" 
    When I am on the home page
    Then the page should be HTML5 valid
    
  Scenario: Search Results (unauthenticated)
    Given I am on the home page
    When I follow "Article"
    Then I should see "TITLE OF HOST JOURNAL"
    And the page should be HTML5 valid
    
  Scenario: Search Results (authenticated)
    Given I am logged in as "archivist1" 
    When I am on the home page
    And I follow "Article"
    Then I should see "TITLE OF HOST JOURNAL"
    And the page should be HTML5 valid
    
  Scenario: Record view browse (unauthenticated)
    Given I am on the show document page for hydrangea:fixture_mods_article2
    Then I should see "TITLE OF HOST JOURNAL"
    And the page should be HTML5 valid
    
  Scenario: Record view browse (authenticated)
    Given I am logged in as "archivist1" 
    When I am on the show document page for hydrangea:fixture_mods_article2
    Then I should see "TITLE OF HOST JOURNAL"
    And the page should be HTML5 valid
    
  Scenario: Record view edit (authenticated)
    Given I am logged in as "archivist1" 
    When I am on the edit document page for hydrangea:fixture_mods_article2
    Then I should see "TITLE OF HOST JOURNAL"
    And the page should be HTML5 valid