global with sharing class BSF_BatchPopulateDriveShift implements Database.Batchable<sObject>{
   
  public date createdDate;    
    global BSF_BatchPopulateDriveShift()
    {
        
    }
    global BSF_BatchPopulateDriveShift(Date createdDate)
    {
        this.createdDate=createdDate;
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'select Id,sked_Projected_Registered_Donors__c,CreatedDate from sked_Drive__c where sked_Projected_Registered_Donors__c != null AND '+
            ' sked_Opportunity__r.Parent_Template_ID__C != null AND Sked_migrationid__c !=null AND sked_status__c!=\'Cancel\'';
        if(this.createdDate != null)
        {
            query = query + ' AND CreatedDate >= :createdDate ';
        }
        system.debug('entered1'+query);
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext bc, List<sked_Drive__c> drivesList)
    {
        system.debug('drivesList'+drivesList);
        
        List<id> driveIdsList = new List<id>();
        map<id,List<sked_Drive_Shift__c>> driveIDShiftsMap = new map<id,List<sked_Drive_Shift__c>>();
        List<sked_Drive_Shift__c> driveShiftUpdateList = new List<sked_Drive_Shift__c>();
        for(sked_Drive__c d:drivesList)
        {
            driveIdsList.add(d.id);
        }
        List<sked_Drive_Shift__c> driveShiftList = [Select id,sked_Drive__c,sked_Donors_Scheduled__c,sked_Start_Time__c from sked_Drive_Shift__c where sked_Drive__c IN :driveIdsList order by sked_Start_Time__c];
        
        for(sked_Drive_Shift__c ds:driveShiftList)
        {
            if(!driveIDShiftsMap.containskey(ds.sked_Drive__c))
            {
                List<sked_Drive_Shift__c> dsList = new List<sked_Drive_Shift__c>();
                dsList.add(ds);
                driveIDShiftsMap.put(ds.sked_Drive__c,dsList);
            }
            else 
            {
                driveIDShiftsMap.get(ds.sked_Drive__c).add(ds);
            }
        }
        
        for(sked_Drive__c d:drivesList)
        {
            if(d.sked_Projected_Registered_Donors__c != null && driveIDShiftsMap.get(d.id) != null)
            {
            Integer noOfDriveShifts = driveIDShiftsMap.get(d.id).Size();
            Decimal totalProducts = d.sked_Projected_Registered_Donors__c;
            for(sked_Drive_Shift__c ds:driveIDShiftsMap.get(d.id))
            {
                ds.sked_Donors_Scheduled__c = totalProducts.divide(noOfDriveShifts,0,System.RoundingMode.UP);
                totalProducts = totalProducts-ds.sked_Donors_Scheduled__c;
                noOfDriveShifts =noOfDriveShifts -1;
                driveShiftUpdateList.add(ds);
            }
            }
        }
        
        try{
            if(!driveShiftUpdateList.isEmpty())
        {
            Database.Update(driveShiftUpdateList,false);
        }
        }
        catch(exception e)
        {
            system.debug('The Error i updating the Driveshifts :'+e.getMessage());
        }
        
    }
    global void finish(Database.BatchableContext bc){
        system.debug('The BSF_BatchPopulateDriveShift batch ran succesfully');
        
    }
}