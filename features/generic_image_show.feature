Feature: GenericImage Show View
  I want to see appropriate information for GenericImage objects in the show view

  Scenario: In Show View for GenericImage Object
    When I am on the show document page for hydra:test_generic_image
    Then I should see "A test object using the GenericImage (active)fedora model"

  Scenario: html5 valid - unauthenticated 
    When I am on the show document page for hydra:test_generic_image
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    When I am on the show document page for hydra:test_generic_image
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    When I am on the show document page for hydra:test_generic_image
    Then the page should be HTML5 valid
