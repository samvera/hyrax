@new @dor_object @terms
Feature: Add a Dor Object to a Admin Policy Object
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  @wip
  Scenario: Accepting terms for Admin Policy Object
    Given I am logged in as "archivist1" 
		And I am on the edit document page for hydrus:admin_class1
    And I follow "Add new item"
		Then I should see "you must agree to its terms of service"