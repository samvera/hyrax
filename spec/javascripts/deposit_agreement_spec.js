describe("DepositAgreement", function() {
  var control = require('hyrax/save_work/deposit_agreement');

  describe("isActiveAgreement", function() {
    describe("with a checkbox agreement", function() {
      beforeEach(function() {
        var fixture = setFixtures('<form><input id="agreement" type="checkbox"><input type="submit"></form>');
        element = fixture.find('form')
        target = new control.DepositAgreement(element);
      });

      it("is true", function() {
        expect(target.isActiveAgreement).toEqual(true);
      });
    });

    describe("without a checkbox agreement", function() {
      beforeEach(function() {
        var fixture = setFixtures('<form><input type="submit"></form>');
        element = fixture.find('form')
        target = new control.DepositAgreement(element);
      });

      it("is false", function() {
        expect(target.isActiveAgreement).toEqual(false);
      });
    });
  });

  describe("isAccepted", function() {
    describe("with a checkbox agreement", function() {
      var element = null;
      beforeEach(function() {
        var fixture = setFixtures('<form><input id="agreement" type="checkbox"><input type="submit"></form>');
        element = fixture.find('form')
        target = new control.DepositAgreement(element);
      });

      describe("and the checkbox is not checked", function() {
        it("is false", function() {
          expect(target.isAccepted).toEqual(false);
          expect(target.mustAgreeAgain).toEqual(false);
        });
      });

      describe("and the checkbox is checked", function() {
        beforeEach(function() {
          element.find('#agreement').prop('checked', true);
        });
        it("is true", function() {
          expect(target.isAccepted).toEqual(true);
          expect(target.mustAgreeAgain).toEqual(false);
        });
      });
    });

    describe("without a checkbox agreement", function() {
      beforeEach(function() {
        var fixture = setFixtures('<form><input type="submit"></form>');
        element = fixture.find('form')
        target = new control.DepositAgreement(element);
      });

      it("is true", function() {
        expect(target.isAccepted).toEqual(true);
        expect(target.mustAgreeAgain).toEqual(false);
      });
    });
  });
});
