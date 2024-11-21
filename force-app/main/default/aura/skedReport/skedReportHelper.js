({
    createChart : function (component) {
        var ready = component.get("v.ready");
        if (ready === false) {
            return;
        }
        var chartCanvas = component.find("chart").getElement();
        
        var action = component.get("c.getreport");
        action.setParams({reportId : '00O3F000000oTnYUAU'})
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var reportResultData = JSON.parse(response.getReturnValue());
                var chartData = [];
                var chartLabels = [];
                for(var i=0; i < (reportResultData.groupingsDown.groupings.length); i++){
                    //Collect all labels for Chart.js data
                    var labelTemp = reportResultData.groupingsDown.groupings[i].label;
                    chartLabels.push(labelTemp);

                    var keyTemp = reportResultData.groupingsDown.groupings[i].key;

                    //Collect all values for Chart.js data
                    var valueTemp = reportResultData.factMap[keyTemp + '!T'].aggregates[0].value ;
                    chartData.push(valueTemp);
                }
                //Construct chart
                var chart = new Chart(chartCanvas,{
                    type: 'doughnut',
                    data: {
                        labels: chartLabels,
                        datasets: [
                            {
                                label: "test",
                                data: chartData,
                                backgroundColor: [
                                    "#52BE80",
                                    "#76D7C4",
                                    "#1E8449"
                                ]
                            }
                        ]
                    },
                    options: {
                        cutoutPercentage: 75,
                        maintainAspectRatio: false,
                        legend: {
                            display: true,
                            position:'right',
                            fullWidth:false,
                            reverse:true,
                            labels: {
                                fontColor: '#000',
                                fontSize:10,
                                fontFamily:"Salesforce Sans, Arial, sans-serif SANS_SERIF"
                            },
                            layout: {
                                padding: 70,
                            }
                        }
                    }
                });
                
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message on createReport: " +
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})