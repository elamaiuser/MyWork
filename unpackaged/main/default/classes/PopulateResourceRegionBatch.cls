/**
* @description: This Scheduler Batch class is used to Populate Collection opration Region on staff Resources based on zip code.
**   Modification Log  ****
*  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 07/22/2023			Barnojit Sharma			The batch will use the satellite address to find collection operations for resources where the work address is unavailable. (HRP-10504)
 * 07/22/2023			Barnojit Sharma			If no collection operations are found with the zipcode, the batch will update Skedulo Region as a primary region of the resource. (HRP-10504)
 * 09/26/2023			Krapy Tuli 			    Utilize Mapping from Custom Metadata to assign region to resources where CO has been renamed (HRP-11049)
 * 10/13/2023			Barnojit Sharma			Email Notification while resource has No Timezone/CO due to no matching Work/Satellite Zip Code. (HRP-10217)
********************************************************************************************************************************************************************************************
*/ 
global class PopulateResourceRegionBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable {
    /*
	* HRP-10504 Changes starts here 
	*/
    public Map<Datetime, List<sked__Resource__c>> updatedDateVsResourceMap = new Map<Datetime, List<sked__Resource__c>>();
    public String query = 'SELECT Id, Name, sked_Timezone__c, sked_Home_Zip_Code__c, sked_Work_Zip_Code__c, sked_Satellite_Zip_Code__c, sked_Biomed_Collection_Op_Center_Name__c,'
                            +' sked__Primary_Region__c, LastModifiedDate, RecordTypeId, RecordType.Name FROM sked__Resource__c';
    public String whereClause =' WHERE sked__Is_Active__c = true AND sked__Resource_Type__c = \'Person\' AND RecordType.Name = \'Staff\'';
    public Boolean runUserBatch = true;
    global PopulateResourceRegionBatch() {
        query = query + whereClause;
    }
    global PopulateResourceRegionBatch(List<String> ids, Boolean runNextBatch){
		query = query + ' WHERE Id IN (\''+string.join(ids,'\',\'')+'\')';
        this.runUserBatch = runNextBatch;
	}

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    /*
	* HRP-10504 Changes ends here 
	*/
    global void execute(Database.BatchableContext BC, List<sked__Resource__c> resources) {
        Set<string> collectionOperationNames = new Set<string>();
        Set<String> workZipCodeList = new Set<String>();
        Set<String> homeZipCodeList = new Set<String>();
        Map<Id,String> zipCodeList = new Map<Id,String>();
        List<Taxonomy__c> taxonomyList = new List<Taxonomy__c>();
        Map<string,Taxonomy__c> taxonomyZipMap = new Map<string,Taxonomy__c>();
        List<string> resTimezone = new List<string>();
        List<sked__Resource__c> resourcesToUpdate = new List<sked__Resource__c>();
        sked__Region__c defaultRegion = getDefaultCollOpp();
        for (sked__Resource__c resource : resources) {
            try{
                if(!String.isBlank(resource.sked_Work_Zip_Code__c)){
                    zipCodeList.put(resource.Id, resource.sked_Work_Zip_Code__c.left(5));
                }
                /*
                * HRP-10504 Changes starts here 
                */
                else if (!String.isBlank(resource.sked_Satellite_Zip_Code__c)) {
                    zipCodeList.put(resource.Id, resource.sked_Satellite_Zip_Code__c.left(5));
                } 
                /*
                * HRP-10504 Changes ends here 
                */
                /**else if (!String.isBlank(resource.sked_Home_Zip_Code__c)) {
                    zipCodeList.put(resource.Id, resource.sked_Home_Zip_Code__c.left(5));
                }**/
            }catch(Exception ex){
                continue;
            }
        }
        
        taxonomyList = [SELECT Id,
                        		Collection_Operation_Name__c,
                        		Time_Zone__c,
                        		Zip_Code__c 
                        FROM Taxonomy__c 
                        WHERE Zip_Code__c IN: zipCodeList.values()
                        AND Collection_Operation_Name__c != null 
                        AND Start_Date__c <= TODAY 
                        AND End_Date__c >= TODAY 
                        AND Type__c = 'Bio Collection BSF' LIMIT 10000];  
        
        /* HRP-11049 Start */
        Map<String, String> taxoRegionMapping = new Map<String, String>();
        List<Taxonomy_Region_CO_Mapping__mdt > coMappings = [SELECT Id, New_Value__c, Old_Value__c from Taxonomy_Region_CO_Mapping__mdt Where Active__c = true];
        if (!coMappings.isEmpty()) {
           	for(Taxonomy_Region_CO_Mapping__mdt coMapping : coMappings){
                taxoRegionMapping.put(coMapping.Old_Value__c, coMapping.New_Value__c);
            } 
        }
        
        /* HRP-11049 End */
        if(!taxonomyList.isEmpty()){
            for(Taxonomy__c taxo : taxonomyList){
                /* HRP-11049 Start */
                if (taxoRegionMapping.containsKey(taxo.Collection_Operation_Name__c)) {
					taxo.Collection_Operation_Name__c = taxoRegionMapping.get(taxo.Collection_Operation_Name__c);
                }
                /* HRP-11049 End */
                collectionOperationNames.add(taxo.Collection_Operation_Name__c);
                resTimezone.add(taxo.Time_Zone__c);
                taxonomyZipMap.put(taxo.Zip_Code__c,taxo);
            }
        }
        
        List<sked__Region__c> regionList = new List<sked__Region__c>();
        
        if(collectionOperationNames != null && resTimezone != null){
            regionList = [SELECT Id, 
                          		Name,
                          		sked__Timezone__c, 
                          		sked_Biomed_Collection_Op_Center__r.Name, 
                          		sked_Biomed_Collection_Op_Center__r.Id 
                          FROM sked__Region__c 
                          WHERE sked_Biomed_Collection_Op_Center__r.Name IN :collectionOperationNames 
                          AND sked__Timezone__c IN :resTimezone];
        }
        
        if(!taxonomyZipMap.isEmpty()) {
            Map<string, sked__Region__c> mapRegion = new Map<string, sked__Region__c>();
            for (sked__Region__c region : regionList) {
                
                string key = region.sked_Biomed_Collection_Op_Center__r.Name + ':' + region.sked__Timezone__c;
                
                mapRegion.put(key, region);
            } 
            for (sked__Resource__c resource : resources) {
                Boolean resIsChanged = false;
                Taxonomy__c taxoForResource = null;
                string zipCodeForResource = '';
                if(zipCodeList.ContainsKey(resource.id)){
                    zipCodeForResource = zipCodeList.get(resource.id);
                }
                
                if(!string.IsBlank(zipCodeForResource) && taxonomyZipMap.ContainsKey(zipCodeForResource)) {
                    taxoForResource = taxonomyZipMap.get(zipCodeForResource);
                }
                
                if(taxoForResource != null)	{
                    if(resource.sked_Timezone__c != null && resource.sked_Timezone__c != taxoForResource.Time_Zone__c){
                        resource.sked_Timezone__c = taxoForResource.Time_Zone__c;
                        resIsChanged = true;
                    }else if(resource.sked_Timezone__c == null){
                        resource.sked_Timezone__c = taxoForResource.Time_Zone__c;
                        resIsChanged = true;
                    }
                    string key = taxoForResource.Collection_Operation_Name__c + ':' + taxoForResource.Time_Zone__c;
                    if (mapRegion.containsKey(key)) {
                        sked__Region__c region = mapRegion.get(key);
                        if(resource.sked__Primary_Region__c != null && resource.sked__Primary_Region__c != region.Id){
                            resource.sked__Primary_Region__c = region.Id;
                            resIsChanged = true;
                        }else if(resource.sked__Primary_Region__c == null){
                            resource.sked__Primary_Region__c = region.Id;
                            resIsChanged = true;
                        }							
                    }else{
                        resource.sked__Primary_Region__c = defaultRegion.Id;
                        resIsChanged = true;
                    }
                    if(resIsChanged){
                        resourcesToUpdate.add(resource);//changes for HRP-10217
                    }
                }
                /*
                * HRP-10504 Changes starts here 
                */
                else{
                    resource.sked_Timezone__c = defaultRegion.sked__Timezone__c;
                    resource.sked__Primary_Region__c = defaultRegion.Id;
                    resourcesToUpdate.add(resource);
                }
                if((resource.sked__Primary_Region__c == defaultRegion.Id) || String.isBlank(resource.sked_Timezone__c)){
                    this.addMap(resource);
                }
            }
        }else{
            for (sked__Resource__c resource : resources) {
                
                resource.sked_Timezone__c = defaultRegion.sked__Timezone__c;
                resource.sked__Primary_Region__c = defaultRegion.Id;
                resourcesToUpdate.add(resource);
                
                this.addMap(resource);//changes for HRP-10217
            }
        }
        /*
        * HRP-10504 Changes ends here 
        */
        if (!resourcesToUpdate.isEmpty()) {
            Database.SaveResult[] lsr = Database.update(resourcesToUpdate, false);
            BSF_Utilities.createErrorLog(lsr,'','PopulateResourceRegionBatch','execute','Error','Error Updating Primary Region and Timezone for Staff Resources');
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if(!Test.isRunningTest() && this.runUserBatch == true){
        	Database.executeBatch(new ResourceUserAllocationBatch());
        }
        /*
        * HRP-10217 Changes starts here 
        */
        
        if(!this.updatedDateVsResourceMap.isEmpty()) {
            this.sendEmail(updatedDateVsResourceMap);
        }
        /*
        * HRP-10217 Changes ends here 
        */
    }
    global void execute(SchedulableContext sc) {
        Id populateResourceId  = Database.executeBatch(new PopulateResourceRegionBatch());
    }
	/*
	* HRP-10504 Changes starts here 
	*/
    public static sked__Region__c getDefaultCollOpp(){
        return [SELECT Id, 
                		Name,
                		sked__Timezone__c, 
                		sked_Biomed_Collection_Op_Center__r.Name, 
                		sked_Biomed_Collection_Op_Center__r.Id 
               	FROM sked__Region__c 
                WHERE Name =:System.label.Default_Primary_Region_Name LIMIT 1];
    }
    /*
	* HRP-10504 Changes ends here 
	*/
    /*
	* HRP-10217 Changes starts here 
	*/
    public void sendEmail(Map<Datetime, List<sked__Resource__c>> resourceMap){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        final Integer noOfResourceToSent = Integer.valueof(System.label.MAX_NO_Of_Resource_To_Sent);
        String lightningUrl = System.URL.getOrgDomainUrl().toExternalForm()+System.label.No_Collection_Operation_Filter_Link;
        Integer noOfResource = 0;
        String emailBodyTable = '<html><table border="1" cellpadding="4" cellspacing="0"><thead><tr><th>Resource Id</th>'
                                +'<th>Resource Name</th><th>Work ZIP Code</th><th>Satellite ZIP Code</th></tr></thead><tbody>';

        if(resourceMap == null || resourceMap.size() == 0){
            return;
        }

        List<Datetime> keySetList = new List<Datetime>(resourceMap.keySet());
        keySetList.sort();

        for(Integer i = keySetList.size() - 1 ; i >= 0; i--){
            Datetime dt = keySetList.get(i);
            emailBodyTable = this.setEmailBody(resourceMap.get(dt),emailBodyTable,noOfResourceToSent - noOfResource);
            noOfResource = noOfResource + resourceMap.get(dt).size();
        }

        emailBodyTable = emailBodyTable + '</tbody></table>';
        Integer noOfResourceSent = noOfResourceToSent > noOfResource ? noOfResource : noOfResourceToSent;
        String emailHeader = 'Hi,<p>Timezones or collection operations are not available for '+noOfResource
                                +' resources, of which the top '+noOfResourceSent+' are as follows:</p><br>';
        String emailFooter =  '<br>Please click on the following link to view the complete list: '
                                +'<a href="'+lightningUrl+'">Visit No Collection Operation List</a><br>';
        
        String emailBody = '<html>'+emailHeader+emailBodyTable+emailFooter+'</html>';
        if(String.isNotBlank(label.RESOURCE_NOTIFICATION_SENDER_EMAIL)){
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: label.RESOURCE_NOTIFICATION_SENDER_EMAIL ];
            if (owea.size()>0) {
                message.setOrgWideEmailAddressId(owea.get(0).Id);
            }
        }
        
        message.toAddresses = System.label.BSF_SUPPORT_EMAIL_ID.split(',');
        message.optOutPolicy = 'FILTER';
        message.subject = 'Timezone/collection operation are blank for the following resources';
        message.setHtmlBody(emailBody);
        Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
    public String setEmailBody(List<sked__Resource__c> resourceList, String emailBody, Integer counter){
        if(resourceList.size() == 0 || counter <= 0){
            return emailBody;
        }

        for(sked__Resource__c resource : resourceList){
            if(counter > 0){
                String workZip = resource.sked_Work_Zip_Code__c == null ? '' : resource.sked_Work_Zip_Code__c;
                String satelliteZip = resource.sked_Satellite_Zip_Code__c == null ? '' : resource.sked_Satellite_Zip_Code__c;
                emailBody = emailBody + '<tr><td>'+resource.Id+'</td><td>'+resource.Name+'</td><td>'+workZip
                                        +'</td><td>'+satelliteZip+'</td></tr>';
                counter--;
            }
        }
        return emailBody;
    }
    public void addMap(sked__Resource__c resource){
        if(resource == null){
            return;
        }
        Datetime filterDT = System.now(); //resource.LastModifiedDate;
        if(this.updatedDateVsResourceMap.isEmpty() || !this.updatedDateVsResourceMap.containsKey(filterDT)){
            this.updatedDateVsResourceMap.put(filterDT, new List<sked__Resource__c>());
        }
        this.updatedDateVsResourceMap.get(filterDT).add(resource);
    }
    /*
	* HRP-10217 Changes ends here 
	*/
}