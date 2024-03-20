/***************************************************************************************************************************************
 * 
 * Description:     This is a batch job for "Calendar Build".  It runs every night and evaluates previously
 *                  completed and cancelled drives and rolls them over to next year with a drive status of
 *                  "draft".  It then performs various criteria evaluations and identifies each rolled over
 *                  drive as either "qualifed" or "unqualifed".  Afterwards, it determines if it's time to
 *                  run the process for moving the drives from Draft to System Generated.  This will be
 * 					scheduled to run every night.
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/28/21     Fitsum Worku        Initial Code Creation
 * 07/27/23		Fitsum Worku		HRP-10179 sending email notification if there is an error during draft drive generation
 *
 ************************************************************************************************************************************/
global class CalendarBuildEvaluateDrivesBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {

    global List<Opportunity> lstCBOpps = new List<Opportunity>();    
    global Integer batchSize;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> setCurOppIds = new Set<Id>();
        system.debug('### Inside start method for batch...');
    
        //get # of days after drive completion from custom metadata type and batch size
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.Number_Of_Days__c.intValue();
        batchSize = mdtDriveCompletion?.Draft_Drives_Batch_Size__c.intValue(); //HRP-10179
        system.debug('### Inside start method for batch; numOfDays is: ...' + numOfDays);
        if(numOfDays != null) {
            //Date driveDateToEval = Helper.AddBusinessDays(system.today(), -numOfDays);  //Per business, we are changing this from business days to include all days
            Date driveDateToEval = system.today().addDays(-numOfDays); 
            system.debug('Inside start method for batch; driveDateToEval is: ' + driveDateToEval);
            
            return Database.getQueryLocator([SELECT Id, Name, Drive_Date__c, StageName, Drive_Designations__c, Rollover_Consideration__c, RecordTypeId,
                                                Parent_Template_Id__c, Parent_Template_Id__r.name, drive_status__c, sked_Cancellation_Reason__c,
                                                Accept_56_Day_Rule_Violation__c, Accepts_Automation__c, Drive_Site__c, Open_to_Public__c, Anticipated_Registered_Donors__c,
                                                WB_Projected_Procedures__c, Double_Red_Projected_Units__c, Drive_Keyword__c, Online_Scheduling_Enabled__c, Type_of_Drive__c, Start_Time__c, End_Time__c,
                                                AccountId, Account.Account_Strategy__c, Account.Marketing_Strategy__c, Account.Account_Status__c, X2RBC_Projected_Procedures__c, Collection_Operation__c, Collections_Zip_Code__c,
                                             	Flow_Start_Time_Field__c, Flow_End_Time_Field__c, OwnerId, anticipated_registered_donors_template__c, WholeBloodProceduresProjectedTemplate__c,
												Double_red_Procedures_Projected_template__c, AcceptblankMilitaryAuthNamePhone__c, From_Template_Id__c, Number_of_2RBC_Assets__c, Number_of_Plasma_Assets__c, Number_of_Platelet_Assets__c,
                                                Direct_Donors_To__c, No_Publicity_Needed__c, Publish_to_Call_Center__c, Web_Scheduling_Enabled__c, Send_Emails__c, Send_Mailers__c,
                                                Web_Scheduling_End_Date_Offset__c, Web_Scheduling_End_Time_Offset__c, Web_Scheduling_Start_Date_Offset__c, Platelet_Projected_Procedures__c,
                                                Plasma_Pheresis_Projected_Procedures__c,Calendar_Build_Parent_Opportunity__c
                                            FROM Opportunity
                                            WHERE (drive_status__c = 'cancel' OR drive_status__c = 'complete') 
                                            AND Rollover_Consideration__c <> 'Do Not Roll'
                                            AND drive_date__c =:driveDateToEval]);                
        }
        else {
            return null;
        }
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
        
        List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
        Map<Exception,String> common_exception_map = new Map<Exception,String>();
    	Map<Id, String> dml_error_map = new Map<Id, String>(); 
        
        try {
            system.debug('### Inside execute for CalendarBuildEvaluateDrivesBatch opps to be cloned' + lstOpportunities.size());
            List<Opportunity> lstOpps = CalendarBuildBatchHandler.cloneDrives(lstOpportunities);
            system.debug('### Inside execute for CalendarBuildEvaluateDrivesBatch cloned opps' + lstOpps.size());
            lstCBOpps.addall(lstOpps);
            //Insert cloned opportunities (Calendar Build Opportunities)
            if(lstOpps != null && lstOpps.size() > 0 ) {
                List<Database.SaveResult> saveResultList = Database.insert(lstOpps, false);
                for(Database.SaveResult sr : saveResultList){
                    Integer i = 0;
                    if(!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
							BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c = '', ApexClass__c = 'CalendarBuildEvaluateDrivesBatch', Method__c = 'Batch Execute', Type__c = '',
                				Error_Description__c = 'Opportunity: ' + lstOpps.get(i).Calendar_Build_Parent_Opportunity__c + ' failed to clone. ' + err.getMessage(),
                				Error_Description_Long__c = err.getStatusCode() + ':::' + err.getFields()
                            );
                			errorLogList.add(errorLog);
                            //Start HRP-10179
                    		dml_error_map.put(sr.getId(),'<tr><td>'+errorLog.ApexClass__c + ', ' + errorLog.Method__c + ' : ' + errorLog.Error_Description__c + ' : ' + err.getMessage()+' Field: '+err.getFields()+'</td><td>'+sr.getId()+'</td></tr>'); 
                            //End HRP-10179
                        }
                    }
                    i++;
                }
                insert errorLogList;
            } 
        }
        catch(Exception e) {
			common_exception_map.put(e,'');  //HRP-10179
        }
        
     	//Start HRP-10179   
        if(!common_exception_map.isEmpty() || !dml_error_map.isEmpty()){
            sendErrorNotification(common_exception_map, dml_error_map);
            /*List<String> emailIds = System.label.BSF_SUPPORT_EMAIL_ID.split(',');
            String oweFromAddress = System.label.BSF_OWEA_SENDER;
            List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:oweFromAddress];
            if(!owea.isEmpty()) {
                Helper.sendEmail(common_exception_map, dml_error_map, emailIds, owea[0].Id, true);
            }*/
        }
        //End HRP-10179
    }

    global void finish(Database.BatchableContext bc) {
        system.debug('### --> Inside finish of CalendarBuildEvaluateDrivesBatch.  Size of cloned opps' + lstCBOpps.size());
        //Call either the Skedulo or Exavalu class to create 'drives on calendar' records for each cloned opportunity
        Calendar_Build_Setting__mdt mdtCBConfigs = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Boolean byPassDriveGeneration = mdtCBConfigs?.Bypass_Auto_Drive_Generation__c;
        if(!byPassDriveGeneration) {
        	CreateSkedDrivesBatch batchOppRecs = new CreateSkedDrivesBatch(lstCBOpps);
        	Database.executeBatch(batchOppRecs, 1);
        }
    }
    
    global void execute(SchedulableContext scon) {
      Database.executeBatch(new CalendarBuildEvaluateDrivesBatch(), batchSize);
   	}
    
    @testvisible private static void sendErrorNotification(Map<Exception, String> commonExMap, Map<Id, String> dmlErrMap ) {
        List<String> emailIds = System.label.BSF_SUPPORT_EMAIL_ID.split(',');
        String oweFromAddress = System.label.BSF_OWEA_SENDER;
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:oweFromAddress];
        if(!owea.isEmpty()) {
            Helper.sendEmail(commonExMap, dmlErrMap, emailIds, owea[0].Id, true);
        }
    }
}