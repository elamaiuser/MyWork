/**
* ***************************************************************************************************************************************************************************
* @Description: This Batch is used to create User records for Staff Resources
* @developer:   Barnojit Sharma
* ***************************************************************************************************************************************************************************
* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 09/29/2023			Barnojit Sharma			Adding Date+Time string in the community nick name to make it unique so that we do not hit the duplicate nick name error.(HRP-10628)
* 09/29/2023			Barnojit Sharma			Job Codes for Collection Management profile moved to Custom label to make it configurable.(HRP-10628)
* 09/29/2023			Barnojit Sharma			Error Mail should have Name of Resource/ User along with Id and Error Message.(HRP-10628)
* 09/29/2023			Barnojit Sharma			Collections whose names appear in metadata are bypassed.(HRP-10628)
* 09/29/2023			Barnojit Sharma			When Linking Existing User to Resource, Profile Should be updated based on Job Code.(HRP-10628)
* 09/29/2023			Barnojit Sharma			When Job Code of Resource Changes and Profile is Either Collections or Collection Management and Resource is active, Profile should be updated.(HRP-10628)
* 09/29/2023			Barnojit Sharma			When Updating User based on Changes to Resource Details including Active/Inactive - have Profile check of Collection Or Collection Management. Details should be only update if Resource is active..(HRP-10628)
* ***************************************************************************************************************************************************************************
**/
global class ResourceUserAllocationBatch implements Database.Batchable<sked__Resource__c>,Database.Stateful,Schedulable{
    global List<sked__Resource__c> resourceList;
    global Integer batchSize = 200;
    global Boolean Last24houes = true;

    private Map<Id,sked__Resource__c> updatableResourceMap1 = new Map<Id,sked__Resource__c>();
    private Map<Id,sked__Resource__c> updatableResourceMap2 = new Map<Id,sked__Resource__c>();
    private Map<Id,String> resourceNameMap = new Map<Id,String>(); //changes for HRP-10628
    private Map<Id,String> userNameMap = new Map<Id,String>(); //changes for HRP-10628
    private List<sked__Resource__c> updatableResource = new List<sked__Resource__c>();
    private Map<String,String> jobCodeVsProfileMap = getJobCodeVsProfileMap(); //changes for HRP-10628

    private Id rcId;
    private Boolean isSandbox;
    private String defaultTimeZone;
    private List<String> collOppNames = new List<String>();
    private Map<String,Id> profileIdMap = new Map<String,Id>();

    global ResourceUserAllocationBatch(){
        this.rcId = getRecordTypeId();
        this.profileIdMap = getProfileId();
        Organization org = [SELECT id, Name,InstanceName, TimeZoneSidKey, IsSandbox FROM Organization];
        this.isSandbox = org.IsSandbox;
        this.defaultTimeZone = org.TimeZoneSidKey;
        this.collOppNames = getMetadata();
    }

    global ResourceUserAllocationBatch(Integer batchSize){
        this.batchSize = batchSize;
        this.rcId = getRecordTypeId();
        this.profileIdMap = getProfileId();
        Organization org = [SELECT id, Name,InstanceName, TimeZoneSidKey, IsSandbox FROM Organization];
        this.isSandbox = org.IsSandbox;
        this.defaultTimeZone = org.TimeZoneSidKey;
        this.collOppNames = getMetadata();
    }
    
    global ResourceUserAllocationBatch (List<sked__Resource__c> resourceList){
        this.resourceList = resourceList;
        this.rcId = getRecordTypeId();
        this.profileIdMap = getProfileId();
        Organization org = [SELECT id, Name,InstanceName, TimeZoneSidKey, IsSandbox FROM Organization];
        this.isSandbox = org.IsSandbox;
        this.defaultTimeZone = org.TimeZoneSidKey;
        this.collOppNames = getMetadata();
    }

    global ResourceUserAllocationBatch (Boolean Last24houes){
        this.Last24houes = Last24houes;
        this.rcId = getRecordTypeId();
        this.profileIdMap = getProfileId();
        Organization org = [SELECT id, Name,InstanceName, TimeZoneSidKey, IsSandbox FROM Organization];
        this.isSandbox = org.IsSandbox;
        this.defaultTimeZone = org.TimeZoneSidKey;
        this.collOppNames = getMetadata();
    }

    global ResourceUserAllocationBatch (Boolean Last24houes, Integer batchSize){
        this.Last24houes = Last24houes;
        this.batchSize = batchSize;
        this.rcId = getRecordTypeId();
        this.profileIdMap = getProfileId();
        Organization org = [SELECT id, Name,InstanceName, TimeZoneSidKey, IsSandbox FROM Organization];
        this.isSandbox = org.IsSandbox;
        this.defaultTimeZone = org.TimeZoneSidKey;
        this.collOppNames = getMetadata();
    }
    global ResourceUserAllocationBatch (List<sked__Resource__c> resourceList, Integer batchSize){
        this.resourceList = resourceList;
        this.batchSize = batchSize;
        this.rcId = getRecordTypeId();
        this.profileIdMap = getProfileId();
        Organization org = [SELECT id, Name,InstanceName, TimeZoneSidKey, IsSandbox FROM Organization];
        this.isSandbox = org.IsSandbox;
        this.defaultTimeZone = org.TimeZoneSidKey;
        this.collOppNames = getMetadata();
    }
    
    global Iterable<sked__Resource__c> start(Database.BatchableContext bc){
        Datetime dateTimeFilter;
        if(Last24houes == true){
            dateTimeFilter = System.now().addHours(-24);
        }else{
            dateTimeFilter = Datetime.newInstance(1900,1,1,0,0,0);
        }
        if(resourceList != null && !resourceList.isEmpty()){
            return resourceList;
        }else{
            return [SELECT CreatedDate,
                            Id,
                            LastModifiedDate,
                            Name,
                            RecordTypeId,
                            sked_ARC_Region_Name__c,
                            sked_Biomed_Collection_Op_Center_Name__c,
                            sked_Collection_Operation_Name_Staging__c,
                            sked_Employee_ID__c,
                            sked_First_Name__c,
                            sked_Last_Name__c,
                            sked_Mobile_Type__c,
                            sked_Preferred_First_Name__c,
                            sked_Primary_Phone_Type__c,
                            sked_Timezone__c,
                            sked_Title__c,
                            sked_ULID__c,
                            sked_Work_Address_1__c,
                            sked_Work_Address_2__c,
                            sked_Work_Address_3__c,
                            sked_Work_Address_GeoLocation__Latitude__s,
                            sked_Work_Address_GeoLocation__Longitude__s,
                            sked_Work_Address_GeoLocation__c,
                            sked_Work_City__c,
                            sked_Work_Country__c,
                            sked_Work_Limitations__c,
                            sked_Work_Phone_Reference_Type__c,
                            sked_Work_Phone__c,
                            sked_Work_State__c,
                            sked_Work_Zip_Code__c,
                            sked__Alias__c,
                            sked__Email__c,
                            sked__GeoLocation__Latitude__s,
                            sked__GeoLocation__Longitude__s,
                            sked__GeoLocation__c,
                            sked__Is_Active__c,
                            sked__Mobile_Phone__c,
                            sked__Primary_Phone__c,
                            sked__Primary_Region__c,
                            sked__Resource_Type__c,
                            sked__UniqueKey__c,
                            sked__User__c,
                    		sked_Job_Code__c
                    FROM sked__Resource__c 
                    WHERE RecordType.Name = 'Staff' AND LastModifiedDate >=: dateTimeFilter
                    ORDER BY sked__User__c NULLS LAST, CreatedDate ASC];
        }
    }
    
    
    global void execute(Database.BatchableContext bc, List<sked__Resource__c> scope){
        doExecute(scope);
    }

    global void execute(SchedulableContext cc) {
        ResourceUserAllocationBatch batchObject;
        if(this.resourceList != null && !this.resourceList.isEmpty()){
            batchObject = new ResourceUserAllocationBatch(this.resourceList);
        }else{
            batchObject = new ResourceUserAllocationBatch();
        }
        Database.executeBatch(batchObject,this.batchSize);
    }
    
    
    global void finish(Database.BatchableContext bc){
        updateResources();
    }

    @TestVisible
    private void doExecute(List<sked__Resource__c> scope){
        Map<Exception,String> common_exception_map = new Map<Exception,String>();
        Map<Id, String> dml_error_map = new Map<Id, String>();
        if(scope == null || scope.isEmpty()){
            return;
        }
        try{
            Map<Id,String> collOpNameMap = new Map<Id,String>();
            List<sked__Resource__c> needToCreateUser = new List<sked__Resource__c>();
            List<sked__Resource__c> needToUpdateUser = new List<sked__Resource__c>();
            Map<Id,Id> resourceVsRegionMap = new Map<Id,Id>();
            Map<Id,Id> userVsresourceMap = new Map<Id,Id>();
            Set<Id> regionIds = new Set<Id>();
            Map<Id,String> biomedNameMap = new Map<Id,String>();
            Set<Id> userIds = new Set<Id>();
            List<String> employeeNumberList = new List<String>();
            Map<Id,User> userMap = new Map<Id,User>();
            Map<String,User> userEmployeeNoMap = new Map<String,User>();
            Map<Id,User> updatableUserMap1 = new Map<Id,User>();
            Map<Id,User> updatableUserMap2 = new Map<Id,User>();
            List<User> creatableUser = new List<User>();
            Map<String,Id> employeeNoVsRecId = new Map<String,Id>();
            Set<Id> existingUserSet = new Set<Id>();
            for(sked__Resource__c resObj : scope){
                if(resObj.sked__Primary_Region__c != null){
                    regionIds.add(resObj.sked__Primary_Region__c);
                    resourceVsRegionMap.put(resObj.Id,resObj.sked__Primary_Region__c);
                }
                if(resObj.sked__User__c != null){
                    userIds.add(resObj.sked__User__c);
                    userVsresourceMap.put(resObj.sked__User__c,resObj.Id);
                }
                if(String.isNotBlank(resObj.sked_Employee_ID__c)){
                    employeeNumberList.add(resObj.sked_Employee_ID__c);
                }
                if(resObj.sked__Is_Active__c == true && resObj.sked__User__c == null && String.isNotBlank(resObj.sked_Employee_ID__c)){ //changes for HRP-10628
                    needToCreateUser.add(resObj);
                }else if(resObj.sked__User__c != null){
                    needToUpdateUser.add(resObj);
                }
                resourceNameMap.put(resObj.Id,resObj.Name); //changes for HRP-10628
            }
            if(!userIds.isEmpty() || !employeeNumberList.isEmpty()){
                userMap = new Map<Id,User>([SELECT Id, 
                                                    EmployeeNumber, 
                                                    isActive, 
                                                    Email,
                                                    Title,
                                                    FirstName,
                                                    LastName,
                                                    FederationIdentifier,
                                                    MobilePhone,
                                                    Latitude,
                                                    Longitude,
                                                    Country,
                                                    CountryCode,
                                                    City,
                                                    State,
                                                    PostalCode,
                                                    Street,
                                                    TimeZoneSidKey,
                                                    StateCode,
                                                    ProfileId,
                                                    Username,
                                                    Profile.UserLicenseId,
                                                    Profile.UserLicense.Name,
                                                    SenderEmail,
                                                    SenderName,
                                                    CommunityNickname
                                                FROM User 
                                                WHERE Profile.UserLicense.Name ='Salesforce Platform' 
                                                AND (EmployeeNumber IN: employeeNumberList
                                                OR Id IN: userIds)]);
                if(!userMap.isEmpty()){
                    for(User ur : userMap.values()){
                        userNameMap.put(ur.Id,ur.FirstName+' '+ur.LastName);//changes for HRP-10628
                        if(String.isNotBlank(ur.EmployeeNumber)){
                            userEmployeeNoMap.put(ur.EmployeeNumber,ur);
                            userNameMap.put(ur.Id,ur.FirstName+' '+ur.LastName+' '+ur.EmployeeNumber);//changes for HRP-10628
                        }
                    }
                }
            }
            if(!regionIds.isEmpty()){
                List<sked__Region__c> regionList = [SELECT Id,
                                                            sked_Biomed_Collection_Op_Center__c,
                                                            sked_Biomed_Collection_Op_Center__r.Name
                                                    FROM sked__Region__c 
                                                    WHERE Id IN: regionIds
                                                    AND sked_Biomed_Collection_Op_Center__c <> null];
                for(sked__Region__c rg : regionList){
                    biomedNameMap.put(rg.Id,rg.sked_Biomed_Collection_Op_Center__r.Name);
                }
            }
            if(!biomedNameMap.isEmpty()){
                for(Id resourceId : resourceVsRegionMap.keySet()){
                    if(biomedNameMap.containsKey(resourceVsRegionMap.get(resourceId))){
                        collOpNameMap.put(resourceId,biomedNameMap.get(resourceVsRegionMap.get(resourceId)));
                    }
                }
            }
            for (sked__Resource__c newRecord : needToUpdateUser) {
                Boolean updateUser = false;
                if(newRecord.recordTypeId != rcId || !collOpNameMap.containsKey(newRecord.Id) || collOppNames.contains(collOpNameMap.get(newRecord.Id)) //changes for HRP-10628
                        || userMap.isEmpty() || !userMap.containsKey(newRecord.sked__User__c) || userMap.get(newRecord.sked__User__c) == null){
                    continue;
                }
                try{
                    User userData = userMap.get(newRecord.sked__User__c);
                    /*
                    * HRP-10628 changes starts here
                    */
                    List<Id> pfIdList = profileIdMap.values();
                    System.debug('## Resource Name : '+newRecord.Name);
                    System.debug('## pfIdList List : '+pfIdList);
                    System.debug('## userData.profileId : '+userData.profileId);
                    if(newRecord.sked__Is_Active__c == false && userData.IsActive == true && !pfIdList.isEmpty() && !pfIdList.contains(userData.profileId)){
                        continue;
                    }
                    /*
                    * HRP-10628 changes ends here
                    */
                    if (newRecord.sked__Is_Active__c != userData.IsActive){
                        updateUser = true;
                        userData.IsActive = newRecord.sked__Is_Active__c;
                    }
                    /*
                    * HRP-10628 changes starts here
                    */
                    if(newRecord.sked__Is_Active__c == true){
                        Id profileId;
                        if(String.isNotBlank(newRecord.sked_Job_Code__c) && jobCodeVsProfileMap.containsKey(newRecord.sked_Job_Code__c) && profileIdMap.containsKey(jobCodeVsProfileMap.get(newRecord.sked_Job_Code__c))){
                            profileId = profileIdMap.get(jobCodeVsProfileMap.get(newRecord.sked_Job_Code__c));
                        }else{
                            profileId = profileIdMap.get('Collections');
                        }
                        if (profileId != userData.profileId){
                            updateUser = true;
                            userData.profileId = profileId;
                        }
                        /*
                        * HRP-10628 changes ends here
                        */
                        if (String.isNotBlank(newRecord.sked__Email__c) && !newRecord.sked__Email__c.equalsIgnoreCase(userData.Email)){
                            updateUser = true;
                            userData.Email = newRecord.sked__Email__c;
                            userData.FederationIdentifier = newRecord.sked__Email__c;
                            userData.SenderEmail = newRecord.sked__Email__c;
                        }
                        if (String.isNotBlank(newRecord.sked_Title__c) && !newRecord.sked_Title__c.equalsIgnoreCase(userData.Title)){
                            updateUser = true;
                            userData.Title = newRecord.sked_Title__c;
                        }
                        if (String.isNotBlank(newRecord.sked_Employee_ID__c) && !newRecord.sked_Employee_ID__c.equalsIgnoreCase(userData.EmployeeNumber)){
                            updateUser = true;
                            userData.EmployeeNumber = newRecord.sked_Employee_ID__c;
                        }
                        if (String.isNotBlank(newRecord.sked_Preferred_First_Name__c) && !newRecord.sked_Preferred_First_Name__c.equalsIgnoreCase(userData.FirstName)){
                            updateUser = true;
                            userData.FirstName = newRecord.sked_Preferred_First_Name__c;
                            //adding Date+Time string in the community nick name 
                            //HRP-10628 changes starts here
                            userData.CommunityNickname = newRecord.sked_Preferred_First_Name__c + ' ' + newRecord.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''); //changes for HRP-10628
                            userData.CommunityNickname = userData.CommunityNickname.length() < 40 ? userData.CommunityNickname : userData.CommunityNickname.substring(0,39);
                            //HRP-10628 changes ends here
                            String lastAl = newRecord.sked_Last_Name__c.length() < 5 ? newRecord.sked_Last_Name__c : newRecord.sked_Last_Name__c.substring(0,5);
                            userData.Alias = userData.FirstName.left(1).toUpperCase()+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
                            userData.SenderName = userData.CommunityNickname;
                        }else if (String.isBlank(newRecord.sked_Preferred_First_Name__c) && String.isNotBlank(newRecord.sked_First_Name__c) && !newRecord.sked_First_Name__c.equalsIgnoreCase(userData.FirstName)){
                            updateUser = true;
                            userData.FirstName = newRecord.sked_First_Name__c;
                            //adding Date+Time string in the community nick name //changes for HRP-10628
                            //HRP-10628 changes starts here
                            userData.CommunityNickname = newRecord.sked_First_Name__c + ' ' + newRecord.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''); //changes for HRP-10628
                            userData.CommunityNickname = userData.CommunityNickname.length() < 40 ? userData.CommunityNickname : userData.CommunityNickname.substring(0,39);
                            //HRP-10628 changes ends here
                            String lastAl = newRecord.sked_Last_Name__c.length() < 5 ? newRecord.sked_Last_Name__c : newRecord.sked_Last_Name__c.substring(0,5);
                            userData.Alias = userData.FirstName.left(1).toUpperCase()+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
                            userData.SenderName = userData.CommunityNickname;
                        }
                        if (String.isNotBlank(newRecord.sked_Last_Name__c) && !newRecord.sked_Last_Name__c.equalsIgnoreCase(userData.LastName)){
                            updateUser = true;
                            userData.LastName = newRecord.sked_Last_Name__c;
                            //adding Date+Time string in the community nick name
                            //HRP-10628 changes starts here
                            userData.CommunityNickname = userData.FirstName + ' ' + newRecord.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-',''); //changes for HRP-10628
                            userData.CommunityNickname = userData.CommunityNickname.length() < 40 ? userData.CommunityNickname : userData.CommunityNickname.substring(0,39);
                            //HRP-10628 changes ends here
                            String lastAl = newRecord.sked_Last_Name__c.length() < 5 ? newRecord.sked_Last_Name__c : newRecord.sked_Last_Name__c.substring(0,5);
                            userData.Alias = userData.FirstName.left(1).toUpperCase()+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
                            userData.SenderName = userData.CommunityNickname;
                        }
                        if(Test.isRunningTest() || (String.isNotBlank(label.SYNC_RESOURCE_ADDRESS_AND_PHONE) && label.SYNC_RESOURCE_ADDRESS_AND_PHONE.equalsIgnoreCase('TRUE'))){
                            if (String.isNotBlank(newRecord.sked__Primary_Phone__c) && !newRecord.sked__Primary_Phone__c.equalsIgnoreCase(userData.MobilePhone)){
                                updateUser = true;
                                userData.MobilePhone = newRecord.sked__Primary_Phone__c;
                            }
                            if(String.isNotBlank(newRecord.sked_Work_Country__c) && newRecord.sked_Work_Country__c.equalsIgnoreCase('USA')){
                                newRecord.sked_Work_Country__c = 'US';
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Country__c) && newRecord.sked_Work_Country__c.length() < 3 && !newRecord.sked_Work_Country__c.equalsIgnoreCase(userData.CountryCode)){
                                updateUser = true;
                                userData.CountryCode = newRecord.sked_Work_Country__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Country__c) && newRecord.sked_Work_Country__c.length() >= 3 && !newRecord.sked_Work_Country__c.equalsIgnoreCase(userData.Country)){
                                updateUser = true;
                                userData.Country = newRecord.sked_Work_Country__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_City__c) && !newRecord.sked_Work_City__c.equalsIgnoreCase(userData.City)){
                                updateUser = true;
                                userData.City = newRecord.sked_Work_City__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_State__c) && newRecord.sked_Work_State__c.length() < 3 && !newRecord.sked_Work_State__c.equalsIgnoreCase(userData.StateCode)){
                                updateUser = true;
                                userData.StateCode = newRecord.sked_Work_State__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_State__c) && newRecord.sked_Work_State__c.length() >= 3 && !newRecord.sked_Work_State__c.equalsIgnoreCase(userData.State)){
                                updateUser = true;
                                userData.State = newRecord.sked_Work_State__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Zip_Code__c) && !newRecord.sked_Work_Zip_Code__c.equalsIgnoreCase(userData.PostalCode)){
                                updateUser = true;
                                userData.PostalCode = newRecord.sked_Work_Zip_Code__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Address_1__c) && !newRecord.sked_Work_Address_1__c.equalsIgnoreCase(userData.Street)){
                                updateUser = true;
                                userData.Street = newRecord.sked_Work_Address_1__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Timezone__c) && !newRecord.sked_Timezone__c.equalsIgnoreCase(userData.Street)){
                                updateUser = true;
                                userData.TimeZoneSidKey = newRecord.sked_Timezone__c;
                            }
                            if ((newRecord.sked_Work_Address_GeoLocation__Latitude__s != null && newRecord.sked_Work_Address_GeoLocation__Latitude__s != userData.Latitude)
                                    || (newRecord.sked_Work_Address_GeoLocation__Longitude__s != null && newRecord.sked_Work_Address_GeoLocation__Longitude__s != userData.Longitude)){
                                updateUser = true;
                                userData.Latitude = newRecord.sked_Work_Address_GeoLocation__Latitude__s;
                                userData.Longitude = newRecord.sked_Work_Address_GeoLocation__Longitude__s;
                            }
                        }
                    }
                    if(updateUser){
                        if(updatableUserMap1.isEmpty() || !updatableUserMap1.containsKey(userData.id)){
                            updatableUserMap1.put(userData.id,userData);
                        }else{
                            updatableUserMap2.put(userData.id,userData);
                        }
                    }
                }catch(Exception exc){
                    common_exception_map.put(exc,'');
                }
            }
            for(sked__Resource__c newRecord : needToCreateUser){
                if(newRecord.recordTypeId != rcId || !collOpNameMap.containsKey(newRecord.Id) || collOppNames.contains(collOpNameMap.get(newRecord.Id)) //changes for HRP-10628
                        || String.isBlank(newRecord.sked_Employee_ID__c)){
                    continue;
                }
                User userData;
                if(!userEmployeeNoMap.isEmpty() && userEmployeeNoMap.containsKey(newRecord.sked_Employee_ID__c) && userEmployeeNoMap.get(newRecord.sked_Employee_ID__c) != null){
                    try{
                        userData = userEmployeeNoMap.get(newRecord.sked_Employee_ID__c);
                        if(!userVsresourceMap.isEmpty() && userVsresourceMap.containsKey(userData.Id)){
                            if(!updatableResourceMap1.isEmpty() && updatableResourceMap1.containsKey(userVsresourceMap.get(userData.Id))){
                                updatableResourceMap1.get(userVsresourceMap.get(userData.Id)).sked__User__c = null;
                            }else if(!updatableResourceMap2.isEmpty() && updatableResourceMap2.containsKey(userVsresourceMap.get(userData.Id))){
                                updatableResourceMap1.get(userVsresourceMap.get(userData.Id)).sked__User__c = null;
                            }
                        }
                        if(updatableResourceMap1.isEmpty() || !updatableResourceMap1.containsKey(newRecord.id)){
                            updatableResourceMap1.put(newRecord.id,new sked__Resource__c(Id = newRecord.id, sked__User__c = userData.Id));
                        }else{
                            updatableResourceMap2.put(newRecord.id,new sked__Resource__c(Id = newRecord.id, sked__User__c = userData.Id));
                        }
                        userVsresourceMap.put(userData.Id,newRecord.id);
                        existingUserSet.add(userData.Id);
                        Boolean updateUser = false;
                        /*
                        * HRP-10628 changes starts here
                        */
                        Id profileId;
                        if(String.isNotBlank(newRecord.sked_Job_Code__c) && jobCodeVsProfileMap.containsKey(newRecord.sked_Job_Code__c) && profileIdMap.containsKey(jobCodeVsProfileMap.get(newRecord.sked_Job_Code__c))){
                            profileId = profileIdMap.get(jobCodeVsProfileMap.get(newRecord.sked_Job_Code__c));
                        }else{
                            profileId = profileIdMap.get('Collections');
                        }
                        if (profileId != userData.profileId){
                            updateUser = true;
                            userData.profileId = profileId;
                        }
                        /*
                        * HRP-10628 changes ends here
                        */
                        if (newRecord.sked__Is_Active__c != userData.IsActive){
                            updateUser = true;
                            userData.IsActive = newRecord.sked__Is_Active__c;
                        }
                        if (String.isNotBlank(newRecord.sked__Email__c) && !newRecord.sked__Email__c.equalsIgnoreCase(userData.Email)){
                            updateUser = true;
                            userData.Email = newRecord.sked__Email__c;
                            userData.FederationIdentifier = newRecord.sked__Email__c;
                            userData.SenderEmail = newRecord.sked__Email__c;
                        }
                        if (String.isNotBlank(newRecord.sked_Title__c) && !newRecord.sked_Title__c.equalsIgnoreCase(userData.Title)){
                            updateUser = true;
                            userData.Title = newRecord.sked_Title__c;
                        }
                        if (String.isNotBlank(newRecord.sked_Preferred_First_Name__c) && !newRecord.sked_Preferred_First_Name__c.equalsIgnoreCase(userData.FirstName)){
                            updateUser = true;
                            userData.FirstName = newRecord.sked_Preferred_First_Name__c;
                            //adding Date+Time string in the community nick name
                            //HRP-10628 changes starts here
                            userData.CommunityNickname = newRecord.sked_Preferred_First_Name__c + ' ' + newRecord.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');//changes for HRP-10628
                            userData.CommunityNickname = userData.CommunityNickname.length() < 40 ? userData.CommunityNickname : userData.CommunityNickname.substring(0,39);
                            //HRP-10628 changes ends here
                            String lastAl = newRecord.sked_Last_Name__c.length() < 5 ? newRecord.sked_Last_Name__c : newRecord.sked_Last_Name__c.substring(0,5);
                            userData.Alias = userData.FirstName.left(1).toUpperCase()+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
                            userData.SenderName = userData.CommunityNickname;
                        }else if (String.isBlank(newRecord.sked_Preferred_First_Name__c) && String.isNotBlank(newRecord.sked_First_Name__c) && !newRecord.sked_First_Name__c.equalsIgnoreCase(userData.FirstName)){
                            updateUser = true;
                            userData.FirstName = newRecord.sked_First_Name__c;
                            //adding Date+Time string in the community nick name
                            //HRP-10628 changes starts here
                            userData.CommunityNickname = newRecord.sked_First_Name__c + ' ' + newRecord.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');//changes for HRP-10628
                            userData.CommunityNickname = userData.CommunityNickname.length() < 40 ? userData.CommunityNickname : userData.CommunityNickname.substring(0,39);
                            //HRP-10628 changes ends here
                            String lastAl = newRecord.sked_Last_Name__c.length() < 5 ? newRecord.sked_Last_Name__c : newRecord.sked_Last_Name__c.substring(0,5);
                            userData.Alias = userData.FirstName.left(1).toUpperCase()+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
                            userData.SenderName = userData.CommunityNickname;
                        }
                        if (String.isNotBlank(newRecord.sked_Last_Name__c) && !newRecord.sked_Last_Name__c.equalsIgnoreCase(userData.LastName)){
                            updateUser = true;
                            userData.LastName = newRecord.sked_Last_Name__c;
                            //adding Date+Time string in the community nick name
                            //HRP-10628 changes starts here
                            userData.CommunityNickname = userData.FirstName + ' ' + newRecord.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');//changes for HRP-10628
                            userData.CommunityNickname = userData.CommunityNickname.length() < 40 ? userData.CommunityNickname : userData.CommunityNickname.substring(0,39);
                            //HRP-10628 changes ends here
                            String lastAl = newRecord.sked_Last_Name__c.length() < 5 ? newRecord.sked_Last_Name__c : newRecord.sked_Last_Name__c.substring(0,5);
                            userData.Alias = userData.FirstName.left(1).toUpperCase()+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
                            userData.SenderName = userData.CommunityNickname;
                        }
                        if(Test.isRunningTest() || (String.isNotBlank(label.SYNC_RESOURCE_ADDRESS_AND_PHONE) && label.SYNC_RESOURCE_ADDRESS_AND_PHONE.equalsIgnoreCase('TRUE'))){
                            if (String.isNotBlank(newRecord.sked__Primary_Phone__c) && !newRecord.sked__Primary_Phone__c.equalsIgnoreCase(userData.MobilePhone)){
                                updateUser = true;
                                userData.MobilePhone = newRecord.sked__Primary_Phone__c;
                            }
                            if(String.isNotBlank(newRecord.sked_Work_Country__c) && newRecord.sked_Work_Country__c.equalsIgnoreCase('USA')){
                                newRecord.sked_Work_Country__c = 'US';
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Country__c) && newRecord.sked_Work_Country__c.length() < 3 && !newRecord.sked_Work_Country__c.equalsIgnoreCase(userData.CountryCode)){
                                updateUser = true;
                                userData.CountryCode = newRecord.sked_Work_Country__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Country__c) && newRecord.sked_Work_Country__c.length() >= 3 && !newRecord.sked_Work_Country__c.equalsIgnoreCase(userData.Country)){
                                updateUser = true;
                                userData.Country = newRecord.sked_Work_Country__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_City__c) && !newRecord.sked_Work_City__c.equalsIgnoreCase(userData.City)){
                                updateUser = true;
                                userData.City = newRecord.sked_Work_City__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_State__c) && newRecord.sked_Work_State__c.length() < 3 && !newRecord.sked_Work_State__c.equalsIgnoreCase(userData.StateCode)){
                                updateUser = true;
                                userData.StateCode = newRecord.sked_Work_State__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_State__c) && newRecord.sked_Work_State__c.length() >= 3 && !newRecord.sked_Work_State__c.equalsIgnoreCase(userData.State)){
                                updateUser = true;
                                userData.State = newRecord.sked_Work_State__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Zip_Code__c) && !newRecord.sked_Work_Zip_Code__c.equalsIgnoreCase(userData.PostalCode)){
                                updateUser = true;
                                userData.PostalCode = newRecord.sked_Work_Zip_Code__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Work_Address_1__c) && !newRecord.sked_Work_Address_1__c.equalsIgnoreCase(userData.Street)){
                                updateUser = true;
                                userData.Street = newRecord.sked_Work_Address_1__c;
                            }
                            if (String.isNotBlank(newRecord.sked_Timezone__c) && !newRecord.sked_Timezone__c.equalsIgnoreCase(userData.Street)){
                                updateUser = true;
                                userData.TimeZoneSidKey = newRecord.sked_Timezone__c;
                            }
                            if ((newRecord.sked_Work_Address_GeoLocation__Latitude__s != null && newRecord.sked_Work_Address_GeoLocation__Latitude__s != userData.Latitude)
                                    || (newRecord.sked_Work_Address_GeoLocation__Longitude__s != null && newRecord.sked_Work_Address_GeoLocation__Longitude__s != userData.Longitude)){
                                updateUser = true;
                                userData.Latitude = newRecord.sked_Work_Address_GeoLocation__Latitude__s;
                                userData.Longitude = newRecord.sked_Work_Address_GeoLocation__Longitude__s;
                            }
                        }
                        if(updateUser){
                            if(updatableUserMap1.isEmpty() || !updatableUserMap1.containsKey(userData.id)){
                                updatableUserMap1.put(userData.id,userData);
                            }else{
                                updatableUserMap2.put(userData.id,userData);
                            }
                        }
                    }catch(Exception exc){
                        common_exception_map.put(exc,'');
                    }
                }else{
                    try{
                        /*
                        * HRP-10628 changes starts here
                        */
                        Id profileId;
                        if(String.isNotBlank(newRecord.sked_Job_Code__c) && jobCodeVsProfileMap.containsKey(newRecord.sked_Job_Code__c) && profileIdMap.containsKey(jobCodeVsProfileMap.get(newRecord.sked_Job_Code__c))){
                            profileId = profileIdMap.get(jobCodeVsProfileMap.get(newRecord.sked_Job_Code__c));
                        }else{
                            profileId = profileIdMap.get('Collections');
                        }
                        /*
                        * HRP-10628 changes ends here
                        */
                        userData = createUserData(newRecord,profileId,isSandbox,defaultTimeZone);
                        creatableUser.add(userData);
                    }catch(Exception exc){
                        common_exception_map.put(exc,'');
                    }
                    employeeNoVsRecId.put(newRecord.sked_Employee_ID__c,newRecord.Id);
                }
            }
            if(!existingUserSet.isEmpty()){
                for(sked__Resource__c rec : [SELECT Id, sked__User__c, sked__UniqueKey__c FROM sked__Resource__c WHERE sked__User__c IN: existingUserSet]){
                    updatableResource.add(new sked__Resource__c(Id = rec.id, sked__User__c = null,sked__UniqueKey__c = null));
                }
            }
            System.debug('updatableUserMap1 : '+updatableUserMap1);
            if(!updatableUserMap1.isEmpty()){
                Database.SaveResult[] srList;
                try{
                    srList = Database.update(updatableUserMap1.values(), false);
                    dml_error_map = addError(srList, dml_error_map, null, null);
                }catch(DmlException dxp){
                    common_exception_map.put(dxp,'');
                }
            }
            if(!updatableUserMap2.isEmpty()){
                Database.SaveResult[] srList;
                try{
                    srList = Database.update(updatableUserMap2.values(), false);
                    dml_error_map = addError(srList, dml_error_map, null, null);
                }catch(DmlException dxp){
                    common_exception_map.put(dxp,'');
                }
            }
            if(!creatableUser.isEmpty()){
                Database.SaveResult[] srList;
                try{
                    srList = Database.insert(creatableUser, false);
                    dml_error_map = addError(srList, dml_error_map,employeeNoVsRecId, creatableUser);
                    resetUserPassword(srList,null);
                }catch(DmlException dxp){
                    common_exception_map.put(dxp,'');
                }
                for(User usr : creatableUser){
                    if(usr.Id != null && String.isNotBlank(usr.EmployeeNumber) && !employeeNoVsRecId.isEmpty() && employeeNoVsRecId.containsKey(usr.EmployeeNumber)){
                        if(!updatableResourceMap1.isEmpty() && updatableResourceMap1.containsKey(employeeNoVsRecId.get(usr.EmployeeNumber))){
                            updatableResourceMap1.get(employeeNoVsRecId.get(usr.EmployeeNumber)).sked__User__c = usr.Id;
                        }else if(!updatableResourceMap2.isEmpty() && updatableResourceMap2.containsKey(employeeNoVsRecId.get(usr.EmployeeNumber))){
                            updatableResourceMap1.get(employeeNoVsRecId.get(usr.EmployeeNumber)).sked__User__c = usr.Id;
                        }else{
                            updatableResourceMap1.put(employeeNoVsRecId.get(usr.EmployeeNumber),new sked__Resource__c(Id = employeeNoVsRecId.get(usr.EmployeeNumber), sked__User__c = usr.Id));
                        }
                    }
                }
            }
            
        }catch(Exception exp){
            System.debug('### doExecute Exception'+exp);
            common_exception_map.put(exp,'');
        }
        if(!common_exception_map.isEmpty() || !dml_error_map.isEmpty()){
            sendEmail(common_exception_map, dml_error_map);
        }
    }

    @TestVisible
    private void updateResources(){
        Map<Exception,String> common_exception_map = new Map<Exception,String>();
        Map<Id, String> dml_error_map = new Map<Id, String>();
        try{
            if(!updatableResource.isEmpty()){
                Database.SaveResult[] srList;
                try{
                    srList = Database.update(updatableResource, false);
                    dml_error_map = addError(srList, dml_error_map, null, null);
                }catch(DmlException dxp){
                    common_exception_map.put(dxp,'');
                }
            }
            if(!updatableResourceMap1.isEmpty()){
                Database.SaveResult[] srList;
                try{
                    srList = Database.update(updatableResourceMap1.values(), false);
                    dml_error_map = addError(srList, dml_error_map, null, null);
                }catch(DmlException dxp){
                    common_exception_map.put(dxp,'');
                }
            }
            if(!updatableResourceMap2.isEmpty()){
                Database.SaveResult[] srList;
                try{
                    srList = Database.update(updatableResourceMap2.values(), false);
                    dml_error_map = addError(srList, dml_error_map, null, null);
                }catch(DmlException dxp){
                    common_exception_map.put(dxp,'');
                }
            }
        }catch(Exception exp){
            System.debug('### doExecute Exception'+exp);
            common_exception_map.put(exp,'');
        }
        if(!common_exception_map.isEmpty() || !dml_error_map.isEmpty()){
            sendEmail(common_exception_map, dml_error_map);
        }
    }

    @TestVisible
    private User createUserData(sked__Resource__c resObj, Id profileId, Boolean isSandbox, String defaultTimeZone){ 
        User newUser = new User();
        newUser.ProfileId = profileId;
        if(System.label.MASK_USER_EMAIL.equalsIgnoreCase('TRUE')){
            newUser.Email = resObj.sked__Email__c +'.'+ 'invalid';
        }else{
            newUser.Email = resObj.sked__Email__c;
        }
        if(isSandbox == true){
            System.Domain d = System.DomainParser.parse(URL.getOrgDomainUrl());
            newUser.Username = resObj.sked__Email__c+'.'+d.getSandboxName().toLowerCase();
        }else{
            newUser.Username = resObj.sked__Email__c;
        }
        newUser.Title = resObj.sked_Title__c;
        String lastAl = resObj.sked_Last_Name__c.length() < 5 ? resObj.sked_Last_Name__c : resObj.sked_Last_Name__c.substring(0,5);
        String firstAl = String.isNotBlank(resObj.sked_Preferred_First_Name__c) ? resObj.sked_Preferred_First_Name__c.left(1).toUpperCase() : resObj.sked_First_Name__c.left(1).toUpperCase();
        newUser.Alias = firstAl+lastAl.capitalize()+Integer.valueof((Math.random() * 99));
        if(String.isNotBlank(resObj.sked_Timezone__c)){
            newUser.TimeZoneSidKey = resObj.sked_Timezone__c;
        }else{
            newUser.TimeZoneSidKey = defaultTimeZone;
        }
        newUser.EmailEncodingKey = 'ISO-8859-1';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmployeeNumber = resObj.sked_Employee_ID__c;
        newUser.IsActive = true;
        newUser.FirstName = (String.isNotBlank(resObj.sked_Preferred_First_Name__c) ? resObj.sked_Preferred_First_Name__c : resObj.sked_First_Name__c);
        newUser.LastName = resObj.sked_Last_Name__c;
        newUser.FederationIdentifier = resObj.sked__Email__c;
        newUser.SenderEmail = resObj.sked__Email__c;
        newUser.sked__skeduloUserType__c = 'Resource';
        //adding Date+Time string in the community nick name
        //HRP-10628 changes starts here
        newUser.CommunityNickname = newUser.FirstName + ' ' + resObj.sked_Last_Name__c + ' '+ String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');//changes for HRP-10628
        newUser.CommunityNickname = newUser.CommunityNickname.length() < 40 ? newUser.CommunityNickname : newUser.CommunityNickname.substring(0,39);
        //HRP-10628 changes ends here
        newUser.SenderName = newUser.CommunityNickname;
        if(Test.isRunningTest() || (String.isNotBlank(label.SYNC_RESOURCE_ADDRESS_AND_PHONE) && label.SYNC_RESOURCE_ADDRESS_AND_PHONE.equalsIgnoreCase('TRUE'))){
            if(resObj.sked__Primary_Phone__c != null){
                newUser.MobilePhone = resObj.sked__Primary_Phone__c;
            }
            if(resObj.sked_Work_Address_GeoLocation__c != null){
                newUser.Latitude = resObj.sked_Work_Address_GeoLocation__Latitude__s;
                newUser.Longitude = resObj.sked_Work_Address_GeoLocation__Longitude__s;
            }
            if(String.isNotBlank(resObj.sked_Work_Country__c) && resObj.sked_Work_Country__c.equalsIgnoreCase('USA')){
                resObj.sked_Work_Country__c = 'US';
            }
            if(String.isNotBlank(resObj.sked_Work_Country__c) && resObj.sked_Work_Country__c.length() < 3){
                newUser.CountryCode = resObj.sked_Work_Country__c;
            }
            if(String.isNotBlank(resObj.sked_Work_Country__c) && resObj.sked_Work_Country__c.length() >= 3){
                newUser.Country = resObj.sked_Work_Country__c;
            }
            if(String.isNotBlank(resObj.sked_Work_City__c)){
                newUser.City = resObj.sked_Work_City__c;
            }
            if(String.isNotBlank(resObj.sked_Work_State__c) && resObj.sked_Work_State__c.length() < 3){
                newUser.StateCode = resObj.sked_Work_State__c;
            }
            if(String.isNotBlank(resObj.sked_Work_State__c) && resObj.sked_Work_State__c.length() >= 3){
                newUser.State = resObj.sked_Work_State__c;
            }
            if(String.isNotBlank(resObj.sked_Work_Zip_Code__c)){
                newUser.PostalCode = resObj.sked_Work_Zip_Code__c;
            }
            if(String.isNotBlank(resObj.sked_Work_Address_1__c)){
                newUser.Street = resObj.sked_Work_Address_1__c;
            }
        }
        return newUser;
    }

    @TestVisible
    private Id getRecordTypeId(){
        return Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
    }

    @TestVisible
    private Map<String,Id> getProfileId(){
        Map<String,Id> profileMap = new Map<String,Id>();
        for(Profile pr : [SELECT Id, Name FROM Profile WHERE Name IN ('Collections','Collection Management')]){
            profileMap.put(pr.Name,pr.Id);
        }
        return profileMap;
    }

    @TestVisible
    private List<String> getMetadata(){
        List<String> collopList = new List<String>();
        List<Live_Biomed_Collection_Op_Center__mdt> biomedCollopList = [SELECT MasterLabel FROM Live_Biomed_Collection_Op_Center__mdt];
        for(Live_Biomed_Collection_Op_Center__mdt co : biomedCollopList){
            collopList.add(co.MasterLabel);
        }
        return collopList;
    }

    @TestVisible
    private Map<Id, String> addError(Database.SaveResult[] srList, Map<Id, String> dml_error_map, Map<String,Id> employeeNoVsRecId, List<User> creatableUser){
        for (Integer i=0; i < srList.size(); i++){
            if(!srList.get(i).isSuccess()) {
                for(Database.Error err : srList.get(i).getErrors()) {
                    String recName = '';
                    Id recId = srList.get(i).getId();
                    if(srList.get(i).getId() == null && employeeNoVsRecId != null && !employeeNoVsRecId.isEmpty() && creatableUser != null && !creatableUser.isEmpty() && creatableUser[i].get('EmployeeNumber') != null){
                        String emp = (String) creatableUser[i].get('EmployeeNumber');
                        recId = employeeNoVsRecId.get(emp);
                    }
                    /*
                    * HRP-10628 changes starts here
                    */
                    if(recId != null && !resourceNameMap.isEmpty() && resourceNameMap.containsKey(recId)){
                        recName = resourceNameMap.get(recId);
                    }else if(recId != null && !userNameMap.isEmpty() && userNameMap.containsKey(recId)){
                        recName = userNameMap.get(recId);
                    }
                    String str_msg = '<tr><td>'+err.getMessage()+' Field: '+err.getFields()+'</td><td>'+recId+'</td><td>'+recName+'</td></tr>';
                    /*
                    * HRP-10628 changes ends here
                    */
                    dml_error_map.put(recId,str_msg); 
                } 
            }
        }
        return dml_error_map;
    }

    @TestVisible
    private void sendEmail(Map<Exception,String> common_exception_map, Map<Id, String> dml_error_map){
        try{
            if((dml_error_map!= null && dml_error_map.size() > 0) || (common_exception_map != null && common_exception_map.size() > 0)){
                String emailBody = '<html><table border="1" cellpadding="4" cellspacing="0"><thead><tr><th>Error Details</th><th>Record Id</th><th>Record Name</th></tr></thead><tbody>';//changes for HRP-10628
                if(dml_error_map.size() > 0){
                    for(Id recordId : dml_error_map.keySet()){
                        emailBody = emailBody + dml_error_map.get(recordId);
                    }
                }
                if(common_exception_map.size() > 0){
                    for(Exception exr : common_exception_map.keySet()){
                        System.debug(exr.getLineNumber() + ': ' + exr.getMessage());
                        emailBody = emailBody + '<tr><td>'+exr.getMessage()+' Stacktress: '+exr.getStackTraceString()+exr.getLineNumber()+'</td><td></td><td>'+common_exception_map.get(exr)+'</td></tr>';//changes for HRP-10628
                    }
                }
                System.debug('emailBody : '+emailBody);
                emailBody = emailBody + '</tbody></table></html>';
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                if(String.isNotBlank(label.RESOURCE_NOTIFICATION_SENDER_EMAIL)){
                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: label.RESOURCE_NOTIFICATION_SENDER_EMAIL ];
                    if (owea.size()>0) {
                        message.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                }
                List<String> emailIds = System.label.BSF_SUPPORT_EMAIL_ID.split(',');
                message.toAddresses = emailIds;
                message.optOutPolicy = 'FILTER';
                message.subject = 'Error on updating of Resourses';
                message.setHtmlBody(emailBody);
                Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: '+ results[0].errors[0].message);
                }
            }
        }catch(Exception expm){}
    }

    @TestVisible
    private void resetUserPassword(Database.SaveResult[] srList, Set<Id> useIds){
        if(!System.label.MASK_USER_EMAIL.equalsIgnoreCase('TRUE')){
            for (Database.SaveResult sr : srList) {
                if(sr.isSuccess()) {
                    if(useIds == null || useIds.isEmpty() || useIds.contains(sr.getId())){
                        System.resetPassword(sr.getId(), true);
                    }
                }
            }
        }
    }
    /*
    * HRP-10628 changes starts here
    */
    //Job Codes for Collection Management profile moved to Custom label
    @TestVisible
    private Map<String,String> getJobCodeVsProfileMap(){
        String jobCodes = System.label.Team_Supervisor_Job_Code;
        List<String> jobCodeList = jobCodes.split(',');
        Map<String,String> jobCodeVsProfileMap = new Map<String,String>();
        for (String jobCode : jobCodeList) {
            jobCodeVsProfileMap.put(jobCode,'Collection Management');
        }
        return jobCodeVsProfileMap;
    }
    /*
    * HRP-10628 changes ends here
    */
}