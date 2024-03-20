global virtual class skedNotificationBatchBase {

    protected Set<Id> recordIds;
    protected notificationSettingModel notificationSetting;
    protected Set<string> templateFields;
    protected Set<string> subjectFields;
    protected Map<string, string> mapSite_Url;
    protected contentRendererBase contentRenderer;
    protected customTargetDestinationBase customTargetDestination;

    protected List<SObject> newRecords;
    protected Map<Id, SObject> oldMap;
    
    /************************************************* Private methods *******************************************************/
    protected virtual skedNotificationBatchBase.notificationSettingModel getNotificationSetting(Id notificationSettingId) {
        sked_Notification_Setting__mdt skedNotificationSetting = sked_Notification_Setting__mdt.getInstance(notificationSettingId);
        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel(skedNotificationSetting);
        return setting;
    }
    
    protected virtual void baseInitialize() {
        if (this.notificationSetting != NULL) {
            Set<string> siteNames = skedUtils.getSiteNamesFromTemplate(this.notificationSetting.template);
            if (!siteNames.isEmpty()) {
                Map<Id, Site> mapSite = new Map<Id, Site>([SELECT Id,  Name FROM Site WHERE Name IN :siteNames]);
                List<SiteDetail> siteDetails = [SELECT SecureURL, DurableId FROM SiteDetail WHERE DurableId IN :mapSite.keySet()];
                this.mapSite_Url = new Map<string, string>();
                for (SiteDetail siteDetail : siteDetails) {
                    Site site = mapSite.get(siteDetail.DurableId);
                    this.mapSite_Url.put(site.Name, siteDetail.SecureURL);
                }
            }
            
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                string className = 'skedNotificationBatchBase.' + this.notificationSetting.customTargetDestination;
                Type customTargetDestinationType = Type.forName(classname);
                this.customTargetDestination = (customTargetDestinationBase)customTargetDestinationType.newInstance();
            }
            
            this.templateFields = new Set<string>();
            if (string.isNotBlank(this.notificationSetting.contentRenderer)) {
                string className = 'skedNotificationBatchBase.' + this.notificationSetting.contentRenderer;
                Type contentRendererType = Type.forName(className);
                this.contentRenderer = (contentRendererBase)contentRendererType.newInstance();
            }
            else {
                this.templateFields = skedUtils.getFieldNameFromTemplate(this.notificationSetting.template);
            }
            
            if (this.notificationSetting.notificationFormats != NULL && !this.notificationSetting.notificationFormats.isEmpty()) {
                for (notificationFormatModel notificationFormat : this.notificationSetting.notificationFormats) {
                    this.templateFields.add(notificationFormat.dateTimeField);
                    if (!string.isBlank(notificationFormat.timezoneField)) {
                        this.templateFields.add(notificationFormat.timezoneField);
                    }
                }
            }
            
            if (String.isNotBlank(this.notificationSetting.subject)) {
                if (this.notificationSetting.subject.contains('{{')) {
                    this.subjectFields = skedUtils.getFieldNameFromTemplate(this.notificationSetting.subject);
                }
            }
        }
    }
    
    protected virtual List<sObject> retrieveTargetRecords() {
        List<string> fields = new List<string>();

        skedUtils.concactSetString(fields, this.templateFields);
        skedUtils.concactSetString(fields, this.subjectFields);
        skedUtils.concactString(fields, this.notificationSetting.destinationField);

        if (this.notificationSetting.notificationType == 'email') {
            skedUtils.concactString(fields, this.notificationSetting.notificationTargetField);
            skedUtils.concactString(fields, this.notificationSetting.emailFromAddressField);
        }
        else if (this.notificationSetting.notificationType == 'oneoff') {
            skedUtils.concactString(fields, this.notificationSetting.oneoffProtocolField);
        }
        skedUtils.concactString(fields, 'Id');
        
        Set<Id> idsParam = this.recordIds;
        string queryStatement = 'SELECT ' + string.join(fields, ', ') +
                                ' FROM ' + this.notificationSetting.targetSObject +
                                ' WHERE Id IN :idsParam';
        if (!string.isBlank(this.notificationSetting.customFilter)) {
            queryStatement += ' AND (' + notificationSetting.customFilter + ')';
        }
        return Database.query(queryStatement);
    }
    
    protected virtual void sendNotification(string notificationType, List<sObject> records) {
        if (notificationType == 'email') {
            this.sendEmailNotifications(records);
        }
        else if (notificationType == 'customsms') {
            this.sendCustomSms(records);
        }
        else if (notificationType == 'oneoff') {
            this.sendOneOffNotifications(records);
        }
        else if (notificationType == 'salesforcepush') {
            this.sendSalesforcePushNotifications(records);
        }
    }
    
    protected virtual void sendEmailNotifications(List<sObject> records) {
        List<skedEmailService.emailModel> models = new List<skedEmailService.emailModel>();
        for (sObject record : records) {
            Object destination = skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
            if (destination == NULL) {
                if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                    destination = this.customTargetDestination.mapDestination.get(record.Id);
                }
                
                if (destination == null) {
                    continue;//TODO: Error Handler
                }
            }
            Object targetObjectId = skedUtils.getSourceFieldValue(record, this.notificationSetting.notificationTargetField);
            if (targetObjectId == NULL) {
                if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                    targetObjectId = this.customTargetDestination.mapTarget.get(record.Id);
                }
                //continue;//TODO: Error Handler
            }
            string content = getContent(record);
            string subject = getSubject(record); 
            content = applyFormat(record, content);
            
            List<string> toList = new List<string>();
            toList.add(string.valueOf(destination));
            
            skedEmailService.emailModel model = new skedEmailService.emailModel();
            model.subject = subject;
            model.htmlBody = content;
            model.whatId = record.Id;
            model.targetObjId = string.valueOf(targetObjectId);
            model.toList = toList;
            model.fromAddress = (string)skedUtils.getSourceFieldValue(record, this.notificationSetting.emailFromAddressField);
            if (!string.isBlank(skedSetting.instance.Admin.schedulersGroupEmail)) {
                model.fromAddress = skedSetting.instance.Admin.schedulersGroupEmail;
            }
            if (!string.isBlank(this.notificationSetting.sendingFromEmailAddress)) {
                model.fromAddress = this.notificationSetting.sendingFromEmailAddress;
            }
            models.add(model);
        }
        if (!models.isEmpty()) {
            this.convertQueueIdToUserEmails(models);
            
            skedEmailService emailService = new skedEmailService();
            emailService.sendEmails(models);
        }
    }
    
    @TestVisible
    protected virtual void convertQueueIdToUserEmails(List<skedEmailService.emailModel> models) {
        Set<Id> queueIds = new Set<Id>();
        for (skedEmailService.emailModel model : models) {
            Id recordId = (Id) model.targetObjId;
            if (recordId != null) {
                SObjectType sObjectType = recordId.getSObjectType();
                string sObjectTypeName = sObjectType.getDescribe().getName();
                if (sObjectTypeName == Group.getSobjectType().getDescribe().getName()) {
                    queueIds.add(recordId);
                }
            }
        }
        
        if (!queueIds.isEmpty()) {
            List<GroupMember> queueMembers = [SELECT Id, UserOrGroupId, GroupId
                                              FROM GroupMember
                                              WHERE GroupId IN :queueIds];
            Map<Id, Id> map_memberId_queueId = new Map<Id, Id>();
            for (GroupMember queueMember : queueMembers) {
                map_memberId_queueId.put(queueMember.UserOrGroupId, queueMember.GroupId);
            }
            List<User> users = [SELECT Id, Email
                                FROM User
                                WHERE Id IN :map_memberId_queueId.keySet()];
            Map<Id, List<string>> map_queueId_emails = new Map<Id, List<string>>();
            for (User u : users) {
                Id queueId = map_memberId_queueId.get(u.Id);
                List<string> emails;
                if (map_queueId_emails.containsKey(queueId)) {
                    emails = map_queueId_emails.get(queueId);
                }
                else {
                    emails = new List<string>();
                    map_queueId_emails.put(queueId, emails);
                }
                if (u.Email != NULL) {
                    emails.add(u.Email);
                }
            }
            for (skedEmailService.emailModel model : models) {
                Id recordId = (Id)model.targetObjId;
                SObjectType sObjectType = recordId.getSObjectType();
                string sObjectTypeName = sObjectType.getDescribe().getName();
                if (sObjectTypeName == Group.getSobjectType().getDescribe().getName()) {
                    List<string> emails = map_queueId_emails.get(recordId);
                    model.toList = emails;
                    model.targetObjId = NULL;
                }
            }
        }
    }
    
    protected virtual void sendCustomSms(List<sObject> records) {
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        string smsCountryCodeAbbreviation = skedSetting.instance.Admin.smsCountryCodeAbbreviation;

        List<sObject> recordsToUpdate = new List<sObject>();
        for (sObject record : records) {
            string destination = (string)skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
            if (destination == NULL) {
                continue;//TODO: Error Handler
            }
            string content = getContent(record);
            content = applyFormat(record, content);
            
            skedSkeduloApiData.smsResult smsResult = apiManager.notifySms(smsCountryCodeAbbreviation, destination, content);
            if (!smsResult.success) {
                //record.put('sked_API_Error_Message__c', smsResult.error.message);
                //recordsToUpdate.add(record);
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    
    protected virtual void sendOneOffNotifications(List<sObject> records) {
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        string smsCountryCodeAbbreviation = skedSetting.instance.Admin.smsCountryCodeAbbreviation;

        List<sObject> recordsToUpdate = new List<sObject>();
        for (sObject record : records) {
            string destination = (string)skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
            if (destination == NULL) {
                continue;//TODO: Error Handler
            }
            string protocol = (string)skedUtils.getSourceFieldValue(record, this.notificationSetting.oneoffProtocolField);
            protocol = string.isblank(protocol) ? 'push' : protocol;
            string content = getContent(record);
            content = applyFormat(record, content);

            skedSkeduloApiData.oneoffResult oneoffResult = apiManager.notifyOneOff(destination, protocol, content);
            if (!oneoffResult.success) {
                //record.put('sked_API_Error_Message__c', oneoffResult.error.message);
                //recordsToUpdate.add(record);
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    
    protected virtual void sendSalesforcePushNotifications(List<sObject> records) {
        for (sObject record : records) {
            Object destination = skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
            if (destination == NULL) {
                if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                    destination = this.customTargetDestination.mapDestination.get(record.Id);
                }
                else {
                    continue;//TODO: Error Handler
                }
                
            }

            Id targetObjectId;
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                targetObjectId = Id.valueOf(this.customTargetDestination.mapTarget.get(record.Id));
            }
            else {
                targetObjectId = Id.valueOf(string.valueOf(skedUtils.getSourceFieldValue(record, this.notificationSetting.notificationTargetField)));
            }

            string content = getContent(record);
            string subject = getSubject(record); 
            content = applyFormat(record, content);
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setBody(content);
            notification.setTitle(subject);
            notification.setSenderId(UserInfo.getUserId());
            CustomNotificationType customType = [SELECT Id 
                                                 FROM CustomNotificationType 
                                                 WHERE DeveloperName = 'sked_Custom_Notification'];
            notification.setNotificationTypeId(customType.id);
            notification.setTargetId(targetObjectId);
            notification.send(new Set<String> { string.valueOf(destination) });
        }
    }
    
    protected virtual string getContent(sObject record) {
        string content;
        if (string.isNotBlank(this.notificationSetting.contentRenderer)) {
            content = this.contentRenderer.mapContent.get(record.Id);
        }
        else {
            content = this.notificationSetting.template;
            for (string templateField : this.templateFields) {
                object value = skedUtils.getSourceFieldValue(record, templateField);
                string templateFieldValue = value == null ? '' : string.valueOf(value);
                templateField = '{{' + templateField + '}}';
                content = content.replace(templateField, templateFieldValue);
            }
        }

        if (this.mapSite_Url != NULL && !this.mapSite_Url.isEmpty()) {
            for (string siteName : this.mapSite_Url.keySet()) {
                string siteUrl = this.mapSite_Url.get(siteName);
                string templateSiteName = '!$' + siteName + '$';
                content = content.replace(templateSiteName, siteUrl);
            }
        }

        return content;
    }
    
    protected virtual string getSubject(sObject record) {
        string subject = this.notificationSetting.subject;
        if (this.subjectFields != NULL && !this.subjectFields.isEmpty()) {
            for (string subjectField : this.subjectFields) {
                object value = skedUtils.getSourceFieldValue(record, subjectField);
                string subjectFieldValue = value == null ? '' : string.valueOf(value);
                subjectField = '{{' + subjectField + '}}';
                subject = subject.replace(subjectField, subjectFieldValue);
            }
        }
        return subject;
    }

    protected virtual string applyFormat(sObject record, string content) {
        if (this.notificationSetting.notificationFormats != NULL && !this.notificationSetting.notificationFormats.isEmpty()) {
            for (notificationFormatModel notificationFormat : this.notificationSetting.notificationFormats) {
                string timezoneSidId = UserInfo.getTimeZone().getID();
                if (!string.isBlank(notificationFormat.timezoneField)) {
                    string timezoneValue = (string)skedUtils.getSourceFieldValue(record, notificationFormat.timezoneField);
                    if (!string.isBlank(timezoneValue)) {
                        timezoneSidId = timezoneValue;
                    }
                }
                DateTime dateTimeValue = (DateTime)skedUtils.getSourceFieldValue(record, notificationFormat.dateTimeField);
                string formatedValue = '';
                if (dateTimeValue != NULL) {
                    formatedValue = dateTimeValue.format(notificationFormat.formatString, timezoneSidId);
                }
                content = content.replace('[[' + notificationFormat.formatForToken + ']]', formatedValue);
            }
        }
        return content;
    }
    
    /************************************************* Nested classes *******************************************************/
    global class notificationSettingModel {
        public string contentRenderer;
        public string customFilter;
        public string customTargetDestination;
        public string destinationField;
        public string emailFromAddressField;
        public string notificationTargetField;
        public string oneoffProtocolField;
        public string notificationType;
        public Set<Id> recordIds;
        public string subject;
        public string sendingFromEmailAddress;
        public string targetSObject;
        public string template;
        public List<notificationFormatModel> notificationFormats;
        
        public notificationSettingModel() {}
        
        public notificationSettingModel(sked_Notification_Setting__mdt skedNotificationSetting, Set<Id> recordIds) {
            this.initilizeSetting(skedNotificationSetting);
            this.recordIds = recordIds;
        }
        
        public notificationSettingModel(sked_Notification_Setting__mdt skedNotificationSetting) {
            this.initilizeSetting(skedNotificationSetting);
        }
        
        private void initilizeSetting(sked_Notification_Setting__mdt skedNotificationSetting) {
            this.contentRenderer = skedNotificationSetting.sked_Content_Renderer__c;
            this.customFilter = skedNotificationSetting.sked_Filter__c;
            this.customTargetDestination = skedNotificationSetting.sked_Custom_Target_Destination__c;
            this.destinationField = skedNotificationSetting.sked_Destination_Field__c;
            this.notificationTargetField = skedNotificationSetting.sked_Notification_Target_Field__c;
            this.emailFromAddressField = skedNotificationSetting.sked_Email_From_Address_Field__c;
            this.sendingFromEmailAddress = skedNotificationSetting.sked_Sending_From_Email_Address__c;
            this.notificationType = skedNotificationSetting.sked_Notification_Type__c;
            this.oneoffProtocolField = skedNotificationSetting.sked_Oneoff_Protocol_Field__c;
            this.targetSObject = skedNotificationSetting.sked_Target_SObject__c;
            this.template = skedNotificationSetting.sked_Template__c;
            this.subject = skedNotificationSetting.sked_Subject__c;
            if (skedNotificationSetting.sked_Notification_Formats__r != NULL && !skedNotificationSetting.sked_Notification_Formats__r.isEmpty()) {
                this.notificationFormats = new List<notificationFormatModel>();
                for (sked_Notification_Format__mdt notificationFormat : skedNotificationSetting.sked_Notification_Formats__r) {
                    notificationFormatModel format = new notificationFormatModel();
                    format.dateTimeField = notificationFormat.sked_Date_Time_Field__c;
                    format.formatForToken = notificationFormat.sked_Format_For_Token__c;
                    format.formatString = notificationFormat.sked_Format_String__c;
                    format.timezoneField = notificationFormat.sked_Timezone_Field__c;
                    this.notificationFormats.add(format);
                }
            }
        }
    }
    
    global class notificationFormatModel {
        public string timezoneField;
        public string dateTimeField;
        public string formatForToken;
        public string formatString;
    }
    
    /************************************************* Custom Target *********************************************************/
    global abstract class customTargetDestinationBase {
        public Map<Id, string> mapTarget;
        public Map<Id, string> mapDestination;

        public virtual void process (Set<Id> recordIds, List<SObject> newRecords) {}
    }

    global class driveLeadTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, string>();
            mapDestination = new Map<Id, string>();

            List<sked__Job_Allocation__c> skedJobAllocations = [SELECT Id, sked__Job__r.sked_Drive__c
                                                                FROM sked__Job_Allocation__c
                                                                WHERE Id IN :recordIds];
            Set<Id> driveIds = new Set<Id>();
            for (sked__Job_Allocation__c skedJonAllocation : skedJobAllocations) {
                driveIds.add(skedJonAllocation.sked__Job__r.sked_Drive__c);
            }

            sked_Resource_Role_Group__c resourceRoleGroup = [SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                                                            FROM sked_Resource_Role_Group__c
                                                            WHERE sked_Resource_Role_Group__c = 'Supervisory roles'
                                                            LIMIT 1];
            List<string> roles = resourceRoleGroup.sked_Resource_Roles__c.split(';');

            List<sked__Job_ALlocation__c> skedDriveLeadAllocations = [SELECT Id, sked__Resource__r.sked__Email__c, 
                                                                        sked__Resource__r.sked__User__c, sked__Job__r.sked_Drive__c
                                                                        FROM sked__Job_ALlocation__c
                                                                        WHERE sked__Job__r.sked_Drive__c IN :driveIds 
                                                                            AND sked__Job__r.sked_Resource_Role__c IN :roles
                                                                            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
                                                                            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED];
            //
            Map<Id, sked__Job_ALlocation__c> mapDrive_LeadAllocation = new Map<Id, sked__Job_ALlocation__c>();
            for (sked__Job_ALlocation__c skedDriveLeadAllocation : skedDriveLeadAllocations) {
                mapDrive_LeadAllocation.put(skedDriveLeadAllocation.sked__Job__r.sked_Drive__c, skedDriveLeadAllocation);
            }

            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                sked__Job_ALlocation__c driveLeadAllocation = mapDrive_LeadAllocation.get(skedJobAllocation.sked__Job__r.sked_Drive__c);
                if (driveLeadAllocation != NULL) {
                    mapTarget.put(skedJobAllocation.Id, driveLeadAllocation.sked__Resource__r.sked__User__c);
                    mapDestination.put(skedJobAllocation.Id, driveLeadAllocation.sked__Resource__r.sked__User__c);
                }
            }
        }
    }
    
    global class driveDcrQueueTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, string>();
            mapDestination = new Map<Id, string>();
            
            List<sked_Drive__c> skedDrives = [SELECT Id, sked_Collection_Operation__r.Name
                                              FROM sked_Drive__c
                                              WHERE Id IN :recordIds];
            Set<string> queueNames = new Set<string>();
            for (sked_Drive__c skedDrive : skedDrives) {
                queueNames.add(skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS);
            }
            
            List<Group> approvalQueues = [SELECT Id, Name
                                          FROM Group
                                          WHERE Name IN :queueNames
                                          AND Type = :skedConstants.GROUP_TYPE_QUEUE];
            Map<string, Group> mapQueueByName = new Map<string, Group>();
            for (Group approvalQueue : approvalQueues) {
                mapQueueByName.put(approvalQueue.Name, approvalQueue);
            }
            
            for (sked_Drive__c skedDrive : skedDrives) {
                string queueName = skedDrive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS;
                if (mapQueueByName.containsKey(queueName)) {
                    Group approvalQueue = mapQueueByName.get(queueName);
                    mapTarget.put(skedDrive.Id, approvalQueue.Id);
                    mapDestination.put(skedDrive.Id, approvalQueue.Id);
                }
            }
        }
    }
    
    /************************************************* Content Renderer *******************************************************/
    global abstract class contentRendererBase {
        public Map<Id, string> mapContent;
        
        public virtual void process(Set<Id> recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) { }
    }

    global class logisticChangeRender extends contentRendererBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) {
            Map<Id, SObject> mapNewRecords = new Map<Id, SObject>(newRecords);
            
            Map<String, Schema.SObjectField> mapSObjectDriveField = Schema.SObjectType.sked_Drive__c.fields.getMap();
            
            Map<string, string> mapLogisticsField = new Map<string, string>();
            mapLogisticsField.put('sked_Drive_Date__c', 'Drive Date');
            mapLogisticsField.put('sked_Start_Time__c', 'Start Time');
            mapLogisticsField.put('sked_End_Time__c', 'End Time');
            mapLogisticsField.put('sked_Drive_Site__c', 'Drive Site');
            mapLogisticsField.put('sked_Projected_Registered_Donors__c', 'Projected Registered Donors');
            mapLogisticsField.put('sked_WB_Projected_Procedures__c', 'WB Projected Procedures');
            mapLogisticsField.put('sked_2RBC_Projected_Procedures__c', '2RBC Projected Procedures');
            mapLogisticsField.put('sked_Platelet_Projected_Procedures__c', 'Platelet Projected Procedures');
            mapLogisticsField.put('sked_Plasma_Projected_Procedures__c', 'Plasma Projected Procedures');
            
            Set<Id> siteIds = new Set<Id>();
            for (Id recordId : recordIds) {
                sked_Drive__c drive = (sked_Drive__c)mapNewRecords.get(recordId);
                sked_Drive__c oldData = (sked_Drive__c)oldMap.get(recordId);
                siteIds.add(drive.sked_Drive_Site__c);
                siteIds.add(oldData.sked_Drive_Site__c);
            }
            Map<Id, sked__Location__c> mapSite = new Map<Id, sked__Location__c>([SELECT Id, Name
                                                                                 FROM sked__Location__c
                                                                                 WHERE Id IN :siteIds]);
            
            mapContent = new Map<Id, string>();
            for (Id recordId : recordIds) {
                sked_Drive__c drive = (sked_Drive__c)mapNewRecords.get(recordId);
                sked_Drive__c oldData = (sked_Drive__c)oldMap.get(recordId);
                
                string content = '[DriveName] for [DriveDate] have changed: \n';
                content = content.replace('[DriveName]', drive.Name);
                content = content.replace('[DriveDate]', JSON.serialize(drive.sked_Drive_Date_Text__c));
                
                for (string logisticsField : mapLogisticsField.keySet()) {
                    string newValue = string.valueOf(drive.get(logisticsField));
                    string oldValue = string.valueOf(oldData.get(logisticsField));
                    if (newValue != oldValue) {
                        Schema.SObjectField sObjectField = mapSObjectDriveField.get(logisticsField);
                        DescribeFieldResult sObjectFieldResult = sObjectField.getDescribe();
                        
                        string fieldType = string.valueOf(sObjectFieldResult.getType()).toLowerCase();
                        string fieldLabel = sObjectFieldResult.getLabel();
                        
                        if (logisticsField == 'sked_Drive_Site__c') {
                            Id newSiteId = (Id)drive.get(logisticsField);
                            newValue = mapSite.containsKey(newSiteId) ? mapSite.get(newSiteId).Name : 'NULL';
                            
                            Id oldSiteId = (Id)oldData.get(logisticsField);
                            newValue = mapSite.containsKey(oldSiteId) ? mapSite.get(oldSiteId).Name : 'NULL';
                        }
                        else {
                            newValue = skedUtils.formatFieldValue(newValue, fieldType);
                            oldValue = skedUtils.formatFieldValue(oldValue, fieldType);
                        }
                        
                        string fieldChangedContent = '[LogisticItem] has changed from [old] to [new]. \n';
                        fieldChangedContent = fieldChangedContent.replace('[LogisticItem]', fieldLabel);
                        fieldChangedContent = fieldChangedContent.replace('[old]', oldValue);
                        fieldChangedContent = fieldChangedContent.replace('[new]', newValue);
                        content += fieldChangedContent;
                    }
                }
                
                mapContent.put(recordId, content);
            }
        }
    }

    global class driveShiftTradeExceptionRender extends contentRendererBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) {
            List<skedHC__Exception__c> skedExceptions = [SELECT Id, sked_Exception_Code__c, 
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Drive__r.Name,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff_Drive__r.Name,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff__r.Name,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff__r.Name,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Trading_Event_Name__c,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff_Trading_Event_Name__c,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Reason_Approval_Required__c,
                                                        skedHC__Availability__c,
                                                        skedHC__Activity__c, skedHC__Activity__r.Name,
                                                        skedHC__Job_Allocation__c,
                                                        sked_Conflicted_Job__r.sked_Drive__r.Name,
                                                        skedHC__Job_Allocation__r.sked__Resource__c,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff__c,
                                                        skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff__c
                                                        FROM skedHC__Exception__c
                                                        WHERE Id IN :recordIds];
            mapContent = new Map<Id, string>();
            for (skedHC__Exception__c skedException : skedExceptions) {
                string content = '';
                boolean isRequestingStaff = skedException.skedHC__Job_Allocation__r.sked__Resource__c == skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff__c;
                boolean isTradingStaff = skedException.skedHC__Job_Allocation__r.sked__Resource__c == skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff__c;
                if (isRequestingStaff) {
                    content =  skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff__r.Name;
                    content += ' moving from ';
                    content += skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Trading_Event_Name__c;
                    content += ' to ';
                    content += skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff_Trading_Event_Name__c;
                }
                else if (isTradingStaff) {
                    content =  skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff__r.Name;
                    content += ' moving from ';
                    content += skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Trading_Staff_Trading_Event_Name__c;
                    content += ' to ';
                    content += skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Trading_Event_Name__c;
                }

                string reasonApprovalRequired = skedException.skedHC__Job_Allocation__r.sked_Drive_Shift_Trade__r.sked_Reason_Approval_Required__c;
                if (skedException.sked_Exception_Code__c == skedConstants.EXCEPTION_CODE_TURNAROUND_TIME_VIOLATION) {
                    if (isRequestingStaff && reasonApprovalRequired.contains('Requesting User has a TAT Contention')) {
                        content += ' would create a TAT violation';
                    }
                    else if (isTradingStaff && reasonApprovalRequired.contains('Trading User has a TAT Contention')) {
                        content += ' would create a TAT violation';
                    }
                }
                else if (skedException.skedHC__Availability__c != NULL) {
                    content += ' conflicts with previously approved PTO';
                }
                else if (skedException.skedHC__Job_Allocation__c != NULl) {
                    content += ' conflicts with ' + skedException.sked_Conflicted_Job__r.sked_Drive__r.Name;
                }
                else if (skedException.skedHC__Activity__c != NULL) {
                    content += ' conflicts with ' + skedException.skedHC__Activity__r.Name;
                }
                mapContent.put(skedException.Id, content);
            }
        }
    }

    global class driveShiftTradeOvertimeExceptionRender extends contentRendererBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) {
            List<sked__Job_Allocation__c> skedJobAllocations = [SELECT Id,  
                                                                sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Drive__r.Name,
                                                                sked_Drive_Shift_Trade__r.sked_Trading_Staff_Drive__r.Name,
                                                                sked_Drive_Shift_Trade__r.sked_Requesting_Staff__r.Name,
                                                        		sked_Drive_Shift_Trade__r.sked_Trading_Staff__r.Name,
                                                                sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Trading_Event_Name__c,
                                                                sked_Drive_Shift_Trade__r.sked_Trading_Staff_Trading_Event_Name__c,
                                                                sked_Drive_Shift_Trade__r.sked_Reason_Approval_Required__c,
                                                                sked__Resource__c,
                                                                sked_Drive_Shift_Trade__r.sked_Requesting_Staff__c,
                                                                sked_Drive_Shift_Trade__r.sked_Trading_Staff__c
                                                                FROM sked__Job_Allocation__c
                                                                WHERE Id IN :recordIds];
            mapContent = new Map<Id, string>();
            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                boolean isRequestingStaff = skedJobAllocation.sked__Resource__c == skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Requesting_Staff__c;
                boolean isTradingStaff = skedJobAllocation.sked__Resource__c == skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Trading_Staff__c;
                string content = '';
                if (isRequestingStaff) {
                    content =  skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Requesting_Staff__r.Name;
                    content += ' moving from ';
                    content += skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Trading_Event_Name__c;
                    content += ' to ';
                    content += skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Trading_Staff_Trading_Event_Name__c;
                }
                else if (isTradingStaff) {
                    content =  skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Trading_Staff__r.Name;
                    content += ' moving from ';
                    content += skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Trading_Staff_Trading_Event_Name__c;
                    content += ' to ';
                    content += skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Requesting_Staff_Trading_Event_Name__c;
                }

                string reasonApprovalRequired = skedJobAllocation.sked_Drive_Shift_Trade__r.sked_Reason_Approval_Required__c;
                if (isRequestingStaff && reasonApprovalRequired.contains('Requesting User exceeds Max Hours per week')) {
                    content += ' would create excess overtime';
                }
                else if (isTradingStaff && reasonApprovalRequired.contains('Trading User exceeds Max Hours per week')) {
                    content += ' would create excess overtime';
                }
                mapContent.put(skedJobAllocation.Id, content);
            }
        }
    }
    
}