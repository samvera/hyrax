@new @admin
Feature: Create a new collection
  In order to create a collection
  A admin policy object editor
  wants to create a new collection object


  Scenario: Visiting home page
		Given I am logged in as "archivist1" with "admin_policy_object_editor" permissions
    And I am on the home page	
		Then I should see "Create new collection" within "ul#select-item-list"
    When I follow "Create new collection"
	 	And I should see an inline edit containing ""
	  And the "Collection Name:" inline edit should contain ""
    And I should see "Description" within "div#accordion h2.section-title"
	  Then I should see an "h2.section-title" element containing "Set Permissions"
    Then I should see an "h2.section-title" element containing "License & Restrictions"
	  Then I should see an "h2.section-title" element containing "Contact"

