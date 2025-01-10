/* Description:
 * This class is the controller behind Apply changes to future drives Quick action from Template Opportunity 
 * The quick action is used to pass selected values from template to selected future drives
 * Related Components - Aura- ApplychangestoDrives,LWC-filterDriveContainer,AppliedFieldSelecetion,FilteredDriveTable
 * 
 * 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 05/10/2023				  Balaji N					 Logic for HRP-10083 (Method:applyChangestoFutureDrives,BSF Error Log)
 * 06/13/2024				  Apurba Bhattacharjee		 Logic for HRP-4878
 * 06/08/2024				  Raktim Ghosal			  	 Publicity Material Ordering at template level(HRP-12664) 
 * 09/12/2024				  Priti Jana			     Logic for HRP-13275, 13367
 * 10/28/2024				  Barnojit Sharma			 Template Order products not cascading to Opportunity Order. (Logic for HRP-13521)
 * 11/13/2024				  Barnojit Sharma		     Unable to create Mobile Drive when the Template has an over-budget template order (Logic for HRP-13716)
 *****************************************************************************
*/
public with sharing class FutureDrivesController {
    @AuraEnabled
    public static List<FieldSetClass> getFieldsFromFieldSets(){
        List<FieldSetClass> fdlist = new List<FieldSetClass>();
        try {
            FieldSetClass fdset;
            for( Schema.FieldSetMember f : Schema.SObjectType.Opportunity.fieldSets.FieldsApplytoDrives.getFields() ){
                fdset = new FieldSetClass();
                fdset.fieldapiname = f.getFieldPath() ; 
                fdset.fieldlabel = f.getLabel() ;
                fdlist.add( fdset );
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return fdlist ;
    }
    @AuraEnabled
    public static List<FutureDriveClass> getFutureDrives( String recordid ){
        List<FutureDriveClass> FutureDriveClassList = new List<FutureDriveClass>();
        FutureDriveClass fd;
        try {
            Date currentDate = System.Today();
            List<Opportunity> opprecord = new List<Opportunity>();
            String parentTemplateId;
            Date driveDate ;
            opprecord = [select Id, Parent_Template_Id__c, Drive_Date__c from Opportunity where Id =: recordid  ];
            parentTemplateId = opprecord[0].Parent_Template_Id__c;
            driveDate = opprecord[0].Drive_Date__c;
            List<Opportunity> opplist = new List<Opportunity>();
            opplist = [ select Id, Name, StageName, DriveStatus__c, Drive_Date__c, Drive_Site__r.Name
                       from Opportunity
                       where Parent_Template_Id__c =:recordid and
                       is_template__c = false and
                       Drive_Date__c > : currentDate  ];
            if( !opplist.isEmpty() ){
                for( Opportunity opp : opplist ){
                    fd = new FutureDriveClass();
                    fd.drivenanme = opp.Name ;
                    fd.driveid = opp.Id ;
                    fd.drivestage = opp.StageName ;
                    fd.drivestatus = opp.DriveStatus__c ;
                    fd.drivedate = String.valueOf(opp.Drive_Date__c);
                    fd.drivesite = opp.Drive_Site__r.Name ;
                    fd.isselected = false ;
                    FutureDriveClassList.add( fd );
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return FutureDriveClassList;
    }

    @AuraEnabled
    public static string applyChangestoFutureDrives(String FutureDriveClass, String recordid, List<String> fields ){
        List<String> driveidset = new List<String>();
        try {
            List<FutureDriveClass> fslist = (List<FutureDriveClass>)JSON.deserialize( FutureDriveClass, List<FutureDriveClass>.class );
            for( FutureDriveClass fd: fslist ){
                if( fd.driveid != null && fd.isselected == true ){
                    driveidset.add( fd.driveid );
                }
            }
            if(!driveidset.isEmpty()){   
                Integer batchSize = Integer.valueOf(Custom_Messages__mdt.getInstance('BatchSizeFor_BSF_BatchFutureDriveUpdate').Value__c);
                DataBase.executeBatch(new BSF_BatchFutureDriveUpdate(driveidset,recordid,fields),batchSize);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return 'success';
    }
    public static void applyChangestoFutureDrives(List<String> driveidset, String recordid, List<String> fields ){
        try {
            String driverecordid = recordid;
            String fieldstoberetrieved = '';
            boolean isDriveAffiliationFound = false;
            boolean isDriveServiceRolesFound = false;
            boolean isWebschedulingSettingsFound = false;
            boolean isTemplateOrderFound = false;
            List<String> fields2 = new List<String>();
            List<String> fieldSetFields = new List<String>();
            //List<String> driveidset = new List<String>();//HRP-13521
            List<Opportunity> updateopplist = new List<Opportunity>();
            List<Opportunity> sourceopplist = new List<Opportunity>();
            Map<Id, Opportunity> sourceopp = new Map<Id, Opportunity>();
            Map<Id, Opportunity> targetopp = new Map<Id, Opportunity>();
            GlobalWebSchedulingSettings__mdt globalWebSchedulingSettings = GlobalWebSchedulingSettings__mdt.getInstance('MobileDriveSettings'); //added for HRP-4878              
            //set of mandatory fields in case of webschedule date updates in functionality
            Set<String> webSchedulingFields = new Set<String>{'End_Time__c','Web_Schedule_Start_Time__c','Web_Schedule_EndDate__c', 'Web_Schedule_StartDate__c',
                                                            'TimeZone__c','Web_Schedule_Start_Date__c','Web_Schedule_End_Date__c','Web_Schedule_End_Time__c','Web_Sched_Offset_from_CO_Global_Settings__c'}; //added for HRP-4878  
            /*List<FutureDriveClass> fslist = (List<FutureDriveClass>)JSON.deserialize( FutureDriveClass, List<FutureDriveClass>.class );
            for( FutureDriveClass fd: fslist ){
                if( fd.driveid != null && fd.isselected == true ){
                    driveidset.add( fd.driveid );
                }
            }*/
            
            for(FieldSetClass fdset : getFieldsFromFieldSets()){
                fieldSetFields.add(fdset.fieldapiname);
            }
            for( String str : fields ){
                if(str.equalsIgnoreCase('Template Order')){
                    isTemplateOrderFound = true;
                }
                if(str.equalsIgnoreCase('Drive Affiliations')){
                    isDriveAffiliationFound = true;
                }
                if(str.equalsIgnoreCase('Drive Service Roles')){
                    isDriveServiceRolesFound = true;
                }
                if(str.equalsIgnoreCase('Web Scheduling Settings')){
                    isWebschedulingSettingsFound = true;
                }
                if((!str.contains('Drive Affiliations'))&&(!str.contains('Drive Service Roles')) &&(!str.contains('Web Scheduling Settings')) && (!str.contains('Template Order'))){
                    fields2.add(str);
                }
            }
            System.debug('fields2:'+fields2);

			//HRP-10083 Start
			if(boolean.valueof(system.label.HRP_10083ByPassLabel) || test.isRunningTest())
            {
            List<BSF_Error_Log__c> logList = new List<BSF_Error_Log__c>();
            logList.add(BSF_Utilities.getErrorLog('Apply future chnages to Drives','Future Drives Controller','applyChangestoFutureDrives','Debug Log','ParentTemplateid:'+recordid+'__Selected Fields'+fields+'__Date & Time'+system.today(),'Future Fields'));
            InsertBsfErrorLog.insertBsfErrors(logList);
            }
            //HRP-10083 End
            // HRP-4878 --> Start
            set<string>fieldsNeeded=new set<string>(); 
            fieldsNeeded.addAll(fields2);
            if(isWebschedulingSettingsFound)
                fieldsNeeded.addAll(webSchedulingFields);
            // HRP-4878 --> End
            for( String str : fieldsNeeded ){
                if(fieldstoberetrieved==''){
                    fieldstoberetrieved = str;
                }
                else{
                    fieldstoberetrieved = fieldstoberetrieved + ',' + str;
                }
            }
            fieldstoberetrieved = fieldstoberetrieved.replaceAll('null,', '');
            String[] fieldsarray;
            fieldsarray = fieldstoberetrieved.split( ',');
            system.debug('fieldsarray '+fieldsarray);
            fieldsarray.sort();// sorted so that webschedule fields comes last
            String sourcequery = '';
            if(fieldstoberetrieved.length()>0){
                //quering offset fields for calculation of webschedule dates
                     sourcequery = ' select Id,Web_Scheduling_Start_Date_Offset__c,Web_Scheduling_Start_Time__c,Web_Scheduling_End_Date_Offset__c,Web_Scheduling_End_Time_Offset__c, APT_Quantity__c, APT_Change_Reason__c, ' + fieldstoberetrieved + ' from Opportunity where Id =:driverecordid' ;
                sourceopplist = Database.query( sourcequery );
            }
            else if(fieldstoberetrieved.length()==0 && (isDriveAffiliationFound == true || isDriveServiceRolesFound == true)){
                sourcequery = ' select Id from Opportunity where Id =:driverecordid' ;
                sourceopplist = Database.query( sourcequery );
            }
            for( Opportunity opp : sourceopplist ){
                sourceopp.put( opp.Id, opp );
            }
            String targetquery = '';
            
            if(fieldstoberetrieved.length()>0){
                targetquery = ' select Id,Drive_date__c,Drive_Site__c, APT_Quantity__c, APT_Change_Reason__c, ' + fieldstoberetrieved + ' from Opportunity where Id IN:driveidset' ;
                updateopplist = Database.query( targetquery );
            }
            else if(fieldstoberetrieved.length()==0 && (isDriveAffiliationFound == true || isDriveServiceRolesFound == true)){
                targetquery = ' select Id,Drive_date__c from Opportunity where Id IN:driveidset' ;
                updateopplist = Database.query( targetquery );
            }
            //HRP-5343: Apply Drive Affiliations or Drive Service Roles to selected future drives
            if(isDriveAffiliationFound == true || isDriveServiceRolesFound == true){
                rollAffiliationsOrServiceRoles(isDriveAffiliationFound,isDriveServiceRolesFound,recordid,updateopplist,driveidset);
            }
            if(isTemplateOrderFound == true){
                //syncTemplateOrderToOpportunity(recordid,driveidset);
                OrderCloningService.cloneTemplateOrder(driveidset);//Logic for HRP-13716
            }
            //using this map to get the unmodified values of the opportunity to be updated
            Set<Id> opportunitySiteIds = new Set<Id>();
            map<id,Opportunity> updateOpplistMap = new map<id,Opportunity>();
            //HRP-4878--> Start the following fields are to fetch the drive CO web scheduling offset values
            Map<Id, sked_Site_Collection_Operation__c> oppIdVsCoMap = new Map<Id, sked_Site_Collection_Operation__c>(); 
            if(isWebschedulingSettingsFound){
                for(opportunity opp: updateopplist)
                {
                    updateOpplistMap.put(opp.id,opp);
                    opportunitySiteIds.add(opp.Drive_Site__c);
                }
                Map<Id, sked__Location__c> siteVsSiteCoMap = new Map<Id, sked__Location__c>([SELECT Id, Name, sked_Collection_Operation__r.Name, sked_Site_Collection_Operation_Count__c, (Select Id, Name, sked_Start_Date__c, sked_End_Date__c, sked_Collection_Operation__c, sked_Collection_Operation__r.Name, 
                                                                        sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Time__c, sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Date_Offset__c, sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Time_Offset__c, 
                                                                        sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Date_Offset__c,sked_Collection_Operation__r.FS_Web_Scheduling_Start_Time__c, sked_Collection_Operation__r.FS_Web_Scheduling_Start_Date_Offset__c, 
                                                                        sked_Collection_Operation__r.FS_Web_Scheduling_End_Time_Offset__c, sked_Collection_Operation__r.FS_Web_Scheduling_End_Date_Offset__c FROM sked_Site_Collection_Operations__r WHERE sked_Start_Date__c<= TODAY AND sked_End_Date__c>= TODAY ) FROM sked__Location__c WHERE Id IN :opportunitySiteIds]);
                
                
                                             
                for (Opportunity opp : updateopplist) {
                    for (sked_Site_Collection_Operation__c siteCo : siteVsSiteCoMap.get(opp.Drive_Site__c).sked_Site_Collection_Operations__r) {
                        if (opp.drive_Date__c>=siteCo.sked_Start_Date__c && opp.drive_Date__c<=siteCo.sked_End_Date__c) {
                            oppIdVsCoMap.put(opp.Id, siteCo);
                            break;
                        }
                    }
                }
            }
            //HRP-4878 --> End
            System.debug('fieldsarray==> '+fieldsarray);
            if(fieldsarray.size() > 0) {
                for( String s1 : fieldsarray ) {
                    for( Opportunity opp : updateopplist )
                    {
                            if(s1!=null && s1!='' && sourceopp!=null)
                            {
                                // Web_Schedule_Start_Time__c
                                // Web_Schedule_End_Time__c
                                // Web_Schedule_EndDate__c
                                // Web_Schedule_StartDate__c
                                if(s1=='Web Scheduling Settings' && isWebschedulingSettingsFound == false) {
                                    continue;
                                }
                               
                                //these fields need not be stamped on opportunity instead used as a label to filter the calculation of the webschedule dates using offset values
                                if(!webSchedulingFields.contains(s1) || fieldSetFields.contains(s1)) {
                                    opp.put(s1, sourceopp.get(driverecordid).get(s1));
                                }
                                //HRP-4878  --> Starts
                                //webschedule dates & time fields calculation
                                else if(webSchedulingFields.contains(s1)) {
                                    opportunity oppty = new opportunity();
                        			if(updateOpplistMap.get(opp.id)!=null)
                        			{
                            		oppty = updateOpplistMap.get(opp.id);
                                    String WebSchedStartDateOffset='Web_Scheduling_Start_Date_Offset__c';
                                    String WebSchedEndDateOffset='Web_Scheduling_End_Date_Offset__c';
                                    String WebSchedEndTimeOffset='Web_Scheduling_End_Time_Offset__c';
                                    String WebSchedStartTime='Web_Scheduling_Start_Time__c';
                                    Date driveDate=oppty.Drive_Date__c;
                                    Integer WebSchedulingStartDateOffset;
                                    String webStartTime;
                                    Integer WebSchedulingEndDateOffset;
                                    Integer WebSchedulingEndTimeOffset;
                                    Boolean fetchFromTemplate = (Boolean)sourceopp.get(driverecordid).get('Web_Sched_Offset_from_CO_Global_Settings__c');
                                    if (!fetchFromTemplate) {
                                        WebSchedulingStartDateOffset = Integer.valueOf(sourceopp.get(driverecordid).get(WebSchedStartDateOffset));
                                        webStartTime = String.valueOf(sourceopp.get(driverecordid).get(WebSchedStartTime));
                                        WebSchedulingEndDateOffset = Integer.valueOf(sourceopp.get(driverecordid).get(WebSchedEndDateOffset));
                                        WebSchedulingEndTimeOffset = Integer.valueOf(sourceopp.get(driverecordid).get(WebSchedEndTimeOffset));
                                    } else {
                                        if(oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Date_Offset__c!=null)
                                            WebSchedulingStartDateOffset = (Integer)oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Date_Offset__c;
                                        else
                                            WebSchedulingStartDateOffset = (Integer)globalWebSchedulingSettings.Web_Scheduling_Start_Date_Offset__c;
                                        if(!String.isBlank(oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Time__c))
                                            webStartTime = oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_Start_Time__c;
                                        else
                                            webStartTime = globalWebSchedulingSettings.Web_Scheduling_Start_Time__c;
                                        if(oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Date_Offset__c!=null)
                                            WebSchedulingEndDateOffset = (Integer)oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Date_Offset__c;
                                        else
                                            WebSchedulingEndDateOffset = (Integer)globalWebSchedulingSettings.Web_Scheduling_End_Date_Offset__c;
                                        if(oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Time_Offset__c!=null)
                                            WebSchedulingEndTimeOffset = (Integer)oppIdVsCoMap.get(oppty.Id).sked_Collection_Operation__r.Mobile_Web_Scheduling_End_Time_Offset__c;
                                        else
                                            WebSchedulingEndTimeOffset = (Integer)globalWebSchedulingSettings.Web_Scheduling_End_Date_Offset__c;
                                    }
                                    
                                    //HRP-4878  --> Ends
                                    DateTime wsStartDateTime;
                                    DateTime wsEndDateTime;
                                    if(s1=='Web_Schedule_StartDate__c' || s1=='Web_Schedule_Start_Date__c')
                                    {
                                    //WebSchedule StartDate Calc
                                    Time startTimeInstance= Time.newInstance(Integer.valueOf(webStartTime.left(2)),Integer.valueOf(webStartTime.right(2)),0,0);  
                                    
                                    Date driveDateAddStartDateOffSet=driveDate.addDays(WebSchedulingStartDateOffset);
                                    if(driveDateAddStartDateOffSet != null){    
                                        DateTime driveDateAddStartDateOffSetTime=driveDateAddStartDateOffSet;  
                                        DateTime webSchStartDate=driveDateAddStartDateOffSetTime.addHours(Integer.valueOf(webStartTime.left(2))).addMinutes(Integer.valueOf(webStartTime.right(2)));
                                        
                                        
                                        
                                        if(opp.TimeZone__c!=null){
                                            wsStartDateTime= DateTimeConverter.convertDateTimeIntoGMT(oppty.TimeZone__c,driveDateAddStartDateOffSet,startTimeInstance);
                                            
                                        } else {
                                            wsStartDateTime=webSchStartDate;
                                            
                                        }
                                    }
                                    opp.put('Web_Schedule_Start_Time__c',startTimeInstance);
                                    opp.put('Web_Schedule_StartDate__c',driveDateAddStartDateOffSet);
                                    opp.put('Web_Schedule_Start_Date__c',wsStartDateTime);
                                    
                                    }
                                    if(s1=='Web_Schedule_EndDate__c' || s1=='Web_Schedule_End_Time__c')
                                    {
                                    //WebSchedule EndDate Calc
                                    Time endTime = oppty.End_Time__c;     
                                    Time calculatedEndTime= endTime.addHours(WebSchedulingEndTimeOffset);
                                        
                                    Date driveDateAddEndDateOffSet=driveDate.addDays(WebSchedulingEndDateOffset);
                                    if(driveDateAddEndDateOffSet != null && calculatedEndTime != null){    
                                        DateTime driveDateAddEndDateOffSetTime=driveDateAddEndDateOffSet;
                                        DateTime webSchEndDate=driveDateAddEndDateOffSetTime.addHours(calculatedEndTime.hour()).addMinutes(calculatedEndTime.minute());
                                        
                                        
                                        if(oppty.TimeZone__c!=null){
                                            wsEndDateTime= DateTimeConverter.convertDateTimeIntoGMT(oppty.TimeZone__c,driveDateAddEndDateOffSet,calculatedEndTime);
                                        } else {
                                            wsEndDateTime=webSchEndDate;
                                        } 
                                    }
                                    opp.put('Web_Schedule_EndDate__c',driveDateAddEndDateOffSet);
                                    opp.put('Web_Schedule_End_Date__c',wsEndDateTime);
                                    opp.put('Web_Schedule_End_Time__c',calculatedEndTime);
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
            if(!updateopplist.isEmpty())
            {   
                //Integer batchSize = Integer.valueOf(Custom_Messages__mdt.getInstance('BatchSizeFor_BSF_BatchFutureDriveUpdate').Value__c);
                //DataBase.executeBatch(new BSF_BatchFutureDriveUpdate(updateopplist, batchSize));
                DataBase.saveResult[] srOppList = Database.update(updateopplist,true);//HRP-13521
                List<BSF_Error_Log__c> errorLogJobs = BSF_Utilities.createErrorLog(srOppList,'Update processed record status', 'BSF_BatchFutureDriveUpdate', 'execute', 'Error', 'Error in Future Drives Update');
                insert errorLogJobs;
            }
        } catch (Exception e) {
            System.debug('An error is occured:'+e.getLineNumber()+'___'+e.getMessage());
            throw new FutureDrivesControllerException(e.getMessage());//HRP-13521
        }
    }
    public static string rollAffiliationsOrServiceRoles(Boolean isDriveAffiliationFound,Boolean isDriveServiceRolesFound,String recordid, List<Opportunity> updateopplist,List<String> driveidset){
        try{
            List<Drive_Marketing_Programs__c> driveAffliationsToInsertList = new List<Drive_Marketing_Programs__c>();
            List<OpportunityContactRole> driveServiceRolesToInsertList = new List<OpportunityContactRole>();
            //Insert Drive Affliations(Drive_Marketing_Programs__c) to all the selected opportuntities
            if(isDriveAffiliationFound){
                //Delete existing the Drive Affliations(Drive_Marketing_Programs__c) from the selected opportunites first.
                List<Drive_Marketing_Programs__c> existingDriveAffliationsToDeleteList =[SELECT Id,Marketing_Program__c,Account__c,Migration_ID__c,
                                                                                         Date_Removed__c, Start_Date__c,End_Date__c,
                                                                                         Blood_Drive_Opportunity__c FROM Drive_Marketing_Programs__c
                                                                                         WHERE Blood_Drive_Opportunity__c IN:driveidset
                                                                                          ];
                if(existingDriveAffliationsToDeleteList.size()>0){
                    Database.delete(existingDriveAffliationsToDeleteList,true);//HRP-13521
                }
                List<Drive_Marketing_Programs__c> driveAffiliationsList = [SELECT Marketing_Program__c,Account__c,Migration_ID__c,
                                                                           Date_Removed__c, Start_Date__c,End_Date__c,
                                                                           Blood_Drive_Opportunity__c FROM Drive_Marketing_Programs__c
                                                                           WHERE Blood_Drive_Opportunity__c =:recordid
                                                                            ];
                for(Drive_Marketing_Programs__c driveAffiliation:driveAffiliationsList){
                    for(Opportunity opty:updateopplist){
                        Drive_Marketing_Programs__c affiliationToInsert = new Drive_Marketing_Programs__c();
                        affiliationToInsert.Marketing_Program__c = driveAffiliation.Marketing_Program__c;
                        affiliationToInsert.Blood_Drive_Opportunity__c = opty.Id;
                        affiliationToInsert.Account__c = driveAffiliation.Account__c;
                        affiliationToInsert.Migration_ID__c = driveAffiliation.Migration_ID__c;
                        affiliationToInsert.Date_Removed__c = driveAffiliation.Date_Removed__c;
                        driveAffliationsToInsertList.add(affiliationToInsert);
                    }
                }
            }
            //Insert Drive Service Roles(OpportunityContactRole) to all the selected opportuntities
            if(isDriveServiceRolesFound){            
                
                //Delete existing the Drive Service Roles(AccountContactRole) from the selected opportunites first. 
                List<OpportunityContactRole> existingDriveServiceRoleToDeleteList = [SELECT OpportunityId,ContactId 
                                                                                     FROM OpportunityContactRole 
                                                                                     WHERE OpportunityId =:driveidset];
                if(existingDriveServiceRoleToDeleteList.size()>0){
                     Database.delete(existingDriveServiceRoleToDeleteList,true);//HRP-13521
                }
                List<OpportunityContactRole> driveServiceRoleList = [SELECT OpportunityId,ContactId, Role
                                                                     FROM OpportunityContactRole
                                                                     WHERE OpportunityId =:recordid  ];
                for(OpportunityContactRole driveServiceRole:driveServiceRoleList){
                    for(Opportunity opty:updateopplist){
                        OpportunityContactRole driveServiceRoleToInsert = new OpportunityContactRole();
                        driveServiceRoleToInsert.ContactId = driveServiceRole.ContactId;
                        driveServiceRoleToInsert.OpportunityId = opty.Id;
                        driveServiceRoleToInsert.Role = driveServiceRole.Role;
                        driveServiceRolesToInsertList.add(driveServiceRoleToInsert);
                    }
                }
            }
            if(driveAffliationsToInsertList.size()>0){
                Database.insert(driveAffliationsToInsertList,true);//HRP-13521
            }
            if(driveServiceRolesToInsertList.size()>0){
                Database.insert(driveServiceRolesToInsertList,true);//HRP-13521
            }
        }
        catch (Exception e) {
            throw new FutureDrivesControllerException(e.getMessage());//HRP-13521
        }
        return 'success';
    }
    @AuraEnabled
    public static string futureDriveSubmissionMessage(){
        return String.valueOf(Custom_Messages__mdt.getInstance('Apply_Changes_to_Future_Drive_Toast').Value__c);
    }
    //--> HRP-12664 continues
    /*public static string syncTemplateOrderToOpportunity(String recordid, List<String> driveidset){
        try{
        Set<ID> oppID = new Set<ID>();
        List<Order> createOppOrder = new List<Order>();
        List<OrderItem> createOppOrderItem = new List<OrderItem>();
		List<Order> getExistingOppOrder = new List<Order>();
        List<Order> getTemplateOrder = [SELECT Id, Order_Due_Date__c, EffectiveDate, AccountId, OpportunityId, Material_Recipient__c, Material_Recipient_Type__c,
                                        Comments__c, Publicity_Approved__c, Publicity_Submitted__c, Status, StatusCode,Pricebook2Id,Local_Recruitment_Request__c,
                                        Local_Recruitment_Request_Need_by_Date__c,Material_Recipient_Default__c,
                                        (SELECT Id, OrderID, Product2Id, TotalPrice, ListPrice, Quantity, UnitPrice, PricebookEntryId FROM OrderItems)
                                        FROM Order WHERE OpportunityId =: recordid];

        Set<String> setOfDriveID=new Set<String>(driveidset);  
                                              
        getExistingOppOrder = [SELECT Id, OpportunityId, Publicity_Approved__c, Publicity_Submitted__c,
        (SELECT Id, OrderID, Product2Id, TotalPrice, ListPrice, Quantity, UnitPrice, PricebookEntryId FROM OrderItems)
                                      FROM Order WHERE OpportunityId IN: setOfDriveID];
        List<OrderItem> deleteOppOrderProds = new List<OrderItem>();
        Map<Id,Id> oppVsOrderId = new Map<Id,Id>();
            for(Order getOrder : getExistingOppOrder){
                if(getOrder.Publicity_Approved__c == False && getOrder.Publicity_Submitted__c == False){
                    //deleteOppOrder.add(getOrder);
                    oppVsOrderId.put(getOrder.OpportunityId,getOrder.Id);
                    for (OrderItem odrItem : getOrder.OrderItems){
                        deleteOppOrderProds.add(odrItem);
                    }
                }
                 if(getOrder.Publicity_Approved__c == True || getOrder.Publicity_Submitted__c == True){
                    oppID.add(getOrder.OpportunityId);
                }
            }
            if(deleteOppOrderProds != NULL && !deleteOppOrderProds.isEmpty()) {
            	Database.DeleteResult[] drList = Database.delete(deleteOppOrderProds, true);//HRP-13521
                    
    	}
       if(getTemplateOrder != NULL && !getTemplateOrder.isEmpty()){
        for(String driveid:driveidset){
			if(oppID != NULL && !oppID.isEmpty() && oppID.contains(driveid)){
                Continue;
            }
            Order newOrder = new Order();
                newOrder.EffectiveDate = getTemplateOrder[0].EffectiveDate;
                newOrder.AccountId = getTemplateOrder[0].AccountId;
                newOrder.Material_Recipient__c = getTemplateOrder[0].Material_Recipient__c;
                newOrder.Material_Recipient_Type__c = getTemplateOrder[0].Material_Recipient_Type__c;
                newOrder.Comments__c = getTemplateOrder[0].Comments__c;
                newOrder.Publicity_Submitted__c = getTemplateOrder[0].Publicity_Submitted__c;
                newOrder.Pricebook2Id = getTemplateOrder[0].Pricebook2Id;
                newOrder.Status = getTemplateOrder[0].Status;
                newOrder.Publicity_Approved__c = getTemplateOrder[0].Publicity_Approved__c;
                newOrder.Local_Recruitment_Request__c = getTemplateOrder[0].Local_Recruitment_Request__c;
                newOrder.Local_Recruitment_Request_Need_by_Date__c = getTemplateOrder[0].Local_Recruitment_Request_Need_by_Date__c;
                newOrder.Publicity_Approved_By__c = null;
                newOrder.Publicity_Approved_Date__c = null;
                newOrder.Publicity_Submitted_By__c = null;
                newOrder.Publicity_Submitted_Date__c = null;
                newOrder.Material_Recipient_Default__c = getTemplateOrder[0].Material_Recipient_Default__c;
                newOrder.OpportunityId = driveid;
                newOrder.Id = null;
                if(!oppVsOrderId.isEmpty() && oppVsOrderId.containsKey(driveid)){
                    newOrder.Id = oppVsOrderId.get(driveid);
                }
                
                createOppOrder.add(newOrder);
           
        }
        if (!createOppOrder.isEmpty()) {
            Database.upsertResult[] srList = Database.upsert(createOppOrder, true);//HRP-13521
            for (Database.upsertResult sr : srList) {
                if (sr.isSuccess()) {
                    for(Order cloneOrder: getTemplateOrder){
                        if(cloneOrder.OrderItems != NULL){
                            for (OrderItem cloneOrderItem : cloneOrder.OrderItems){
                                
                                OrderItem newOrderItem = new OrderItem();
                                newOrderItem.OrderId = sr.getId();
                                newOrderItem.Product2Id = cloneOrderItem.Product2Id;                        
                                newOrderItem.ListPrice = cloneOrderItem.ListPrice;
                                newOrderItem.Quantity = cloneOrderItem.Quantity;
                                newOrderItem.UnitPrice = cloneOrderItem.UnitPrice;
                                newOrderItem.PricebookEntryId = cloneOrderItem.PricebookEntryId;
                                
                               If(newOrderItem.OrderId != NULL){
                                createOppOrderItem.add(newOrderItem);
                              }
                           }
                        }
                    }
                }
                
            }
            if (!createOppOrderItem.isEmpty()){
                Database.SaveResult[] oppOrderList = Database.insert(createOppOrderItem, true);//HRP-13521
            }
        }
       }
      } catch (Exception e) {
            throw new FutureDrivesControllerException(e.getMessage());//HRP-13521
        }      
        return 'Success';
    }*/
    //--> HRP-12664 ends here
    public class FutureDriveClass{
        @AuraEnabled public String drivenanme;
        @AuraEnabled public String driveid;
        @AuraEnabled public String drivedate;
        @AuraEnabled public String drivesite;
        @AuraEnabled public String drivestage;
        @AuraEnabled public String drivestatus;
        @AuraEnabled public Boolean isselected ;
    }
    public class FieldSetClass{
        @AuraEnabled public String fieldapiname;
        @AuraEnabled public String fieldlabel;
    }
    public class FutureDrivesControllerException extends Exception{}//HRP-13521
}