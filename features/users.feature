Feature: User Profile 

  Scenario: Show my profile 
    Given I load users
    Given I am logged in as "curator1@example.com"
    And I follow "curator1@example.com"
    Then I should see "Edit Your Profile"

  Scenario: Edit my profile 
    Given I load users
    Given I am logged in as "curator1@example.com"
    And I follow "curator1@example.com"
    And I follow "Edit Your Profile"
    And I fill in "user_twitter_handle" with "curatorOfData"
    And I press "Save Profile"
    Then I should see "Your profile has been updated"
    And I should see "curatorOfData"

