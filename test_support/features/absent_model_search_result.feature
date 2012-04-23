Feature: Objects Without Models - Search Results
  I want to see appropriate information in search results for objects without an (active)fedora model

  # Objects without a model, are not ever displayed because they don't have rightsMetadata
    
  Scenario: html5 valid - unauthenticated 
    When I am on the home page
    And I fill in "q" with "test"
    And I press "search"
    Then I should not see a link to "the show document page for hydra:test_no_model"

  Scenario: html5 valid - authenticated 
    Given I am logged in as "archivist1@example.com" 
    And I am on the home page
    And I fill in "q" with "test"
    When I press "search"
    Then the page should be HTML5 valid

