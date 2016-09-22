describe "Chart Generation", ->
  beforeEach () ->
    loadFixtures('chart_example.html')
  describe "instantiation", ->
    it "builds a chart for all stats pies", ->
      $(".stats-pie").on("load", ->
        canvas = $(".stats-pie > .highcharts-container")
        expect(canvas.length).toBeLessThan(1)
      )
      Blacklight.activate()
