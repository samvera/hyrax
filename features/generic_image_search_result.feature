Feature: GenericImage Search Results
  I want to see appropriate information for GenericImage objects in a search result

  Scenario: Have a GenericImage Search Result
    Given I am on the home page
    And I fill in "q" with "generic image"
    When I press "submit"
    Then I should see a link to "the show document page for hydra:test_generic_image"

  Scenario: html5 valid - unauthenticated 
    Given I am on the home page
    And I fill in "q" with "generic image"
    When I press "submit"
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated 
    Given I am logged in as "archivist1" 
    And I am on the home page
    And I fill in "q" with "generic image"
    When I press "submit"
    Then the page should be HTML5 valid

