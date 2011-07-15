Feature: Objects Without Models - Show View
  I want to see appropriate information in the show view for objects without an (active)fedora model

  Scenario: In Show View for Object Without a Model
# FIXME: you can't get to show view for object with no model ... not even with edit permissions
#    Given I am logged in as "archivist1" 
#    And I am on the show document page for hydra:test_no_model
#    Then I should see "test object for default partials"

  Scenario: html5 valid - unauthenticated 
    Given I am on the show document page for hydra:test_no_model
    Then I should see "do not have sufficient access privileges"
    And the page should be HTML5 valid

  Scenario: html5 valid - authenticated (read)
# FIXME: you can't get to show view for object with no model ... not even with edit permissions
#    Given I am logged in as "public" 
#    And I am on the show document page for hydra:test_no_model
#    Then I should see "test object for default partials"
#    And the page should be HTML5 valid

  Scenario: html5 valid - authenticated (edit)
# FIXME: you can't get to show view for object with no model ... not even with edit permissions
#    Given I am logged in as "archivist1" 
#    And I am on the show document page for hydra:test_no_model
#    Then I should see "test object for default partials"
#    And the page should be HTML5 valid
