Feature: Generic Image Show View
  I want to see appropriate information for generic image objects in the show view

  Scenario: Viewing Generic Image
    Given I am on the show document page for hydra:fixture_generic_image
    Then I should see "I am a generic image object for testing"

  Scenario: html5 valid - unauthenticated 
    Given I am on the show document page for hydra:fixture_generic_image
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    And I am on the show document page for hydra:fixture_generic_image
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    And I am on the show document page for hydra:fixture_generic_image
    Then the page should be HTML5 valid
