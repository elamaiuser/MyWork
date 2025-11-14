/**
* ***************************************************************************************************************************************************************************
* @Description: This class is used to clone Drive Affiliation records from Opportunity Template to Blood Drive Opportunity
* ***************************************************************************************************************************************************************************
* @developer         Barnojit Sharma
* @version        1.0
* @created        06/19/2023
* ***************************************************************************************************************************************************************************
* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 06/19/2023			Barnojit Sharma			Creation of Drive Affiliation is moved from Batch apex to Platform event-driven process (Logic for HRP-10204)
* ***************************************************************************************************************************************************************************
**/
public without sharing class DriveAffiliationHandler{
    
    //private class variable declarations
    private Boolean createViaEvent;
    private Map<String,String> templateMap;
    private List<Opportunity> oppList;
    private List<Clone_Drive_Affiliations_Event__e> eventList;
    private Map<String, List<Drive_Marketing_Programs__c>> driveAffiliationMap;
    private Clone_Drive_Affiliations_Event__e event;

    //private constructor to prevent creating instances when there are no getInstance() methods call
    private DriveAffiliationHandler(List<Opportunity> Opportunities, List<Clone_Drive_Affiliations_Event__e> events, Boolean viaPlatformEvent){
        oppList = Opportunities;
        eventList = events;
        createViaEvent = viaPlatformEvent == null 
                         ? true // createViaEvent is default true
                         : viaPlatformEvent;
    }

    //The getInstance() method is a static method that returns an instance of the DriveAffiliationHandler class 
    public static DriveAffiliationHandler getInstance(List<Opportunity> newOppList, Boolean viaPlatformEvent){
        return new DriveAffiliationHandler(newOppList,null,viaPlatformEvent);
    }
    public static DriveAffiliationHandler getInstance(List<Clone_Drive_Affiliations_Event__e> events){
        return new DriveAffiliationHandler(null,events,null);
    }

    //The run() method is the only public method for this class to initiate the Drive Affiliations creation process
    public void run(){
        
        if(oppList != null) {
        system.debug('inside DriveAffiliationHandler ');
                createAffiliations();
        }
        else if(eventList != null)
                processEvents();
    }

    //Listed below are the private methods of this class which continues different oparations for the Drive Affiliations creation process
    @TestVisible
    private void createAffiliations(){
		system.debug('inside DriveAffiliationHandler: createAffiliations');
        getTemplateMap();
        system.debug('inside DriveAffiliationHandler: getTemplateMap '+templateMap);
        if(createViaEvent){
            system.debug('inside DriveAffiliationHandler:createViaEvent : true ');
                createEvents();
        }else{
            system.debug('inside DriveAffiliationHandler:createViaEvent : false ');
                getDriveAffiliations();
                insertAffiliations();
        }
    }

    @TestVisible
    private void processEvents(){
        getTemplateMap();
        getDriveAffiliations();
        insertAffiliations();
    }

    @TestVisible
    private void createEvents(){
        system.debug('inside DriveAffiliationHandler:  createEvents');
        eventList = new List<Clone_Drive_Affiliations_Event__e>();

        for(String oppId                    :                   templateMap.keySet()){
                   event                    =                   new Clone_Drive_Affiliations_Event__e(
                   Opportunity_Id__c        =                   oppId,
                   Template_Id__c           =                   templateMap.get(oppId)
            );
            eventList.add(event);
        }
        system.debug('inside DriveAffiliationHandler eventList '+eventList);
        if(!eventList.isEmpty()){
            List<Database.SaveResult> results = EventBus.publish(eventList);
        }
    }

    @TestVisible
    private Drive_Marketing_Programs__c cloneDriveAffiliation(String oppId, Drive_Marketing_Programs__c affiliation){

        //This method has four Boolean type optional parameters : clone(preserveId, isDeepClone, preserveReadonlyTimestamps, preserveAutonumber)
        Drive_Marketing_Programs__c newAffiliation          =                   affiliation.clone(false,true,false,false);
        newAffiliation.Migration_ID__c                      =                   null;
        newAffiliation.Blood_Drive_Opportunity__c           =                   oppId;

        return newAffiliation;
    }

    @TestVisible
    private List<Drive_Marketing_Programs__c> cloneDriveAffiliation(String oppId){
        system.debug('inside DriveAffiliationHandler: cloneDriveAffiliation '+oppId+' and driveAffiliationMap '+driveAffiliationMap);
        List<Drive_Marketing_Programs__c> affiliationList = new List<Drive_Marketing_Programs__c>();
        if(driveAffiliationMap.get(templateMap.get(oppId)) != NULL) {
            for(Drive_Marketing_Programs__c affiliation : driveAffiliationMap.get(templateMap.get(oppId)))
                affiliationList.add(cloneDriveAffiliation(oppId,affiliation));
        }   
        return affiliationList;
    }

    @TestVisible
    private void getDriveAffiliations(){
        driveAffiliationMap = new Map<String, List<Drive_Marketing_Programs__c>>();

        //SOQL to get active Drive Affiliation records that are associated with the opportunity templates
        List<Drive_Marketing_Programs__c> driveAffiliationList = [SELECT Id,
                                                                        Blood_Drive_Opportunity__c, 
                                                                        Account__c, 
                                                                        Assigned_By__c, 
                                                                        Booking_End_Date__c, 
                                                                        Date_Assigned__c, 
                                                                        Date_Removed__c, 
                                                                        End_Date__c,
                                                                        Name, 
                                                                        IsActive__c, 
                                                                        Marketing_Program__c, 
                                                                        Removed_By__c, 
                                                                        Start_Date__c,
                                                                        LastViewedDate,
                                                                        Lastactivitydate 
                                                                    FROM Drive_Marketing_Programs__c
                                                                    WHERE Marketing_Program__r.is_active__c = true 
                                                                    AND blood_drive_opportunity__c IN :templateMap.values()];

        for(Drive_Marketing_Programs__c affiliation : driveAffiliationList){
            if(!driveAffiliationMap.containsKey(affiliation.blood_drive_opportunity__c))
                    driveAffiliationMap.put(affiliation.blood_drive_opportunity__c,new List<Drive_Marketing_Programs__c>());
                driveAffiliationMap.get(affiliation.blood_drive_opportunity__c).add(affiliation);
        }
    }

    @TestVisible
    private void insertAffiliations(){
        system.debug('inside DriveAffiliationHandler : insertAffiliations ');
        List<Drive_Marketing_Programs__c> newDriveAffiliationList = new List<Drive_Marketing_Programs__c>();

        for(String oppId : templateMap.keySet()) {
            
                newDriveAffiliationList.addAll(cloneDriveAffiliation(oppId));
        }
        system.debug('inside DriveAffiliationHandler : insertAffiliations '+newDriveAffiliationList);
        if(!newDriveAffiliationList.isEmpty())
                List<Database.SaveResult> results = Database.insert(newDriveAffiliationList,false);
    }

    @TestVisible
    private void getTemplateMap(){
        templateMap = new Map<String,String>();
        
        //populate templateMap (opportunity Id vs template Id) from opportunity List
        if(oppList != null){
            for(Opportunity opp : oppList){
                if(opp.Parent_Template_Id__c != null && !opp.Is_Template__c){
                            templateMap.put(opp.Id,opp.Parent_Template_Id__c);
                }
            }
        }
        //populate templateMap (opportunity Id vs template Id) from platfrom event
        else if(eventList != null){
            for(Clone_Drive_Affiliations_Event__e evnt : eventList){
                if(String.isNotBlank(evnt.Opportunity_Id__c) && String.isNotBlank(evnt.Template_Id__c)){
                            templateMap.put(evnt.Opportunity_Id__c,evnt.Template_Id__c);
                }
            }
        }

    }
}