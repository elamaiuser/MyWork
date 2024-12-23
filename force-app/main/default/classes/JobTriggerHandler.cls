/* Modification Log 
 *    Date					     Developer Name			     Comments
 * **********************************************************************************
 *  09/26/2024				      Priti Jana		        Logic for HRP-13522
 *  12/09/2024                    Krapy Tuli                Logic for HRP-13901
 * **********************************************************************************
 */
 /* test class : GenerateMobileDriveTest */

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
        if(super.getTriggerMethodsToBypass().indexOf('updateDriveShiftResourceAllocatedWhenJobDeleted') == -1) {
             BSF_Constants.After_Delete = True;
        	 updateDriveShiftResourceAllocatedWhenJobDeleted((List<sked__Job__c>)trigger.old);
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

    public void updateDriveShiftResourceAllocatedWhenJobDeleted(List<sked__Job__c> oldRecords){//HRP-13901 start
        Set<Id> driveShiftIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        for (sked__Job__c record : oldRecords) {
            driveShiftIds.add(record.sked_Drive_Shift__c);
            jobIds.add(record.Id);
        }
        if (!driveShiftIds.isEmpty()) {
            List<sked_Drive_Shift__c> driveShifts = [SELECT Id, sked_Drive__c, sked_Drive__r.sked_Account__c, sked_Vehicles_Allocated__c,
                                                     sked_Equipment_Allocated__c, sked_Staff_Allocated__c, sked_Assigned_Staff_Count__c, sked_Staff_Setup__c,
                                                     (SELECT Id, sked__Job_Allocation_Count__c, sked_Asset_Type__c, sked_Resource_Role__c, sked__Quantity__c
                                                      FROM sked_Jobs__r
                                                      WHERE (sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED AND Id != :jobIds))
                                                     FROM sked_Drive_Shift__c
                                                     WHERE Id IN :driveShiftIds];
            Set<String> staffAllocatedExcludedRoles = new Set<String>();
            Set<String> assignedStaffCountExcludedRoles = new Set<String>();
            for (sked_Staff_Setup_Excluded_Role__c staffSetupExcludedRole : [
                SELECT sked_Resource_Role__c, sked_Excluded_For_Staff_Allocated__c, sked_Excluded_for_Assigned_Staff_Count__c
                FROM sked_Staff_Setup_Excluded_Role__c
            ]) {
                if (staffSetupExcludedRole.sked_Excluded_For_Staff_Allocated__c == true) {
                    staffAllocatedExcludedRoles.add(staffSetupExcludedRole.sked_Resource_Role__c);
                }
                if (staffSetupExcludedRole.sked_Excluded_for_Assigned_Staff_Count__c == true) {
                    assignedStaffCountExcludedRoles.add(staffSetupExcludedRole.sked_Resource_Role__c);
                }
            }
            for (sked_Drive_Shift__c driveShift : driveShifts) {
                driveShift.sked_Assigned_Staff_Count__c = 0;
                driveShift.sked_Staff_Allocated__c = 0;
                driveShift.sked_Equipment_Allocated__c = 0;
                driveShift.sked_Vehicles_Allocated__c = 0;
                //driveShift.sked_Staff_Setup__c = 0;

                if (driveShift.sked_Jobs__r != NULL) {
                    for (sked__Job__c skedJob : driveShift.sked_Jobs__r) {
                        System.debug('skedJob :: '+skedJob);
                        if (skedJob.sked_Resource_Role__c != NULL) {
                            if (!staffAllocatedExcludedRoles.contains(skedJob.sked_Resource_Role__c)) {
                                driveShift.sked_Staff_Allocated__c += skedJob.sked__Job_Allocation_Count__c;
                                System.debug('skedJob.sked__Quantity__c :: '+skedJob.sked__Quantity__c);
                                System.debug('skedJob.sked_Resource_Role__c :: '+skedJob.sked_Resource_Role__c);
                                //driveShift.sked_Staff_Setup__c += skedJob.sked__Quantity__c;
                            }
                            if (!assignedStaffCountExcludedRoles.contains(skedJob.sked_Resource_Role__c)) {
                                driveShift.sked_Assigned_Staff_Count__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                        }
                        else if (skedJob.sked_Asset_Type__c != NULL) {
                            if (skedJob.sked_Asset_Type__c == skedConstants.ASSET_TYPE_VEHICLE) {
                                driveShift.sked_Vehicles_Allocated__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                            else if (skedJob.sked_Asset_Type__c == skedConstants.ASSET_TYPE_EQUIPMENT) {
                                driveShift.sked_Equipment_Allocated__c += skedJob.sked__Job_Allocation_Count__c;
                            }
                        }
                    }
                }
            }
            update driveShifts;
        }
    }//HRP-13901 end
}