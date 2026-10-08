public class skedDriveHandlerService implements Callable {

    /**************************************** CALLABLE INTERFACE  ***************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'cascadeCancelEvents' {
                    cascadeCancelEvents((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class),
                                        (Set<Id>) JSON.deserialize((String) params.get('param2'), Set<Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedDriveHandlerService.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
    /****************************************************************************************************/
    
    public static void cascadeCancelEvents(Set<Id> cancelledDriveIds, Set<Id> cancelledOppIds) {

        //1. Cancel Jobs
        List<sked__Job__c> skedJobsToCancelled = [SELECT Id, sked__Job_Status__c, sked__Job_Allocation_Count__c
                                                    FROM sked__Job__c
                                                    WHERE sked_Drive__c IN :cancelledDriveIds
                                                    AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                                    AND sked__Job_Status__c != :skedConstants.JOB_STATUS_COMPLETE];
        if (!skedJobsToCancelled.isEmpty()) {
            for (sked__Job__c skedJob : skedJobsToCancelled) {
                skedJob.sked__Job_Status__c = skedConstants.JOB_STATUS_CANCELLED;
            }
            update skedJobsToCancelled;
        }
           
        //2. Close Exception Logs
        List<skedHC__Exception__c> exceptionLogToClose = [SELECT Id, skedHC__Status__c
                                                            FROM skedHC__Exception__c
                                                            WHERE sked_Drive__c IN :cancelledDriveIds
                                                            AND skedHC__Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED];
        if (!exceptionLogToClose.isEmpty()) {
            for (skedHC__Exception__c exceptionItem : exceptionLogToClose) {
                exceptionItem.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
            }
            update exceptionLogToClose;
        }
            
        //3. Cancel Pending DCRs
        List<sked_Drive_Change_Request__c> pendingDCRs = [SELECT Id, sked_Status__c
                                                            FROM sked_Drive_Change_Request__c
                                                            WHERE sked_Drive__c IN :cancelledDriveIds
                                                            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
                                                            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
                                                            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
                                                            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED];
        if (!pendingDCRs.isEmpty()) {
            for (sked_Drive_Change_Request__c pendingDCR : pendingDCRs) {
                pendingDCR.sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED;
            }
            update pendingDCRs;
        }

        //4. Cancel Tasks
        if(cancelledOppIds != null && !cancelledOppIds.isEmpty()) {
            TaskService.cancelOpportunityTasks(cancelledOppIds);
        }
           
        //5. Remove Pending Action Work Items
        skedFutureCallEventHandler.publishFutureCallEvent(
            slwcApprovalService.class.getName(),
            'removeWorkItems',
            cancelledDriveIds
        );
    }

    public static void cascadeCompleteEvents(Set<Id> completeDriveIds) {
        List<sked_Drive_Change_Request__c> pendingDCRs = [
            SELECT Id, sked_Status__c
            FROM sked_Drive_Change_Request__c
            WHERE sked_Drive__c IN :completeDriveIds
            AND sked_Status__c NOT IN (
                :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM,
                :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED,
                :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED,
                :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED
            )
        ];

        if (pendingDCRs != null && !pendingDCRs.isEmpty()) {
            for (sked_Drive_Change_Request__c pendingDCR : pendingDCRs) {
                pendingDCR.sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED;
            }
            update pendingDCRs;
        }
    }
}