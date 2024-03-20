/***********************************************************************************************************
 * 
 * Description:         This is a batch job for Calendar Build.  It gets called from the "finish" method
 *                      of the batch class "CalendarBuildEvaluateDrivesBatch".  The purpose of it is to
 *                      mass update draft drives to system generated at the end of each month plus a 
 *                      configurable number of days.  This will be scheduled to run every night.
 * 
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/20/21     Fitsum Worku        Initial Code Creation
 * 09/11/23		Fitsum Worku		Added logic for HRP-10964
 *
 **********************************************************************************************************/

global class CalendarBuildUpdateDrivesBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    global List<sked_drive__c> lstDrives = new List<sked_drive__c>();
    global Integer batchSize=1;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        string query;
        Calendar_Build_Setting__mdt mdtSystemGenQuery = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        String driveDateLiteral = mdtSystemGenQuery?.Date_Literal__c;
		Date systemGenStartDate = mdtSystemGenQuery?.System_Gen_Start_Date__c;
        Date systemGenEndDate = mdtSystemGenQuery?.System_Gen_End_Date__c;
        batchSize = mdtSystemGenQuery?.System_Gen_Drives_Batch_Size__c.intValue();
       
        //Select those opportunties in "draft status" from a previous month to move to "system generated"
        query = 'SELECT Id, Name, Drive_Date__c, StageName, Rollover_Consideration__c, RecordTypeId, drive_status__c, source__c ' +
           		' FROM Opportunity WHERE drive_status__c = \'draft\' AND Rollover_Consideration__c <> \'Do Not Roll\' AND source__c = \'Calendar Build\'';
        
        //If in the custom metadata type config, automation is turned off, then either a literal value of date range will be used. If neither fields are 
        //populated or if automation is turned on, then we are running resource allocation for previous month.
        if(driveDateLiteral != null) {
        	query += ' AND Drive_Date__c = ' + driveDateLiteral;
        } 
        else if(systemGenStartDate != null && systemGenEndDate != null) {
            string startDate = String.valueOf(systemGenStartDate);
            string endDate = String.valueOf(systemGenEndDate);
            query += ' AND Drive_Date__c >= ' + startDate + ' And Drive_Date__c <= ' + endDate;
        } 
        else {
        	//We are running resource allocation for previous month drives
			Date firstDayOfLastMonth = date.today().toStartOfMonth().addMonths(-1);
            Date LastDayOfLastMonth = date.Today().toStartOfMonth().addDays(-1);
			query += ' AND Drive_Date__c >= ' + firstDayOfLastMonth + ' And Drive_Date__c <= ' + LastDayOfLastMonth;    
        }
        system.debug('### System gen query: ' + query);
        return Database.getQueryLocator(query);   
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
        
        //Get Ids of the opportunities
        if(lstOpportunities != null && lstOpportunities.size() > 0) {
            Set<Id> oppIds = (new Map<Id,SObject>(lstOpportunities)).keySet();
            //Get the list of drives associated with the opportunities
            
            //start HRP-10964
            List<sked_drive__c> drivesList = [SELECT Id, sked_Status__c 
                         					  FROM sked_drive__c 
                         					  WHERE sked_Status__c = 'draft' And sked_Opportunity__c in:oppIds];
            lstDrives.addAll(drivesList);
  			//end HRP-10964
        }
    }

    global void finish(Database.BatchableContext bc) {
        if(lstDrives != null && lstDrives.size() > 0) {
            Set<Id> skedDrives = new Set<ID>();
            For(sked_drive__c driveRec : lstDrives) {
                skedDrives.add(driveRec.Id);
            }
            system.debug('### About to call drive allocation... drive = ' + skedDrives);
            database.executeBatch(new DriveResourceAllocationBatch(skedDrives), 1);
        }
    }
    
    global void execute(SchedulableContext scon) {
      Database.executeBatch(new CalendarBuildUpdateDrivesBatch(), batchSize);
   }
}