Feature: Objects Without Models - Edit View
  I want to see appropriate information in the edit view for objects without an (active)fedora model

  Scenario: In Edit View for Object Without a Model
    Given I am on the edit document page for hydra:test_no_model
    Then I should see "hydra test object without a model"

  Scenario: html5 valid - unauthenticated 
    Given I am on the edit document page for hydra:test_no_model
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    And I am on the edit document page for hydra:test_no_model
    Then the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydra:test_no_model
    Then the page should be HTML5 valid

