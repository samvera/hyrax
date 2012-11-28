Feature: Browse Dashboard files 


  Scenario: Browse via Fixtures 
    Given I am logged in as "archivist2@example.com"
    And I follow "dashboard"
    And I follow "more Keywords"
    And I follow "keyf"
    Then I should see "Test mp3"

  Scenario: Edit Dashboard File 
    Given I am logged in as "archivist2@example.com"
    And I follow "dashboard"
    When I follow the link within
    """
    a[href="/files/test5/edit"]
    """
    Then I should see "Edit Test mp3"

