Feature: Default Partials in Search Results
  I want to see appropriate information in search results for (active)fedora objects that use the default partials

  Scenario: Have a Search Result that is an Object That Uses Default Partials
    Given I am on the home page
    And I fill in "q" with "default"
    When I press "submit"
    Then I should see a link to "the show document page for hydra:test_default_partials"

  Scenario: html5 valid - unauthenticated 
    Given I am on the home page
    And I fill in "q" with "default"
    When I press "submit"
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated 
    Given I am logged in as "archivist1" 
    And I am on the home page
    And I fill in "q" with "default"
    When I press "submit"
    Then I should see a link to "the show document page for hydra:test_default_partials"
    And the page should be HTML5 valid
