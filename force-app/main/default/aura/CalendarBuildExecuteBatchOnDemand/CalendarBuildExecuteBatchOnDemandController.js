({
    executeBatch : function (cmp, event, helper){
        var msg;
        var draftBatchSize;
        var buttonName = event.getSource().get("v.name");
        console.log('button pressed is:', buttonName);
                                   
        if(buttonName == "generate") {
            var action = cmp.get("c.executeBatchJob");
            msg ='Are you sure you want to generate CB draft drives? If so, the system will process records in batches of: ' + cmp.get("v.draftBatchSize");
        }
        else if(buttonName == "update") {
            var action = cmp.get("c.executeBatchUpdateJob");
            msg ='Are you sure you want to update all draft drives to system generated? If so, the system will process records in batches of: ' + cmp.get("v.sysGenBatchSize");
        }
        if (!confirm(msg)) {
            return false;
        } else {
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": "The Job has been successfully initiated."
                    });
                    toastEvent.fire();
                    
                    if (state === "SUCCESS"){
                        var interval = setInterval($A.getCallback(function () {
                            var jobStatus = cmp.get("c.getBatchJobStatus");
                            if(jobStatus != null){
                                jobStatus.setParams({ jobID : response.getReturnValue()});
                                jobStatus.setCallback(this, function(jobStatusResponse){
                                    var state = jobStatus.getState();
                                    if (state === "SUCCESS"){
                                        var job = jobStatusResponse.getReturnValue();
                                        cmp.set('v.apexJob',job);
                                        var processedPercent = 0;
                                        if(job.JobItemsProcessed != 0){
                                            processedPercent = (job.JobItemsProcessed / job.TotalJobItems) * 100;
                                        }
                                        var progress = cmp.get('v.progress');
                                        cmp.set('v.progress', progress === 100 ? clearInterval(interval) :  processedPercent);
                                    }
                                });
                                $A.enqueueAction(jobStatus);
                            }
                        }), 2000);
                    }
                }
                else if (state === "ERROR") {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "An Error has occured. Please try again or contact System Administrator."
                    });
                    toastEvent.fire();
                }
            });}
        $A.enqueueAction(action);
    },
    
    myAction: function(component, event, helper) {
        helper.fetchDraftBatchSize(component, event, helper);
        helper.fetchSysGenBatchSize(component, event, helper);
    }
});