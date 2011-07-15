Feature: Default Partials - Edit View
  I want to see appropriate information in the edit view for (active) fedora objects that use the default partials

  Scenario: In Edit View for Object Using Default Partials
    Given I am logged in as "archivist1" 
    When I am on the edit document page for hydra:test_default_partials
    Then I should see "hydra:test_default_partials"
    And I should see "descMetadata"
    And I should see "rightsMetadata"

  Scenario: html5 valid - unauthenticated 
    When I am on the edit document page for hydra:test_default_partials
    Then I should see "do not have sufficient privileges"
    And the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    When I am on the edit document page for hydra:test_default_partials
    Then I should see "do not have sufficient privileges"
    And the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    When I am on the edit document page for hydra:test_default_partials
    Then I should see "descMetadata"
    And the page should be HTML5 valid

