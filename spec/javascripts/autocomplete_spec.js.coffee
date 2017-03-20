describe "auto complete", ->
  beforeEach ->
    # set up the spy to see in the autocomplete is called
    resp = [{"uri":"http://lexvo.org/id/iso639-3/fra","label":"French"},{"uri":"http://lexvo.org/id/iso639-3/fsl","label":"French Sign Language"}]
    @spy_on_json = spyOn($, 'getJSON').and.returnValue resp

    #set up a key down event to trigger the auto complete
    @typeEvent = $.Event('keydown')
    @typeEvent.keyCode = 70 # lower case f

    #define the jasmine clock so we can control time
    jasmine.clock().install()

  afterEach ->
    #undefine the jasmine clock so time goes back to normal
    jasmine.clock().uninstall()

  describe "language", ->
    beforeEach ->
      # setup two inputs for us to attach  auto complete to
      setFixtures  '<input class="generic_work_language"  value="" id="generic_work_language" type="text" data-autocomplete="language" data-autocomplete-url="foo">
                    <input class="generic_work_language"  value="" type="text" data-autocomplete="language" data-autocomplete-url="foo">'

      # run all Blacklight.onload functions
      Blacklight.activate()

    describe "first input", ->

      # field triggers auto complete
      it "auto completes on typing", ->
        # send a key stroke to the target input to activate the auto complete
        target = $($("input.generic_work_language")[0])
        target.val('fre')
        target.trigger(@typeEvent)

        # move time along so that events have a chance to happen
        jasmine.clock().tick(800)

        # verify that the ajax call was made
        expect(@spy_on_json).toHaveBeenCalled()


    describe "second input", ->

      # field triggers auto complete
      it "auto completes on typing", ->
        # send a key stroke to the target input to activate the auto complete
        target = $($("input.generic_work_language")[1])
        target.val('fre')
        target.trigger(@typeEvent)

        # move time along so that events have a chance to happen
        jasmine.clock().tick(800)

        # verify that the ajax call was made
        expect(@spy_on_json).toHaveBeenCalled()

  describe "subject", ->
    beforeEach ->
      # setup two inputs for us to attach  auto complete to
      setFixtures  '<input class="generic_work_subject"  value="" id="generic_work_subject" type="text" data-autocomplete="subject" data-autocomplete-url="foo">
                    <input class="generic_work_subject"  value="" type="text" data-autocomplete="subject" data-autocomplete-url="foo">'

      # run all Blacklight.onload functions
      Blacklight.activate()

    describe "first input", ->

      # field triggers auto complete
      it "auto completes on typing", ->
        # send a key stroke to the target input to activate the auto complete
        target = $($("input.generic_work_subject")[0])
        target.val('fre')
        target.trigger(@typeEvent)

        # move time along so that events have a chance to happen
        jasmine.clock().tick(800)

        # verify that the ajax call was made
        expect(@spy_on_json).toHaveBeenCalled()


    describe "second input", ->

      # field triggers auto complete
      it "auto completes on typing", ->
        # send a key stroke to the target input to activate the auto complete
        target = $($("input.generic_work_subject")[1])
        target.val('fre')
        target.trigger(@typeEvent)

        # move time along so that events have a chance to happen
        jasmine.clock().tick(800)

        # verify that the ajax call was made
        expect(@spy_on_json).toHaveBeenCalled()


  describe "location", ->
    beforeEach ->
      # setup two inputs for us to attach  auto complete to
      setFixtures  '<input class="generic_work_based_near" value="" id="generic_work_based_near" type="text" data-autocomplete="based_near" data-autocomplete-url="foo">
                    <input class="generic_work_based_near" value="" type="text" data-autocomplete="based_near" data-autocomplete-url="foo">'

      # run all Blacklight.onload functions
      Blacklight.activate()

    describe "first input", ->

      # field triggers auto complete
      it "auto completes on typing", ->
        # send a key stroke to the target input to activate the auto complete
        target = $($("input.generic_work_based_near")[0])
        target.val('fre')
        target.trigger(@typeEvent)

        # move time along so that events have a chance to happen
        jasmine.clock().tick(800)

        # verify that the ajax call was made
        expect(@spy_on_json).toHaveBeenCalled()


    describe "second input", ->

      # field triggers auto complete
      it "auto completes on typing", ->
        # send a key stroke to the target input to activate the auto complete
        target = $($("input.generic_work_based_near")[1])
        target.val('fre')
        target.trigger(@typeEvent)

        # move time along so that events have a chance to happen
        jasmine.clock().tick(800)

        # verify that the ajax call was made
        expect(@spy_on_json).toHaveBeenCalled()

  describe "for works", ->
    beforeEach ->
      # setup two inputs for us to attach auto complete to
      setFixtures  '<input class="generic_work_work" value="" id="generic_work_based_near" type="text" data-autocomplete="work" data-autocomplete-url="foo">
                    <input class="generic_work_work" value="" type="text" data-autocomplete="work" data-autocomplete-url="foo">'

      # run all Blacklight.onload functions
      Blacklight.activate()

    describe "the first input", ->
      it "initializes using select2", ->
        target = $($("input.generic_work_work")[0])
        expect(target.select2('open')).toBe(true)

    describe "the second input", ->
      it "initializes using select2", ->
        target = $($("input.generic_work_work")[1])
        expect(target.select2('open')).toBe(true)
