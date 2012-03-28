Feature: Non-existent Objects - Show View
  I want to see a 404 for the show view for objects not in fedora or solr
  Scenario: an object exists for an id
    Given I am on the show document page for hydra:test_no_model
    Then I should get a status code 200
  Scenario: no object exists for an id 
    Given I am on the show document page for hydra:test_no_exist
    Then I should get a status code 404
    And I should see "Sorry, you have requested a record that doesn't exist."