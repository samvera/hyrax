@edit @dor_object
Feature: Edit a Dor Object
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Visit Document Edit Page for a DorObject
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrus:test_object1
    # Then I should see "A Test Hydrus Item" within "h1.document_heading"
    Then I should see "A Test Hydrus Item"
    And I should see an inline edit containing "A Test Hydrus Item"
    And I should see a "Save Description" button

  Scenario: Viewing browse/edit buttons
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrus:test_object1
    Then I should see a "span" tag with a "class" attribute of "edit-browse"