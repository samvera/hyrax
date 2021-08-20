export default class {
    constructor(data) {
        this.userSelector = 'user-activity'
        this.growthSelector = 'dashboard-growth'
        this.statusSelector = 'dashboard-repository-objects'
        if (this.hasSelector(this.userSelector))
            this.userActivity(data.userActivity);
        if (this.hasSelector(this.growthSelector))
            this.repositoryGrowth(data.repositoryGrowth);
        if (this.hasSelector(this.statusSelector))
            this.objectStatus(data.repositoryObjects);
    }
    // Don't attempt to initialize Morris if the selector is not on the page
    // otherwise it raises a "Graph container element not found" error
    hasSelector(selector) {
        return $(`#${selector}`).length > 0;
    }
    // Draws a bar chart of new user signups
    userActivity(data) {
        if (typeof data === 'undefined') return
        Morris.Bar({
            element: this.userSelector,
            data: data,
            xkey: 'y',
            // TODO: when we add returning users:
            // ykeys: ['a', 'b'],
            // labels: ['New Users', 'Returning'],
            ykeys: ['a'],
            labels: ['New Users', 'Returning'],
            barColors: ['#001219','#005f73','#0a9396','#94d2bd','#e9d8a6','#ee9b00','#ca6702','#bb3e03','#ae2012','#9b2226'],
            gridTextSize: '12px',
            hideHover: true,
            resize: true,
            gridLineColor: '#E5E5E5'
        });
    }
    // Draws a donut chart of active/inactive objects
    objectStatus(data) {
        if (typeof data === "undefined")
            return
        Morris.Donut({
            element: this.statusSelector,
            data: data,
            colors: ['#001219','#005f73','#0a9396','#94d2bd','#e9d8a6','#ee9b00','#ca6702','#bb3e03','#ae2012','#9b2226'],
            gridTextSize: '12px',
            resize: true
        });
    }
    // Creates a line graph of collections and object in the last 90 days
    repositoryGrowth(data) {
        if (typeof data === "undefined")
            return
        Morris.Line({
            element: this.growthSelector,
            data: data,
            xkey: 'y',
            ykeys: ['a','b'],
            labels: ['Objects','Collections'],
            resize: true,
            hideHover: true,
            xLabels: 'day',
            gridTextSize: '12px',
            lineColors: ['#001219','#005f73','#0a9396','#94d2bd','#e9d8a6','#ee9b00','#ca6702','#bb3e03','#ae2012','#9b2226'],
            gridLineColor: '#E5E5E5'
        });
    }
}
