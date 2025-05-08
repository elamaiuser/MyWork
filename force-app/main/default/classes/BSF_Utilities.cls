/*@Description:  This utility class contains several reusable methods which can be used across many other places.

 * ***************************************************************************************************************************************************************/

 /* Modification Log 
 * Date					     Developer Name			     Comments
  ********************************************************************************************************************************************************************
* 08/29/2023				 Balaji N				 Logic for HRP-10890(New Method: MetaDataupdate)  
* 10/03/2023                 Priti Jana              Logic for HRP-10115
* 03/12/2024				 Balaji N				 HRP-11375 Method: getJobCodeVsProfileMap,getProfileId, custom metadata changes, start query sked_FCC_Code__c filter
* 06/06/2024                 Priti Jana              Logic for HRP-12011
* 06/28/2024                 Balaji N                Logic for HRP-12054
* 09/18/2024				 Priti Jana				 Added an utility boolean to forcibly generate exceptions, especially during test class run (HRP-12706)
* 09/24/2024				 Fitsum Worku			 Fix for HRP-13435
* 10/18/2024				 Balaji N				 HRP-13489 Methods isWbFixedSiteOpportunity
* 12/10/2024				 Priti Jana				 Logic for HRP-13190
 *********************************************************************************************************************************************************************
*/

public with sharing class BSF_Utilities {
    
    private static Map<String, RecordType> recordTypeMap = null;
    public static Boolean IS_SET_TO_GENERATE_EXCEPTION = FALSE; //HRP-12706
    
    private static void populateRecordTypeMap() {
        recordTypeMap = new Map<String, RecordType>();
        RecordType[] rtList = [Select Id, sObjectType, Name From RecordType  ];
        for(RecordType rt : rtList) {
            recordTypeMap.put(rt.sObjectType + '|' + rt.Name, rt);
            recordTypeMap.put(rt.Id, rt);
        }
    } 
    
    private static RecordType getRecordType(String sobjectType, String recordtypeName) {
        if(recordTypeMap == null || recordTypeMap.size()==0) 
            populateRecordTypeMap();
        
        RecordType rt = recordTypeMap.get(sobjectType + '|' + recordtypeName);
        return (rt != null? rt:null);
    }
    
    public static Id getRecordTypeId(String sobjectType, String recordtypeName) 
    {
        RecordType rt = getRecordType(sobjectType, recordtypeName);
        return (rt != null? rt.Id:null);
    }
    
    public static String getRecordTypeName(Id recordtypeId) {
        if(recordTypeMap == null || recordTypeMap.size()==0)
            populateRecordTypeMap();
        
        RecordType rt = recordTypeMap.get(recordtypeId);
        return (rt != null? rt.Name:null);
    }
    
    public static Map<String,Set<String>> taxoTypeNodeMap = null;
    public static void populateTaxonomyNodes(){
        taxoTypeNodeMap = new Map<String,Set<String>>();
        
        taxoTypeNodeMap.put(BSF_Constants.BIO_COLLECTION_RECORD_TYPE,new Set<String>{});
        taxoTypeNodeMap.put(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','Team_Code__c','ABM_Code__c','DRD_Territory_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','Team_Code__c','ABM_Code__c','DRD_Territory_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','District_Code__c','Collection_Operation_Code__c','Portfolio_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','Portfolio_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','Portfolio_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE,new Set<String>{'Portfolio_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','Team_Code__c','Supervisor_Code__c','DRD_Territory_Code__c'});
        taxoTypeNodeMap.put(BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE,new Set<String>{'Division_Code__c','DS_Region_Code__c','Portfolio_Code__c'});
        
    }
    
    public static Set<String> getTaxonomyNodes(String taxonomyType){
        if(taxoTypeNodeMap == null || taxoTypeNodeMap.size() == 0){
            populateTaxonomyNodes();
        }
        
        return taxoTypeNodeMap.get(taxonomyType);
    }
    
    public static String getPortFolioType(String recordTypeName){
        if(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE == recordTypeName)
            return BSF_Constants.ACCOUNT_MANAGER;
        
        if(BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE == recordTypeName)
            return BSF_Constants.ACCOUNT_MANAGER;
        
        if(BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE == recordTypeName)
            return BSF_Constants.FIXED_SITE;
        
        if(BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE == recordTypeName)
            return BSF_Constants.SICKLE_CELL_ACCOUNT_MANAGER;
        
        if(BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE == recordTypeName)
            return BSF_Constants.RELATIONSHIP_MANAGER;
        
        if(BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE == recordTypeName)
            return BSF_Constants.NATIONAL_ACCOUNT_MANAGER;
        
        if(BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE == recordTypeName)
            return BSF_Constants.ACCOUNT_MANAGER;
        
        if(BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE ==recordTypeName)
            return BSF_Constants.Booking_Support;
        
        return null;
    } 
    
    public static Boolean isTerritoryPortfolio(String recordTypeName){
        if(recordTypeName == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE){
            return true;
        }else{
            return false;
        }
    }
    
    public static List<BSF_Error_Log__c> createErrorLog(Database.UpsertResult[] upsertResults,String processName,String className,String methodName,String typeValue,String errorDescription) 
    {
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        
        for(Database.UpsertResult result:upsertResults){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
                BSF_Error_Log__c log = new BSF_Error_Log__c(Process_Name__c =processName,ApexClass__c=className,Method__c=methodName,Type__c=typeValue,Error_Description__c=errorDescription);
                log.Error_Description_Long__c  = result.getErrors()[0].getMessage().length() > 2500?result.getErrors()[0].getMessage().subString(0,2500):result.getErrors()[0].getMessage();
                log.Error_Description_Long__c = log.Error_Description_Long__c+'ID: '+result.getId()+'  ERROR: '+result.getErrors();
                errorList.add(log);
            }
        }
		
         for(Database.upsertResult result:upsertResults) 
        {
         if(!result.isSuccess())
         {
             system.debug('ID: '+result.getId()+'  ERROR: '+result.getErrors()+'   CREATED: '+ result.isCreated());
         }
         
        }        
        return errorList;
    }
    
    public static List<BSF_Error_Log__c> createErrorLog(Database.SaveResult[] saveResults,String processName,String className,String methodName,String typeValue,String errorDescription) 
    {
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        
        for(Database.SaveResult result:saveResults){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
                BSF_Error_Log__c log = new BSF_Error_Log__c(Process_Name__c =processName,ApexClass__c=className,Method__c=methodName,Type__c=typeValue,Error_Description__c=errorDescription);
                log.Error_Description_Long__c  = result.getErrors()[0].getMessage().length() > 2500?result.getErrors()[0].getMessage().subString(0,2500):result.getErrors()[0].getMessage();
                log.Error_Description_Long__c = log.Error_Description_Long__c+'ID: '+result.getId()+'  ERROR: '+result.getErrors();
                errorList.add(log);
            }
        }
        
         for(Database.SaveResult result:saveResults) 
        {
         if(!result.isSuccess())
         {
             system.debug('ID: '+result.getId()+'  ERROR: '+result.getErrors()+'   CREATED: ');
         }
         
        }
        
        return errorList;
    }
    
    public static List<BSF_Error_Log__c> createErrorLog(Database.DeleteResult[] deleteResults,String processName,String className,String methodName,String typeValue,String errorDescription) 
    {
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        
        for(Database.DeleteResult result:deleteResults){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
                BSF_Error_Log__c log = new BSF_Error_Log__c(Process_Name__c =processName,ApexClass__c=className,Method__c=methodName,Type__c=typeValue,Error_Description__c=errorDescription);
                log.Error_Description_Long__c  = result.getErrors()[0].getMessage().length() > 2500?result.getErrors()[0].getMessage().subString(0,2500):result.getErrors()[0].getMessage();
                log.Error_Description_Long__c = log.Error_Description_Long__c+'ID: '+result.getId()+'  ERROR: '+result.getErrors();
                errorList.add(log);
            }
        }
        
         for(Database.DeleteResult result:deleteResults) 
        {
         if(!result.isSuccess())
         {
             system.debug('ID: '+result.getId()+'  ERROR: '+result.getErrors()+'   CREATED: ');
         }
         
        }
        
        return errorList;
    }
    public static List<BSF_Error_Log__c> getErrorLogs(String processName,String className,String methodName,String typeValue,String errorDescription, List<String> errors){
        List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
        for(String errorMsg:errors){
            logList.add(getErrorLog(processName,className,methodName,typeValue,errorDescription,errorMsg));
        }
        return logList;
    }
    
    public static BSF_Error_Log__c getErrorLog(String processName,String className,String methodName,String typeValue,String errorDescription, String errorMsg){
        BSF_Error_Log__c log = new BSF_Error_Log__c(Process_Name__c =processName,ApexClass__c=className,Method__c=methodName,Type__c=typeValue,Error_Description__c=errorDescription);
        if(errorMsg != null && !String.isBlank(errorMsg)){
            log.Error_Description_Long__c  = errorMsg.length() > 2500?errorMsg.subString(0,2500):errorMsg;    
        }
        return log;
    }
    
    public static List<BSF_Error_Log__c> platformSuccessLog(Set<string> idSet,String processName,String className,String methodName,String typeValue,String errorDescription)
    {
        
        string s;
        list<string>idList = new list<string>();
        for(String portId :idSet)
            {
                if(s==null)
                {
                    s=portId;
                }
                else
                {
                    s=s+'_'+portId;
                }
                if(s.length()>2400)
                    {
                        idList.add(s);
                        s=null;
                    }
            }
        if(s!=null)
        {
            idList.add(s);
        }
        List<BSF_Error_Log__c> pltfrmLogList = new List<BSF_Error_Log__c>();
        for(string ids :idList)
        {
               bsf_error_log__c pltfrmLog = BSF_Utilities.getErrorLog(processName,className,methodName,typeValue,errorDescription,ids);
 			   pltfrmLogList.add(pltfrmLog);
        }
        
        return pltfrmLogList;
    }

    // Works for EE.. formats - used in Publicity Task Batch to avoid tasks on weekends
    public static Date getTaskDueDate(Date inputDate , String desiredFormat)
    {
        String formattedDateString;
        Date dueDate;
        formattedDateString = Datetime.newInstance(inputDate.year(),inputDate.month(),inputDate.day()).format(desiredFormat);
        if(formattedDateString != '')
        {
            if(formattedDateString.startsWithIgnoreCase('Sa'))
            {
                dueDate = inputDate - 1;
            }else if(formattedDateString.startsWithIgnoreCase('Su'))
            {
                dueDate = inputDate - 2;
            }else {
                dueDate = inputDate;
            }
        }

        return dueDate;      
    }

    /* HRP-10115 --> Starts Here
        @ Description : Utility method to restrict non-admin users from deletion of records for the objects specified in the metadata
    */
    public static void restrictNonAdminUsersForSobjectDeletion(String objName , List<Sobject> oldItemsList)
    {

        // Quering the custom metadata 
        Admin_Profile_Setting__mdt adminProfileSetting = [SELECT Profile_Name__c, Error_Msg__c FROM Admin_Profile_Setting__mdt 
                                                          WHERE Object_Name__c = :objName
                                                          AND Change_Type__c = 'Delete'
                                                          AND Is_Checked__c = true 
                                                          LIMIT 1];

        List<String> adminProfileNames = adminProfileSetting.Profile_Name__c.split(',');

        Map<Id,Profile> adminProfileIdToNameMap = new Map<Id,Profile>([SELECT Id, Name FROM Profile WHERE Name IN :adminProfileNames]);
        
        if(!oldItemsList.isEmpty())
        {
            for(Sobject obj : oldItemsList)
            {
                // checking if the keyset of the map contains the profileId same as the logged-in user's profileId
                if(!adminProfileIdToNameMap.keyset().contains(UserInfo.getProfileId()))
                {
                    obj.addError(adminProfileSetting.Error_Msg__c);
                }
            }
        }
    }
    // HRP-10115 --> Ends Here
    
    //HRP-10890  starts
    public static BatchByPassSettings__mdt  metaDataupdate(Datetime startDate,Datetime endDate,Boolean byPass,string BatchName)
    {
        
        BatchByPassSettings__mdt batchBypass = [select id,DeveloperName,MasterLabel,Batch_Size__c,By_Pass_Batch__c,Manual_By_pass__c,End_DateTime__c,Start_Datetime__c from BatchByPassSettings__mdt where DeveloperName=:BatchName limit 1];
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'BatchByPassSettings__mdt.'+batchBypass.DeveloperName;
            customMetadata.label = batchBypass.MasterLabel;
            
        Boolean Updated=false;
        if(byPass!=null)
        {
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = 'By_Pass_Batch__c';
            customField.value = byPass;
            customMetadata.values.add(customField);
            Updated=true;
            batchBypass.By_Pass_Batch__c=byPass;
        }
        if(startDate!=null)
        {
            Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue();
            customField1.field = 'Start_Datetime__c';
            customField1.value = startDate;
            customMetadata.values.add(customField1);
            Updated=true;
        }
            if(endDate!=null)
        {
            Metadata.CustomMetadataValue customField2 = new Metadata.CustomMetadataValue();
            customField2.field = 'End_DateTime__c';
            customField2.value = endDate;
            customMetadata.values.add(customField2);
            Updated=true;
        }
        if(Updated)
        {
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);
            if(!Test.isRunningTest())
            Metadata.Operations.enqueueDeployment(mdContainer, null);
            
        }
        
        

            return batchBypass;
    }
    //HRP-10890  Ends
    /*
     * HRP-11375 starts here
    */
    public static List<String> getActivePicklistValues(Schema.sObjectField field) 
    {
        List<Schema.PicklistEntry> pickList = field.getDescribe().getPickListValues();
        List<String> activePickList = new List<String>();
        for (Schema.PicklistEntry value : pickList) 
        {
            if (value.isActive()) 
            {
                activePickList.add(value.getValue());
            }
        }
        return activePickList;
    }
    /*
     * HRP-11375 ends here
    */

    //HRP-12011 --> starts Here
    public static Boolean isWbFixedSiteOpportunity(Opportunity newOpp,sked__Location__c driveSite) //HRP-13489 2nd parameter driveSite
    {
        //Commented part of HRP-13489
        /*sked__Location__c driveSite = new sked__Location__c();
        if(newOpp.Drive_Site__c != NULL) {
            driveSite = [SELECT Id, Operation_Type__c FROM sked__Location__c WHERE ID = :newOpp.Drive_Site__c LIMIT 1]; 
        }*/
        return newOpp.Type_of_Drive__c.equalsIgnoreCase(Constants.FIX_SITE_OPP) && driveSite != NULL && driveSite.Operation_Type__c != NULL && driveSite.Operation_Type__c.equalsIgnoreCase(Constants.NON_INTEGRATED_WB_OPERATION_TYPE);
    }
    public static Boolean isMobileOpportunity(Opportunity newOpp) {
        return newOpp.Type_of_Drive__c != NULL && newOpp.Type_of_Drive__c.equalsIgnoreCase(Constants.MOBILE_SITE_OPP);
    }
    //HRP-12011 --> Ends Here
    //HRP-12054 start
    Public Static Map<String,Id> findSkedRegion(Set<String> collOpCodeSet,Set<String> zipCodeSet,List<Taxonomy__c> taxoList,List<sked_Site_Collection_Operation__c> siteCoList, Map<Id,Collections_Territory__c> collZipIdMap,Map<Id,sked__Location__c> siteIdMap)
    {
        Boolean isTaxNull;
        Map<String,Id> CollZipRegionMap = new Map<String,Id>();
        Map<String,Id> CollcodeRegionMap = new Map<String,Id>();
        
        Set<String> timeZoneSiteSet = new Set<String>();
        if((taxoList==null || taxoList.isEmpty()) && !siteCoList.isEmpty() && siteCoList!=null)
        {
            taxoList=[select Id,Collection_Operation_Code__c, End_Date__c, Start_Date__c, Zip_Code__c,Time_Zone__c from Taxonomy__c where Collection_Operation_Code__c IN:collOpCodeSet AND Zip_Code__c IN:zipCodeSet];
            isTaxNull=true;
            
            Map<String,List<Taxonomy__c>> collZipTaxoListMap = new Map<String,List<Taxonomy__c>>();
            for(Taxonomy__c tx:taxoList)
            {
                if(!collZipTaxoListMap.containsKey(tx.Collection_Operation_Code__c+'_'+tx.Zip_Code__c))
                    collZipTaxoListMap.put(tx.Collection_Operation_Code__c+'_'+tx.Zip_Code__c,new List<Taxonomy__c>()); 
                
                collZipTaxoListMap.get(tx.Collection_Operation_Code__c+'_'+tx.Zip_Code__c).add(tx);
            }
            List<Taxonomy__c> taxoListFiltered =new List<Taxonomy__c>();
            for(sked_Site_Collection_Operation__c siteCo : siteCoList)
            {
                Taxonomy__c filteredTax;
                String key =siteCo.sked_Collections_Zip_Code__c;
                if(collZipIdMap.containsKey(key))
                {
                    Key =collZipIdMap.get(siteCo.sked_Collections_Zip_Code__c).Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+collZipIdMap.get(siteCo.sked_Collections_Zip_Code__c).Zip__c;
                    if(collZipTaxoListMap.containsKey(Key))
                    {
                        for(Taxonomy__c tx :collZipTaxoListMap.get(Key))
                        {
                            if((filteredTax == null && tx.End_date__c >= siteCo.sked_End_Date__c) || (filteredTax!=null && filteredTax.End_Date__c < tx.End_date__c))
                            {
                                filteredTax=tx;
                            }
                        }
                        
                        if(filteredTax != null)
                        {
                            taxoListFiltered.add(filteredTax);
                        }
                        else
                        {
                            timeZoneSiteSet.add(siteIdMap.get(siteCo.sked_Site__c).sked_Timezone__c);
                        }
                    }
                }
            }
            taxoList.addAll(taxoListFiltered);
            
        }
        
        if(!taxoList.isEmpty())
        {
            Set<String> timeZoneSet = new Set<String>();
            for(Taxonomy__c tx: taxoList)
            {
                timeZoneSet.add(tx.Time_Zone__c);
            }
            
            for(sked__Region__c region :[SELECT Id, sked__Timezone__c,sked_Biomed_Collection_Op_Center__r.Biomed_Collection_Op_Code_Center_ID__c FROM sked__Region__c where sked_Biomed_Collection_Op_Center__r.Biomed_Collection_Op_Code_Center_ID__c IN:collOpCodeSet AND (sked__Timezone__c IN:timeZoneSet OR sked__Timezone__c IN:timeZoneSiteSet)])
            {
                CollcodeRegionMap.put(region.sked_Biomed_Collection_Op_Center__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+region.sked__Timezone__c,region.Id);
            }
            
            
            for(Taxonomy__c tx: taxoList)
            {
                CollZipRegionMap.put(tx.Collection_Operation_Code__c+'_'+tx.Zip_Code__c,CollcodeRegionMap.get(tx.Collection_Operation_Code__c+'_'+tx.Time_Zone__c));
            }
        }
        
        if(siteCoList != null && !siteCoList.isEmpty())
        {
            for(sked_Site_Collection_Operation__c siteCo : siteCoList)
            {
                if(collZipIdMap.containsKey(siteCo.sked_Collections_Zip_Code__c))
                {
                    String Key=collZipIdMap.get(siteCo.sked_Collections_Zip_Code__c).Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+collZipIdMap.get(siteCo.sked_Collections_Zip_Code__c).Zip__c;
                    String siteKey = collZipIdMap.get(siteCo.sked_Collections_Zip_Code__c).Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+siteIdMap.get(siteCo.sked_Site__c).sked_Timezone__c;
                    if(CollZipRegionMap.containsKey(Key))
                    {
                        siteCo.sked_Region__c=CollZipRegionMap.get(Key);
                    }
                    else if(CollcodeRegionMap.containsKey(siteKey))
                    {
                        siteCo.sked_Region__c=CollcodeRegionMap.get(siteKey);
                    }
                }
            }
        }
        
        
        return CollZipRegionMap;
    }
    //HRP-12054 End

    public static List<BSF_Error_Log__c> createErrorLogWithObjectId(Database.SaveResult[] saveResults, String processName, String className, String methodName, String typeValue, String functionality) {
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        for(Database.SaveResult result : saveResults) {
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0) {
                BSF_Error_Log__c log = new BSF_Error_Log__c(
                    Process_Name__c = processName, 
                    ApexClass__c = className,
                    Method__c = methodName,
                    Type__c = typeValue,
                    Functionality__c = functionality
                );
                log.Error_Description__c  = result.getErrors()[0].getMessage().length() > 255 ? result.getErrors()[0].getMessage().subString(0,255) : result.getErrors()[0].getMessage();
                log.Error_Description_Long__c = 'Error Details : \n'+result.getErrors()[0];
                log.Object_RecordId__c = result.getId();
                if(result.getId() != NULL) {
                    log.Object_Name__c = String.valueOf(result.getId().getSobjectType());
                }
                errorList.add(log);
            }
        } 
        return errorList;
    }

    public static BSF_Error_Log__c createBsfErrorLogForExceptions(
        Exception ex, 
        String className, 
        String methodName, 
        String processName,
        String functionality,
        String objectName,
        String objectRecordId
    ) {
        String errorDescription = 'Error Type - '+ex.getTypeName()+'\n'+ex.getMessage();
        BSF_Error_Log__c errorLog = new BSF_Error_Log__c(
            ApexClass__c = className,
            Method__c = methodName,
            Type__c = 'Error',
            Error_Description__c = errorDescription.length() > 255 ? errorDescription.subString(0, 255) : errorDescription,
            Error_Description_Long__c = 'Message : '+ex.getMessage()+'\nStackTracing : \n'+ex.getStackTraceString()+'\n'+'Specific Line Number :: '+ex.getLineNumber(),
            Process_Name__c = processName,
            Functionality__c = functionality,
            Object_Name__c = objectName,
            Object_RecordId__c = objectRecordId
        );
        return errorLog;
    }

    public static Set<ID> getSuccessfullySavedRecordIds(Database.SaveResult[] saveResults) {
        Set<ID> recordIds = new Set<ID>();
        for(Database.SaveResult result : saveResults) {
            if(result != null && result.isSuccess()) {
                recordIds.add(result.getId());
            }
        }
        return recordIds;
    }

    @AuraEnabled(cacheable = true)
    public static List<String> getActivePicklistValues(String objectApiName, String fieldApiName) {
        List<String> activePickList = new List<String>();

        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> map_fieldStringName_sObjectField = objDescribeSobject.fields.getMap();
        Schema.DescribeFieldResult fieldResult = map_fieldStringName_sObjectField.get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> pickList = fieldResult.getPickListValues();
        
        for (Schema.PicklistEntry value : pickList) {
            if (value.isActive()) {
                activePickList.add(value.getValue());
            }
        }
        return activePickList;
    }

    public static String createDriveQueryForCalendarBuild() {
        return 'SELECT Id, Is_Template__c, Name, Drive_Date__c, StageName, Drive_Designations__c, Rollover_Consideration__c, RecordTypeId, '+
                'Parent_Template_Id__c, Parent_Template_Id__r.name, drive_status__c, sked_Cancellation_Reason__c, '+
                'Accept_56_Day_Rule_Violation__c, Accepts_Automation__c, Drive_Site__c, Open_to_Public__c, '+
                'Anticipated_Registered_Donors__c,WB_Projected_Procedures__c, Double_Red_Projected_Units__c, Drive_Keyword__c, '+
                'Online_Scheduling_Enabled__c, Type_of_Drive__c, Start_Time__c, End_Time__c,AccountId, Account.Account_Strategy__c, '+
                'Account.Marketing_Strategy__c, Account.Account_Status__c, X2RBC_Projected_Procedures__c, Collection_Operation__c, Collections_Zip_Code__c, '+
                'Flow_Start_Time_Field__c, Flow_End_Time_Field__c, OwnerId, anticipated_registered_donors_template__c, WholeBloodProceduresProjectedTemplate__c, '+
                'Double_red_Procedures_Projected_template__c, AcceptblankMilitaryAuthNamePhone__c, From_Template_Id__c, '+
                'Number_of_2RBC_Assets__c, Number_of_Plasma_Assets__c, Number_of_Platelet_Assets__c,Direct_Donors_To__c, '+
                'No_Publicity_Needed__c, Publish_to_Call_Center__c, Web_Scheduling_Enabled__c, Send_Emails__c, Send_Mailers__c, '+
                'Web_Scheduling_End_Date_Offset__c, Web_Scheduling_End_Time_Offset__c, Web_Scheduling_Start_Date_Offset__c, Platelet_Projected_Procedures__c, '+
                'Plasma_Pheresis_Projected_Procedures__c, Calendar_Build_Parent_Opportunity__c, Type, DriveStatus__c, Slot_Generator__c, Related_Scheduled_Drive__c, '+ //HRP-12011 
                //'FROM Opportunity';
                'APT_Quantity__c, APT_Required__c, Booking_Strategy__c, Redcross_Volunteer_Required__c, Redcross_Volunteer_Quantity__c FROM Opportunity'; //Added APT fields HRP-13190; Added Volunteer fields HRP-13146
    }
    
    /* HRP-13190 -> Starts Here
     * @Description -> This method will calculate the APT Quantity based on action performed and Total procedures value
    */
    
    public static List<Opportunity> getAPTQuantity(List<Opportunity> oppList, String action) {
        Set<String> excludedAccindustryCodes = new Set<String>{BSF_Constants.ACCOUNT_INDUSTRY_CODE_MIDDLE_SCHOOL, BSF_Constants.ACCOUNT_INDUSTRY_CODE_ELEMENTARY_SCHOOL};
        Set<Id> accountIds = new Set<Id>();
        
        for(Opportunity opp : oppList) {
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Account> map_accountId_accountInfo = new Map<Id, Account>([SELECT Id, Industry_Code__c FROM Account WHERE ID IN: accountIds]);
        
        for(Opportunity opp : oppList) {
            Boolean isAptNotNeededRule1 = !String.isBlank(opp.Type_of_Drive__c) && opp.Type_of_Drive__c.equalsIgnoreCase(BSF_Constants.FIXED_SITE);
            Boolean isAptNotNeededRule2 = !String.isBlank(opp.Source__c) && opp.Source__c.equalsIgnoreCase(BSF_Constants.BATCH_CALENDAR_BUILD);
            if (isAptNotNeededRule1 || isAptNotNeededRule2) continue;
            Decimal aptQuantity = 0;
            if(!String.isBlank(opp.Account_Type__c) && opp.Account_Type__c.equalsIgnoreCase(BSF_Constants.ACCOUNT_TYPE_EDUCATION)) {
                if(map_accountId_accountInfo.get(opp.AccountId) != NULL && !String.isBlank(map_accountId_accountInfo.get(opp.AccountId).Industry_Code__c)) {
                    if(!excludedAccindustryCodes.contains(map_accountId_accountInfo.get(opp.AccountId).Industry_Code__c)) {
                        aptQuantity = Math.floor(opp.Total_Projected_Procedures__c / 40);
                    }
                }
            } else {
                if(opp.Total_Projected_Procedures__c >= 40) {
                    aptQuantity = 1;
                }
            }
            if(action == 'Insert') {
                if(opp.Is_Template__c || opp.Site_TBD__c) {
                    opp.APT_Quantity__c = aptQuantity;
                    opp.APT_Required__c = aptQuantity > 0 ? TRUE : FALSE;
                }
            } else {
                opp.APT_Quantity__c = aptQuantity == 0 && opp.APT_Required__c ? 1 : aptQuantity;
                opp.APT_Required__c = opp.APT_Required__c || aptQuantity > 0;
                opp.APT_Change_Reason__c = (opp.Is_Template__c ? 'Template' : 'Opportunity') + ' APT changed by ' + userInfo.getName() + ' on '+system.now();
            }
        }
        return oppList;
    }
    //HRP-13190 -> Ends Here

    public static String capitalizeName(String unformatedName, Boolean isForPDF){
        String formatedName = '';        
        if(String.isNotBlank(unformatedName)){
            List<String> words = unformatedName.split(' ');
            for(String word : words){
                if(String.isNotBlank(word)){
                    if(String.isNotBlank(formatedName)){
                        String lastChar = formatedName.substring(formatedName.length()-1);
                        if(lastChar != ' '){
                            formatedName += ' ';
                        }
                    }
                    if(!word.isNumeric()){
                        Integer str_len = word.length();
                        word = word.left(1).toUpperCase() + word.right(str_len - 1).toLowerCase();
                    }
                    if(isForPDF){
                        formatedName += String.join(getTextParts(word,Integer.valueOf(Custom_Report_Config__mdt.getInstance('RoleTimeReportCharacterSplit').Value__c)),' ');
                    }
                    else {
                        formatedName += word;
                    }
                }
            }
            formatedName = formatedName.trim(); 
        } 
        return formatedName;
    }
    public static List<String> getTextParts(String text, Integer partitionSize) {
        List<String> parts = new List<String>();
        Integer len = text.length();
        for (Integer i=0; i<len; i+=partitionSize)
        {
            parts.add(text.substring(i, Math.min(len, i + partitionSize)));
        }
        return parts;
    }

    public static String getStringWithinLimit(String text, Integer charLimit) {
        return (text != NULL && String.isNotBlank(text) && text.length() > charLimit) ? text.subString(0, charLimit) : (text == NULL ? '' : text);
    }
}