@new @dor_object @terms
Feature: Accepting Collection terms for Admin Policy Object
  In order to add an item to a collection
  Users
  need to accept the collection's terms
  
  Scenario: Viewing Collection terms for Admin Policy Object
    Given I am logged in as "archivist1"	
    When I follow "Add new item"
	Then I should see "you must agree to its terms of service"	

  Scenario: Accepting Collection terms for Admin Policy Object
    Given I am logged in as "archivist1"	
    And I follow "Add new item"
	When I press "I agree"		
	## We should really be checking that we're on the page for a new dor_object
	## I'm not sure how to test for that as it keeps loading the /edit page for a brand new object
	## So, let's check a couple of the expected labels
    Then I should see "Description" within "div#accordion h2.section-title"
	And I should see an "h2.section-title a" element containing "Set permissions"
	
  Scenario: Non-logged in users shouldn't have access to create new items
    Given I am not logged in
	And I am on the homepage	
	Then I should not see "you must agree to to its terms of service"