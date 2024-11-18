/**
 * @description: This batch class is used to populate Excess Staff Capacity Name on Drive.
 * @createdby: Barnojit Sharma
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  08/08/2024                Barnojit Sharma            System identify excess staff capacity. (HRP-10994)
 *************************************************************************************************************************************************
**/
public class BSF_UpdateDriveExcessStaffCapacityBatch implements Database.Batchable<sObject>{
    DateTime startDate;
    DateTime endDate;
    List<String> statusList;
    List<String> jobRoles;


    public BSF_UpdateDriveExcessStaffCapacityBatch(Date sDate, Date edate, List<String> sList){
        this.startDate = DateTime.newInstance(sDate.year(),sDate.month(),sDate.day());
        this.endDate = DateTime.newInstance(edate.year(),edate.month(),edate.day());
        this.statusList = sList;
        this.jobRoles = new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'};
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, sked_Staff_Capacity__c, sked_Projected_Registered_Donors__c, Average_Staff_Capacity__c, Excess_Staff_Capacity__c FROM sked_Drive__c WHERE'+
                                        ' sked_Drive_Date__c >= '+this.startDate.format('yyyy-MM-dd')+
                                        ' AND sked_Drive_Date__c <= '+this.endDate.format('yyyy-MM-dd')+
                                        ' AND sked_Status__c IN (\''+String.join(this.statusList, '\',\'')+'\')'+
                                        ' AND sked_Staff_Capacity__c != null'+
                                        ' AND sked_Projected_Registered_Donors__c != null'+
                                        ' AND (sked_Type_of_Drive__c = \'Mobile\''+
                                        ' OR (sked_Type_of_Drive__c = \'Fixed Site\''+
                                        ' AND  sked_Operation_Type__c = \'Non Integrated WB\'))');
    }

	public void execute(Database.BatchableContext BC, List<sked_Drive__c> scope){
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        Map<Id, Integer> quantityCountMap = new Map<Id, Integer>();
        //try{
            Map<Id, sked_Drive__c> driveMap = new Map<Id, sked_Drive__c>(scope);
            
            List<sked__Job__c> jobList = [SELECT Id, 
                                                sked__Quantity__c,
                                                sked_APT_Quantity__c,
                                                sked_Drive__c 
                                            FROM sked__Job__c
                                            WHERE sked__Job_Status__c != 'Cancelled'
                                            AND sked_Drive__c IN :driveMap.keySet()
                                            AND sked__Type__c IN :this.jobRoles];
            for(sked__Job__c job : jobList){
                Integer count = 0;
                if(quantityCountMap.containsKey(job.sked_Drive__c)){
                    count = quantityCountMap.get(job.sked_Drive__c);
                }
                if(job.sked__Quantity__c != null){
                    count = count + Integer.valueOf(job.sked__Quantity__c);
                }
                if(job.sked_APT_Quantity__c != null){
                    count = count - Integer.valueOf(job.sked_APT_Quantity__c);
                }
                quantityCountMap.put(job.sked_Drive__c,count);
            }

            for(Id drvId : driveMap.keySet()){
                Decimal averageStaffCapacity = 0;
                Decimal excessStaffCapacity = 0;
                if(quantityCountMap.containsKey(drvId)){
                    averageStaffCapacity = driveMap.get(drvId).sked_Staff_Capacity__c / quantityCountMap.get(drvId);
                    averageStaffCapacity = averageStaffCapacity.setScale(1);
                    excessStaffCapacity = (driveMap.get(drvId).sked_Staff_Capacity__c - driveMap.get(drvId).sked_Projected_Registered_Donors__c)/averageStaffCapacity;
                    excessStaffCapacity = excessStaffCapacity.setScale(1);
                }
                if(driveMap.get(drvId).Average_Staff_Capacity__c != averageStaffCapacity || driveMap.get(drvId).Average_Staff_Capacity__c != excessStaffCapacity){
                    drivesToUpdate.add(new sked_Drive__c(Id = drvId,
                                                        Average_Staff_Capacity__c = averageStaffCapacity,
                                                        Excess_Staff_Capacity__c = excessStaffCapacity
                                                        )
                    );
                
                }
                
            }
            
            if(!drivesToUpdate.isEmpty()){
                skedHubBase.BypassUpdateTriggers = true;
                TriggerHandler.bypass('DriveTriggerHandler');
                Database.update(drivesToUpdate,false);
            }
        //}catch(Exception ex){
                
        //}

	}
	public void finish(Database.BatchableContext BC){}
}