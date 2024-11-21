global class RemoveDuplicateTagFromDriveShift implements Database.Batchable<sObject>,Database.Stateful{
    Date startDate;
    Date endDate;
    Integer limitOfRecord;
    Set<Id> driveShiftIdSet = new Set<Id>();
    global RemoveDuplicateTagFromDriveShift(Date startDate, Date endDate, Set<Id> driveShiftIdSet, integer limitOfRecord){
        this.startDate = startDate;
        this.endDate = endDate;
        this.driveShiftIdSet = driveShiftIdSet;
        this.limitOfRecord = limitOfRecord;
    }  
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        if(this.startDate != null && this.endDate != null){
            query = createDriveShiftQueryConditionDriveDate();
        }
        if(driveShiftIdSet != null && !driveShiftIdSet.isEmpty()){
            query = createDriveShiftQueryConditionDriveShiftIdSet();
        }
        return Database.getQueryLocator(query);
        
    }
    global void execute(Database.BatchableContext BC, List<sked_Drive_Shift__c> driveShiftsList){
        set<Id> driveShiftIdSets = new set<Id>();
        for(sked_Drive_Shift__c driveShift : driveShiftsList){
            driveShiftIdSets.add(driveShift.Id);
        }
        List<sked_Drive_Shift__c> driveShifts = [Select id, sked_Drive__c, sked_Drive__r.sked_Account__c , sked_Drive__r.sked_Drive_Site__c, (SELECT Id, Name, sked_Drive_Shift__c, sked_Tag__c, sked_Tag__r.Name, sked_Minimum_Quantity__c from sked_Drive_Shift_Tags__r) from sked_Drive_Shift__c Where Id in: driveShiftIdSets];
        Map<Id,Id> driveIdVsAccountIdMap = new Map<Id,Id>();
        Map<Id,Id> driveIdVsLocationIdMap = new Map<Id,Id>();
        Map<String,List<sked_Drive_Shift_Tag__c>> driveShiftVsDriveShiftTagList = new Map<String,List<sked_Drive_Shift_Tag__c>>();
        Map<String,String> driveShiftVsDriveIdMap = new Map<String,String>();
        
        For(sked_Drive_Shift__c driveShift : driveShifts){
            
            Map<String,List<sked_Drive_Shift_Tag__c>> duplicateTagNameVsTagIds = new Map<String,List<sked_Drive_Shift_Tag__c>>();
            
            for (sked_Drive_Shift_Tag__c driveShiftTag : driveShift.sked_Drive_Shift_Tags__r) {
                if(!duplicateTagNameVsTagIds.containsKey(driveShiftTag.sked_Tag__r.Name)){
                    duplicateTagNameVsTagIds.put(driveShiftTag.sked_Tag__r.Name,new List<sked_Drive_Shift_Tag__c>());
                }
                duplicateTagNameVsTagIds.get(driveShiftTag.sked_Tag__r.Name).add(driveShiftTag);
            }
            for (String tagName : duplicateTagNameVsTagIds.keySet()) {
                if(duplicateTagNameVsTagIds.get(tagName).size() > 1){
                    if(driveShiftVsDriveShiftTagList.get(driveShift.Id) != null){
                        driveShiftVsDriveShiftTagList.get(driveShift.Id).addAll(duplicateTagNameVsTagIds.get(tagName));
                    } else {
                        driveShiftVsDriveShiftTagList.put(driveShift.Id,duplicateTagNameVsTagIds.get(tagName));
                    }
                    driveShiftVsDriveIdMap.put(driveShift.Id,driveShift.sked_Drive__c);
                    driveIdVsAccountIdMap.put(driveShift.sked_Drive__c,driveShift.sked_Drive__r.sked_Account__c);
                    driveIdVsLocationIdMap.put(driveShift.sked_Drive__c,driveShift.sked_Drive__r.sked_Drive_Site__c);
                }
            }
            
            
        }
        Map<Id,Account> accountMap = new Map<Id,Account> ([SELECT Id, (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Account__c, sked__Required__c, sked_Minimum_Quantity__c FROM sked__Account_Tags__r) FROM Account where Id In: driveIdVsAccountIdMap.values()]);
        Map<Id,sked__Location__c> siteMap =  new Map<Id,sked__Location__c> ( [SELECT Id, (SELECT Id, sked_Location__c, sked_Tag__c,sked_Tag__r.Name, sked_Minimum_Quantity__c, sked_Required__c FROM sked_Location_Tags__r) FROM sked__Location__c where Id In: driveIdVsLocationIdMap.values()]);
        Map<Id,Account> driveIdVsAccountMap = new Map<Id,Account>();
        Map<Id,sked__Location__c> driveIdVsLocationMap = new Map<Id,sked__Location__c>();
        
        For(Id driveId : driveIdVsAccountIdMap.keySet()){
            driveIdVsAccountMap.put(driveId,accountMap.get(driveIdVsAccountIdMap.get(driveId)));
        }
        
        For(Id driveId : driveIdVsLocationIdMap.keySet()){
            driveIdVsLocationMap.put(driveId,siteMap.get(driveIdVsLocationIdMap.get(driveId)));
        }
        
        Map<Id,sked_Drive_Shift_Tag__c> driveShiftTagToBeDeleted = new Map<Id,sked_Drive_Shift_Tag__c>();
        
        for(Id driveShiftId : driveShiftVsDriveShiftTagList.keySet()){
                Account acc = driveIdVsAccountMap.get(driveShiftVsDriveIdMap.get(driveShiftId));
                sked__Location__c site = driveIdVsLocationMap.get(driveShiftVsDriveIdMap.get(driveShiftId));
                Map<String,Id> tagNameRequired = new Map<String,Id>();
                Map<Id,sked_Drive_Shift_Tag__c> uniqueTag = new Map<Id,sked_Drive_Shift_Tag__c>();
                Map<String,sked_Drive_Shift_Tag__c> tagNameVsIDQuantitityMap = new Map<String,sked_Drive_Shift_Tag__c>();
                for (sked__Account_Tag__c accountTag : acc.sked__Account_Tags__r) {
                    if(accountTag.sked__Required__c == TRUE && (!tagNameRequired.containsKey(accountTag.sked__Tag__r.Name))){
                        tagNameRequired.put(accountTag.sked__Tag__r.Name,accountTag.sked__Tag__c);
                    }
                    if ((accountTag.sked__Required__c == FALSE) && (!tagNameRequired.containsKey(accountTag.sked__Tag__r.Name))) {	
                        sked_Drive_Shift_Tag__c tempDriveShiftTag = new sked_Drive_Shift_Tag__c();
                        if(tagNameVsIDQuantitityMap.containsKey(accountTag.sked__Tag__r.Name)){
                            if(tagNameVsIDQuantitityMap.get(accountTag.sked__Tag__r.Name).sked_Minimum_Quantity__c <= accountTag.sked_Minimum_Quantity__c){
                                tagNameVsIDQuantitityMap.get(accountTag.sked__Tag__r.Name).sked_Tag__c = accountTag.sked__Tag__c;
                                tagNameVsIDQuantitityMap.get(accountTag.sked__Tag__r.Name).sked_Minimum_Quantity__c = accountTag.sked_Minimum_Quantity__c;
                            }
                        } else if(!tagNameVsIDQuantitityMap.containsKey(accountTag.sked__Tag__r.Name)){
                            tempDriveShiftTag.sked_Tag__c = accountTag.sked__Tag__c;
                            tempDriveShiftTag.sked_Minimum_Quantity__c = accountTag.sked_Minimum_Quantity__c;
                            tagNameVsIDQuantitityMap.put(accountTag.sked__Tag__r.Name,tempDriveShiftTag);
                        }
                    }
                }
                
                for (sked_Location_Tag__c locationTag : site.sked_Location_Tags__r) {
                    if ((!tagNameRequired.containsKey(locationTag.sked_Tag__r.Name)) && locationTag.sked_Required__c == True) {
                        tagNameRequired.put(locationTag.sked_Tag__r.Name,locationTag.sked_Tag__c);
                    }
                    if ((locationTag.sked_Required__c == FALSE) && (!tagNameRequired.containsKey(locationTag.sked_Tag__r.Name))) {
                        sked_Drive_Shift_Tag__c tempDriveShiftTag = new sked_Drive_Shift_Tag__c();
                        if(tagNameVsIDQuantitityMap.containsKey(locationTag.sked_Tag__r.Name)){
                            if(tagNameVsIDQuantitityMap.get(locationTag.sked_Tag__r.Name).sked_Minimum_Quantity__c <= locationTag.sked_Minimum_Quantity__c){
                                tagNameVsIDQuantitityMap.get(locationTag.sked_Tag__r.Name).sked_Tag__c = locationTag.sked_Tag__c;
                                tagNameVsIDQuantitityMap.get(locationTag.sked_Tag__r.Name).sked_Minimum_Quantity__c = locationTag.sked_Minimum_Quantity__c;
                            }
                        } else if (!tagNameVsIDQuantitityMap.containsKey(locationTag.sked_Tag__r.Name)){
                            tempDriveShiftTag.sked_Tag__c = locationTag.sked_Tag__c;
                            tempDriveShiftTag.sked_Minimum_Quantity__c = locationTag.sked_Minimum_Quantity__c;
                            tagNameVsIDQuantitityMap.put(locationTag.sked_Tag__r.Name,tempDriveShiftTag);
                        }
                    }
                    if(tagNameRequired.containsKey(locationTag.sked_Tag__r.Name)){
                        tagNameVsIDQuantitityMap.remove(locationTag.sked_Tag__r.Name);
                    }
                }
                if(driveShiftVsDriveShiftTagList.get(driveShiftId) != null){
                Map<String,sked_Drive_Shift_Tag__c> tagNameTagIDTagQuantitityVsTagDetailsMap = new Map<String,sked_Drive_Shift_Tag__c>();
                for (sked_Drive_Shift_Tag__c driveShiftTag : driveShiftVsDriveShiftTagList.get(driveShiftId)) {
                    if(tagNameVsIDQuantitityMap.get(driveShiftTag.sked_Tag__r.Name) != null){
                        if(tagNameVsIDQuantitityMap.get(driveShiftTag.sked_Tag__r.Name).sked_Minimum_Quantity__c != driveShiftTag.sked_Minimum_Quantity__c && tagNameVsIDQuantitityMap.get(driveShiftTag.sked_Tag__r.Name).sked_Tag__c == driveShiftTag.sked_Tag__c){
                            driveShiftTagToBeDeleted.put(driveShiftTag.Id,driveShiftTag);
                        } else {
                            if(tagNameTagIDTagQuantitityVsTagDetailsMap.get(driveShiftTag.sked_Tag__r.Name+driveShiftTag.sked_Tag__c+tagNameVsIDQuantitityMap.get(driveShiftTag.sked_Tag__r.Name).sked_Minimum_Quantity__c) != null ){
                                driveShiftTagToBeDeleted.put(driveShiftTag.Id,driveShiftTag);
                            } else{
                                tagNameTagIDTagQuantitityVsTagDetailsMap.put(driveShiftTag.sked_Tag__r.Name+driveShiftTag.sked_Tag__c+tagNameVsIDQuantitityMap.get(driveShiftTag.sked_Tag__r.Name).sked_Minimum_Quantity__c,driveShiftTag);
                            }
                        }
                    }
                  }  
                }
        }
        
        if(!driveShiftTagToBeDeleted.isEmpty()){
            system.debug('driveShiftTagToBeDeleted :: '+driveShiftTagToBeDeleted);
            Database.delete(driveShiftTagToBeDeleted.values());
            BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c = '', ApexClass__c = 'RemoveDuplicateDriveShiftTag', Method__c ='Batch Execute', Type__c='', Error_Description__c = 'error',Error_Description_Long__c = String.join(new List<Id>(driveShiftTagToBeDeleted.keySet()),';'));
            Insert errorLog;
        }
    }
    global void finish(Database.BatchableContext bc){
        System.debug('duplicate Drive shift tag is deleted');
    }
    
    private static String createDriveShiftQueryConditionDriveShiftIdSet () {
        string drivShiftQuery = 'select id, sked_Drive__c, sked_Drive__r.sked_Account__c , sked_Drive__r.sked_Drive_Site__c from sked_Drive_Shift__c where Id in : driveShiftIdSet';
        return drivShiftQuery;
    }
    
    private static String createDriveShiftQueryConditionDriveDate () {
        string drivShiftQuery = 'select id, sked_Drive__c, sked_Drive__r.sked_Account__c , sked_Drive__r.sked_Drive_Site__c from sked_Drive_Shift__c where sked_drive_date__c >=: startDate AND sked_drive_date__c <=: endDate';
        return drivShiftQuery;
    }
}