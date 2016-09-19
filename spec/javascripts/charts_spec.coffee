describe "Chart Generation", ->
  beforeEach () ->
    loadFixtures('chart_example.html')
  describe "instantiation", ->
    it "builds a chart for all stats doughnuts", ->
      Blacklight.activate()
      canvas = $(".stats-doughnut > canvas")
      expect(canvas.length).not.toBeLessThan(1)
