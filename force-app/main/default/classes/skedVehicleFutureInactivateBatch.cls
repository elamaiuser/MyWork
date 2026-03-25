/* This batch will be scheduled to run everyday
 * It will fetch Vehicle resources whose Future Inactive Date has been reached (<= today)
 * It will unmark the active checkbox - inactive vehicle
 * This batch is written as a part of HRP-16539
---------------------------------------------------------------------------------- */

global class skedVehicleFutureInactivateBatch implements Database.Batchable<sked__Resource__c>, Schedulable {

    global Iterable<sked__Resource__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked__Is_Active__c
            FROM sked__Resource__c
            WHERE sked_Asset_Type__c = 'Vehicle'
            AND sked__Is_Active__c = true
            AND sked_Future_Inactive_Date__c <= TODAY
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked__Resource__c> scope) {
        List<sked__Resource__c> vehiclesToInactivate = new List<sked__Resource__c>();

        if (!scope.isEmpty()) {
            for (sked__Resource__c vehicle : scope) {
                vehicle.sked__Is_Active__c = false;
                vehiclesToInactivate.add(vehicle);
            }
        }

        Database.SaveResult[] srList = Database.update(vehiclesToInactivate, false);

        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Vehicle Future Inactive Date', 'skedVehicleFutureInactivateBatch', 'execute', 'Error', 'Error in deactivating vehicle');
        Database.insert(logList, false);
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new skedVehicleFutureInactivateBatch());
    }
}