/* Modification Log 
 *    Date					     Developer Name			     Comments
 * **********************************************************************************
 *  09/26/2024				      Priti Jana		        Logic for HRP-13522
 * **********************************************************************************
 */

public class JobTriggerHandler extends TriggerHandler implements Callable {
    
    public override void beforeUpdate() {}
    
    public override void afterUpdate() {
       if(super.getTriggerMethodsToBypass().indexOf('jobPopulateDriveSupervisoryRole') == -1) { 
        	jobPopulateDriveSupervisoryRole((List<sked__Job__c>)trigger.new, (Map<Id,sked__Job__c>)trigger.oldMap);
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
}