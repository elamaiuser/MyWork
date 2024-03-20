global class slwcAdminConsoleController {
    @AuraEnabled
    public static slwcAuraResult getEventTypeSettings() {
        slwcAuraResult result = new slwcAuraResult();
        Map<string, sked_Event_Type_Setting__c> mapEventTypeSetting = new Map<string, sked_Event_Type_Setting__c>();
        List<sked_Event_Type_Setting__c> skedEventTypeSettings = [SELECT Id, sked_Item__c, sked_Available_Start__c, sked_Available_End__c,
                                                                  sked_Background_Color__c, sked_Can_Be_Pre_dated__c, sked_Color__c,
                                                                  sked_Short_Name__c, sked_Step__c, sked_Is_Available__c, sked_Show_Legend__c,
                                                                  sked_Category__c, sked_Is_Active__c, sked_Number__c
                                                                  FROM sked_Event_Type_Setting__c];
        List<string> jobTypes = skedUtils.getPickListValues('sked__Job__c', 'sked__Type__c');
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        List<string> availabilityTypes = skedUtils.getPickListValues('sked__Availability__c', 'sked__Type__c');
        availabilityTypes.add('non-working');
        List<string> locationAvailabilityTypes = skedUtils.getPickListValues('sked_Location_Availability__c', 'sked_Type__c');
        locationAvailabilityTypes.add('non-working');
        List<string> clientAvailabilityTypes = new List<string>();
        clientAvailabilityTypes.add('Preferred');
        clientAvailabilityTypes.add('Normal');
        clientAvailabilityTypes.add('Unavailable');
        List<string> customAvailabilityTypes = new List<string>();
        customAvailabilityTypes.add('Volunteer');
        List<string> allTypes = new List<string>();
        allTypes.addAll(jobTypes);
        allTypes.addAll(activityTypes);
        allTypes.addAll(availabilityTypes);
        allTypes.addAll(clientAvailabilityTypes);
        allTypes.addAll(customAvailabilityTypes);
        allTypes.addAll(locationAvailabilityTypes);
        allTypes.add('On Call');
        eventTypeSettingGeneratorModel generator = new eventTypeSettingGeneratorModel();
        generator.maxNumber = 1;
        if (skedEventTypeSettings != NULL && skedEventTypeSettings.size() > 0) {
            List<sked_Event_Type_Setting__c> skedSettingsToDelete = new List<sked_Event_Type_Setting__c>();
            for (sked_Event_Type_Setting__c skedEventTypeSetting : skedEventTypeSettings) {
                if (allTypes.contains(skedEventTypeSetting.sked_Item__c)) {
                    string key = skedEventTypeSetting.sked_Category__c + ':' + skedEventTypeSetting.sked_Item__c;
                    mapEventTypeSetting.put(key, skedEventTypeSetting);
                    if (generator.maxNumber < skedEventTypeSetting.sked_Number__c) {
                        generator.maxNumber = integer.valueOf(skedEventTypeSetting.sked_Number__c);
                    }
                }
                else {
                    skedSettingsToDelete.add(skedEventTypeSetting);
                }
            }
            if (!skedSettingsToDelete.isEmpty()) {
                delete skedSettingsToDelete;
            }
        }
        generateEventTypeSettings('job', jobTypes, mapEventTypeSetting, generator);
        generateEventTypeSettings('activity', activityTypes, mapEventTypeSetting, generator);
        generateEventTypeSettings('availability', availabilityTypes, mapEventTypeSetting, generator);
        generateEventTypeSettings('clientAvailability', clientAvailabilityTypes, mapEventTypeSetting, generator);
        generateEventTypeSettings('customAvailability', customAvailabilityTypes, mapEventTypeSetting, generator);
        generateEventTypeSettings('locationAvailability', locationAvailabilityTypes, mapEventTypeSetting, generator);
        result.returnedData = mapEventTypeSetting.values();
        return result;
    }
    @AuraEnabled
    public static slwcAuraResult getScheduleList() {
        slwcAuraResult result = new slwcAuraResult();
        Map<string, string> map_scheduleName_label = new Map<string, string>();
        map_scheduleName_label.put('skedBiddingExpirationSchedulable', 'Bidding Expiration Schedule');
        map_scheduleName_label.put('skedCollectionsZipCodeBatch', 'Collections Zip Code Batch');
        map_scheduleName_label.put('skedConvertBiddingToStandardSchedulable', 'Convert Bidding To Standard Schedule');
        map_scheduleName_label.put('skedOperationGeneratorSchedulable', 'Operation Record Generator Schedule');
        map_scheduleName_label.put('skedOperationRecordExternalDataBatch', 'Operation Record External Data Schedule');
        map_scheduleName_label.put('skedProcessBiddingPTOSchedulable', 'Process Bidding PTO Schedule');
        map_scheduleName_label.put('skedRegulatedMedicalScreenerGenBatch', 'Regulated Medical Screener Generation');
        map_scheduleName_label.put('skedResourceSeniorityRankingBatch', 'Resource Seniority Ranking Batch');
        map_scheduleName_label.put('skedResourceTagExpirySchedulable', 'Resource Tag Expiry Schedule');
        List<scheduleModel> schedules = new List<scheduleModel>();
        List<CronTrigger> skedSchedules = [SELECT Id, State, CronJobDetail.Name, StartTime, NextFireTime
                                           FROM CronTrigger
                                           WHERE CronJobDetail.Name IN :map_scheduleName_label.keySet()];
        Map<string, CronTrigger> mapSchedule = new Map<string, CronTrigger>();
        for (CronTrigger skedSchedule : skedSchedules) {
            mapSchedule.put(skedSchedule.CronJobDetail.Name, skedSchedule);
        }
        for (string scheduleName : map_scheduleName_label.keySet()) {
            scheduleModel schedule = new scheduleModel();
            schedule.id = scheduleName;
            schedule.name = scheduleName;
            schedule.label = map_scheduleName_label.get(scheduleName);
            if (mapSchedule.containsKey(scheduleName)) {
                CronTrigger skedSchedule = mapSchedule.get(scheduleName);
                schedule.state = skedSchedule.State;
                schedule.startTime = skedSchedule.StartTime;
                schedule.nextFireTime = skedSchedule.NextFireTime;
            }
            schedules.add(schedule);
        }
		result.returnedData = schedules;
        return result;
    }
    @AuraEnabled
    public static slwcAuraResult executeSchedule(executeScheduleRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();
        string scheduleNameQueryStr = '%temp_' + request.scheduleName + '%';
        List<CronTrigger> runningScheduleQuery = [SELECT Id
                                                  FROM CronTrigger
                                                  WHERE (CronJobDetail.Name = :request.scheduleName AND State = 'EXECUTING')
                                                  OR (CronJobDetail.Name LIKE :scheduleNameQueryStr AND (State = 'EXECUTING' OR State = 'WAITING'))];
        if (runningScheduleQuery != NULL && !runningScheduleQuery.isEmpty()) {
            throw new skedException('The schedule is running, please try again later.');
        }
        decimal hour = Datetime.now().hour();
        decimal min = Datetime.now().minute() + 1;
        decimal ss = Datetime.now().second();
        if (min == 60) {
            min = 0;
            hour += 1;
        }
        string dayOfMonth = String.valueOf(Datetime.now().day());
        string month = String.valueOf(Datetime.now().month());
        string year = String.valueOf(Datetime.now().year());
        //parse to cron expression
        String nextFireTime = String.valueOf(ss) + ' ' + String.valueOf(min) + ' ' + String.valueOf(hour) + ' ' + dayOfMonth + ' ' +  month +' ? ' + year + '-' + year;
        Type scheduleType = Type.forName(request.scheduleName);
        Schedulable scheduleInstance = (Schedulable)scheduleType.newInstance();
        System.schedule('temp_' + request.scheduleName + '_' + String.valueOf(Datetime.now()), nextFireTime, scheduleInstance);
        result.success = true;
        return result;
    }
    /*************************************************** Private methods ***************************************************/
    private static void generateEventTypeSettings(string objectType, List<string> eventTypes, Map<string, sked_Event_Type_Setting__c> mapEventTypeSetting, eventTypeSettingGeneratorModel generator) {
        List<sked_Event_Type_Setting__c> newSkedSettings = new List<sked_Event_Type_Setting__c>();
        for (string eventType : eventTypes) {
            string key = objectType + ':' + eventType;
            if (!mapEventTypeSetting.containsKey(key)) {
                generator.maxNumber++;
                sked_Event_Type_Setting__c skedEventTypeSetting = new sked_Event_Type_Setting__c();
                skedEventTypeSetting.Name = 'Event Type Setting ' + generator.maxNumber;
                skedEventTypeSetting.sked_Number__c = generator.maxNumber;
                skedEventTypeSetting.sked_Category__c = objectType;
                skedEventTypeSetting.sked_Item__c = eventType;
                skedEventTypeSetting.sked_Available_Start__c = 0;
                skedEventTypeSetting.sked_Available_End__c = 2400;
                skedEventTypeSetting.sked_Background_Color__c = '#0EA7CC';
                skedEventTypeSetting.sked_Color__c = '#fff';
                skedEventTypeSetting.sked_Is_Active__c = TRUE;
                skedEventTypeSetting.sked_Show_Legend__c = TRUE;
                skedEventTypeSetting.sked_Step__c = 30;
                newSkedSettings.add(skedEventTypeSetting);
            }
        }
        if (!newSkedSettings.isEmpty()) {
            insert newSkedSettings;
            for (sked_Event_Type_Setting__c skedEventTypeSetting : newSkedSettings) {
                string key = skedEventTypeSetting.sked_Category__c + ':' + skedEventTypeSetting.sked_Item__c;
                mapEventTypeSetting.put(key, skedEventTypeSetting);
            }
        }
    }
    /*************************************************** Nested classes ***************************************************/
    public class eventTypeSettingGeneratorModel {
        public integer maxNumber;
    }
    public class executeScheduleRequestModel {
        @AuraEnabled public string scheduleName {get;set;}
    }
    public class scheduleModel {
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string label {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public string state {get;set;}
        @AuraEnabled public DateTime startTime {get;set;}
        @AuraEnabled public DateTime nextFireTime {get;set;}
    }
}