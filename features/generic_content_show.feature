Feature: Generic Content Show View
  I want to see appropriate information for generic content objects in the show view

  Scenario: Viewing Generic Content
    Given I am on the show document page for hydra:test_generic_content
    Then I should see "A test object using the GenericContent (active)fedora model"

  Scenario: html5 valid - unauthenticated 
    Given I am on the show document page for hydra:test_generic_content
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    And I am on the show document page for hydra:test_generic_content
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    And I am on the show document page for hydra:test_generic_content
    Then the page should be HTML5 valid
