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
    Boolean recalculateStaffCapacity;
    List<String> statusList;
    List<String> jobRoles = new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'};


    public BSF_UpdateDriveExcessStaffCapacityBatch(Date sDate, Date edate, List<String> sList, Boolean recalculate){
        this.startDate = DateTime.newInstance(sDate.year(),sDate.month(),sDate.day());
        this.endDate = DateTime.newInstance(edate.year(),edate.month(),edate.day());
        this.statusList = sList;
        this.recalculateStaffCapacity = recalculate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, sked_Staff_Capacity__c, sked_Projected_Registered_Donors__c,'+
                        ' Max_Role_Capacity__c, Max_Role_Capacity_With_Draw_Hours__c,'+
                        ' sked_Maximum_Lunch_Break_Duration__c, sked_Collection_Operation__c,'+ 
                        ' sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c,sked_Drive_Date__c,'+
                        ' sked_Timezone__c, Average_Staff_Capacity__c, Excess_Staff_Capacity__c,'+ 
                        ' (SELECT Id, sked_Start_Time__c,sked_End_Time__c, sked_Lunch_Break__c'+
                        ' FROM sked_Drive_Shifts__r) FROM sked_Drive__c WHERE'+
                        ' sked_Drive_Date__c >= '+this.startDate.format('yyyy-MM-dd')+
                        ' AND sked_Drive_Date__c <= '+this.endDate.format('yyyy-MM-dd')+
                        ' AND sked_Status__c IN (\''+String.join(this.statusList, '\',\'')+'\')'+
                        ' AND sked_Staff_Capacity__c != null'+
                        ' AND sked_Projected_Registered_Donors__c != null'+
                        ' AND sked_Collection_Operation__c != null';
        if(this.recalculateStaffCapacity != true){
            query += ' AND Excess_Staff_Capacity__c = null';
        }
        return Database.getQueryLocator(query);
    }

	public void execute(Database.BatchableContext BC, List<sked_Drive__c> scope){
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        Map<Id, sked_Drive__c> driveMap = new Map<Id, sked_Drive__c>(scope);
        Map<Id, sked_Staffing_Decision_Matrix__c> staffingDecisionMatrxMap = new  Map<Id, sked_Staffing_Decision_Matrix__c>([
                                                                            SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
                                                                            sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, sked_WB_Hourly_Capacity__c,
                                                                            sked_Platelet_Hourly_Capacity__c, sked_Plasma_Hourly_Capacity__c, sked_2RBC_Hourly_Capacity__c,
                                                                            sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
                                                                            sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c,
                                                                            RecordType.Name
                                                                            FROM sked_Staffing_Decision_Matrix__c]);
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMs = [SELECT Id, sked_Collection_Operation__c, sked_Staffing_Decision_Matrix__c,
                                                                            sked_Effective_End_Date__c, sked_Effective_Start_Date__c
                                                                            FROM sked_Collection_Operation_SDM__c
                                                                            WHERE sked_Collection_Operation__c != null
                                                                            AND sked_Effective_Start_Date__c != null];
        Map<Id,List<sked__Job__c>> driveJobsMap = new Map<Id,List<sked__Job__c>>();
        List<sked__Job__c> jobList = [SELECT Id, 
                                            sked__Type__c,
                                            sked_Drive__c 
                                        FROM sked__Job__c
                                        WHERE sked__Job_Status__c != 'Cancelled'
                                        AND sked_Drive__c IN :driveMap.keySet()
                                        AND sked__Type__c IN :this.jobRoles];
        for(sked__Job__c job : jobList){
            if(!driveJobsMap.containsKey(job.sked_Drive__c)){
                driveJobsMap.put(job.sked_Drive__c, new List<sked__Job__c>());
            }
            driveJobsMap.get(job.sked_Drive__c).add(job);
        }
                            
        for(Id driveId : driveMap.keySet()){
            Decimal maxRoleCapacity = 0;
            Decimal maxRoleCapacityWithDrawHours = 0;
            Decimal driveDrawHours = 0;
            Decimal excessStaffCapacity;
            List<String> driveJobRoles = new List<String>();
            Id driveStaffingDecisionMatrixId;

            if(driveJobsMap.containsKey(driveId)){
                for(sked__Job__c job : driveJobsMap.get(driveId)){
                    driveJobRoles.add(job.sked__Type__c);
                }
            }

            if(!collectionOperationSDMs.isEmpty()){
                for(sked_Collection_Operation_SDM__c coSDM : collectionOperationSDMs){
                    if(coSDM.sked_Collection_Operation__c == driveMap.get(driveId).sked_Collection_Operation__c
                            && coSDM.sked_Effective_Start_Date__c <= driveMap.get(driveId).sked_Drive_Date__c  
                            && (coSDM.sked_Effective_End_Date__c == null
                            || coSDM.sked_Effective_End_Date__c >= driveMap.get(driveId).sked_Drive_Date__c)
                            && staffingDecisionMatrxMap.containsKey(coSDM.sked_Staffing_Decision_Matrix__c)){
                                driveStaffingDecisionMatrixId = coSDM.sked_Staffing_Decision_Matrix__c;
                                break;
                    }
                }
            }

            if(!driveJobRoles.isEmpty() && driveStaffingDecisionMatrixId != null){
                for(String role : driveJobRoles){
                    if(role.equalsIgnoreCase('Driver') 
                            && maxRoleCapacity < staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_Driver_Capacity__c){
                                maxRoleCapacity = staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_Driver_Capacity__c;
                    }else if(role.equalsIgnoreCase('Driver Support') 
                            && maxRoleCapacity < staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_Driver_Support_Capacity__c){
                                maxRoleCapacity = staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_Driver_Support_Capacity__c;
                    }else if(role.equalsIgnoreCase('2RBC') 
                            && maxRoleCapacity < staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_2RBC_Staff_Capacity__c){
                                maxRoleCapacity = staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_2RBC_Staff_Capacity__c;
                    }else if(role.equalsIgnoreCase('VP/HH') 
                            && maxRoleCapacity < staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_VP_HH_Capacity__c){
                                maxRoleCapacity = staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_VP_HH_Capacity__c;
                    }else if(role.equalsIgnoreCase('Charge') 
                            && maxRoleCapacity < staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_Charge_Capacity__c){
                                maxRoleCapacity = staffingDecisionMatrxMap.get(driveStaffingDecisionMatrixId).sked_Charge_Capacity__c;
                    }
                }
            }

            if(!driveJobRoles.isEmpty() && driveMap.get(driveId).sked_Drive_Shifts__r != null){
                for(sked_Drive_Shift__c driveShift : driveMap.get(driveId).sked_Drive_Shifts__r){
                    Decimal drawHours = 0;
                    Datetime drawStartTime = DateTime.newInstanceGMT(driveMap.get(driveId).sked_Drive_Date__c, driveShift.sked_Start_Time__c);
                    Datetime drawStart = skedDateTimeUtils.toTimezone(drawStartTime, driveMap.get(driveId).sked_Timezone__c);
                    Datetime drawEndTime = DateTime.newInstanceGMT(driveMap.get(driveId).sked_Drive_Date__c, driveShift.sked_End_Time__c);
                    Datetime drawEnd = skedDateTimeUtils.toTimezone(drawEndTime, driveMap.get(driveId).sked_Timezone__c);
                    Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(drawStart, drawEnd);
                    Decimal drawHoursActual = drawDuration / 60;
                    drawHours = drawHoursActual;
                    Decimal coMaxLunchBreakDuration = driveMap.get(driveId).sked_Maximum_Lunch_Break_Duration__c != null ? Decimal.valueOf(driveMap.get(driveId).sked_Maximum_Lunch_Break_Duration__c) : 30;
                    if(driveShift.sked_Lunch_Break__c && (!driveMap.get(driveId).sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c)){
                        Decimal driveshiftDrawhr = (drawHoursActual * 60) -  coMaxLunchBreakDuration;
                        Decimal drawHourswithLunchBreak = driveshiftDrawhr.divide(60, 2, System.RoundingMode.UP);
                        drawHours = drawHourswithLunchBreak != null ? drawHourswithLunchBreak : drawHoursActual;
                    }
                    driveDrawHours = driveDrawHours + drawHours;
                }
            }
            if(maxRoleCapacity > 0  && driveDrawHours > 0){
                maxRoleCapacityWithDrawHours = maxRoleCapacity * driveDrawHours;
                maxRoleCapacityWithDrawHours = maxRoleCapacityWithDrawHours.setScale(2);
                maxRoleCapacity = maxRoleCapacity.setScale(2);
            }

            if(maxRoleCapacityWithDrawHours > 0){
                excessStaffCapacity = (driveMap.get(driveId).sked_Staff_Capacity__c - driveMap.get(driveId).sked_Projected_Registered_Donors__c)/maxRoleCapacityWithDrawHours;
                excessStaffCapacity = excessStaffCapacity.setScale(1);
            }
            if(driveMap.get(driveId).Max_Role_Capacity__c != maxRoleCapacity 
                    || driveMap.get(driveId).Max_Role_Capacity_With_Draw_Hours__c != maxRoleCapacityWithDrawHours
                    || driveMap.get(driveId).Excess_Staff_Capacity__c != excessStaffCapacity){
                        drivesToUpdate.add(new sked_Drive__c(Id = driveId,
                                                            Max_Role_Capacity__c = maxRoleCapacity,
                                                            Max_Role_Capacity_With_Draw_Hours__c = maxRoleCapacityWithDrawHours,
                                                            Excess_Staff_Capacity__c = excessStaffCapacity
                                                            )
                        );
            }
        }
            
        if(!drivesToUpdate.isEmpty()){
            skedHubBase.BypassUpdateTriggers = true;
            TriggerHandler.bypass('DriveTriggerHandler');
            Database.saveResult[] drivesUpdateResultList = Database.update(drivesToUpdate,false);
            List<BSF_Error_Log__c> logListForDriveStatusUpdate = BSF_Utilities.createErrorLogWithObjectId(
                drivesUpdateResultList, 
                'UpdateDriveExcessStaffCapacity',
                'BSF_UpdateDriveExcessStaffCapacityBatch',
                'execute',
                'Error',
                'Error in Updating Drive Excess Staff Capacity'
            );
            Database.SaveResult[] logResultList = Database.Insert(logListForDriveStatusUpdate, false);
        }
	}
	public void finish(Database.BatchableContext BC){}
}