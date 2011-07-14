Feature: GenericContent Show View
  I want to see appropriate information for GenericContent objects in the show view

  Scenario: In Show View for GenericContent Object
    When I am on the show document page for hydra:test_generic_content
    Then I should see "A test object using the GenericContent (active)fedora model"

  Scenario: html5 valid - unauthenticated 
    When I am on the show document page for hydra:test_generic_content
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    When I am on the show document page for hydra:test_generic_content
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    When I am on the show document page for hydra:test_generic_content
    Then the page should be HTML5 valid
