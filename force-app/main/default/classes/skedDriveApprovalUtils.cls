public class skedDriveApprovalUtils {

    public static List<string> getDMApprovalStatuses() {
        List<String> results = new List<string>();
        results.add('Waiting for DM Approval');
        results.add('DM Waiting for DRD Feedback');
        return results;
    }

    public static List<string> getPendingApprovalStatuses() {
        List<string> results = new List<string>();
        results.add('Submitted');
        results.add('Waiting for APS Approval');
        results.add('Waiting for DM Approval');
        results.add('APS Waiting for DRD Feedback');
        results.add('DM Waiting for DRD Feedback');
        return results;
    }
    
    public static void processDriveApprovals(List<Approval.ProcessSubmitRequest> requests, Map<Id, sked_Drive__c> driveById) {
        List<sked__Debug_Log__c> debugLogs = new List<sked__Debug_Log__c>();
        if (!requests.isEmpty()) {
            List<Approval.ProcessResult> results = Approval.process(requests, false);
            for (Integer i = 0; i < results.size(); i++) {
                Approval.ProcessSubmitRequest request = requests[i];
                Approval.ProcessResult result = results[i];
                if (!result.isSuccess()) {
                    sked_Drive__c drive = driveById.get(request.getObjectId());
                    List<String> errors = skedErrorUtils.getErrorStrings(result.getErrors());
                    debugLogs.add(new sked__Debug_Log__c(
                        sked__Type__c = 'Debug Log',
                        sked__Message__c = 'NOTICE: Failed to Submit Drive for Approval',
                        sked__Summary__c = 'Failed to submit a Drive for Approval with the following details: ' +
                        '\n\n ' +
                        '\nID: ' + drive.Id +
                        '\nName: ' + drive.Name +
                        '\nDrive Date: ' + drive.sked_Drive_Date__c + 
                        '\nType:' + drive.sked_Type_of_Drive__c +
                        '\n\n Record was deleted by: ' + UserInfo.getName() + ' :: ' + UserInfo.getUserEmail() + 
                        '\n Record was deleted at: ' + System.now() +
                        '\nSystem Error: ' + String.join(errors, '\n')
                    ));

                    
                    drive.addError('Failed to submit drive for approval, a Debug Log has been created outlining the details, please contact an Administrator for more information.');
                }
            }
        }

        if (!debugLogs.isEmpty()) {
            insert debugLogs;
        }
    }

}