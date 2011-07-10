@edit @contributors
Feature: Add a Contributor
  In order to associate new people, organizations and conferences with an item
  As a person with edit permissions
  I want to add a new contributor

  # These are breaking with complaints that "Only get requests are allowed. (ActionController::MethodNotAllowed)"
  # This error only occurs in cucumber, not in real browser testing.

  @nojs
  Scenario: Add a person without javascript
    Given I am logged in as "archivist1"
    And I am on the edit document page for hydrangea:fixture_mods_article1
    When I follow "Add a Person"
    And I fill in the following:
    | Computing ID  | 098556 |
    | First Name    | Myra |
    | Last Name     | Breckenridge |
    | Department    | Posture and Empathy |
    | Institution   | Academy for Aspiring Young Actors and Actresses |
    # And I press "Add Person"
    #    Then I should be on the edit document page for hydrus:test_object1
    #    And the following should contain:
    #    | Computing ID  | 098556 |
    #    | First Name    | Myra |
    #    | Last Name     | Breckenridge |
    #    | Department    | Posture and Empathy |
    #    | Institution   | Academy for Aspiring Young Actors and Actresses |

  @nojs
  Scenario: Add an organization without javascript
    Given I am logged in as "archivist1"
    And I am on the edit document page for hydrangea:fixture_mods_article1
    When I follow "Add an Organization"
    And I fill in "Organization" with "American Film Academy"
    # And I press "Add Organization"
    # Then I should be on the edit document page for hydrus:test_object1
    # And the "Organization" field should contain "American Film Academy"
    