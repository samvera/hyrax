@user @session
Feature: Switch user sessions
  In order to gain access to different permissions
  a user
  wants to log in and out of user accounts from the same browser
  
  Scenario: Logging in, logging out, then logging in as someone else
    Given I am logged in as "permissionlessdude@mail.com"
    Then I should see "Log Out"
    And I should see "permissionlessdude@mail.com"
    When I log out
    And I log in as "archivist1@examplesite.com"
    Then I should see "Log Out"
    And I should see "archivist1@examplesite.com"