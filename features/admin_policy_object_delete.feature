@edit @admin
Feature: Delete a collection
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
	# This probably doesn't give much test covage, since this is dependent on ajax. just a start. 
	Scenario: Cancel from the delete dialog for a collection object
   Given I am logged in as "archivist1" with "admin_policy_object_editor" permissions
   And I am on the edit document page for hydrus:admin_class1
   Then I should see "Delete this" within "div.sidebar"
   When I follow "delete_asset_link" within "div.sidebar"
	 Then I should see "Permanently delete hydrus:admin_class1 and its assets from the repository?" within "div#delete_dialog"
	 And I should not see "Edit" 
	 And I should not see "Browse"
	 And I should see a "input" tag with an "value" attribute of "Delete"
	 And I should see a "input" tag with an "value" attribute of "Withdraw"
	 And I should see a "input" tag with an "value" attribute of "Cancel"
	 When I press "Cancel"
	 Then I should be on the edit document page for hydrus:admin_class1
		
	 Scenario: Delete a collection 
		Given I am logged in as "archivist1" with "admin_policy_object_editor" permissions
	  And I am on the home page	
		Then I should see "Create new collection" within "ul#select-item-list"
	  When I follow "Create new collection"
		Then I should see "Delete this" within "div.sidebar"
	  When I follow "delete_asset_link" within "div.sidebar"
	  And I press "Delete"
	  Then I should see "Deleted hydrangea:" within "div.notice"
	  
	