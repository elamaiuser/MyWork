/* @Description: Below Batch class runs daily and finds any Inactive users witk Sked License and removes sked license assignment from them
 * **********************************************************************************************************************************************
 * Modification Log 
 *  Date					      Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 12/04/2023				      Anil K		Logic for HRP-11574 (Batch class runs daily and finds any Inactive users witk Sked License and removes sked license assignment from them.
 */

global class RemoveSkedLicenseForInactiveUsersBatch implements Database.Batchable<SObject>, Schedulable{
    
    

    //  Start method to pick UserPackageLicense records with sked license and inactive user status
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select userid from UserPackageLicense where packagelicenseid=\'0505c000000kBuqAAE\' and userid in (select id from user where isActive=false)';
        return Database.getQueryLocator(query);
    }

    // The execute method is called for each batch of records
    global void execute(Database.BatchableContext bc, List<UserPackageLicense> scope) {
        System.debug('Record size in this batch scope->'+scope.size());
        List<UserPackageLicense> userPackageLicenseList = new List<UserPackageLicense>();
        for(UserPackageLicense userPkgLicense : scope) {
            userPackageLicenseList.add(userPkgLicense);
        }
         Database.delete(userPackageLicenseList,false);
    }

    global void finish(Database.BatchableContext bc) {
    }

    // Bare bones execute method for the Schedulable interface
    global void execute(SchedulableContext sc) {
        RemoveSkedLicenseForInactiveUsersBatch myBatch = new RemoveSkedLicenseForInactiveUsersBatch();
        Database.executeBatch(myBatch);
    }


}