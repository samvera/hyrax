Feature: Objects Without Models - Search Results
  I want to see appropriate information in search results for objects without an (active)fedora model

  Scenario: Have a Search Result that is an Object Without a Model
    Given I am logged in as "archivist1" 
    And I am on the home page
    And I fill in "q" with "test"
    When I press "submit"
    Then I should see a link to "the show document page for hydra:test_no_model"

# you can't see this object unless you are an editor
  Scenario: html5 valid - unauthenticated 
    When I am on the home page
    And I fill in "q" with "test"
    And I press "submit"
    Then I should not see a link to "the show document page for hydra:test_no_model"

  Scenario: html5 valid - authenticated 
    Given I am logged in as "archivist1" 
    And I am on the home page
    And I fill in "q" with "test"
    When I press "submit"
    Then the page should be HTML5 valid

