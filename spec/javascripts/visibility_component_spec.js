describe("VisibilityComponent", function() {
  var VisibilityComponent = require('hyrax/save_work/visibility_component');
  var AdminSetWidget = require('hyrax/editor/admin_set_widget');
  var target = null;
  var element = null;
  var admin_set = null;
  var form = null;

  beforeEach(function() {
    var fixture = setFixtures(visibilityForm(''));
    element = fixture.find('.visibility');
    form = element.closest('form');
    form.on("submit", function (e) { e.preventDefault(); });
    admin_set = new AdminSetWidget(fixture.find('select'));
    target = new VisibilityComponent(element, admin_set);
  });

  it("enables all options before form submit", function() {
    spyOn(target, 'enableAllOptions');
    form.trigger('submit');
    expect(target.enableAllOptions).toHaveBeenCalled();
  })

  //limitByAdminSet() - Also tests restrictToVisibility(selected) which is where much of logic sits
  describe("limitByAdminSet", function() {
    describe("with no admin set selected", function() {
      beforeEach(function() {
        spyOn(target, 'enableAllOptions');
      });
      it("enables all visibility options", function() {
        target.limitByAdminSet();
        expect(target.enableAllOptions).toHaveBeenCalled();
      });
    });
    describe("with selected admin set having no restrictions", function() {
      beforeEach(function() {
        var fixture = setFixtures(visibilityForm('<option selected="selected">No Restrictions AdminSet</option>'));
        element = fixture.find('.visibility');
        target = new VisibilityComponent(element, admin_set);
        spyOn(target, 'enableAllOptions');
      });
      it("enables all visibility options", function() {
        target.limitByAdminSet();
        expect(target.enableAllOptions).toHaveBeenCalled();
      });
    });
    describe("with selected admin set having visibility restrictions only", function() {
      beforeEach(function() {
        var fixture = setFixtures(visibilityForm('<option data-visibility="authenticated" selected="selected">Institution-Only AdminSet</option>'));
        element = fixture.find('.visibility');
        admin_set = new AdminSetWidget(fixture.find('select'))
        target = new VisibilityComponent(element, admin_set);
        spyOn(target, 'applyRestrictions');
      });
      it("calls applyRestrictions with specified visibility", function() {
        target.limitByAdminSet();
        expect(target.applyRestrictions).toHaveBeenCalledWith('authenticated', undefined, undefined, undefined);
      });
    });
    describe("with selected admin set having release immediately restrictions (no visibility)", function() {
      beforeEach(function() {
        var fixture = setFixtures(visibilityForm('<option data-release-no-delay="true" selected="selected">Release Immediately AdminSet</option>'));
        element = fixture.find('.visibility');
        admin_set = new AdminSetWidget(fixture.find('select'))
        target = new VisibilityComponent(element, admin_set);
        spyOn(target, 'applyRestrictions');
      });
      it("calls applyRestrictions with release_no_delay=true", function() {
        target.limitByAdminSet();
        expect(target.applyRestrictions).toHaveBeenCalledWith(undefined, true, undefined, undefined);
      });
    });
    describe("with selected admin set having release publicly immediately restrictions", function() {
      beforeEach(function() {
        var fixture = setFixtures(visibilityForm('<option data-visibility="open" data-release-no-delay="true" selected="selected">Release Publicly Immediately AdminSet</option>'));
        element = fixture.find('.visibility');
        admin_set = new AdminSetWidget(fixture.find('select'))
        target = new VisibilityComponent(element, admin_set);
        spyOn(target, 'applyRestrictions');
      });
      it("calls applyRestrictions with release_no_delay=true and visibility requirement", function() {
        target.limitByAdminSet();
        expect(target.applyRestrictions).toHaveBeenCalledWith("open", true, undefined, undefined);
      });
    });
    describe("with selected admin set having release on future date set", function() {
      beforeEach(function() {
        var fixture = setFixtures(visibilityForm('<option data-release-date="' + getOneYearFromToday() + '" data-release-before-date="false" selected="selected">Release in One Year AdminSet</option>'));
        element = fixture.find('.visibility');
        admin_set = new AdminSetWidget(fixture.find('select'))
        target = new VisibilityComponent(element, admin_set);
        spyOn(target, 'applyRestrictions');
      });
      it("calls applyRestrictions with specified date requirement", function() {
        target.limitByAdminSet();
        expect(target.applyRestrictions).toHaveBeenCalledWith(undefined, undefined, getOneYearFromToday(), false);
      });
    });
    describe("with selected admin set having release to institution before one year set", function() {
      beforeEach(function() {
        var fixture = setFixtures(visibilityForm('<option data-visibility="authenticated" data-release-date="' + getOneYearFromToday() + '" data-release-before-date="true" selected="selected">Release in One Year to Institution AdminSet</option>'));
        element = fixture.find('.visibility');
        admin_set = new AdminSetWidget(fixture.find('select'))
        target = new VisibilityComponent(element, admin_set);
        spyOn(target, 'applyRestrictions');
      });
      it("calls applyRestrictions with specified date and visibility requirement", function() {
        target.limitByAdminSet();
        expect(target.applyRestrictions).toHaveBeenCalledWith("authenticated", undefined, getOneYearFromToday(), true);
      });
    });
  });

  //applyRestrictions(visibility, release_date, release_before)
  describe("applyRestrictions", function() {
    describe("with visibility restrictions only (no release date requirements)", function() {
      beforeEach(function() {
        spyOn(target, 'enableReleaseNowOrEmbargo');
      });
      it("enable that visibility option OR embargo, and limit embargo to any future date", function() {
        target.applyRestrictions("authenticated", undefined, undefined, undefined);
        expect(target.enableReleaseNowOrEmbargo).toHaveBeenCalledWith("authenticated", undefined, undefined);
      });
    });
    describe("with release date of today (immediately) and no visibility", function() {
      beforeEach(function() {
        spyOn(target, 'disableEmbargoAndLease');
      });
      it("disables embargo and lease options", function() {
        target.applyRestrictions(undefined, true, undefined, undefined);
        expect(target.disableEmbargoAndLease).toHaveBeenCalled();
      });
    });
    describe("with release date of today (immediately) and required visibility", function() {
      beforeEach(function() {
        spyOn(target, 'selectVisibility');
      });
      it("selects that visibility (disabling other options)", function() {
        target.applyRestrictions("open", true, undefined, undefined);
        expect(target.selectVisibility).toHaveBeenCalledWith("open");
      });
    });
    describe("with required visibility and embargo allowed (release before future date)", function() {
      beforeEach(function() {
        spyOn(target, 'enableReleaseNowOrEmbargo');
      });
      it("allows any date between now and future date", function() {
        var futureDate = getOneYearFromToday();
        target.applyRestrictions("open", undefined, futureDate, true);
        expect(target.enableReleaseNowOrEmbargo).toHaveBeenCalledWith("open", futureDate, true);
      });
    });
    describe("with required future release date, and any visibility allowed", function() {
      beforeEach(function() {
        spyOn(target, 'requireEmbargo');
      });
      it("require embargo until release_date and don't restrict visibility", function() {
        var futureDate = getOneYearFromToday();
        target.applyRestrictions(undefined, undefined, futureDate, false);
        expect(target.requireEmbargo).toHaveBeenCalledWith(undefined, futureDate);
      });
    });
    describe("with required future release date, and required visibility", function() {
      beforeEach(function() {
        spyOn(target, 'requireEmbargo');
      });
      it("require embargo until release_date and require visibility", function() {
        var futureDate = getOneYearFromToday();
        target.applyRestrictions("authenticated", undefined, futureDate, false);
        expect(target.requireEmbargo).toHaveBeenCalledWith("authenticated", futureDate);
      });
    });
    describe("with required past release date, dont restrict visibility", function() {
      beforeEach(function() {
        spyOn(target, 'disableEmbargoAndLease');
      });
      it("disable embargo and lease", function() {
        target.applyRestrictions(undefined, undefined, "2017-01-01", false);
        expect(target.disableEmbargoAndLease).toHaveBeenCalled();
      });
    });
    describe("with required past release date, and required visibility", function() {
      beforeEach(function() {
        spyOn(target, 'selectVisibility');
      });
      it("require visibility", function() {
        var visibility = "authenticated";
        target.applyRestrictions(visibility, undefined, "2017-01-01", false);
        expect(target.selectVisibility).toHaveBeenCalledWith(visibility);
      });
    });
  });

  //selectVisibility(visibility)
  describe("selectVisibility", function() {
    describe("with 'open' passed in", function() {
      it("selects the required open visibility, disabling all other options", function() {
        target.selectVisibility("open");
        expect(element.find("[type='radio'][value='open']")).toBeChecked();
        expect(element.find("[type='radio'][value='open']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='authenticated']")).toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).toBeDisabled();
        expect(element.find("[type='radio'][value='restricted']")).toBeDisabled();
        expect(element.find("[type='radio'][value='lease']")).toBeDisabled();
      });
    });
    describe("with 'restricted' passed in", function() {
      it("selects the required restricted visibility, disabling all other options", function() {
        target.selectVisibility("restricted");
        expect(element.find("[type='radio'][value='open']")).toBeDisabled();
        expect(element.find("[type='radio'][value='authenticated']")).toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).toBeDisabled();
        expect(element.find("[type='radio'][value='restricted']")).toBeChecked();
        expect(element.find("[type='radio'][value='restricted']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='lease']")).toBeDisabled();
      });
    });
  });

  //enableReleaseNowOrEmbargo(visibility, release_date, release_before)
  describe("enableReleaseNowOrEmbargo", function() {
    describe("with visibility only", function() {
      it("enable that visibility option OR embargo, restrict release_date to after today, and set visibility after embargo", function() {
        target.enableReleaseNowOrEmbargo("open", undefined, undefined);
        expect(element.find("[type='radio'][value='open']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
        expect(target.getEmbargoDateInput()).toHaveProp("min", target.getToday());
        expect(target.getEmbargoDateInput()).not.toBeDisabled();
        expect(target.getVisibilityAfterEmbargoInput()).toHaveValue("open");
        expect(target.getVisibilityAfterEmbargoInput()).toBeDisabled();
      });
    });
    describe("with visibility and release_date range", function() {
      it("enable that visibility OR embargo, restrict release_date to range, and set visibility after embargo", function() {
        var futureDate = getOneYearFromToday();
        target.enableReleaseNowOrEmbargo("authenticated", futureDate, true);
        // enable immediate release or embargo with given visibility
        expect(element.find("[type='radio'][value='authenticated']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
        // restrict embargo date range
        expect(target.getEmbargoDateInput()).toHaveProp("min", target.getToday());
        expect(target.getEmbargoDateInput()).toHaveProp("max", futureDate);
        expect(target.getEmbargoDateInput()).not.toBeDisabled();
        // require visibility after embargo
        expect(target.getVisibilityAfterEmbargoInput()).toHaveValue("authenticated");
        expect(target.getVisibilityAfterEmbargoInput()).toBeDisabled();
      });
    });
  });

  //disableEmbargoAndLease
  describe("disableEmbargoAndLease", function() {
    it("Disables embargo and lease options, enabling all others", function() {
      target.disableEmbargoAndLease();
      expect(element.find("[type='radio'][value='open']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='authenticated']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='embargo']")).toBeDisabled();
      expect(element.find("[type='radio'][value='restricted']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='lease']")).toBeDisabled();
    });
  });

  //requireEmbargo(visibility, release_date)
  describe("requireEmbargo", function() {
    describe("with release_date only", function() {
      it("select 'embargo', require that release_date, allow any visibility", function() {
        target.requireEmbargo(undefined, "2017-01-01");
        expect(element.find("[type='radio'][value='embargo']")).toBeChecked();
        expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
        expect(target.getEmbargoDateInput()).toHaveValue("2017-01-01");
        expect(target.getEmbargoDateInput()).toBeDisabled();
        expect(target.getVisibilityAfterEmbargoInput()).not.toBeDisabled();
      });
    });
    describe("with release_date and visibility", function() {
      it("select 'embargo', require that release_date, require visibility", function() {
        target.requireEmbargo("open", "2017-01-01");
        expect(element.find("[type='radio'][value='embargo']")).toBeChecked();
        expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
        expect(target.getEmbargoDateInput()).toHaveValue("2017-01-01");
        expect(target.getEmbargoDateInput()).toBeDisabled();
        expect(target.getVisibilityAfterEmbargoInput()).toHaveValue("open");
        expect(target.getVisibilityAfterEmbargoInput()).toBeDisabled();
      });
    });
  });

  //enableVisibilityOptions(options)
  describe("enableVisibilityOptions", function() {
    describe("with array of options", function() {
      it("enables listed radio buttons, and disables any unlisted", function() {
        target.enableVisibilityOptions(["open","restricted"]);
        expect(element.find("[type='radio'][value='open']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='authenticated']")).toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).toBeDisabled();
        expect(element.find("[type='radio'][value='restricted']")).not.toBeDisabled();
      });
    });
    describe("with no options", function() {
      it("disables all radio buttons", function() {
        target.enableVisibilityOptions([]);
        expect(element.find("[type='radio'][value='open']")).toBeDisabled();
        expect(element.find("[type='radio'][value='authenticated']")).toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).toBeDisabled();
        expect(element.find("[type='radio'][value='restricted']")).toBeDisabled();
      });
    });
  });

  //disableVisibilityOptions(options)
  describe("disableVisibilityOptions", function() {
    describe("with array of options", function() {
      it("disables listed radio buttons, and enables any unlisted", function() {
        target.disableVisibilityOptions(["open","restricted"]);
        expect(element.find("[type='radio'][value='open']")).toBeDisabled();
        expect(element.find("[type='radio'][value='authenticated']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='restricted']")).toBeDisabled();
      });
    });
    describe("with no options", function() {
      it("enables all radio buttons", function() {
        target.disableVisibilityOptions([]);
        expect(element.find("[type='radio'][value='open']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='authenticated']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
        expect(element.find("[type='radio'][value='restricted']")).not.toBeDisabled();
      });
    });
  });

  //getMatcherForVisibilities(options)
  describe("getMatcherForVisibilities", function() {
    describe("with array of options", function() {
      it("returns a jQuery matcher to match ONLY visibility radio buttons listed in options", function() {
        expect(target.getMatcherForVisibilities(["one","two","three"])).toEqual("[type='radio'][value='one'],[type='radio'][value='two'],[type='radio'][value='three']");
      });
    });
    describe("with no options", function() {
      it("returns an empty string (matches none of the radio buttons)", function() {
        expect(target.getMatcherForVisibilities([])).toEqual("");
      });
    });
  });

  //getMatcherForNotVisibilities(options)
  describe("getMatcherForNotVisibilities", function() {
    describe("with array of options", function() {
      it("returns a jQuery matcher to match visibility radio buttons NOT listed in options", function() {
        expect(target.getMatcherForNotVisibilities(["one","two","three"])).toEqual("[type='radio'][value!='one'][value!='two'][value!='three']");
      });
    });
    describe("with no options", function() {
      it("returns a jQuery matcher to match all visibility radio buttons", function() {
        expect(target.getMatcherForNotVisibilities([])).toEqual("[type='radio']");
      });
    });
  });

  //restrictEmbargoDate(release_date, release_before)
  describe("restrictEmbargoDate", function() {
    describe("with no date specified", function() {
      it("sets a minimum date of today", function() {
        target.restrictEmbargoDate("",false);
        expect(target.getEmbargoDateInput()).toHaveProp("min", target.getToday());
      });
    });
    describe("with exact release_date specified", function() {
      it("sets release_date and disables field", function() {
        target.restrictEmbargoDate("2017-01-01",false);
        var input = target.getEmbargoDateInput();
        expect(input).toHaveValue("2017-01-01");
        expect(input).toBeDisabled();
      });
    });
    describe("with release_date specified and prior dates allowed", function() {
      it("sets minimum date of today, maximum date of release_date and enables field", function() {
        var futureDate = getOneYearFromToday();
        target.restrictEmbargoDate(futureDate, true);
        var input = target.getEmbargoDateInput();
        expect(input).toHaveProp("min", target.getToday());
        expect(input).toHaveProp("max", futureDate);
        expect(input).not.toBeDisabled();
      });
    });
  });

  // selectVisibilityAfterEmbargo(visibility)
  describe("selectVisibilityAfterEmbargo", function() {
    describe("with 'open'", function() {
      it("selects 'open' option and disables field", function() {
        target.selectVisibilityAfterEmbargo("open");
        var input = target.getVisibilityAfterEmbargoInput();
        expect(input.find("option[value='open']")).toBeSelected();
        expect(input).toBeDisabled();
      });
    });
    describe("with no option", function() {
      it("enables field", function() {
        target.selectVisibilityAfterEmbargo("");
        var input = target.getVisibilityAfterEmbargoInput();
        expect(input).not.toBeDisabled();
      });
    });
  });

  // enableAllOptions()
  describe("enableAllOptions", function() {
    beforeEach(function() {
      element.find("[type='radio'][value='open']").prop("disabled", true);
      target.getEmbargoDateInput().prop("disabled", true);
      target.getVisibilityAfterEmbargoInput().prop("disabled", true);
    });
    it("enables all visibility fields", function() {
      target.enableAllOptions();
      expect(element.find("[type='radio'][value='open']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='authenticated']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='embargo']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='restricted']")).not.toBeDisabled();
      expect(element.find("[type='radio'][value='lease']")).not.toBeDisabled();
      expect(target.getEmbargoDateInput()).not.toBeDisabled();
      expect(target.getVisibilityAfterEmbargoInput()).not.toBeDisabled();
    });
  });

  // getEmbargoDateInput()
  describe("getEmbargoDateInput", function() {
    it("returns embargo date input", function() {
      expect(target.getEmbargoDateInput()).toHaveProp("name", "generic_work[embargo_release_date]");
    });
  });

  // getVisibilityAfterEmbargoInput()
  describe("getVisibilityAfterEmbargoInput", function() {
    it("returns visibility after embargo selectbox", function() {
      expect(target.getVisibilityAfterEmbargoInput()).toHaveProp("name", "generic_work[visibility_after_embargo]");
    });
  });

  //checkEnabledVisibilityOption()
  describe("checkEnabledVisibilityOption", function() {
    describe("with disabled option selected", function() {
      beforeEach(function() {
        target.enableAllOptions();
        element.find("[type='radio'][value='restricted']").prop("checked", true).prop("disabled", true);
      });
      it("selects last enabled radio option", function() {
        target.checkEnabledVisibilityOption();
        expect(element.find("[type='radio'][value='restricted']")).not.toBeChecked();
        expect(element.find("[type='radio'][value='lease']")).toBeChecked();
      });
    });
    describe("with enabled option selected", function() {
      beforeEach(function() {
        target.enableAllOptions();
        element.find("[type='radio'][value='open']").prop("checked", true);
      });
      it("does not change selection", function() {
        target.checkEnabledVisibilityOption();
        expect(element.find("[type='radio'][value='open']")).toBeChecked();
      });
    });
  });
});

// Generate a form that includes AdminSet selectbox (with a passed in option)
// AND the visibility radio button options
function visibilityForm(admin_set_option) {
    return '<form id="new_generic_work">' +
        '  <div>' +
        '    <select id="generic_work_admin_set_id">' +
        '     ' + admin_set_option +
        '    </select>' +
        '  </div>' +
        '  <div>' +
        '    <ul class="visibility">' +
        '      <li class="radio">' +
        '        <label>' +
        '          <input data-target="#collapsePublic" type="radio" value="open" name="generic_work[visibility]"/>Public' +
        '          <div class="collapse in" id="collapsePublic">' +
        '            <p>Public message that is collapsed by default</p>' +
        '          </div>' +
        '        </label>' +
        '      </li>' +
        '      <li class="radio">' +
        '        <label>' +
        '          <input type="radio" value="authenticated" name="generic_work[visibility]"/>Your Institution' +
        '        </label>' +
        '      </li>' +
        '      <li class="radio">' +
        '        <label>' +
        '          <input data-target="#collapseEmbargo" type="radio" value="embargo" name="generic_work[visibility]"/>Embargo' +
        '          <div class="collapse in" id="collapseEmbargo">' +
        '            <input type="date" id="generic_work_embargo_release_date" name="generic_work[embargo_release_date]"/>' +
        '            <select id="generic_work_visibility_after_embargo" name="generic_work[visibility_after_embargo]">' +
        '              <option value="open">Public</option>' +
        '              <option value="authenticated">Institution Name</option>' +
        '            </select>' +
        '          </div>' +
        '        </label>' +
        '      </li>' +
        '      <li class="radio">' +
        '        <label>' +
        '          <input type="radio" value="lease" name="generic_work[visibility]"/>Lease' +
        '        </label>' +
        '      </li>' +
        '      <li class="radio">' +
        '        <label>' +
        '          <input type="radio" value="restricted" name="generic_work[visibility]"/>Private' +
        '        </label>' +
        '      </li>' +
        '    </ul>' +
        '  </div>' +
        '</form>';
}

// Get the date one year from today in YYYY-MM-DD format
function getOneYearFromToday() {
  var today = new Date();
  var dd = today.getDate();
  var mm = today.getMonth() + 1;  // January is month 0
  var yyyy = today.getFullYear() + 1; // Add one year to this year

  // prepend zeros as needed
  if(dd < 10) {
    dd = '0' + dd;
  }
  if(mm < 10) {
    mm = '0' + mm;
  }
  return yyyy + '-' + mm + '-' + dd;
}
