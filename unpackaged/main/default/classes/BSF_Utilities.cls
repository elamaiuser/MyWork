/*@Description:  This utility class contains several reusable methods which can be used across many other places.

 * ***************************************************************************************************************************************************************/

 /* Modification Log 
 * Date					     Developer Name			     Comments
  ********************************************************************************************************************************************************************
* 08/29/2023				 Balaji N				 Logic for HRP-10890(New Method: MetaDataupdate)  
* 10/03/2023                 Priti Jana              Logic for HRP-10115
 *********************************************************************************************************************************************************************
*/

public with sharing class BSF_Utilities {
    
    private static Map<String, RecordType> recordTypeMap = null;
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
}