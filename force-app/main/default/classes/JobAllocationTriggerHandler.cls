/* Modification Log 
 *    Date					     Developer Name			     Comments
 * **********************************************************************************
 *  09/26/2024				      Priti Jana		        Logic for HRP-13522
 * **********************************************************************************
 */

public class JobAllocationTriggerHandler extends TriggerHandler implements Callable {
    
	public override void afterUpdate() {
       if(super.getTriggerMethodsToBypass().indexOf('jobAllocPopulateDriveSupervisoryRole') == -1) {
        	jobAllocPopulateDriveSupervisoryRole((List<sked__Job_Allocation__c>)trigger.new, (Map<Id,sked__Job_Allocation__c>)trigger.oldMap);
        }
    }
    
    public override void beforeInsert() {}
    
    public override void beforeUpdate() {}
    
    public override void afterDelete() {
        if(super.getTriggerMethodsToBypass().indexOf('jobAllocPopulateDriveSupervisoryRole') == -1) { 
            BSF_Constants.After_Delete = True;
        	jobAllocPopulateDriveSupervisoryRole((List<sked__Job_Allocation__c>)trigger.old, null);
            BSF_Constants.After_Delete = False;
        }
    }
    
    public override void afterInsert() {
       if(super.getTriggerMethodsToBypass().indexOf('jobAllocPopulateDriveSupervisoryRole') == -1) { 
        	jobAllocPopulateDriveSupervisoryRole((List<sked__Job_Allocation__c>)trigger.new, null);
        }
    }
    
    /**************************************** CALLABLE INTERFACE  ***************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'captureDriveSupervisoryRole' {
                    captureDriveSupervisoryRole(
                        (List<sked__Job_Allocation__c>) JSON.deserialize((String) params.get('param1'), List<sked__Job_Allocation__c>.class),
                        (Map<Id, sked__Job_Allocation__c>) JSON.deserialize((String) params.get('param2'), Map<Id, sked__Job_Allocation__c>.class)  
                    );
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + JobAllocationTriggerHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }
    /**********************************************************************************************************/
    
    public static void jobAllocPopulateDriveSupervisoryRole(List<sked__Job_Allocation__c> newAllocationsList, Map<Id, sked__Job_Allocation__c> oldAllocationsMap) {
        
        // Running the following process asynchronously - HRP-13522
		if (!System.isBatch()) {
            if(newAllocationsList != NULL && !newAllocationsList.isEmpty()) {
                skedFutureCallEventHandler.publishFutureCallEvent(
                    JobAllocationTriggerHandler.class.getName(),
                    'captureDriveSupervisoryRole',
                    newAllocationsList,
                    oldAllocationsMap
                );
            }
        } else {
            captureDriveSupervisoryRole(newAllocationsList, oldAllocationsMap);
        }
    }
    // HRP-13522
    
    private static void captureDriveSupervisoryRole(List<sked__Job_Allocation__c> newAllocationsList, Map<Id, sked__Job_Allocation__c> oldAllocationsMap) {
        Set<Id> driveIdsToUpdate = new Set<Id>();
		Set<Id> jobIds = new Set<Id>();

    	for (sked__Job_Allocation__c newAllocation : newAllocationsList) {
            if (newAllocation.sked__Job__c != null) {
            	jobIds.add(newAllocation.sked__Job__c);
            }
        }
        Map<Id, sked__Job__c> jobMap = new Map<Id, sked__Job__c>(
            [SELECT Id, sked_Drive__c FROM sked__Job__c WHERE Id IN :jobIds]);
        Set<String> oldRoles = new Set<String>();
        Set<String> newRoles = new Set<String>();
        for (sked__Job_Allocation__c newAllocation : newAllocationsList) {
            if(oldAllocationsMap != null && newAllocation.Id != null) {
        		sked__Job_Allocation__c oldAllocation = oldAllocationsMap.get(newAllocation.Id);
                oldRoles = (oldAllocation.sked_Additional_Roles__c != null) ? new Set<String>(oldAllocation.sked_Additional_Roles__c.split(';')) : oldRoles;               
                newRoles = (newAllocation.sked_Additional_Roles__c != null) ? new Set<String>(newAllocation.sked_Additional_Roles__c.split(';')) : newRoles;
				if (!oldRoles.equals(newRoles) || newAllocation.sked__Status__c != oldAllocation.sked__Status__c) {                
    		    	sked__Job__c job = jobMap.get(newAllocation.sked__Job__c);
                	if (job != null) { 
						driveIdsToUpdate.add(job.sked_Drive__c);
                    }
                }
       		}
         	else if(oldAllocationsMap == null && newAllocation.Id != null) {
                sked__Job__c job = jobMap.get(newAllocation.sked__Job__c);
                if (job != null) {
                    driveIdsToUpdate.add(job.sked_Drive__c);
                }
           }
    	}
        DriveTriggerService.populateDriveSupervisoryRole(driveIdsToUpdate);
    }
}