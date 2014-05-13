/**
 * This Javascript/JQuery method is used for the population of the contributor field
 * when a proxy user is making a deposit on behalf of someone else.  The method gets the selected
 * person on behalf of whom the proxy person is making the deposit and places that person's name in
 * a Contributor field and clicks the contributor Add button.
 */
function updateContributors(){

    // Get the selected owner name from the owner control.
    // If it is 'Myself', then pluck the name from the display name on the dropdown menu in the title bar of the page.
    // If 'nothing' was selected, do nothing and return.

    var ownerName = $("[id*='_owner'] option:selected").text();
    if (ownerName == 'Myself') {
        ownerName = $(".user-display-name").text().trim();
    }
    else if (ownerName === "") { return; }

    // Put that name into the "Add" Contributor control and force a click of the Add button.
    // Note that the last Contributor control is always the one into which a new user is entered.
    $('input[id$=_contributor]').last().val(ownerName);
    $("div[class*=_contributor] .add").click();
}
