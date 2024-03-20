global without sharing class slwcOperationRecordService {
    
    public static final string errorMessage400_499 = 'Op Record submission failed due to problem with Op Record or Staff. Check to make sure Op Record and Staffing is complete and correct, and retry. Contact BSF support or system administrator with the Op Record Name or Drive ID for assistance.';
    public static final string errorMessage500_599 = 'Op Record submission failed due to problem with Azure server or database. Please contact BSF support or system administrator Op Record Name or Drive ID for assistance, and wait a few minutes before retrying.';
        
    @AuraEnabled
    public static void generateOperationRecords(generateOperationRecordsRequest request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        Set<Id> driveIds = new Set<Id>{request.driveId};

        skedOperationRecordService.generateOperationRecords(driveIds, true);
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
                    AND (sked_Expiry_Date__c = NULL OR sked_Expiry_Date__c >= :inputDate)
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
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        result.success = true;

        string loginUserId = UserInfo.getUserId();
        string logSummary = '';
        string logMessage = '';
        integer statusCode;

        sked_Operation_Record__c opRecord = skedOperationRecordUtils.getOpsRecords(new Set<Id>{request.operationRecordId})[0];
        try {
            skedOpsRecordApiData.opsRecordRequest opsRecordRequest = skedOperationRecordUtils.getOpsRecordRequest(opRecord);
            if (opsRecordRequest != null) {
                skedOpsRecordApiManager apiManager = new skedOpsRecordApiManager();
                skedOpsRecordApiData.resultBase opsRecordResult = apiManager.updateStaffRecord(opsRecordRequest);
                statusCode = opsRecordResult.statusCode;
                
                logSummary = 'Submission Details: ' + 
                '\n\nRequest: ' + JSON.serialize(opsRecordRequest) +
                '\n\nResponse: ' + JSON.serialize(opsRecordResult) + 
                '\n\nSuccess: ' + opsRecordResult.success +
                '\nStatus Code: ' + opsRecordResult.statusCode +
                '\nStatus: ' + opsRecordResult.status + 
                '\nMessage: ' + opsRecordResult.message;

                if (!opsRecordResult.success) {
                    logMessage = opsRecordResult.statusCode >= 500 ? errorMessage500_599 : errorMessage400_499;
                    result.success = false;
                    result.returnedData = opsRecordResult.message;
                    result.message = logMessage;
                } 
                else {
                    logMessage = 'Ops Record Submitted Successfully';
                    opRecord.sked_Submitted_By__c = skedTriggerHub_Cache.getCurrentUserResource().Id;
                    opRecord.sked_Locked__c = TRUE;
                    opRecord.sked_Status__c = skedConstants.OPERATION_STATUS_SUBMITTED;
                    update opRecord;
                }
            }
        } 
        catch (Exception ex) {
            logMessage = 'Ops Record Submission Failed With A Caught Exception';
            logSummary = 'Exception Details: ' +
            '\n\nMessage: ' + ex.getMessage() +
            '\nStack Trace: ' + ex.getStackTraceString() +
            '\nCause: ' + ex.getCause();
            result.returnedData = ex.getMessage();
            result.success = false;
        }
        
        logSummary += 
            '\n\nOperation Record: ' + opRecord.Id +
            '\nOperation Status: ' + opRecord.sked_Status__c +
            '\nDrive: ' + opRecord.sked_Drive__c + 
            '\nDrive Status: ' + opRecord.sked_Drive__r.sked_Status__c;

        sked__Debug_Log__c submissionLog;
        if (skedSetting.instance.Admin.enableOperationRecordLog) {
            submissionLog = new sked__Debug_Log__c(
                sked__Type__c = 'Operation Record Submission',
                sked__User__c = loginUserId,
                sked__Summary__c = logSummary,
                sked__Message__c = logMessage
            );
            insert submissionLog;
        }
        
        if (statusCode != NULL && statusCode >= 500) {
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
                + 'Affected Op Record: {{opRecordName}} <br/>'
                + 'Affected Drive: {{driveUFID}} <br/>';
            if (submissionLog != NULL && submissionLog.Id != NULL) {
                content += 'Op Record Debug Log ID: {{debugLogId}} <br/>';
                content = content.replace('{{debugLogId}}', submissionLog.Id);
            }
            
            content = content.replace('{{opRecordName}}', opRecord.Name);
            string driveUFID = opRecord.sked_Drive__r.sked_UFID__c != NULL ? opRecord.sked_Drive__r.sked_UFID__c : 'null';
            content = content.replace('{{driveUFID}}', driveUFID);
            
            List<skedEmailService.emailModel> emails = new List<skedEmailService.emailModel>();
            skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
            emailItem.subject = 'Alert: Op Record API failure';
            emailItem.htmlBody = content;
            emailItem.whatId = opRecord.Id;
            emailItem.targetObjId = loginUserId;
            emailItem.toList = toList;
            emails.add(emailItem);
            
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(emails);
        }

        return result;
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
}