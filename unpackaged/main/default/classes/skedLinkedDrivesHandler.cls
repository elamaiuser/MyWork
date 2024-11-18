public class skedLinkedDrivesHandler implements Callable {
    
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'updateLinkedDriveDetails' {
                    updateLinkedDriveDetails((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));

                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedLinkedDrivesHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    private static void updateLinkedDriveDetails(Set<Id> linkedDriveIds) {
        List<sked_Linked_Drives__c> linkedDrives = [
            SELECT Id, sked_Earliest_Drive_Date__c, sked_Latest_Drive_Date__c,
            (SELECT Id, sked_Drive_Date__c, sked_ARC_Region_ID__c FROM sked_Drives__r)
            FROM sked_Linked_Drives__c
            WHERE Id IN :linkedDriveIds
        ];

        for (sked_Linked_Drives__c linkedDrive : linkedDrives) {
            if (linkedDrive.sked_Drives__r != null && !linkedDrive.sked_Drives__r.isEmpty()) {
                linkedDrive.sked_ARC_Region__c = (Id) linkedDrive.sked_Drives__r[0].sked_ARC_Region_ID__c;
                for (sked_Drive__c drive : linkedDrive.sked_Drives__r) {
                    if (linkedDrive.sked_Earliest_Drive_Date__c == null || linkedDrive.sked_Earliest_Drive_Date__c > drive.sked_Drive_Date__c) {
                        linkedDrive.sked_Earliest_Drive_Date__c = drive.sked_Drive_Date__c;
                    }

                    if (linkedDrive.sked_Latest_Drive_Date__c == null || linkedDrive.sked_Latest_Drive_Date__c < drive.sked_Drive_Date__c) {
                        linkedDrive.sked_Latest_Drive_Date__c = drive.sked_Drive_Date__c;
                    }
                }
            }
        }

        update linkedDrives;
    }
}