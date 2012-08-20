Feature: Sending an email via the contact form 

  Scenario: Input info to contact form and send 
    Given I am on the home page
    When I follow "Contact" 
    Then I should see "Contact Form"
    And I fill in "contact_form_name" with "Test McPherson" 
    And I fill in "contact_form_email" with "archivist1@example.com"
    And I fill in "contact_form_message" with "I am contacting you regarding ScholarSphere."
    And I select "Depositing content" from "contact_form_issue_type"
    And I press "Send"
    Then I should see "Thank you"

  Scenario: Input no selection for contact type 
    Given I am on the home page
    When I follow "Contact" 
    Then I should see "Contact Form"
    And I fill in "contact_form_name" with "Test McPherson" 
    And I fill in "contact_form_email" with "archivist1"
    And I fill in "contact_form_message" with "I am contacting you regarding ScholarSphere."
    And I press "Send"
    Then I should see "Sorry, this message was not sent successfully"

  Scenario: Input poorly formed email address for contact 
    Given I am on the home page
    When I follow "Contact" 
    Then I should see "Contact Form"
    And I fill in "contact_form_name" with "Test McPherson" 
    And I fill in "contact_form_email" with "archivist1"
    And I fill in "contact_form_message" with "I am contacting you regarding ScholarSphere."
    And I press "Send"
    Then I should see "Sorry, this message was not sent successfully"

  Scenario: Input empty name field 
    Given I am on the home page
    When I follow "Contact" 
    Then I should see "Contact Form"
    And I fill in "contact_form_email" with "archivist1@example.com"
    And I fill in "contact_form_message" with "I am contacting you regarding ScholarSphere."
    And I press "Send"
    Then I should see "Sorry, this message was not sent successfully"


  Scenario: Input empty message field 
    Given I am on the home page
    When I follow "Contact" 
    Then I should see "Contact Form"
    And I fill in "contact_form_name" with "Test McPherson" 
    And I fill in "contact_form_email" with "archivist1@example.com"
    And I press "Send"
    Then I should see "Sorry, this message was not sent successfully"

  Scenario: Input spam field  
    Given I am on the home page
    When I follow "Contact" 
    Then I should see "Contact Form"
    And I fill in "contact_form_contact_method" with "My name is"
    And I fill in "contact_form_name" with "Test McPherson" 
    And I fill in "contact_form_email" with "archivist1@example.com"
    And I fill in "contact_form_message" with "I am contacting you regarding ScholarSphere."
    And I press "Send"
    Then I should see "Sorry, " 
