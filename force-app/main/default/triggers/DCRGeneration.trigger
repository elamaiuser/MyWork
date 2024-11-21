trigger DCRGeneration on DCRGenerationEvent__e (After Insert) {
try{
    List<Id> impactedDrivesId = new List<Id>();
    List<String> idString = new List<String>();
    for (DCRGenerationEvent__e evt : Trigger.New) {  
        idString.addAll(evt.impactedDrivesId__c.replaceAll('[\\(\\)]', '').split(','));
    }
    for (String id : idString) {
        impactedDrivesId.add((Id)id);
    }
    if(!impactedDrivesId.isEmpty()){
        List<sked_Drive__c> impactedDrives = [SELECT Id FROM sked_Drive__c where Id in: impactedDrivesId ];
        if(impactedDrives != null && impactedDrives.size() > 0){
            slwcDriveService.captureNonUserChangeDCRsModel request = new slwcDriveService.captureNonUserChangeDCRsModel();
            request.fieldLabel = 'Travel Time Changed';
            request.fieldApiName = 'sked_Travel_Time_Change__c';
            request.fieldType = 'Boolean';
            request.driveChangeRequestType = skedConstants.DRIVE_CHANGE_REQUEST_TYPE_TRAVEL_TIME_CHANGE;
            request.impactedDrives = impactedDrives;

            slwcDriveService.skedCaptureNonUserChangeDCRs(request);
        }
     } 

}catch(Exception e){
        System.debug('Exception happened in DCRGeneration->');
        BSF_Error_Log__c errorLog = BSF_Utilities.getErrorLog(null,'DCRGeneration','execute','error',e.getStackTraceString(), e.getMessage());
        insert errorLog;
   }
}