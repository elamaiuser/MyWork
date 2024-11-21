global class skedCommonService extends skedDataService {

    private List<sObject> query(string sObjectApiName, queryModelBase query) {
        this.sObjectApiName = sObjectApiName;
        return query(query);
    }

    public skedCommonService() {
        super();
    }
    
    public List<skedModels.biomedCollectionOp> getAllBiomedCollectionOp() {
        List<Biomed_Collection_Op_Center__c> records = [SELECT Id, Name, sked_Waitlist_Enabled__c, Staging_Location_Address__c, Staging_Location_Geolocation__c,
                                                        (SELECT Id, Name, sked__Timezone__c, sked_Biomed_Collection_Op_Center__c,
                                                         sked_Territory__c
                                                         FROM sked_Regions__r)
                                                        FROM Biomed_Collection_Op_Center__c
                                                        WHERE sked_Is_Deactivated__c = FALSE];
        List<skedModels.biomedCollectionOp> results = new List<skedModels.biomedCollectionOp>();
        for (sObject record : records) {
            skedModels.biomedCollectionOp biomedCollectionOp = (skedModels.biomedCollectionOp)skedAutoMapper.instance.mapTo(record, skedModels.biomedCollectionOp.class);
            results.add(biomedCollectionOp);
        }
        return results;
    }

    public List<skedModels.holiday> getAllHolidays() {
        List<skedModels.holiday> results = new List<skedModels.holiday>();
        List<sObject> holidayRecords = this.query('sked__Holiday__c', new queryModelBase());
        for (sObject record : holidayRecords) {
            skedModels.holiday holiday = (skedModels.holiday)skedAutoMapper.instance.mapTo(record, skedModels.holiday.class);
            results.add(holiday);
        }
        List<sObject> holidayRegionRecords = this.query('sked__Holiday_Region__c', new queryModelBase());
        for (sObject record : holidayRegionRecords) {
            skedModels.holiday holiday = (skedModels.holiday)skedAutoMapper.instance.mapTo(record, skedModels.holiday.class);
            results.add(holiday);
        }
        return results;
    }
    
    public List<skedModels.selectOption> getAllProfiles() {
        List<Profile> profiles = [SELECT Id, Name 
                                  FROM Profile 
                                  ORDER BY Name ASC];
        List<skedModels.selectOption> results = new List<skedModels.selectOption>();
        for (Profile profile : profiles) {
            skedModels.selectOption model = new skedModels.selectOption(profile.Id, profile.Name);
            results.add(model);
        }
        return results;
    }

    public List<skedModels.region> getAllRegions() {
        List<sObject> records = this.query('sked__Region__c', new queryModelBase());
        List<skedModels.region> results = new List<skedModels.region>();
        for (sObject record : records) {
            skedModels.region region = (skedModels.region)skedAutoMapper.instance.mapTo(record, skedModels.region.class);
            results.add(region);
        }
        return results;
    }
    
    public List<skedModels.selectOption> getAllSkeduloPermissionSets() {
        List<PermissionSet> permissionsetSets = [SELECT Id, Label
                                                 FROM PermissionSet
                                                 WHERE Label LIKE 'Skedulo%'
                                                 ORDER BY Label ASC];
        List<skedModels.selectOption> results = new List<skedModels.selectOption>();
        for (PermissionSet permissionsetSet : permissionsetSets) {
            skedModels.selectOption model = new skedModels.selectOption(permissionsetSet.Id, permissionsetSet.Label);
            results.add(model);
        }
    	return results;
    }

    public List<skedModels.tag> getAllTags() {
        List<sObject> records = this.query('sked__Tag__c', new queryModelBase());
        List<skedModels.tag> results = new List<skedModels.tag>();
        for (sObject record : records) {
            skedModels.tag tag = (skedModels.tag)skedAutoMapper.instance.mapTo(record, skedModels.tag.class);
            results.add(tag);
        }
        return results;
    }
    
    public List<skedModels.territory> getAllTerritories() {
        List<sObject> records = this.query('sked_Territory__c', new queryModelBase());
        List<skedModels.territory> results = new List<skedModels.territory>();
        for (sObject record : records) {
            skedModels.territory territory = (skedModels.territory)skedAutoMapper.instance.mapTo(record, skedModels.territory.class);
            results.add(territory);
        }
        return results;
    }

    public List<skedModels.selectOption> getAllTimezones() {
        List<skedModels.selectOption> results = new List<skedModels.selectOption>();
        List<sked__Region__c> itemList = [SELECT Id, sked__Timezone__c FROM sked__Region__c];
        Set<string> allTimezones = new Set<string>();

        string userTimezoneSidId = UserInfo.getTimeZone().getID();
        skedModels.selectOption userTimezoneOption = new skedModels.selectOption(userTimezoneSidId, userTimezoneSidId, true);
        allTimezones.add(userTimezoneSidId);
        results.add(userTimezoneOption);

        for (sked__Region__c item : itemList) {
            if (allTimezones.contains(item.sked__Timezone__c)) {
                continue;
            }
            else {
                allTimezones.add(item.sked__Timezone__c);
            }
            skedModels.selectOption option = new skedModels.selectOption(item.sked__Timezone__c, item.sked__Timezone__c);
            results.add(option);
        }
        return results;
    }

}