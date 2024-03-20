global class skedScheduleChangeNotificationBatch implements Database.Batchable<sked__Job_Allocation__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected Set<Id> jobIds;
    protected Map<Id, sked__Job__c> mapNewJob;
    protected Map<Id, sked__Job__c> mapOldJob;
    
    global skedScheduleChangeNotificationBatch(Set<Id> inputJobIds, Map<Id, sked__Job__c> newMap, Map<Id, sked__Job__c> oldMap) {
        this.jobIds = inputJobIds;
        this.mapNewJob = newMap;
        this.mapOldJob = oldMap;
    }
    
    global List<sked__Job_Allocation__c> start(Database.BatchableContext BC) {
        return [SELECT Id, Name, sked__Resource__c, sked__Resource__r.Name, sked__Job__r.sked_Drive__c, sked__Job__c, sked__Job__r.sked_Drive__r.Name,
                sked__Job__r.sked_Drive__r.sked_Drive_Date__c, sked__Resource__r.sked__User__c, sked__Resource__r.sked__Email__c,
                sked__Resource__r.sked__Notification_Type__c, sked__Job__r.sked_Drive__r.sked_Timezone__c
                FROM sked__Job_Allocation__c
                WHERE sked__Job__c IN : this.jobIds
                AND sked__Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> records) {
        this.sendScheduleChangePushToStaff(records, this.mapNewJob, this.mapOldJob);
        this.sendScheduleChangeEmailToStaff(records, this.mapNewJob, this.mapOldJob);
        this.sendScheduleChangeSFPushToStaff(records, this.mapNewJob, this.mapOldJob);
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void sendScheduleChangeEmailToStaff(List<sked__Job_Allocation__c> jobAllocations, Map<Id, sked__Job__c> mapNewJob, Map<Id, sked__Job__c> mapOldMap) {
        List<skedEmailService.emailModel> emails = new List<skedEmailService.emailModel>();
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            if (jobAllocation.sked__Resource__r.sked__User__c != NULL) {
                sked__Job__c newRecord = mapNewJob.get(jobAllocation.sked__Job__c);
                sked__Job__c oldData = mapOldMap.get(jobAllocation.sked__Job__c);
                
                string subject = getScheduleChangeSubject(jobAllocation);
                string content = getScheduleChangeContent(jobAllocation, oldData, newRecord);
                content = content.replace('[breakLine]', '<br />');
                
                if (jobAllocation.sked__Resource__r.sked__Email__c != NULL) {
                    List<string> toList = new List<string>();
                    toList.add(jobAllocation.sked__Resource__r.sked__Email__c);
                    
                    skedEmailService.emailModel emailItem = new skedEmailService.emailModel();
                    emailItem.subject = subject;
                    emailItem.htmlBody = content;
                    emailItem.whatId = jobAllocation.Id;
                    emailItem.targetObjId = string.valueOf(jobAllocation.sked__Resource__r.sked__User__c);
                    emailItem.toList = toList;
                    emails.add(emailItem);
                }
            }
        }
        if (!emails.isEmpty()) {
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(emails);
        }
    }
    
    private void sendScheduleChangeSFPushToStaff(List<sked__Job_Allocation__c> jobAllocations, Map<Id, sked__Job__c> mapNewJob, Map<Id, sked__Job__c> mapOldMap) {
        CustomNotificationType customType = [SELECT Id 
                                            FROM CustomNotificationType 
                                            WHERE DeveloperName = 'sked_Custom_Notification'];

        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            if (jobAllocation.sked__Resource__r.sked__User__c != NULL) {
                sked__Job__c newRecord = mapNewJob.get(jobAllocation.sked__Job__c);
                sked__Job__c oldData = mapOldMap.get(jobAllocation.sked__Job__c);
                
                string subject = getScheduleChangeSubject(jobAllocation);
                string content = getScheduleChangeContent(jobAllocation, oldData, newRecord);
                content = content.replace('[breakLine]', '\n');

                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setBody(content);
                notification.setTitle(subject);
                notification.setSenderId(UserInfo.getUserId());
                notification.setNotificationTypeId(customType.id);
                notification.setTargetId(jobAllocation.Id);
                notification.send(new Set<String> { jobAllocation.sked__Resource__r.sked__User__c });
            }
        }
    }
    
    private void sendScheduleChangePushToStaff(List<sked__Job_Allocation__c> jobAllocations, Map<Id, sked__Job__c> mapNewJob, Map<Id, sked__Job__c> mapOldMap) {
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        string smsCountryCodeAbbreviation = skedSetting.instance.Admin.smsCountryCodeAbbreviation;

        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            string destination = jobAllocation.sked__Resource__c;
            sked__Job__c newRecord = mapNewJob.get(jobAllocation.sked__Job__c);
            sked__Job__c oldData = mapOldMap.get(jobAllocation.sked__Job__c);
            
            string protocol = jobAllocation.sked__Resource__r.sked__Notification_Type__c;
            protocol = string.isblank(protocol) ? 'push' : protocol;
            string content = getScheduleChangeContent(jobAllocation, oldData, newRecord);
            content = content.replace('[breakLine]', '\n');
            
            skedSkeduloApiData.oneoffResult oneoffResult = apiManager.notifyOneOff(destination, protocol, content);
        }
    }
    
    private string getScheduleChangeSubject(sked__Job_Allocation__c jobAllocation) {
        string subject = '[DriveName] for [DriveDate] has changed. Please review your schedule';
        subject = subject.replace('[DriveName]', jobAllocation.sked__Job__r.sked_Drive__r.Name);
        subject = subject.replace('[DriveDate]', JSON.serialize(jobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c).remove('"'));
        return subject;
    }
    
    private string getScheduleChangeContent(sked__Job_Allocation__c jobAllocation, sked__Job__c oldData, sked__Job__c newRecord) {
        string content = '[DriveName] for [DriveDate] has changed from: [breakLine] [old] to: [breakLine] [new] [breakLine] Please review your schedule.';
        content = content.replace('[ImpactedResourceName]', jobAllocation.sked__Resource__r.Name);
        content = content.replace('[DriveName]', jobAllocation.sked__Job__r.sked_Drive__r.Name);
        content = content.replace('[DriveDate]', JSON.serialize(jobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c).remove('"'));
        
        string oldInfo = '';
        string newInfo = '';
        String driveTimezone = jobAllocation.sked__Job__r.sked_Drive__r.sked_Timezone__c;
        if (newRecord.sked__Start__c != oldData.sked__Start__c) {
            oldInfo = 'Start Time: ' + oldData.sked__Start__c.format('MM/dd/yyyy hh:mm a z', driveTimezone) + '[breakLine]';
            newInfo = 'Start Time: ' + newRecord.sked__Start__c.format('MM/dd/yyyy hh:mm a z', driveTimezone) + '[breakLine]';
        }
        if (newRecord.sked__Finish__c != oldData.sked__Finish__c) {
            oldInfo += 'End Time: ' + oldData.sked__Finish__c.format('MM/dd/yyyy hh:mm a z', driveTimezone) + '[breakLine]';
            newInfo += 'End Time: ' + newRecord.sked__Finish__c.format('MM/dd/yyyy hh:mm a z', driveTimezone) + '[breakLine]';
        }
        if (newRecord.sked__Address__c != oldData.sked__Address__c) {
            oldInfo += 'Address: ' + oldData.sked__Address__c + '[breakLine]';
            newInfo += 'Address: ' + newRecord.sked__Address__c + '[breakLine]';
        }
        content = content.replace('[old]', oldInfo);
        content = content.replace('[new]', newInfo);
        return content;
    }
    
}