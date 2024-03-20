global class PopulateDriveandSiteExternalIDBatch implements Database.Batchable<Sobject>,Schedulable{
    global Integer batchSize = 200;
    global Boolean forSite = false;
    private final String QUERY_FOR_SITE = 'SELECT Id FROM sked__Location__c WHERE Site_External_ID__c = null';
    private final String QUERY_FOR_DRIVE = 'SELECT Id FROM sked_Drive__c WHERE sked_Drive_External_Id__c = null';
    
    @TestVisible
    private List<DriveBridgeAPI__x> drvExtObjList;
    @TestVisible
    private List<SiteBridgeAPI__x> sitExtObjList;

    global PopulateDriveandSiteExternalIDBatch(){}
    
	@TestVisible
    private PopulateDriveandSiteExternalIDBatch(Boolean forSite){
        this.forSite = forSite;
    }

    global PopulateDriveandSiteExternalIDBatch(Integer batchSize){
        this.batchSize = batchSize;
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        String query;
        if(this.forSite == true){
            query = QUERY_FOR_SITE;
        }else{
            query = QUERY_FOR_DRIVE;
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Sobject> scope){
        if(scope == null || scope.isEmpty()){
            return;
        }
        try{
            Set<Id> ids = new Set<Id>(new Map<Id, Sobject>(scope).keySet());
            Id idToProccess = new List<Id>(ids)[0];
            Schema.sObjectType entityType = idToProccess.getSObjectType();
            if(entityType == sked_Drive__c.sObjectType){
                doExecuteforDrives(ids);
            }else if(entityType == sked__Location__c.sObjectType){
                doExecuteforSites(ids);
            }
        }catch(Exception ex){
            System.debug(ex.getMessage()+ex.getLineNumber());
        }
    }

    global void execute(SchedulableContext cc) {
        PopulateDriveandSiteExternalIDBatch batchObject = new PopulateDriveandSiteExternalIDBatch();
        Database.executeBatch(batchObject,this.batchSize);
    }
    
    global void finish(Database.BatchableContext bc){
        if(!this.forSite){
            PopulateDriveandSiteExternalIDBatch batchObject = new PopulateDriveandSiteExternalIDBatch(true);
            Database.executeBatch(batchObject,this.batchSize);
        }
    }

    @TestVisible
    private void doExecuteforDrives(Set<Id> driveIds){
        List<sked_Drive__c> driveList = new List<sked_Drive__c>();
        if(driveIds == null || driveIds.isEmpty()){
            return;
        }
        try{
            List<DriveBridgeAPI__x> extObjList = [SELECT Id,external_id__c,guid__c FROM DriveBridgeAPI__x WHERE guid__c IN: driveIds];
            if(Test.isRunningTest()){
                extObjList = drvExtObjList;
            }
            for(DriveBridgeAPI__x obj : extObjList){
                if(String.isNotBlank(obj.external_id__c)){
                    driveList.add(new sked_Drive__c(Id = obj.guid__c, sked_Drive_External_Id__c = obj.external_id__c));
                }
            }
            if(!driveList.isEmpty()){
                Database.update(driveList,false);
            }
        }catch(Exception exp){
            System.debug(exp.getMessage()+exp.getLineNumber());
        }
    }
    @TestVisible
    private void doExecuteforSites(Set<Id> siteIds){
        List<sked__Location__c> siteList = new List<sked__Location__c>();
        if(siteIds == null || siteIds.isEmpty()){
            return;
        }
        try{
            List<SiteBridgeAPI__x> extObjList = [SELECT Id,external_id__c,guid__c FROM SiteBridgeAPI__x WHERE guid__c IN: siteIds];
            if(Test.isRunningTest()){
                extObjList = sitExtObjList;
            }
            for(SiteBridgeAPI__x obj : extObjList){
                if(String.isNotBlank(obj.external_id__c)){
                    siteList.add(new sked__Location__c(Id = obj.guid__c, Site_External_ID__c = obj.external_id__c));
                }
            }
            if(!siteList.isEmpty()){
                Database.update(siteList,false);
            }
        }catch(Exception exp){
            System.debug(exp.getMessage()+exp.getLineNumber());
        }
    }
}