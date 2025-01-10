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

    protected Id customNotificationTypeId {
        get {
            if (customNotificationTypeId == null) {
                CustomNotificationType customType = [
                    SELECT Id 
                    FROM CustomNotificationType 
                    WHERE DeveloperName = 'sked_Custom_Notification'
                ];
                customNotificationTypeId = customType.Id;
            }
            return customNotificationTypeId;
        }
        private set;
    }
    
    /************************************************* Private methods *******************************************************/
    protected virtual Map<Id, notificationSettingModel> getNotificationSettingsMap(Set<Id> notificationSettingIdS) {
        Map<Id, notificationSettingModel> map_id_settingModel = new Map<Id, notificationSettingModel>();
        for (sked_Notification_Setting__mdt skedNotificationSetting : [
            SELECT Id, Label, DeveloperName, sked_Target_SObject__c, sked_Target_Field__c, 
            sked_Target_Field_Value__c, sked_Notification_Type__c, sked_Filter__c,
            sked_Destination_Field__c, sked_Notification_Target_Field__c, 
            sked_Email_From_Address_Field__c, sked_Template__c, 
            sked_Sending_From_Email_Address__c, sked_Custom_Target_Destination__c,
            sked_Content_Renderer__c, sked_Oneoff_Protocol_Field__c, sked_Subject__c,
            sked_Priority__c, sked_Expiry_DateTime_Field__c,
            (SELECT Id, sked_Date_Time_Field__c, sked_Format_For_Token__c, 
             sked_Format_String__c, sked_Timezone_Field__c
             FROM sked_Notification_Formats__r)
            FROM sked_Notification_Setting__mdt
            WHERE Id IN :notificationSettingIds
        ]) {
            map_id_settingModel.put(skedNotificationSetting.Id, new notificationSettingModel(skedNotificationSetting));
        }
        
        loadMapSiteUrl(map_id_settingModel.values());
        
        return map_id_settingModel;
    }

    private void loadMapSiteUrl(List<notificationSettingModel> notificationSettings) {
        Set<string> siteNames = new Set<string>();
        for (notificationSettingModel notificationSetting : notificationSettings) {
            siteNames.addAll(skedUtils.getSiteNamesFromTemplate(notificationSetting.template));
        }
        if (!siteNames.isEmpty()) {
            Map<Id, Site> mapSite = new Map<Id, Site>([SELECT Id,  Name FROM Site WHERE Name IN :siteNames]);
            List<SiteDetail> siteDetails = [SELECT SecureURL, DurableId FROM SiteDetail WHERE DurableId IN :mapSite.keySet()];
            this.mapSite_Url = new Map<string, string>();
            for (SiteDetail siteDetail : siteDetails) {
                Site site = mapSite.get(siteDetail.DurableId);
                this.mapSite_Url.put(site.Name, siteDetail.SecureURL);
            }
        }
    }

    public static contentRendererBase getContentRendererInstance(string contentRenderer) {
        string className = 'skedNotificationBatchBase.' + contentRenderer;
        Type contentRendererType = Type.forName(className);
        return contentRendererType != NULL ? (contentRendererBase)contentRendererType.newInstance() : new contentRendererBase();
    }
    
    protected virtual void baseInitialize() {
        this.resetNotificationConfiguration();
        if (this.notificationSetting != NULL) {            
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                string className = 'skedNotificationBatchBase.' + this.notificationSetting.customTargetDestination;
                Type customTargetDestinationType = Type.forName(classname);
                this.customTargetDestination = (customTargetDestinationBase)customTargetDestinationType.newInstance();                
            }
            
            this.templateFields = new Set<string>();
            if (string.isNotBlank(this.notificationSetting.contentRenderer)) {
                this.contentRenderer = getContentRendererInstance(this.notificationSetting.contentRenderer);
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
        skedUtils.concactString(fields, this.notificationSetting.expiryDateTimeField);

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
    
    protected virtual List<BSF_Custom_Notification__c> generateBsfCustomNotifications(List<sObject> records) {
        List<BSF_Custom_Notification__c> allGeneratedNotifications = new List<BSF_Custom_Notification__c>();
        Map<Id, List<BSF_Custom_Notification__c>> map_recordId_notifications = new Map<Id, List<BSF_Custom_Notification__c>>();
        Map<Id, SObject> map_id_record = new Map<Id, SObject>(records);
        String notificationType = this.notificationSetting.notificationType;
        for (sObject record : records) {
            List<BSF_Custom_Notification__c> generatedNotifications = new List<BSF_Custom_Notification__c>();
            if (notificationType == 'email') {
                generatedNotifications = this.generateEmailNotification(record);
            }
            else if (notificationType == 'customsms') {
                generatedNotifications = this.generateCustomSms(record);
            }
            else if (notificationType == 'oneoff') {
                generatedNotifications = this.generateOneOffNotification(record);
            }
            else if (notificationType == 'salesforcepush') {
                generatedNotifications = this.generateSalesforcePushNotification(record);
            }

            map_recordId_notifications.put(record.Id, generatedNotifications);
            allGeneratedNotifications.addAll(generatedNotifications);
        }

        for (Id recordId : map_recordId_notifications.keySet()) {
            List<BSF_Custom_Notification__c> generatedNotifications = map_recordId_notifications.get(recordId);
            for (BSF_Custom_Notification__c generatedNotification : generatedNotifications) {
                this.populateCustomNotificationAdditionalData(generatedNotification, map_id_record.get(recordId));
            }
        }

        return allGeneratedNotifications;
    }
    
    protected virtual List<BSF_Custom_Notification__c> generateEmailNotification(sObject record) {
        List<BSF_Custom_Notification__c> customNotifications = new List<BSF_Custom_Notification__c>();
        Set<Id>  destinations = new Set<Id>();
        Object destination = skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
        if (destination == NULL) {
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                if (this.customTargetDestination.mapDestination.containsKey(record.Id)) {
                    destinations.addAll(this.customTargetDestination.mapDestination.get(record.Id));
                }
            }
        } else {
            destinations.add((Id)destination);
        }

        if (!destinations.isEmpty()) {
            Set<Id> targetUserIds = checkToConvertQueueIdsToUserIds(destinations);
            string content = getContent(record);
            string subject = getSubject(record); 
            content = applyFormat(record, content);
            subject = applyFormat(record, subject);
            String senderEmail = (string)skedUtils.getSourceFieldValue(record, this.notificationSetting.emailFromAddressField);
            if (!string.isBlank(skedSetting.instance.Admin.schedulersGroupEmail)) {
                senderEmail = skedSetting.instance.Admin.schedulersGroupEmail;
            }
            if (!string.isBlank(this.notificationSetting.sendingFromEmailAddress)) {
                senderEmail = this.notificationSetting.sendingFromEmailAddress;
            }
            
            for (Id targetUserId : targetUserIds) {
                customNotifications.add(new BSF_Custom_Notification__c(
                    Subject__c = subject,
                    Body__c = content,
                    Target_Record_Id__c = record.Id,
                    Destination_Id__c = targetUserId,
                    Sender_Email__c = senderEmail
                ));
            }
        }

        return customNotifications;
    }
    
    protected virtual List<BSF_Custom_Notification__c> generateCustomSms(sObject record) {
        List<BSF_Custom_Notification__c> customNotifications = new List<BSF_Custom_Notification__c>();

        Set<Id>  destinations = new Set<Id>();
        Object destination = skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
        if (destination == NULL) {
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                if (this.customTargetDestination.mapDestination.containsKey(record.Id)) {
                    destinations.addAll(this.customTargetDestination.mapDestination.get(record.Id));
                }
            }
        } else {
            destinations.add((Id)destination);
        }

        if (!destinations.isEmpty()) {
            Set<Id> targetUserIds = checkToConvertQueueIdsToUserIds(destinations);
            string content = getContent(record);
            content = applyFormat(record, content);
            for (Id targetUserId : targetUserIds) {
                customNotifications.add(new BSF_Custom_Notification__c(
                    Target_Record_Id__c = record.Id,
                    Body__c = content,
                    Destination_Id__c = targetUserId,
                    SMS_Country_Code_Abbreviation__c = skedSetting.instance.Admin.smsCountryCodeAbbreviation
                ));
            }
        }

        return customNotifications;
    }
    
    protected virtual List<BSF_Custom_Notification__c> generateOneOffNotification(sObject record) {
        List<BSF_Custom_Notification__c> customNotifications = new List<BSF_Custom_Notification__c>();

        Map<Id, String> protocolByDestinationId = new Map<Id, String>();
        Object destination = skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
        if (destination != null) {
            string protocol = (string)skedUtils.getSourceFieldValue(record, this.notificationSetting.oneoffProtocolField);
            protocolByDestinationId.put((Id) destination, protocol);
        } else {
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                if (this.customTargetDestination.mapDestination.containsKey(record.Id)) {
                    for (Id destinationId : this.customTargetDestination.mapDestination.get(record.Id)) {
                        if (this.customTargetDestination.mapDestinationToProtocol != null && this.customTargetDestination.mapDestinationToProtocol.containsKey(destinationId)) {
                            protocolByDestinationId.put(destinationId, this.customTargetDestination.mapDestinationToProtocol.get(destinationId));
                        }
                    }
                }
            }
        }

        if (!protocolByDestinationId.keySet().isEmpty()) {
            for (Id destinationId : protocolByDestinationId.keySet()) {
                String protocol = protocolByDestinationId.get(destinationId);
                protocol =  String.isBlank(protocol) ? 'push' : protocol;
                String content = getCOntent(record);
                content = applyFormat(record, content);
                customNotifications.add(new BSF_Custom_Notification__c(
                    Target_Record_Id__c = record.Id,
                    Body__c = content,
                    Destination_Id__c = destinationId,
                    Oneoff_Protocol__c = protocol
                ));
            }
        }
        
        return customNotifications;
    }
    
    protected virtual List<BSF_Custom_Notification__c> generateSalesforcePushNotification(sObject record) {
        List<BSF_Custom_Notification__c> customNotifications = new List<BSF_Custom_Notification__c>();
        Set<Id>  destinations = new Set<Id>();
        Object destination = skedUtils.getSourceFieldValue(record, this.notificationSetting.destinationField);
        if (destination == NULL) {
            if (!string.isBlank(this.notificationSetting.customTargetDestination)) {
                if (this.customTargetDestination.mapDestination.containsKey(record.Id)) {
                    destinations.addAll(this.customTargetDestination.mapDestination.get(record.Id));
                }
            }
        } else {
            destinations.add((Id)destination);
        }

        if (!destinations.isEmpty()) {
            Set<Id> targetUserIds = checkToConvertQueueIdsToUserIds(destinations);
            Set<Id> targetObjectIds = new Set<Id>();
            if (!string.isBlank(this.notificationSetting.customTargetDestination) && this.customTargetDestination.mapTarget.containsKey(record.Id)) {
                targetObjectIds.addAll(this.customTargetDestination.mapTarget.get(record.Id));
            }
            else {
                targetObjectIds.add(Id.valueOf(string.valueOf(skedUtils.getSourceFieldValue(record, this.notificationSetting.notificationTargetField))));
            }
    
            string content = getContent(record);
            string subject = getSubject(record); 
            content = applyFormat(record, content);
            subject = applyFormat(record, subject);

            for (Id targetUserId : targetUserIds) {
                if (targetObjectIds.isEmpty()) {
                    customNotifications.add(new BSF_Custom_Notification__c(
                        Subject__c = subject,
                        Body__c = content,
                        Destination_Id__c = targetUserId,
                        Custom_Notification_Type_Id__c = this.customNotificationTypeId
                    ));
                } else {
                    for (Id targetObjectId : targetObjectIds) {
                        customNotifications.add(new BSF_Custom_Notification__c(
                            Subject__c = subject,
                            Body__c = content,
                            Target_Record_Id__c = targetObjectId,
                            Destination_Id__c = targetUserId,
                            Custom_Notification_Type_Id__c = this.customNotificationTypeId
                        ));
                    }
                }
            }
        }

        return customNotifications;
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

    private void populateCustomNotificationAdditionalData(BSF_Custom_Notification__c customNotification, sObject targetRecord) {
        customNotification.Notification_Type__c = this.notificationSetting.notificationType;
        customNotification.Status__c = skedConstants.BSF_CUSTOM_NOTIFICATION_STATUS_QUEUED;
        customNotification.Priority__c = this.notificationSetting.priority;
        customNotification.sked_Notification_Setting_Id__c = this.notificationSetting.id + ':' + targetRecord.Id;
        if (!String.isBlank(this.notificationSetting.expiryDateTimeField)) {
            customNotification.Expiry_TimeStamp__c = (Datetime)skedUtils.getSourceFieldValue(targetRecord, this.notificationSetting.expiryDateTimeField);
        }
    }

    private Set<Id> checkToConvertQueueIdsToUserIds(Set<Id> destinationIds) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        for (Id destinationId : destinationIds) {
            SObjectType sObjectType = destinationId.getSObjectType();
            string sObjectTypeName = sObjectType.getDescribe().getName();
            if (sObjectTypeName == Group.getSobjectType().getDescribe().getName()) {
                queueIds.add(destinationId);
            } else {
                userIds.add(destinationId);
            }
        }

        if (!queueIds.isEmpty()) {
            for (GroupMember queueMember : [
                SELECT Id, UserOrGroupId
                FROM GroupMember
                WHERE GroupId IN :queueIds]
            ) {
                userIds.add(queueMember.UserOrGroupId);
            }
        }


        return userIds;
    }

    private void resetNotificationConfiguration() {
        this.templateFields = new Set<string>();
        this.subjectFields = new Set<string>();
        this.mapSite_Url = new Map<string, string>();
        this.contentRenderer = NULL;
        this.customTargetDestination = NULL;
    }
    
    /************************************************* Nested classes *******************************************************/
    global class notificationSettingModel {
        public string id;
        public string label;
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
        public Decimal priority;
        public string expiryDateTimeField;
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
            this.id = skedNotificationSetting.Id;
            this.label = skedNotificationSetting.Label;
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
            this.priority = skedNotificationSetting.sked_Priority__c;
            this.expiryDateTimeField = skedNotificationSetting.sked_Expiry_DateTime_Field__c;
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
        public Map<Id, Set<Id>> mapTarget;
        public Map<Id, Set<Id>> mapDestination;
        public Map<Id, String> mapDestinationToProtocol;

        public virtual void process (Set<Id> recordIds, List<SObject> newRecords) {}
    }

    global class resourceAllocationDriveLeadEmailTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            List<sked__Job_Allocation__c> skedJobAllocations = [
                SELECT Id, sked__Job__r.sked_Drive__c
                FROM sked__Job_Allocation__c
                WHERE Id IN :recordIds
            ];
            Set<Id> driveIds = new Set<Id>();
            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                driveIds.add(skedJobAllocation.sked__Job__r.sked_Drive__c);
            }

            sked_Resource_Role_Group__c resourceRoleGroup = [
                SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                FROM sked_Resource_Role_Group__c
                WHERE sked_Resource_Role_Group__c = 'Supervisory roles'
                LIMIT 1
            ];
            List<string> roles = resourceRoleGroup.sked_Resource_Roles__c.split(';');

            List<sked__Job_Allocation__c> skedDriveLeadAllocations = [
                SELECT Id, 
                sked__Resource__r.sked__User__c, sked__Job__r.sked_Drive__c
                FROM sked__Job_Allocation__c
                WHERE sked__Job__r.sked_Drive__c IN :driveIds 
                    AND sked__Job__r.sked_Resource_Role__c IN :roles
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ];
            Map<Id, sked__Job_Allocation__c> mapDrive_LeadAllocation = new Map<Id, sked__Job_Allocation__c>();
            for (sked__Job_Allocation__c skedDriveLeadAllocation : skedDriveLeadAllocations) {
                mapDrive_LeadAllocation.put(skedDriveLeadAllocation.sked__Job__r.sked_Drive__c, skedDriveLeadAllocation);
            }

            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                sked__Job_Allocation__c driveLeadAllocation = mapDrive_LeadAllocation.get(skedJobAllocation.sked__Job__r.sked_Drive__c);
                if (driveLeadAllocation != NULL) {
                    mapTarget.put(skedJobAllocation.Id, new Set<Id>{driveLeadAllocation.sked__Resource__r.sked__User__c});
                    mapDestination.put(skedJobAllocation.Id, new Set<Id>{driveLeadAllocation.sked__Resource__r.sked__User__c});
                }
            }
        }
    }

    global class resourceAllocationDriveLeadOneOffTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();
            mapDestinationToProtocol = new Map<Id, String>();

            List<sked__Job_Allocation__c> skedJobAllocations = [
                SELECT Id, sked__Job__r.sked_Drive__c
                FROM sked__Job_Allocation__c
                WHERE Id IN :recordIds
            ];
            Set<Id> driveIds = new Set<Id>();
            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                driveIds.add(skedJobAllocation.sked__Job__r.sked_Drive__c);
            }

            sked_Resource_Role_Group__c resourceRoleGroup = [
                SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                FROM sked_Resource_Role_Group__c
                WHERE sked_Resource_Role_Group__c = 'Supervisory roles'
                LIMIT 1
            ];
            List<string> roles = resourceRoleGroup.sked_Resource_Roles__c.split(';');

            List<sked__Job_Allocation__c> skedDriveLeadAllocations = [
                SELECT Id, sked__Resource__c, sked__Resource__r.sked__Notification_Type__c,
                sked__Resource__r.sked__User__c, sked__Job__r.sked_Drive__c
                FROM sked__Job_Allocation__c
                WHERE sked__Job__r.sked_Drive__c IN :driveIds 
                    AND sked__Job__r.sked_Resource_Role__c IN :roles
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ];
            Map<Id, sked__Job_Allocation__c> mapDrive_LeadAllocation = new Map<Id, sked__Job_Allocation__c>();
            for (sked__Job_Allocation__c skedDriveLeadAllocation : skedDriveLeadAllocations) {
                mapDrive_LeadAllocation.put(skedDriveLeadAllocation.sked__Job__r.sked_Drive__c, skedDriveLeadAllocation);
            }

            for (sked__Job_Allocation__c skedJobAllocation : skedJobAllocations) {
                sked__Job_Allocation__c driveLeadAllocation = mapDrive_LeadAllocation.get(skedJobAllocation.sked__Job__r.sked_Drive__c);
                if (driveLeadAllocation != NULL) {
                    mapTarget.put(skedJobAllocation.Id, new Set<Id>{driveLeadAllocation.sked__Resource__c});
                    mapDestination.put(skedJobAllocation.Id, new Set<Id>{driveLeadAllocation.sked__Resource__c});
                    mapDestinationToProtocol.put(driveLeadAllocation.sked__Resource__c, driveLeadAllocation.sked__Resource__r.sked__Notification_Type__c);
                }
            }
        }
    }

    global class onCallSupervisorTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            List<sked__Availability__c> callOuts = [
                SELECT Id, sked_Start_Date__c, sked__Resource__c, sked__Resource__r.Name,
                    sked__Resource__r.sked__User__c, CreatedById,
                    sked_Call_Out_Type__c, sked__Timezone__c, CreatedDate,
                    sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Drive_Date__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Resource_Role__c,
                    sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                FROM sked__Availability__c 
                WHERE Id IN :recordIds
            ];

            skedQueryBuilder queryBuilder = new skedQueryBuilder();
            queryBuilder.setFromClause('sked__Activity_Resource__c');
            queryBuilder.setIsOrQuery(true);
            queryBuilder.addFields(new List<String>{
                'Id', 'sked__Activity__r.sked_Start_Date__c', 'sked__Activity__r.sked_End_Date__c', 'sked__Resource__r.sked__User__c',
                'sked__Resource__c', 'sked__Resource__r.sked__Email__c', 'sked__Resource__r.sked__Mobile_Phone__c'
            });

            for (sked__Availability__c callOut : callOuts) {
                Date callOutDate = callOut.sked_Start_Date__c;
                Id resourceCoId = callOut.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                
                List<String> conditionGroup = new List<String>();
                conditionGroup.add(queryBuilder.generateCondition('sked__Activity__r.sked_Start_Date__c <= {0}', callOutDate));
                conditionGroup.add(queryBuilder.generateCondition('sked__Activity__r.sked_End_Date__c >= {0}', callOutDate));
                conditionGroup.add(queryBuilder.generateCondition('sked__Activity__r.sked_Collection_Operation__c = {0}', resourceCoId));
                conditionGroup.add(queryBuilder.generateCondition('sked__Activity__r.sked__Type__c = {0}', skedConstants.ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT));
                queryBuilder.addConditionGroup(conditionGroup);
            }

                        
            if (queryBuilder.hasConditionGroups()) {
                List<sked__Activity_Resource__c> onCallActivityResources = Database.query(queryBuilder.toString());
                for (sked__Availability__c callOut : callOuts) {
                    Set<Id> targets = new Set<Id>();
                    for (sked__Activity_Resource__c onCallActivityResource : onCallActivityResources) {
                        Date activityStartDate = onCallActivityResource.sked__Activity__r.sked_Start_Date__c;
                        Date activityEndDate = onCallActivityResource.sked__Activity__r.sked_End_Date__c;
                        if (callOut.sked_Start_Date__c >= activityStartDate && callOut.sked_Start_Date__c <= activityEndDate) {                        
                            targets.add(onCallActivityResource.sked__Resource__r.sked__User__c);
                        }
                    }

                    if (!targets.isEmpty()) {
                        mapTarget.put(callOut.Id, targets);
                        mapDestination.put(callOut.Id, targets);
                    }
                }
            }
        }
    }

    global class driveLeadCalloutOneOffTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();
            mapDestinationToProtocol = new Map<Id, String>();

            List<sked__Availability__c> callOuts = [
                SELECT Id, sked_Start_Date__c, sked__Resource__c, sked__Resource__r.Name,
                    sked__Resource__r.sked__User__c, CreatedById,
                    sked_Call_Out_Type__c, sked__Timezone__c, CreatedDate,
                    sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Drive_Date__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Resource_Role__c,
                    sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                FROM sked__Availability__c 
                WHERE Id IN :recordIds
            ];

            Set<Id> driveIds = new Set<Id>();
            for (sked__Availability__c callOut : callOuts) {
                if (callOut.sked_Call_Out_for_Job_Allocation__r != null) {
                    driveIds.add(callOut.sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c);
                }
            }

            sked_Resource_Role_Group__c resourceRoleGroup = [
                SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                FROM sked_Resource_Role_Group__c
                WHERE sked_Resource_Role_Group__c = 'Supervisory roles'
                LIMIT 1
            ];
            List<string> roles = resourceRoleGroup.sked_Resource_Roles__c.split(';');

            List<sked__Job_Allocation__c> skedDriveLeadAllocations = [
                SELECT Id, sked__Resource__r.sked__Email__c, 
                sked__Resource__r.sked__User__c, sked__Job__r.sked_Drive__c, sked__Resource__r.sked__Notification_Type__c
                FROM sked__Job_Allocation__c
                WHERE sked__Job__r.sked_Drive__c IN :driveIds 
                    AND sked__Job__r.sked_Resource_Role__c IN :roles
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ];

            Map<Id, List<sked__Job_Allocation__c>> driveLeadsByDriveId = new Map<Id, List<sked__Job_Allocation__c>>();
            for (sked__Job_Allocation__c skedDriveLeadAllocation : skedDriveLeadAllocations) {
                Id driveId = skedDriveLeadAllocation.sked__Job__r.sked_Drive__c;
                List<sked__Job_Allocation__c> driveLeadsForDrive = driveLeadsByDriveId.get(driveId);
                if (driveLeadsForDrive == null) {
                    driveLeadsForDrive = new List<sked__Job_Allocation__c>();
                }

                driveLeadsForDrive.add(skedDriveLeadAllocation);
                driveLeadsByDriveId.put(driveId, driveLeadsForDrive);
            }

            for (sked__Availability__c callOut : callOuts) {
                Set<Id> targets = new Set<Id>();
                if (callOut.sked_Call_Out_for_Job_Allocation__c != null) {
                    Id driveId = callOut.sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c;
                    List<sked__Job_Allocation__c> driveLeadAllocations = driveLeadsByDriveId.get(driveId);
                    if (driveLeadAllocations != null && !driveLeadAllocations.isEmpty()) {
                        for (sked__Job_Allocation__c driveLeadAllocation : driveLeadAllocations) {
                            targets.add(driveLeadAllocation.sked__Resource__c);
                            mapDestinationToProtocol.put(driveLeadAllocation.sked__Resource__c, driveLeadAllocation.sked__Resource__r.sked__Notification_Type__c);
                        }
                    }
                }

                if (!targets.isEmpty()) {
                    mapTarget.put(callOut.Id, targets);
                    mapDestination.put(callOut.Id, targets);
                }
            }
        }
    }

    global class driveLeadCalloutEmailTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            List<sked__Availability__c> callOuts = [
                SELECT Id, sked_Start_Date__c, sked__Resource__c, sked__Resource__r.Name,
                    sked__Resource__r.sked__User__c, CreatedById,
                    sked_Call_Out_Type__c, sked__Timezone__c, CreatedDate,
                    sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Drive_Date__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Resource_Role__c,
                    sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                FROM sked__Availability__c 
                WHERE Id IN :recordIds
            ];

            Set<Id> driveIds = new Set<Id>();
            for (sked__Availability__c callOut : callOuts) {
                if (callOut.sked_Call_Out_for_Job_Allocation__r != null) {
                    driveIds.add(callOut.sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c);
                }
            }

            sked_Resource_Role_Group__c resourceRoleGroup = [
                SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                FROM sked_Resource_Role_Group__c
                WHERE sked_Resource_Role_Group__c = 'Supervisory roles'
                LIMIT 1
            ];
            List<string> roles = resourceRoleGroup.sked_Resource_Roles__c.split(';');

            List<sked__Job_Allocation__c> skedDriveLeadAllocations = [
                SELECT Id, sked__Resource__r.sked__Email__c, 
                sked__Resource__r.sked__User__c, sked__Job__r.sked_Drive__c
                FROM sked__Job_Allocation__c
                WHERE sked__Job__r.sked_Drive__c IN :driveIds 
                    AND sked__Job__r.sked_Resource_Role__c IN :roles
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
                    AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            ];

            Map<Id, List<sked__Job_Allocation__c>> driveLeadsByDriveId = new Map<Id, List<sked__Job_Allocation__c>>();
            for (sked__Job_Allocation__c skedDriveLeadAllocation : skedDriveLeadAllocations) {
                Id driveId = skedDriveLeadAllocation.sked__Job__r.sked_Drive__c;
                List<sked__Job_Allocation__c> driveLeadsForDrive = driveLeadsByDriveId.get(driveId);
                if (driveLeadsForDrive == null) {
                    driveLeadsForDrive = new List<sked__Job_Allocation__c>();
                }

                driveLeadsForDrive.add(skedDriveLeadAllocation);
                driveLeadsByDriveId.put(driveId, driveLeadsForDrive);
            }

            for (sked__Availability__c callOut : callOuts) {
                Set<Id> targets = new Set<Id>();
                if (callOut.sked_Call_Out_for_Job_Allocation__c != null) {
                    Id driveId = callOut.sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c;
                    List<sked__Job_Allocation__c> driveLeadAllocations = driveLeadsByDriveId.get(driveId);
                    if (driveLeadAllocations != null && !driveLeadAllocations.isEmpty()) {
                        for (sked__Job_Allocation__c driveLeadAllocation : driveLeadAllocations) {
                            targets.add(driveLeadAllocation.sked__Resource__r.sked__User__c);
                        }
                    }
                }

                if (!targets.isEmpty()) {
                    mapTarget.put(callOut.Id, targets);
                    mapDestination.put(callOut.Id, targets);
                }
            }
        }
    }

    global class apsSchedulersCallOutTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            List<sked__Availability__c> callOuts = [
                SELECT Id, sked_Start_Date__c, sked__Resource__c, sked__Resource__r.Name,
                    sked__Resource__r.sked__User__c, CreatedById,
                    sked_Call_Out_Type__c, sked__Timezone__c, CreatedDate,
                    sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Drive_Date__c,
                    sked_Call_Out_for_Job_Allocation__r.sked_Resource_Role__c,
                    sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                FROM sked__Availability__c 
                WHERE Id IN :recordIds
            ];

            Set<Id> driveIds = new Set<Id>();
            for (sked__Availability__c callOut : callOuts) {
                if (callOut.sked_Call_Out_for_Job_Allocation__r != null) {
                    driveIds.add(callOut.sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c);
                }
            }

            List<sked_Drive__c> affectedDrives = [
                SELECT Id, sked_Collection_Operation__r.Name
                FROM sked_Drive__c
                WHERE Id IN :driveIds
            ];

            Map<Id, Set<String>> queueNameByDriveId = new Map<Id, Set<String>>();
            Set<String> queueNames = new Set<String>();
            for (sked_Drive__c drive : affectedDrives) {
                Set<String> queueNamesForDrive = new Set<String>();
                queueNamesForDrive.add(drive.sked_Collection_Operation__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES);
                queueNameByDriveId.put(
                    drive.Id,
                    queueNamesForDrive
                );
                queueNames.addAll(queueNamesForDrive);
            }

            List<Group> approvalQueues = [
                SELECT Id, Name
                FROM Group
                WHERE Name IN :queueNames
                AND Type = :skedConstants.GROUP_TYPE_QUEUE
            ];

            Map<String, Group> approvalQueueByName = new Map<String, Group>();
            for (Group approvalQueue : approvalQueues) {
                approvalQueueByName.put(approvalQueue.Name, approvalQueue);
            }

            for (sked__Availability__c callOut : callOuts) {
                Set<Id> targets = new Set<Id>();
                Id driveId = callOut.sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__c;
                Set<String> queueNamesForDrive = queueNameByDriveId.get(driveId);
                if (queueNamesForDrive != null && !queueNamesForDrive.isEmpty()) {
                    for (String queueName : queueNamesForDrive) {
                        if (approvalQueueByName.containsKey(queueName)) {
                            Group approvalQueue = approvalQueueByName.get(queueName);
                            targets.add(approvalQueue.Id);
                        }
                    }
                }

                if (!targets.isEmpty()) {
                    mapTarget.put(callOut.Id, targets);
                    mapDestination.put(callOut.Id, targets);
                }
            }
        }
    }
    
    global class driveDcrQueueTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<SObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();
            
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
                    mapTarget.put(skedDrive.Id, new Set<Id>{approvalQueue.Id});
                    mapDestination.put(skedDrive.Id, new Set<Id>{approvalQueue.Id});
                }
            }
        }
    }

    global class siteFeedBackRejectionTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<sObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            Map<Id, Set<Id>> map_recordId_stepApprovers = new Map<Id, Set<Id>>();
            for (ProcessInstanceStep step : [
                SELECT Id, Actor.Id, ProcessInstance.TargetObjectId
                FROM ProcessInstanceStep
                WHERE ProcessInstance.TargetObjectId IN :recordIds
                AND StepStatus IN ('Approved', 'Started')
            ]) {
                if (!map_recordId_stepApprovers.containsKey(step.ProcessInstance.TargetObjectId)) {
                    map_recordId_stepApprovers.put(step.ProcessInstance.TargetObjectId, new Set<Id>());
                }
                map_recordId_stepApprovers.get(step.ProcessInstance.TargetObjectId).add(step.Actor.Id);
            }
            
            for (Id recordId : recordIds) {
                if (map_recordId_stepApprovers.containsKey(recordId)) {
                    this.mapTarget.put(recordId, map_recordId_stepApprovers.get(recordId));
                    this.mapDestination.put(recordId, map_recordId_stepApprovers.get(recordId));
                }
            }
        }
    }

    global class apsSchedulersCancelledATOTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<sObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            List<sked__Availability__c> cancelledApprovedTimeOffs = [
                SELECT Id,
                    sked__Resource__c,
                    sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Name
                FROM sked__Availability__c 
                WHERE Id IN :recordIds
            ];

            Map<Id, String> queueNameByResourceId = new Map<Id, String>();
            for (sked__Availability__c timeOff : cancelledApprovedTimeOffs) { 
                queueNameByResourceId.put(
                    timeOff.sked__Resource__c,
                    timeOff.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Name + ': ' + skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES
                );
            }

            List<Group> approvalQueues = [
                SELECT Id, Name
                FROM Group
                WHERE Name IN :queueNameByResourceId.values()
                AND Type = :skedConstants.GROUP_TYPE_QUEUE
            ];
            Map<String, Group> approvalQueueByName = new Map<String, Group>();
            for (Group approvalQueue : approvalQueues) {
                approvalQueueByName.put(approvalQueue.Name, approvalQueue);
            }

            for (sked__Availability__c timeOff : cancelledApprovedTimeOffs) {
                Set<Id> targets = new Set<Id>();
                String queueName = queueNameByResourceId.get(timeOff.sked__Resource__c);
                if (queueName != null && approvalQueueByName.containsKey(queueName)) {
                    Group approvalQueue = approvalQueueByName.get(queueName);
                    targets.add(approvalQueue.Id);
                }

                if (!targets.isEmpty()) {
                    mapTarget.put(timeOff.Id, targets);
                    mapDestination.put(timeOff.Id, targets);
                }
            }
        }
    }

    global class workdaySystemGroupTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<sObject> newRecords) {
            System.debug('GETTING WORKDAY SYSTEM GROUP');
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            Group workdaySystemGroup = [
                SELECT Id
                FROM Group
                WHERE Name = 'Workday System Errors Group'
                AND Type = :skedConstants.GROUP_TYPE_REGULAR
            ];

            if (workdaySystemGroup != null) {
                Set<Id> targets = new Set<Id>();
                targets.add(workdaySystemGroup.Id);
                for (Id recordId : recordIds) {
                    mapTarget.put(recordId, targets);
                    mapDestination.put(recordId, targets);
                }
            }
            System.debug('MAP TARGET :: ' + mapTarget + ' :: ' + mapDestination);
        }
    }

    global class workdayValidationGroupTargetDestination extends customTargetDestinationBase {
        public override void process(Set<Id> recordIds, List<sObject> newRecords) {
            mapTarget = new Map<Id, Set<Id>>();
            mapDestination = new Map<Id, Set<Id>>();

            Group workdayValidationGroup = [
                SELECT Id
                FROM Group
                WHERE Name = 'Workday Validation Errors Group'
                AND Type = :skedConstants.GROUP_TYPE_REGULAR
            ];

            if (workdayValidationGroup != null) {
                Set<Id> targets = new Set<Id>();
                targets.add(workdayValidationGroup.Id);
                for (Id recordId : recordIds) {
                    mapTarget.put(recordId, targets);
                    mapDestination.put(recordId, targets);
                }
            }
        }
    }
    
    /************************************************* Content Renderer *******************************************************/
    global virtual class contentRendererBase {
        public List<String> fieldsForRenderer;
        public Map<Id, string> mapContent;

        public contentRendererBase() {
            this.registerFieldsForRenderer();
        }
        
        public virtual void process(Set<Id> recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) { }
        public virtual void registerFieldsForRenderer() {
            this.fieldsForRenderer = new List<String>();
        }
    }

    global class logisticChangeRender extends contentRendererBase {
        public override void registerFieldsForRenderer() {
            this.fieldsForRenderer = new List<String> {
                'Id',
                'Name',
                'sked_Drive_Date_Text__c',
                'sked_Drive_Date__c',
                'sked_Start_Time__c',
                'sked_End_Time__c',
                'sked_Drive_Site__c',
                'sked_Projected_Registered_Donors__c',
                'sked_WB_Projected_Procedures__c',
                'sked_2RBC_Projected_Procedures__c',
                'sked_Platelet_Projected_Procedures__c',
                'sked_Plasma_Projected_Procedures__c'
            };
        }

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
    
    global class siteFeedbackSubmitterNotificationRender extends contentRendererBase {
        public override void registerFieldsForRenderer() {
            this.fieldsForRenderer = new List<String> {
                'Id',
                'Name',
                'sked_Effective_Start_Date__c',
                'sked_Effective_End_Date__c',
                'sked_Buffer_Type__c',
                'sked_Variance_Type__c',
                'sked_Variance_Type_Other__c',
                'sked_Amount__c',
                'sked_Variance_Applies_to__c',
                'sked_Days_Of_Week__c',
                'sked_Resource_Role_Group__c',
                'sked_Current_Submitter__c',
                'sked_Site_Name__c'
            };
        }

        public override void process(Set<Id> recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) {
            Map<Id, SObject> mapNewRecords = new Map<Id, SObject>(newRecords);
            
            Map<String, Schema.SObjectField> mapSObjectSiteFeedbackField = Schema.SObjectType.sked_Site_Feedback__c.fields.getMap();
            
            List<string> feedbackChangedFields = new List<string>{
                'sked_Effective_Start_Date__c',
                'sked_Effective_End_Date__c',
                'sked_Buffer_Type__c',
                'sked_Variance_Type__c',
                'sked_Variance_Type_Other__c',
                'sked_Amount__c',
                'sked_Variance_Applies_to__c',
                'sked_Days_Of_Week__c',
                'sked_Resource_Role_Group__c'
            };

            Set<Id> currentSubmitterIds = new Set<Id>();
            for (SObject newRecord : newRecords) {
                currentSubmitterIds.add((Id)newRecord.get('sked_Current_Submitter__c'));
            }

            Map<Id, User> mapCurrentSubmitter = new Map<Id, User>([SELECT Id, Name
                                                                  FROM User
                                                                  WHERE Id IN :currentSubmitterIds]);
            
            mapContent = new Map<Id, string>();
            for (Id recordId : recordIds) {
                sked_Site_Feedback__c siteFeedback = (sked_Site_Feedback__c)mapNewRecords.get(recordId);
                sked_Site_Feedback__c oldData = (sked_Site_Feedback__c)oldMap.get(recordId);
                User currentSubmitter = mapCurrentSubmitter.get(siteFeedback.sked_Current_Submitter__c);
                
                string content = 'Your RTV Feedback for <strong>[SiteName]</strong> has been updated by <strong>[CurrentSubmitterName]</strong>. Please review the following changes below, no actions are needed from you at this time.<br><br>';
                content = content.replace('[SiteName]', siteFeedback.sked_Site_Name__c);
                content = content.replace('[CurrentSubmitterName]', currentSubmitter.Name);
                
                for (string feedbackChangedField : feedbackChangedFields) {
                    string newValue = string.valueOf(siteFeedback.get(feedbackChangedField));
                    string oldValue = string.valueOf(oldData.get(feedbackChangedField));
                    if (newValue != oldValue) {
                        Schema.SObjectField sObjectField = mapSObjectSiteFeedbackField.get(feedbackChangedField);
                        DescribeFieldResult sObjectFieldResult = sObjectField.getDescribe();
                        
                        string fieldType = string.valueOf(sObjectFieldResult.getType()).toLowerCase();
                        string fieldLabel = sObjectFieldResult.getLabel();
                        newValue = skedUtils.formatFieldValue(newValue, fieldType);
                        
                        string fieldChangedContent = '<strong>[SiteFeedbackField] = [newValue]</strong><br>';
                        fieldChangedContent = fieldChangedContent.replace('[SiteFeedbackField]', fieldLabel);
                        fieldChangedContent = fieldChangedContent.replace('[newValue]', newValue);
                        content += fieldChangedContent;
                    }
                }
                
                mapContent.put(recordId, content);
            }
        }
    }
}