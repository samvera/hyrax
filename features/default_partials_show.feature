Feature: Default Partials - Show View
  I want to see appropriate information in the show view for objects that use the default partials

  Scenario: In Show View for Object Using Default Partials
    When I am on the show document page for hydra:test_default_partials
    Then I should see "ID"
    And I should see "Download"
    And I should see "hydra:test_default_partials"

  Scenario: html5 valid - unauthenticated 
    When I am on the show document page for hydra:test_default_partials
    And the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
    Given I am logged in as "public" 
    When I am on the show document page for hydra:test_default_partials
    Then I should see "Download"
    And the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
    Given I am logged in as "archivist1" 
    When I am on the show document page for hydra:test_default_partials
    Then I should see "Download"
    And the page should be HTML5 valid
