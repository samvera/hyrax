@edit @admin 
Feature: Edit a collection
 	In order to edit a collection
  As a logged-in admin_policy_object_editor
  I want to see & edit a dataset's values
  
  
  
  Scenario: Visit Collection Edit Page
    Given I am logged in as "archivist1" with "admin_policy_object_editor" permissions
    And I am on the edit document page for hydrus:admin_class1
    Then I should see a "span" tag with a "class" attribute of "edit-browse"    
		Then I should see "Electronic Theses and Dissertations" 
		Then I should see an inline edit containing "Electronic Theses and Dissertations"
		Then I should see an inline edit containing "This is a test object for Stanford admin class"


		
	Scenario: Catalog Access Restrictions
	 Given I am logged in as "researcher1"
	 And I am on the edit document page for hydrus:admin_class1
   Then I should see a "div" tag with a "class" attribute of "notice"