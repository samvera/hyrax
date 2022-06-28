describe "tabs", ->
  beforeEach ->
    # run all Blacklight.onload functions
    Blacklight.activate()

  describe "dashboard tabs", ->
    beforeEach ->
      # setup the tabs like the homepage featured and recent tabs
      setFixtures '<ul id="homeTabs" class="nav nav-tabs">
                               <li><a href="#featured_container" data-toggle="tab" role="tab" id="featureTab">Featured Works</a></li>
                               <li><a href="#recently_uploaded" data-toggle="tab" role="tab" id="recentTab">Recently Uploaded</a></li>
                             </ul>'


    describe "tabNavigation", ->

      it "It sets the first tab to active", ->
        expect($('#homeTabs a:first').attr('class')).toBeUndefined()
        tabNavigation();
        expect($('#homeTabs a:first').attr('class')).toBe('active')

  describe "dashboard tabs", ->
    beforeEach ->
      # setup the tabs like the my listing on the dashboards
      setFixtures '<ul class="nav nav-tabs" id="my_nav" role="navigation">
                     <span class="sr-only">You are currently listing your works .  You have 1 works </span>
                     <li>
                       <a href="/dashboard/works">My Works</a>
                     </li>
                     <li class="">
                       <a href="/dashboard/collections">My Collections</a>
                     </li>
                   </ul>'

    describe "tabNavigation", ->

      it "It does not error", ->
        tabNavigation();