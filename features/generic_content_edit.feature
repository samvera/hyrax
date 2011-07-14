Feature: Generic Content Edit View
  I want to see appropriate information for editing generic content objects

  Scenario: html5 valid - unauthenticated 
    Given I am on the edit document page for hydra:fixture_generic_content
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    And I am on the edit document page for hydra:fixture_generic_content
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydra:fixture_generic_content
    Then the page should be HTML5 valid

