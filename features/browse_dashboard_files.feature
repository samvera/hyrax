Feature: Browse Dashboard files 

  Scenario: Browse via Fixtures 
    Given I load sufia fixtures
    Given I am logged in as "archivist2@example.com"
    And I follow "dashboard"
    And I follow "more Keywords"
    And I follow "keyf"
    Then I should see "Test mp3"
