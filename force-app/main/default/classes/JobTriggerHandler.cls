/* Modification Log 
 *    Date					     Developer Name			     Comments
 * **********************************************************************************
 *  09/26/2024				      Priti Jana		        Logic for HRP-13522
 *  08/06/2025				      Krapy Tuli		        Logic for HRP-15160
 * **********************************************************************************
 */

public class JobTriggerHandler extends TriggerHandler implements Callable {
    
    public override void beforeUpdate() {}
    
    public override void afterUpdate() {
       if(super.getTriggerMethodsToBypass().indexOf('jobPopulateDriveSupervisoryRole') == -1) { 
        	jobPopulateDriveSupervisoryRole((List<sked__Job__c>)trigger.new, (Map<Id,sked__Job__c>)trigger.oldMap);
        }
        //HRP-15160
        if(super.getTriggerMethodsToBypass().indexOf('jobPopulateDriveSupervisoryRole') == -1) { 
        	populateAdditionalRole((List<sked__Job__c>)trigger.new, (Map<Id,sked__Job__c>)trigger.oldMap);
        }
    }
    
    public override void beforeInsert() {}
    
    public override void afterInsert() {
        if(super.getTriggerMethodsToBypass().indexOf('jobPopulateDriveSupervisoryRole') == -1) { 
        	jobPopulateDriveSupervisoryRole((List<sked__Job__c>)trigger.new, null);
        }
    }
    
    public override void afterDelete(){
         if(super.getTriggerMethodsToBypass().indexOf('jobPopulateDriveSupervisoryRole') == -1) {
             BSF_Constants.After_Delete = True;
        	 jobPopulateDriveSupervisoryRole((List<sked__Job__c>)trigger.old, null);
             BSF_Constants.After_Delete = False;
        }
    }
    
    /**************************************** CALLABLE INTERFACE  ***************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'populateDriveSupervisoryRole' {
                    populateDriveSupervisoryRole((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                //HRP-15160
                when 'updateAdditionalRole' {
                    updateAdditionalRole((List<sked__Job_Allocation__c>) JSON.deserialize((String) params.get('param1'), List<sked__Job_Allocation__c>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + JobTriggerHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }
    
    /************************************************************************************************************************************************************/
    
    public static void jobPopulateDriveSupervisoryRole(List<sked__Job__c> newJobsList, Map<Id, sked__Job__c> oldJobsMap) {
        if(newJobsList == null || newJobsList.isEmpty()) {
            return;
        }
        Set<Id> driveIdsToUpdate = new Set<Id>();
        for (sked__Job__c newJob : newJobsList) {
            if(oldJobsMap != null && newJob.Id != null) {
                sked__Job__c oldJob = oldJobsMap.get(newJob.Id);           
        		if (newJob.sked_Resource_Role__c != oldJob.sked_Resource_Role__c ||
            		newJob.sked_Dual_Role__c != oldJob.sked_Dual_Role__c ||
            		newJob.sked__Type__c != oldJob.sked__Type__c) {
            		Id driveId = newJob.sked_Drive__c;
           			 if (driveId != null) {
               		 	driveIdsToUpdate.add(driveId);
             		}
            	}
           }
            else if(oldJobsMap == null && newJob.Id != null){
                	Id driveId = newJob.sked_Drive__c;
           			 if (driveId != null) {
               		 	driveIdsToUpdate.add(driveId);
             		}
            }
        }
        // Running the following process asynchronously - HRP-13522
		if (!System.isBatch()) {
            if(driveIdsToUpdate != NULL && !driveIdsToUpdate.isEmpty()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    JobTriggerHandler.class.getName(),
                    'populateDriveSupervisoryRole',
                    driveIdsToUpdate
                );
            }
        } else {
            populateDriveSupervisoryRole(driveIdsToUpdate);
        }
    }
    
    private static void populateDriveSupervisoryRole(Set<Id> driveIdsToUpdate) {
        DriveTriggerService.populateDriveSupervisoryRole(driveIdsToUpdate);
    }
    // HRP-13522

    //HRP-15160 starts
    public static void populateAdditionalRole(List<sked__Job__c> newRecords, Map<Id, sked__Job__c> oldMap) {
        Set<Id> jobIds = new Set<Id>(); 
        for (sked__Job__c newRecord : newRecords) {
            sked__Job__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Dual_Role__c != oldData.sked_Dual_Role__c) {
                jobIds.add(newRecord.id);
            }
        }
        if (!jobIds.isEmpty()) {
            List<sked__Job_Allocation__c> allocations = [Select Id , sked_Additional_Roles__c , sked_Dual_Role__c from sked__Job_Allocation__c where sked__Job__c in : jobIds ];
            if(!allocations.isEmpty()){
            if (!System.isBatch()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    'JobTriggerHandler',
                    'updateAdditionalRole',
                    new List<sked__Job_Allocation__c>(allocations)
                );
            } else {
                JobTriggerHandler.updateAdditionalRole(new List<sked__Job_Allocation__c>(allocations));
            }
        }
        }
    }

    public static void updateAdditionalRole(List<sked__Job_Allocation__c> allocationList) {
        List<sked__Job_Allocation__c> updatedJA = new List<sked__Job_Allocation__c>();
        for(sked__Job_Allocation__c allocation : allocationList){
                List<string> additionalRoles = new List<string>();
                if(!string.isBlank(allocation.sked_Dual_Role__c)){
                    additionalRoles = allocation.sked_Dual_Role__c.split(';');
                    allocation.sked_Additional_Roles__c = string.join(additionalRoles, ';');
                }
                else{
                    allocation.sked_Additional_Roles__c = '';
                }
                    updatedJA.add(allocation);
            }
        if (!updatedJA.isEmpty()) {
            update updatedJA ;
        }
    }
    //HRP-15160 ends
}