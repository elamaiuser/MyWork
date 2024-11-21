global without sharing class slwcOperationRecordService {
    
    //public static final string errorMessage400_499 = 'Op Record submission failed due to problem with Op Record or Staff. Check to make sure Op Record and Staffing is complete and correct, and retry. Contact BSF support or system administrator with the Op Record Name or Drive ID for assistance.';
    //public static final string errorMessage500_599 = 'Op Record submission failed due to problem with Azure server or database. Please contact BSF support or system administrator Op Record Name or Drive ID for assistance, and wait a few minutes before retrying.';
    //public static final string errorMessageNoRecord = 'Op Record submission failed due to no record found on database.';
    //public static final string errorMessageSubmitted = 'Op Record already submitted.'; 

    @AuraEnabled
    public static void generateOperationRecords(generateOperationRecordsRequest request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        Set<Id> driveIds = new Set<Id>{request.driveId};

        skedOperationRecordService.regenerateOperationRecords(driveIds);
    }
    
    @AuraEnabled
    public static slwcAuraResult populateExternalIds(populateExternalIdsRequest request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        
        Set<Id> operationRecordIds = new Set<Id>{request.recordId};

        List<sked_Operation_Record__c> operationRecords = skedOperationRecordService.populateExternalIds(operationRecordIds);
        result.returnedData = operationRecords;
        
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getResourceData(getResourceDataRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();

        sked_Drive_Shift__c driveShift = [
            SELECT Id, sked_Drive__r.sked_ARC_Region_ID__c, sked_Drive__r.sked_Drive_Date__c
            FROM sked_Drive_Shift__c
            WHERE Id = :request.driveShiftId
        ];

        List<sked_Territory_Collection_Operation__c> tcos = [
            SELECT Id, sked_Collection_Operation__c
            FROM sked_Territory_Collection_Operation__c
            WHERE sked_Territory__r.sked_Parent__c = :driveShift.sked_Drive__r.sked_ARC_Region_ID__c
            AND sked_Start_Date__c <= :driveShift.sked_Drive__r.sked_Drive_Date__c
            AND sked_End_Date__c >= :driveShift.sked_Drive__r.sked_Drive_Date__c
        ];

        Set<Id> collectionOperationIds = new Set<Id>();
        if (tcos != null && !tcos.isEmpty()) {
            for (sked_Territory_Collection_Operation__C tco : tcos) {
                collectionOperationIds.add(tco.sked_Collection_Operation__c);
            }
        }

        Date inputDate = skedDateTimeUtils.getDateFromIsoString(request.inputDate);
        List<String> additionalResourceIds = new List<string>();
        List<sked__Resource__c> resources;
        List<sked__Resource__c> filteredResources;
        if (collectionOperationIds != NULL && !collectionOperationIds.isEmpty()) {
            List<sked__Resource_Override_Region__c> resourceOverrideRegions = [
                SELECT Id, sked__Resource_Override__r.sked__Resource__c 
                FROM sked__Resource_Override_Region__c 
                WHERE sked__Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOperationIds
                AND (sked__Resource_Override__r.sked_Start_Date__c <= :inputDate 
                    AND sked__Resource_Override__r.sked_End_Date__c >= :inputDate)
            ];
            if (resourceOverrideRegions != NULL && !resourceOverrideRegions.isEmpty()) {
                for (sked__Resource_Override_Region__c resourceOverrideRegion : resourceOverrideRegions) {
                    additionalResourceIds.add(resourceOverrideRegion.sked__Resource_Override__r.sked__Resource__c);
                }
            }
            
            List<sked_Resource_Biomed_Collection_Op__c> resourceCollectionOperations = [
                SELECT Id, sked_Resource__c
                FROM sked_Resource_Biomed_Collection_Op__c
                WHERE sked_Biomed_Collection_Op_Center__c IN :collectionOperationIds
                AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :inputDate) 
                AND (sked_End_Date__c = NULL OR sked_End_Date__c  >= :inputDate)
            ];
            if (resourceCollectionOperations != NULL && !resourceCollectionOperations.isEmpty()) {
                for (sked_Resource_Biomed_Collection_Op__c resourceCollectionOperation : resourceCollectionOperations) {
                    additionalResourceIds.add(resourceCollectionOperation.sked_Resource__c);
                }
            }

            string queryTextPadded = '%' + request.queryText + '%';
            resources = [
                SELECT Id, Name, sked__User__c, sked__User__r.SmallPhotoUrl, sked__Primary_Region__r.sked__Timezone__c, 
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Biomed_Collection_Op_Center_Name__c
                FROM sked__Resource__c
                WHERE Name LIKE :queryTextPadded
                AND (sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOperationIds 
                    OR Id IN :additionalResourceIds)
                AND sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
                AND sked__Is_Active__c = TRUE
                ORDER BY Name
            ];
            
            
            if (request.roles != NULL && !request.roles.isEmpty()) {
                List<sked__Resource_Tag__c> resourceTags = [
                    SELECT Id, sked__Resource__c
                    FROM sked__Resource_Tag__c
                    WHERE sked__Tag__r.Name IN :request.roles
                    AND sked_Start_Date__c <= :inputDate
                    AND sked__Resource__r.Name LIKE :queryTextPadded
                    AND (sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOperationIds 
                            OR sked__Resource__c IN :additionalResourceIds)
                    AND sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                    AND sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
                    AND sked__Resource__r.sked__Is_Active__c = TRUE
                ];
                Set<Id> resourceIdsThatHaveRoles = new Set<Id>();
                for (sked__Resource_Tag__c resourceTag : resourceTags) {
                    resourceIdsThatHaveRoles.add(resourceTag.sked__Resource__c);
                }
                
                filteredResources = new List<sked__Resource__c>();
                for (sked__Resource__c resource : resources) {
                    if (resourceIdsThatHaveRoles.contains(resource.Id)) {
                        filteredResources.add(resource);
                    }
                }
            }
        }
        
        resourceDataModel data = new resourceDataModel();
        data.resources = filteredResources != NULL ? filteredResources : resources;
        result.returnedData = data;
        
        return result;
    }

    @AuraEnabled
    public static slwcAuraResult submitOperationRecord(submitOpsRecordRequest request) {
        Boolean isSuccess = false;
        String logMessage = Custom_Messages__mdt.getInstance('OpRecordMessage_SomethingWrong').value__c;
        String logSummary = '';

        sked_Operation_Record__c opRecord;

        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;

        try{
            if(request == null || String.isBlank(request.operationRecordId)){
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_NoDataFound').value__c);
            }

            List<sked_Operation_Record__c> opRecordList = skedOperationRecordUtils.getOpsRecords(new Set<Id>{request.operationRecordId});

            if(opRecordList.isEmpty()){
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_NoDataFound').value__c);
            }

            if (opRecordList[0].sked_Drive__c == null) {
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_DriveIdNull').value__c);
            }

            opRecord = opRecordList[0];
            String driveStatus = opRecord.sked_Drive__r.sked_Status__c;

            if(String.isNotBlank(opRecord.sked_Status__c) && opRecord.sked_Status__c.equals(skedConstants.OPERATION_STATUS_SUBMITTED)){
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_AlreadySubmitted').value__c);
            }

            if(opRecord.sked_Operation_Record_Staff__r == null || opRecord.sked_Operation_Record_Staff__r.isEmpty()){
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_staffNull').value__c);
            }

            skedOpsRecordApiData.opsRecordRequest opsRecordRequest = skedOperationRecordUtils.getOpsRecordRequest(opRecord);

            if (opsRecordRequest == null) {
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_RequestNull').value__c);
            }

            skedOpsRecordApiManager apiManager = new skedOpsRecordApiManager();
            skedOpsRecordApiData.resultBase opsRecordResult = apiManager.updateStaffRecord(opsRecordRequest);

            logSummary = 'Submission Details: ' + 
                        '\n\nRequest: ' + JSON.serialize(opsRecordRequest) +
                        '\n\nResponse: ' + JSON.serialize(opsRecordResult);

            if (opsRecordResult == null) {
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_RequestNull').value__c);
            }

            logSummary += '\n\nSuccess: ' + opsRecordResult.success +
                            '\nStatus Code: ' + opsRecordResult.statusCode +
                            '\nStatus: ' + opsRecordResult.status + 
                            '\nMessage: ' + opsRecordResult.message;
            
            if (opsRecordResult.success == false && (opsRecordResult.statusCode == null || opsRecordResult.statusCode >= 500)) {
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_500_599').value__c);
            }
            else if (!opsRecordResult.success) {
                throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_400_499').value__c);
            }

            if (opsRecordResult.success == true) {
                opRecord.sked_Submitted_By__c = skedTriggerHub_Cache.getCurrentUserResource().Id;
                opRecord.sked_Locked__c = true;
                opRecord.sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED;
                Database.SaveResult[] srList = Database.update(new List<sked_Operation_Record__c>{opRecord}, false);
                for (Database.SaveResult sr : srList){
                    if(!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            logSummary += 'Error Details: ' +
                            '\n\nMessage: ' + err.getMessage() +
                            '\nField: ' + err.getFields();
                        }
                        throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_SubmittedButSFRecordFail').value__c);
                    }
                }

                List<sked_Drive__c> drivesList = [SELECT Id, 
                                                        sked_Status__c, 
                                                        (SELECT Id
                                                        FROM sked_Drive_Shifts__r) 
                                                    FROM sked_Drive__c 
                                                    WHERE Id = :opRecord.sked_Drive__c];
                if (!drivesList.isEmpty()) {
                    sked_Drive__c drive = drivesList[0];
                    if ((drive.sked_Status__c != skedConstants.DRIVE_STATUS_COMPLETE)) {
                        driveStatus = drive.sked_Status__c;
                        Boolean isAllOpRecordsSubmitted = true;
                        Map<Id, Boolean> opRecordSumbmittedMap =new Map<Id, Boolean>();
                        if (drive.sked_Drive_Shifts__r != null) {
                            for (sked_Drive_Shift__c drvShift : drive.sked_Drive_Shifts__r) {
                                opRecordSumbmittedMap.put(drvShift.Id,false);
                            }
                            List<sked_Operation_Record__c> opRecordSumbmittedList = [SELECT Id, 
                                                                                            sked_Status__c,
                                                                                            sked_Drive_Shift__c
                                                                                    FROM sked_Operation_Record__c
                                                                                    WHERE sked_Drive_Shift__c IN :opRecordSumbmittedMap.keySet()
                                                                                    AND sked_Status__c = :skedConstants.OPERATION_STATUS_SUBMITTED];
                            for (sked_Operation_Record__c opRecSub : opRecordSumbmittedList) {
                                opRecordSumbmittedMap.put(opRecSub.sked_Drive_Shift__c,true);
                            }
                            for (Id shiftId : opRecordSumbmittedMap.keySet()) {
                                if (!opRecordSumbmittedMap.get(shiftId)) {
                                    isAllOpRecordsSubmitted = false;
                                }
                            }
                        }
                        else {
                            isAllOpRecordsSubmitted = false;
                        }

                        if (!isAllOpRecordsSubmitted) {
                            isSuccess = true;
                            logMessage = Custom_Messages__mdt.getInstance('OpRecordMessage_SubmittedButDOCFailed').value__c;
                        }
                        else {
                            drive.sked_Status__c = skedConstants.DRIVE_STATUS_COMPLETE;
                            Database.SaveResult[] srListDOC = Database.update(new List<sked_Drive__c>{drive}, false);
                            for (Database.SaveResult sr : srListDOC) {
                                if (!sr.isSuccess()) {
                                    String expMessage = '';
                                    for (Database.Error err : sr.getErrors()) {
                                        logSummary += 'Error Details: ' +
                                                    '\n\nMessage: ' + err.getMessage() +
                                                    '\nField: ' + err.getFields();
                                        expMessage +=' Field: ' + err.getFields()+
                                                    ' Message: ' + err.getMessage();
                                    }
                                    throw new OperationRecordServiceException(Custom_Messages__mdt.getInstance('OpRecordMessage_SubmittedButDOCFailedExp').value__c+expMessage);
                                }
                                else {
                                    driveStatus = skedConstants.DRIVE_STATUS_COMPLETE;
                                    isSuccess = true;
                                    logMessage = Custom_Messages__mdt.getInstance('OpRecordMessage_Submitted').value__c;
                                }
                            }
                        }
                    }
                    else {
                        isSuccess = true;
                        logMessage = Custom_Messages__mdt.getInstance('OpRecordMessage_Submitted').value__c;
                    }
                }
            }

            logSummary += '\n\nOperation Record: ' + opRecord.Id +
                            '\nOperation Status: ' + opRecord.sked_Status__c +
                            '\nDrive: ' + opRecord.sked_Drive__c + 
                            '\nDrive Status: ' + driveStatus;

        }catch(OperationRecordServiceException opEx){
            logMessage = opEx.getMessage();
            logSummary += '\n'+ opEx.getMessage();
        }catch(Exception exp){
            logMessage = Custom_Messages__mdt.getInstance('OpRecordMessage_Exception').value__c +' '+ exp.getMessage();
            logSummary += 'Exception Details: ' +
                            '\n\nMessage: ' + exp.getMessage() +
                            '\nStack Trace: ' + exp.getStackTraceString() +
                            '\nCause: ' + exp.getCause();
        }

        String logId = insertDebugLog(logMessage,logSummary);

        if ((opRecord != null && !isSuccess && String.isNotBlank(logId)) || Test.isRunningTest()) {
            sendOpRecordAPIFailureEmail(opRecord,logId);
        }

        slwcAuraResult result = new slwcAuraResult();
        result.message = logMessage;
        result.returnedData = logMessage;
        result.success = isSuccess;
        return result;
    }
    public static String insertDebugLog(String logMessage, String logSummary){
        String logId = '';
        sked__Debug_Log__c submissionLog;
        if (skedSetting.instance.Admin.enableOperationRecordLog) {
            submissionLog = new sked__Debug_Log__c(
                sked__Type__c = 'Operation Record Submission',
                sked__User__c = UserInfo.getUserId(),
                sked__Summary__c = logSummary,
                sked__Message__c = logMessage
            );
            Database.insert(new List<sked__Debug_Log__c>{submissionLog}, false);
        }
        if (submissionLog != null && submissionLog.Id != null) {
            logId = submissionLog.Id;
        }
        return logId;
    }
    public static void sendOpRecordAPIFailureEmail(sked_Operation_Record__c opRecord, String logId){
        try{
            List<string> toList = new List<string>();
            if (!string.isBlank(skedSetting.instance.Email.bitTechnicalSupport)) {
                toList.add(skedSetting.instance.Email.bitTechnicalSupport);
            }
            if (!string.isBlank(skedSetting.instance.Email.bhqApsStaffSchedulingManagers)) {
                toList.add(skedSetting.instance.Email.bhqApsStaffSchedulingManagers);
            }
            if (!string.isBlank(skedSetting.instance.Email.bhqApsStaffSchedulingTimekeeping)) {
                toList.add(skedSetting.instance.Email.bhqApsStaffSchedulingTimekeeping);
            }
            if (!string.isBlank(skedSetting.instance.Email.apsDirectors)) {
                toList.add(skedSetting.instance.Email.apsDirectors);
            }
            if (!string.isBlank(skedSetting.instance.Email.bhqCollectionsPlanningScheduling)) {
                toList.add(skedSetting.instance.Email.bhqCollectionsPlanningScheduling);
            }

            string content = 'Failure information: Op Record API failure - open E-Z Vista ticket routed to [BIT support] <br />'
                                + 'Affected Op Record: '+opRecord.Name+' <br/>'
                                + 'Affected Drive: '+opRecord.sked_Drive__r.sked_UFID__c+' <br/>';
            if (String.isNotBlank(logId)) {
                content += 'Op Record Debug Log ID: '+logId+' <br/>';
            }

            List<skedEmailService.emailModel> emails = new List<skedEmailService.emailModel>();
            skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
            emailItem.subject = 'Alert: Op Record API failure';
            emailItem.htmlBody = content;
            emailItem.whatId = opRecord.Id;
            emailItem.targetObjId = UserInfo.getUserId();
            emailItem.toList = toList;
            emails.add(emailItem);
            
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(emails);
        }catch(Exception ex){/*no action*/}
    }

    /*********************************************************** Nested Classes ***********************************************************/
    public class getResourceDataRequestModel {
        @AuraEnabled public string queryText {get;set;}
        @AuraEnabled public string driveShiftId {get;set;}
        @AuraEnabled public List<string> roles {get;set;}
        @AuraEnabled public string inputDate {get;set;}
    }

    public class generateOperationRecordsRequest {
        @AuraEnabled public string driveId {get;set;}
    }
    
    public class populateExternalIdsRequest {
        @AuraEnabled public string recordId {get;set;}
    }
    
    public class resourceDataModel {
        @AuraEnabled public object resources {get;set;}
    }

    public class submitOpsRecordRequest {
        @AuraEnabled public string operationRecordId {get;set;}
    }

    public class OperationRecordServiceException extends Exception {}
}