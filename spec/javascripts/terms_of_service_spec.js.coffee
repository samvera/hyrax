describe "terms of service", ->
    beforeEach ->
        # setup a simple form with a checkbox and a button tomimic the upload forms
        setFixtures  '<input id="check" type="checkbox" data-activate="activate-submit"><input><div id="div1" class="activate-container" data-toggle="tooltip"><button type="submit" class="activate-submit"></button></div>'

        # call all the Blacklight.onLoad functions
        Blacklight.activate()


    # no submit button unless activate-submit is checked
    it "submit is disabled by default", ->
        expect($('.activate-submit')).toBeDisabled()

    # shows tooltip until active-submit is checked
    it "shows the tooltip by defualt", ->
        se = spyOn $.fn, 'tooltip' # spy on tooltip call
        $('.activate-container').trigger('mousemove')
        expect(se).toHaveBeenCalledWith 'show'

    describe "when checked", ->
        # agree to the terms of service
        beforeEach ->
            $('#check').trigger('click')

        it "activates submit when clicked", ->
            expect($('.activate-submit')).not.toBeDisabled()

        it "does not show the tooltip after checked", ->
            se = spyOn $.fn, 'tooltip' # spy on tooltip call
            $('.activate-container').trigger('mousemove')
            expect(se).toHaveBeenCalledWith 'hide'

