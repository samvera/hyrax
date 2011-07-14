Feature: GenericImage Edit View
  I want to see appropriate information for editing GenericImage objects

  Scenario: In Edit View for GenericImage Object
    When I am on the edit document page for hydra:test_generic_image
    Then I should see "A test object using the GenericImage (active)fedora model"

  Scenario: html5 valid - unauthenticated 
    When I am on the edit document page for hydra:test_generic_image
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    When I am on the edit document page for hydra:test_generic_image
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    When I am on the edit document page for hydra:test_generic_image
    Then the page should be HTML5 valid

