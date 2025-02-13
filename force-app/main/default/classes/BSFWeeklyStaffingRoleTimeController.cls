/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 07/15/2024			Barnojit Sharma				Weekly Staffing Schedule by Employee & Weekly Staffing Role Time Back up Reports shift start and end times are incorrect (HRP-13091)
 * 12/30/2024			Priti Jana					Logic for HRP-13121
 *****************************************************************************************************************************************************************************
*/
public without sharing class BSFWeeklyStaffingRoleTimeController {
    public static List<sked_Territory_Collection_Operation__c> getTerritoryCollectionOperation(Date startDate, Date endDate){
        if(startDate == null || endDate == null){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Date_Null').Value__c;
            errMsg = errMsg.replace('{{startDate}}',String.valueOf(startDate));
            errMsg = errMsg.replace('{{endDate}}',String.valueOf(endDate));
            throw new AuraHandledException(errMsg);
        }
        if(startDate > endDate){
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Start_Date_greater').Value__c);
        }

        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName();

        Id divisionRecordTypeId = recordTypeMapByName.get('Division').getRecordTypeId();
        Id regionRecordTypeId = recordTypeMapByName.get('ARC Region').getRecordTypeId();
        Id districtRecordTypeId = recordTypeMapByName.get('District').getRecordTypeId();

        List<sked_Territory_Collection_Operation__c> territoryCollOp = [SELECT Id,
                                                                                sked_Start_Date__c,
                                                                                sked_End_Date__c,
                                                                                sked_Collection_Operation__c, 
                                                                                sked_Collection_Operation__r.Id,
                                                                                sked_Collection_Operation__r.Name,
                                                                                sked_Territory__c, 
                                                                                sked_Territory__r.Id,
                                                                                sked_Territory__r.RecordTypeId,
                                                                                sked_Territory__r.Name,
                                                                                sked_Territory__r.Start_Date__c,
                                                                                sked_Territory__r.End_Date__c,
                                                                                sked_Territory__r.sked_Parent__c, 
                                                                                sked_Territory__r.sked_Parent__r.Id,
                                                                                sked_Territory__r.sked_Parent__r.RecordTypeId,
                                                                                sked_Territory__r.sked_Parent__r.Name,
                                                                                sked_Territory__r.sked_Parent__r.Start_Date__c,
                                                                                sked_Territory__r.sked_Parent__r.End_Date__c,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__c,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Id,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.RecordTypeId,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Name,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Start_Date__c, 
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.End_Date__c 
                                                                            FROM sked_Territory_Collection_Operation__c 
                                                                            WHERE sked_Collection_Operation__c != null 
                                                                            AND sked_Territory__c != null 
                                                                            AND sked_Territory__r.sked_Parent__c != null 
                                                                            AND sked_Territory__r.sked_Parent__r.sked_Parent__c != null 
                                                                            AND sked_Territory__r.RecordTypeId = :districtRecordTypeId
                                                                            AND sked_Territory__r.sked_Parent__r.RecordTypeId = :regionRecordTypeId
                                                                            AND sked_Territory__r.sked_Parent__r.sked_Parent__r.RecordTypeId = :divisionRecordTypeId
                                                                            AND ((sked_Start_Date__c <= :startDate 
                                                                            AND sked_End_Date__c >= :endDate) 
                                                                            OR (sked_Start_Date__c >= :startDate 
                                                                            AND sked_Start_Date__c < :endDate 
                                                                            AND sked_End_Date__c <= :endDate 
                                                                            AND sked_End_Date__c > :startDate)
                                                                            OR (sked_Start_Date__c <= :endDate 
                                                                            AND sked_Start_Date__c > :startDate 
                                                                            AND sked_End_Date__c > :endDate)
                                                                            OR (sked_Start_Date__c < :startDate 
                                                                            AND sked_End_Date__c <= :endDate 
                                                                            AND sked_End_Date__c > :startDate))];

        return territoryCollOp;
    }

    public static List<sked__Job_Allocation__c> getJobAllocations(Date startDate, Date endDate, List<String> driveDispatchedStatus, Set<String> collOpIds, List<String> driveTypes, List<Boolean> driveDispatchedCheckBox){
        return  [SELECT Id,
                        sked_Additional_Roles__c, 
                        sked_Start_Time__c, //added for HRP-13091
                        sked_Set_End_Time__c, //added for HRP-13091
                        sked__Job__c,
                        sked__Job__r.sked_Drive__c,
                        sked__Job__r.sked__Type__c,
                        sked__Job__r.sked_Start_Time__c,
                        sked__Job__r.sked_Finish_Time__c,
                        sked__Job__r.sked_Drive__r.sked_Drive_Date__c,
                        sked__Job__r.sked_Drive__r.sked_Status__c,
                        sked__Job__r.sked_Drive__r.Id,
                        sked__Job__r.sked_Drive__r.sked_Drive_Dispatched__c,
                        sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c,
                        sked__Job__r.sked_Drive__r.sked_Total_Procedures_Projected__c,
                        sked__Job__r.sked_Drive__r.sked_Total_Staff_Requested__c,
                        sked__Job__r.sked_Drive__r.sked_Equipment_Allocated__c,
                        sked__Job__r.sked_Drive__r.sked_Start_Time__c,
                        sked__Job__r.sked_Drive__r.sked_End_Time__c,
                        sked__Job__r.sked_Drive__r.sked_Account__c,
                        sked__Job__r.sked_Drive__r.sked_Account__r.Name,
                        sked__Job__r.sked_Drive__r.sked_Drive_Site__c,
                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Address_1__c,
                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_City__c,
                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_County__c,
                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_State__c,
                        sked__Job__r.sked_Resource_Role__c,
                        sked__Job__r.sked_Dual_Role__c,
                        sked__Job__r.sked_Lead_Time__c,
                        sked__Job__r.sked_Setup_Time__c,
                        sked__Job__r.sked_Travel_Time__c,
                        sked__Job__r.sked_Site_Logistics_To__c,
                        sked__Job__r.sked_Drive_Shift__c,
                        sked__Job__r.sked_Drive_Shift__r.sked_Start_Time__c,
                        sked__Job__r.sked_Drive_Shift__r.sked_End_Time__c,
                        sked__Job__r.sked_Drive_Shift__r.sked_Min_Shift_Start_Time__c,
                        sked__Job__r.sked_Drive_Shift__r.sked_Max_Shift_End_Time__c,
                        sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c,
                        sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c,
                        sked__Resource__c,
                        sked__Resource__r.Name,
                        sked__Resource__r.sked__Resource_Type__c,
                        sked__Resource__r.RecordTypeId,
                        sked__Resource__r.RecordType.Name,
                        sked__Resource__r.sked__Primary_Region__c,
                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__c,
                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name
                    FROM sked__Job_Allocation__c
                    WHERE sked__Status__c != 'Deleted' 
                    AND sked__Status__c IN :driveDispatchedStatus 
                    AND sked__Resource__c != null
                    AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                    AND sked__Resource__r.RecordType.Name = 'Staff'
                    AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                    AND sked__Job__r.sked_Drive__c != null
                    AND sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c IN :driveTypes
                    AND sked__Job__r.sked_Drive__r.sked_Drive_Dispatched__c IN :driveDispatchedCheckBox
                    AND sked__Job__r.sked_Drive__r.sked_Status__c != 'Cancel'
                    AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c != null
                    AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c >= :startDate
                    AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c <= :endDate];
    }
	
    //HRP-13121 -> Updated Method structure to consider territory keys for fetching activity/activity COs
    public static List<sked__Activity_Resource__c> getActivities(Date startDate, Date endDate, List<String> territoryKeys) {
        List<sked__Activity_Resource__c> activityResources = new List<sked__Activity_Resource__c>();
        
        List<sked__Activity__c> groupActivities = [SELECT Id, sked_Start_Date__c, sked_Start_Time__c, 
                                                    sked_Territory_Key__c, sked_End_Date__c, 
                                                            (SELECT Id,
                                                            sked_Start_Date__c,
                                                            sked_End_Date__c,
                                                            sked_End_Time__c,
                                                            sked_Start_Time__c,
                                                            sked__Activity__c,
                                                            sked__Activity__r.Name,
                                                            sked__Activity__r.sked__Type__c,
                                                            sked__Activity__r.sked_Subtype__c,
                                                            sked__Activity__r.sked__Notes__c,
                                                            sked__Activity__r.sked_Start_Time__c,
                                                            sked__Activity__r.sked_End_Time__c,
                                                            sked__Activity__r.sked_Start_Date__c,
                                                            sked__Resource__c,
                                                            sked__Resource__r.Name,
                                                            sked__Resource__r.sked__Resource_Type__c,
                                                            sked__Resource__r.RecordTypeId,
                                                            sked__Resource__r.RecordType.Name,
                                                            sked__Resource__r.sked__Primary_Region__c,
                                                            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__c,
                                                            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name
                                                            FROM sked__Activity_Resources__r
                                                            WHERE sked__Resource__c != null
                                                            AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                                                            AND sked__Resource__r.RecordType.Name = 'Staff'),
                                                            (SELECT Id, 
                                                            sked_Territory_Key__c, 
                                                            sked_Activity__c 
                                                            FROM sked_Activity_Collection_Operations__r)
                                                    FROM sked__Activity__c
                                                    WHERE sked_Start_Date__c >=: startDate
                                                    AND sked_End_Date__c <= :endDate
                                                    ORDER BY sked_Start_Time__c ASC];
        
        if(groupActivities != NULL && !groupActivities.isEmpty()) {
            for(sked__Activity__c activity : groupActivities) {
                Boolean isValidActivity = FALSE;
                if(territoryKeys.contains(activity.sked_Territory_Key__c)) isValidActivity = TRUE;
                else if(activity.sked_Activity_Collection_Operations__r != NULL && !activity.sked_Activity_Collection_Operations__r.isEmpty()) {
                    for(sked_Activity_Collection_Operation__c activityCO : activity.sked_Activity_Collection_Operations__r) {
                        if(territoryKeys.contains(activityCO.sked_Territory_Key__c)) {
                            isValidActivity = TRUE;
                            break;
                        }
                    }
                }
                if(isValidActivity && activity.sked__Activity_Resources__r != NULL && !activity.sked__Activity_Resources__r.isEmpty()) activityResources.addAll(activity.sked__Activity_Resources__r);
            }
        }
        return activityResources;
    }

    public static List<sked__Availability__c> getavailabilities(Date startDate, Date endDate, List<String> availabilityType, Set<String> collOpIds){
        return [SELECT Id,
                        Name,
                        sked_Start_Date__c,
                        sked_Start_Time__c,
                        sked_Finish_Time__c,
                		sked_Finish_Date__c,
                        sked__Type__c,
                        sked_Is_All_Day__c,
                        sked__Resource__c,
                        sked__Resource__r.Name,
                        sked__Resource__r.sked__Resource_Type__c,
                        sked__Resource__r.sked_Daily_Time_Off_Hours__c,
                        sked__Resource__r.RecordTypeId,
                        sked__Resource__r.RecordType.Name,
                        sked__Resource__r.sked__Primary_Region__c,
                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__c,
                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name
                FROM sked__Availability__c 
                WHERE sked__Resource__c != null
                AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                AND sked__Resource__r.RecordType.Name = 'Staff'
                AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                AND sked__Type__c IN :availabilityType
                AND sked__Status__c = 'Approved'
                AND sked_Start_Date__c >= :startDate 
                AND sked_Start_Date__c <= :endDate 
                ORDER BY sked_Start_Time__c ASC];
    }


    @AuraEnabled
    public static List<sked_Territory__c> getDivisionNames(Date startDate, Date endDate){
        List<sked_Territory__c> divisionList = new List<sked_Territory__c>();
        for(sked_Territory_Collection_Operation__c tco : getTerritoryCollectionOperation(startDate,endDate)){
            divisionList.add(tco.sked_Territory__r.sked_Parent__r.sked_Parent__r);
        }
        if(!divisionList.isEmpty()){
            Set<sked_Territory__c> divisionSet = new Set<sked_Territory__c>(divisionList);
            divisionList.clear();
            divisionList.addAll(divisionSet);
            divisionList.sort();
            divisionList = renameDuplicates(divisionList);
        }
        return divisionList;
    }

    
    @AuraEnabled
    public static List<sked_Territory__c> getRegionNames(Date startDate, Date endDate, String divId){
        if(String.isBlank(divId)){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_Division').Value__c;
            errMsg = errMsg.replace('{{division}}',String.valueOf(divId));
            throw new AuraHandledException(errMsg);
        }
        List<sked_Territory__c> regionList = new List<sked_Territory__c>();
        for(sked_Territory_Collection_Operation__c tco : getTerritoryCollectionOperation(startDate,endDate)){
            if(divId.equals(tco.sked_Territory__r.sked_Parent__r.sked_Parent__c)){
                regionList.add(tco.sked_Territory__r.sked_Parent__r);
            }
        }
        if(!regionList.isEmpty()){
            Set<sked_Territory__c> regionSet = new Set<sked_Territory__c>(regionList);
            regionList.clear();
            regionList.addAll(regionSet);
            regionList.sort();
            regionList = renameDuplicates(regionList);
        }
        return regionList;
    }

    
    @AuraEnabled
    public static List<sked_Territory__c> getDrictictNames(Date startDate, Date endDate, String regId){
        if(String.isBlank(regId)){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_Region').Value__c;
            errMsg = errMsg.replace('{{region}}',String.valueOf(regId));
            throw new AuraHandledException(errMsg);
        }
        List<sked_Territory__c> districtList = new List<sked_Territory__c>();
        for(sked_Territory_Collection_Operation__c tco : getTerritoryCollectionOperation(startDate,endDate)){
            if(regId.equals(tco.sked_Territory__r.sked_Parent__c)){
                districtList.add(tco.sked_Territory__r);
            }
        }
        if(!districtList.isEmpty()){
            Set<sked_Territory__c> districtSet = new Set<sked_Territory__c>(districtList);
            districtList.clear();
            districtList.addAll(districtSet);
            districtList.sort();
            districtList = renameDuplicates(districtList);
        }
        return districtList;
    }

    
    @AuraEnabled
    public static List<Biomed_Collection_Op_Center__c> getCollectionOpNames(Date startDate, Date endDate, String distIdList){
        if(String.isBlank(distIdList)){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_District').Value__c;
            errMsg = errMsg.replace('{{district}}',String.valueOf(distIdList));
            throw new AuraHandledException(errMsg);
        }
        List<String> distIds = distIdList.split(',');
        List<Biomed_Collection_Op_Center__c> collectionOpList = new List<Biomed_Collection_Op_Center__c>();
        for(sked_Territory_Collection_Operation__c tco : getTerritoryCollectionOperation(startDate,endDate)){
            if(distIds.contains(tco.sked_Territory__c)){
                collectionOpList.add(tco.sked_Collection_Operation__r);
            }
        }
        if(!collectionOpList.isEmpty()){
            Set<Biomed_Collection_Op_Center__c> collectionOpSet = new Set<Biomed_Collection_Op_Center__c>(collectionOpList);
            collectionOpList.clear();
            collectionOpList.addAll(collectionOpSet);
            collectionOpList.sort();
        }
        return collectionOpList;
    }

    @AuraEnabled
    public static Boolean isDriveDispatchedCheckBoxEnable(){
        Boolean result = false;
        String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1].Name;
        if(System.label.DriveDispatchedCheckBoxEnableProfile.split(',').contains(profileName)){
            result = true;
        }
        return result;
    }
    
    public static WeeklyStaffScheduleReportController.StaffInfoWrapper validateInputsAndGetStaffInfo(Date startDate, Date endDate, String drivedispatch, String collOpIdList, String driveType) {

        Map<String,String> driveDispatchedMap = new Map<String,String>();
        driveDispatchedMap.put('Yes',Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c);
        driveDispatchedMap.put('No',Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c);
        driveDispatchedMap.put('Both',Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c+','+
                                Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c);
        
        List<String> availabilityType = Custom_Report_Config__mdt.getInstance('AvailabilityType').Value__c.split(',');
        
        Map<String,String> driveTypeMap= new Map<String,String>{'mobile'=>'Mobile','fixed'=>'Fixed Site'};

        if(startDate == null || endDate == null){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Date_Null').Value__c;
            errMsg = errMsg.replace('{{startDate}}',String.valueOf(startDate));
            errMsg = errMsg.replace('{{endDate}}',String.valueOf(endDate));
            throw new AuraHandledException(errMsg);
        }

        if(startDate > endDate){
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Start_Date_greater').Value__c);
        }

        if(startDate.daysBetween(endDate) >= Integer.valueOf(label.RoleTimeMaxDateDifference)){
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_date_range').Value__c);
        }

        if(String.isBlank(drivedispatch) || !driveDispatchedMap.containsKey(drivedispatch)){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_Drive_Dispatch').Value__c;
            errMsg = errMsg.replace('{{drivedispatch}}',String.valueOf(drivedispatch));
            throw new AuraHandledException(errMsg);
        }

        if(String.isBlank(collOpIdList)){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_CollOp').Value__c;
            errMsg = errMsg.replace('{{collop}}',String.valueOf(collOpIdList));
            throw new AuraHandledException(errMsg);
        }

        if(String.isBlank(driveType)){
            String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_Drive_Type').Value__c;
            errMsg = errMsg.replace('{{driveType}}',String.valueOf(driveType));
            throw new AuraHandledException(errMsg);
        }
        
        
        List<String> driveTypes= new List<String>();
        for(String dvTyp: driveType.split(',')){
            if(driveTypeMap.containsKey(dvTyp)){
                driveTypes.add(driveTypeMap.get(dvTyp));
            }else {
                String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_Drive_Type').Value__c;
                errMsg = errMsg.replace('{{driveType}}',String.valueOf(dvTyp));
                throw new AuraHandledException(errMsg);
            }
        }
        Set<String> collOpIds= new Set<String>();
        for(String clop: collOpIdList.split(',')){
            if(String.isNotBlank(clop)){
                collOpIds.add(clop);
            }else{
                String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_CollOp').Value__c;
                errMsg = errMsg.replace('{{collop}}',clop);
                throw new AuraHandledException(errMsg);
            }
        }
        
        List<Boolean> driveDispatchedCheckBox= new List<Boolean>();

        if(drivedispatch.equalsIgnoreCase('Yes')){
            driveDispatchedCheckBox.add(true);
        }else if(drivedispatch.equalsIgnoreCase('No')){
            driveDispatchedCheckBox.add(false);
        }else{
            driveDispatchedCheckBox.add(true);
            driveDispatchedCheckBox.add(false);
        }
                                                                    

        List<String> driveDispatchedStatus= driveDispatchedMap.get(drivedispatch).split(',');
        WeeklyStaffScheduleReportController.StaffInfoWrapper staffInfoWrapper = new WeeklyStaffScheduleReportController.StaffInfoWrapper();
        
        List<sked__Job_Allocation__c> jobAllocationsRetrieved = getJobAllocations(startDate, endDate, driveDispatchedStatus, collOpIds, driveTypes, driveDispatchedCheckBox);
        
        if(jobAllocationsRetrieved.size() >= 50000) {
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Large_data').Value__c);
        }
        
        /* HRP-13121 -> Starts Here
        *  1. Get Territory Collection Operations for the selected collection operations
        *  2. Form Territory keys using district and CO combination
        *  3. Use the List of territory keys to get activities / activity COs
        */
        
        List<sked_Territory_Collection_Operation__c> territoryColOpList = [
            SELECT Id, sked_Territory__c, sked_Collection_Operation__c,
            sked_Start_Date__c, sked_End_Date__c
            FROM sked_Territory_Collection_Operation__c
            WHERE sked_Collection_Operation__c IN :collOpIds
            AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :startDate)
            AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :endDate)
        ];
        
        if(territoryColOpList.size() >= 50000 || (jobAllocationsRetrieved.size() + territoryColOpList.size() >= 50000)) {
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Large_data').Value__c);
        }
        
        Map<Id, List<sked_Territory_Collection_Operation__c>> map_colOpId_territoryCoList = new Map<Id, List<sked_Territory_Collection_Operation__c>>();
        for(sked_Territory_Collection_Operation__c territoryCO : territoryColOpList) {
            if(!map_colOpId_territoryCoList.containsKey(territoryCO.sked_Collection_Operation__c)) {
                map_colOpId_territoryCoList.put(territoryCO.sked_Collection_Operation__c, new List<sked_Territory_Collection_Operation__c>());
            }
            map_colOpId_territoryCoList.get(territoryCO.sked_Collection_Operation__c).add(territoryCO);
        }
        
        List<String> territoryKeys = new List<String>();
        
        for(Id colOpId : collOpIds) {
            if(map_colOpId_territoryCoList.containsKey(colOpId) && map_colOpId_territoryCoList.get(colOpId) != NULL) {
                for(sked_Territory_Collection_Operation__c territoryColOp : map_colOpId_territoryCoList.get(colOpId)) {
                    if(
                        (territoryColOp.sked_Start_Date__c == NULL || territoryColOp.sked_Start_Date__c <= startDate) && 
                        (territoryColOp.sked_End_Date__c == NULL || territoryColOp.sked_End_Date__c >= endDate)
                    ) {
                        
                        territoryKeys.add(territoryColOp.sked_Territory__c + ':' + territoryColOp.sked_Collection_Operation__c);
                        break;
                    }
                }
            }            
        }
        
        List<sked__Activity_Resource__c> activityResourcesRetrieved = getActivities(startDate, endDate, territoryKeys);
        
        if((jobAllocationsRetrieved.size() + activityResourcesRetrieved.size() >= 50000) || activityResourcesRetrieved.size() >= 50000) {
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Large_data').Value__c);
        }
        
        List<sked__Availability__c> availabilitiessRetrieved = getavailabilities(startDate, endDate, availabilityType, collOpIds);
        
        if(jobAllocationsRetrieved.size() + activityResourcesRetrieved.size() + availabilitiessRetrieved.size() >= 50000) {
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Large_data').Value__c);
        }
        
        if((jobAllocationsRetrieved.size() + activityResourcesRetrieved.size() + availabilitiessRetrieved.size()) == 0) {
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_No_data').Value__c);
        }
        
            /*[SELECT Count()
                                        FROM sked__Job_Allocation__c
                                        WHERE sked__Status__c != 'Deleted' 
                                        AND sked__Status__c IN :driveDispatchedStatus 
                                        AND sked__Resource__c != null
                                        AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                                        AND sked__Resource__r.RecordType.Name = 'Staff'
                                        AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                                        AND sked__Job__r.sked_Drive__c != null
                                        AND sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c IN :driveTypes
                                        AND sked__Job__r.sked_Drive__r.sked_Drive_Dispatched__c IN :driveDispatchedCheckBox
                                        AND sked__Job__r.sked_Drive__r.sked_Status__c != 'Cancel'
                                        AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c != null
                                        AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c >= :startDate
                                        AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c <= :endDate];  
        
        Integer activitiesCount =  [SELECT Count()
                                    FROM sked__Activity_Resource__c
                                    WHERE sked__Resource__c != null
                                    AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                                    AND sked__Resource__r.RecordType.Name = 'Staff'
                                    AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                                    AND sked__Activity__r.sked_Start_Date__c >=: startDate 
                                    AND sked__Activity__r.sked_Start_Date__c <=: endDate];
        
        Integer availabilitiesCount =  [SELECT Count()
                                        FROM sked__Availability__c 
                                        WHERE sked__Resource__c != null
                                        AND sked__Resource__r.sked__Resource_Type__c = 'Person'
                                        AND sked__Resource__r.RecordType.Name = 'Staff'
                                        AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                                        AND sked__Type__c IN :availabilityType
                                        AND sked__Status__c = 'Approved'
                                        AND sked_Start_Date__c >= :startDate 
                                        AND sked_Start_Date__c <= :endDate];*/
  
        staffInfoWrapper.jobAllocationList = jobAllocationsRetrieved;
        staffInfoWrapper.activityList = activityResourcesRetrieved;
        staffInfoWrapper.availabilityList = availabilitiessRetrieved;
        staffInfoWrapper.totalRecords = jobAllocationsRetrieved.size() + activityResourcesRetrieved.size() + availabilitiessRetrieved.size();
        
        return staffInfoWrapper; 
    }
    
    @AuraEnabled
    public static List<WeeklyStaffingRTReportWrapper> searchRoleTimeReport(Date startDate, Date endDate, String drivedispatch, String collOpIdList, String driveType, Boolean isForPDF){
        System.debug('startDate : '+startDate);
        System.debug('endDate : '+endDate);
        System.debug('drivedispatch : '+drivedispatch);
        System.debug('collOpIdList : '+collOpIdList);
        System.debug('driveType : '+driveType);

        Map<Date, Set<Id>> dateMap = new  Map<Date, Set<Id>>();
        Map<Id,String> resourceDistrictMap = new Map<Id,String>();
        Map<Id,sked_Drive__c> driveMap = new Map<Id,sked_Drive__c>();
        Map<Id, List<sked__Job_Allocation__c>> driveAllocationMap = new Map<Id, List<sked__Job_Allocation__c>>();
        Map<Id, String> driveVehicleMap = new Map<Id, String>();
        Map<Id, String> driveEquipmentMap = new Map<Id, String>();
        Map<Id, List<sked__Activity_Resource__c>> activityMap = new Map<Id, List<sked__Activity_Resource__c>>();
        List<WeeklyStaffingRTReportWrapper> data = new List<WeeklyStaffingRTReportWrapper>();

        WeeklyStaffScheduleReportController.StaffInfoWrapper staffInfoWrapper = new WeeklyStaffScheduleReportController.StaffInfoWrapper();
        staffInfoWrapper = validateInputsAndGetStaffInfo(startDate, endDate, drivedispatch, collOpIdList, driveType);

        Map<String,String> driveDispatchedMap = new Map<String,String>();
        driveDispatchedMap.put('Yes',Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c);
        driveDispatchedMap.put('No',Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c);
        driveDispatchedMap.put('Both',Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c+','+
                                Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c);
        List<String> availabilityType = Custom_Report_Config__mdt.getInstance('AvailabilityType').Value__c.split(',');
        Map<String,String> driveTypeMap= new Map<String,String>{'mobile'=>'Mobile','fixed'=>'Fixed Site'};

        List<String> driveTypes= new List<String>();
        Set<String> collOpIds= new Set<String>();
        List<String> driveDispatchedStatus= new List<String>();
        List<Boolean> driveDispatchedCheckBox= new List<Boolean>();

        for(String dvTyp: driveType.split(',')){
            if(driveTypeMap.containsKey(dvTyp)){
                driveTypes.add(driveTypeMap.get(dvTyp));
            }
        }

        for(String clop: collOpIdList.split(',')){
            if(String.isNotBlank(clop)){
                collOpIds.add(clop);
            }
        }

        driveDispatchedStatus = driveDispatchedMap.get(drivedispatch).split(',');
        if(drivedispatch.equalsIgnoreCase('Yes')){
            driveDispatchedCheckBox.add(true);
        }else if(drivedispatch.equalsIgnoreCase('No')){
            driveDispatchedCheckBox.add(false);
        }else{
            driveDispatchedCheckBox.add(true);
            driveDispatchedCheckBox.add(false);
        }

        //List<sked__Job_Allocation__c> jobAllocations =  getJobAllocations(startDate, endDate, driveDispatchedStatus, collOpIds, driveTypes, driveDispatchedCheckBox);
        
        for(sked__Job_Allocation__c jba : staffInfoWrapper.jobAllocationList) { //HRP-13121: Using wrapper class info
            if(!driveAllocationMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                driveAllocationMap.put(jba.sked__Job__r.sked_Drive__c, new List<sked__Job_Allocation__c>());
                if(!dateMap.containsKey(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c)){
                    dateMap.put(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c, new Set<Id>());
                }
                dateMap.get(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c).add(jba.sked__Job__r.sked_Drive__c);
            }
            driveAllocationMap.get(jba.sked__Job__r.sked_Drive__c).add(jba);
            driveMap.put(jba.sked__Job__r.sked_Drive__c,jba.sked__Job__r.sked_Drive__r);
            resourceDistrictMap.put(jba.sked__Resource__c,jba.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name);
        }

        List<sked__Job_Allocation__c> vehicleAllocations =  [SELECT Id, 
                                                                sked__Job__c,
                                                                sked__Job__r.sked_Drive__c,
                                                                sked__Job__r.sked__Type__c,
                                                                sked__Resource__c,
                                                                sked__Resource__r.sked_Asset_Type__c,
                                                                sked__Resource__r.Name
                                                        FROM sked__Job_Allocation__c
                                                        WHERE sked__Status__c != 'Deleted' 
                                                        AND sked__Resource__c != null
                                                        AND sked__Job__r.sked__Type__c IN ('Vehicle','Equipment')
                                                        AND sked__Job__r.sked_Drive__c IN :driveAllocationMap.keySet()]; 
        
        if((staffInfoWrapper.totalRecords + vehicleAllocations.size()) >= 50000) {
            throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Large_data').Value__c);
        }

        for(sked__Job_Allocation__c jba : vehicleAllocations) {
            if(jba.sked__Job__r.sked__Type__c == 'Vehicle'){
                if(!driveVehicleMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                    driveVehicleMap.put(jba.sked__Job__r.sked_Drive__c, '');
                }
                String vehicle = driveVehicleMap.get(jba.sked__Job__r.sked_Drive__c);
                if(String.isBlank(vehicle)){
                    vehicle = jba.sked__Resource__r.Name;
                }else{
                    vehicle += ', ' + jba.sked__Resource__r.Name;
                }
                driveVehicleMap.put(jba.sked__Job__r.sked_Drive__c,vehicle);
            }else if(jba.sked__Job__r.sked__Type__c == 'Equipment'){
                if(!driveEquipmentMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                    driveEquipmentMap.put(jba.sked__Job__r.sked_Drive__c, '');
                }
                String equipment = driveEquipmentMap.get(jba.sked__Job__r.sked_Drive__c);
                if(String.isBlank(equipment)){
                    equipment = jba.sked__Resource__r.Name;
                }else{
                    equipment += ', ' + jba.sked__Resource__r.Name;
                }
                driveEquipmentMap.put(jba.sked__Job__r.sked_Drive__c,equipment);
            }
        }

        //List<sked__Activity_Resource__c> activityList = getActivities(startDate, endDate, territoryKeys); //HRP-13121 -> Changed Method Parameter
        
        for(sked__Activity_Resource__c act : staffInfoWrapper.activityList) { //HRP-13121: Using wrapper class info
            if(!activityMap.containsKey(act.sked__Activity__c)){
                activityMap.put(act.sked__Activity__c, new List<sked__Activity_Resource__c>());
                
                //HRP-12921 --> Starts Here
                if (act.sked_Start_Date__c == act.sked_End_Date__c) {
                    if(!dateMap.containsKey(act.sked__Activity__r.sked_Start_Date__c)){
                        dateMap.put(act.sked__Activity__r.sked_Start_Date__c, new Set<Id>());
                    }
                    dateMap.get(act.sked__Activity__r.sked_Start_Date__c).add(act.sked__Activity__c);
           	 	}
                 else {
                    Date currentDate = act.sked_Start_Date__c;
                    while (currentDate <= act.sked_End_Date__c && currentDate <= endDate) {
                        if (currentDate >= startDate) {
                            if(!dateMap.containsKey(currentDate)){
                                dateMap.put(currentDate, new Set<Id>());
                            }
                            dateMap.get(currentDate).add(act.sked__Activity__c);
                        }
                        currentDate = currentDate.addDays(1);
                    }
                  }
                //HRP-12921 --> Continues
            
            }
            activityMap.get(act.sked__Activity__c).add(act);
            resourceDistrictMap.put(act.sked__Resource__c,act.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name);
        }

        Map<Id, sked__Availability__c> availabilityMap = new Map<Id, sked__Availability__c>();
        //List<sked__Availability__c> availabilityList = getavailabilities(startDate,endDate,availabilityType,collOpIds);
        if(!staffInfoWrapper.availabilityList.isEmpty()) { //HRP-13121: Using wrapper class info
            availabilityMap = new Map<Id, sked__Availability__c>(staffInfoWrapper.availabilityList);
        }
        
        for(Id avlId : availabilityMap.keySet()){
            
            //HRP-12921 --> Continues
            if (availabilityMap.get(avlId).sked_Start_Date__c == availabilityMap.get(avlId).sked_Finish_Date__c) {
                if(!dateMap.containsKey(availabilityMap.get(avlId).sked_Start_Date__c)){
                    dateMap.put(availabilityMap.get(avlId).sked_Start_Date__c, new Set<Id>());
                }
                dateMap.get(availabilityMap.get(avlId).sked_Start_Date__c).add(avlId);
           }
            else {
                    Date currentDate = availabilityMap.get(avlId).sked_Start_Date__c;
                    while (currentDate <= availabilityMap.get(avlId).sked_Finish_Date__c && currentDate <= endDate) {
                        if (currentDate >= startDate) {
                            if(!dateMap.containsKey(currentDate)){
                                    dateMap.put(currentDate, new Set<Id>());
                                }
                                dateMap.get(currentDate).add(avlId);
                        }
                        currentDate = currentDate.addDays(1);
                    }
            }
            //HRP-12921 --> Ends Here
            resourceDistrictMap.put(availabilityMap.get(avlId).sked__Resource__c,availabilityMap.get(avlId).sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name);
        }


        List<Date> dateList = new List<Date>(dateMap.keySet());
        dateList.sort();

        

        for(Date dt : dateList){
            WeeklyStaffingRTReportWrapper wrapper = new WeeklyStaffingRTReportWrapper();
            wrapper.eventDate = dateFormat2(dt);
            wrapper.eventDetails = new List<EventDetails>();

            for(Id sobjectId : dateMap.get(dt)){
                EventDetails evDetails = new EventDetails();
                evDetails.resources = new List<ResourceDetails>();

                if(driveAllocationMap.containsKey(sobjectId)){
                    evDetails.isDrive = true;
                    Set<String> resourceDistricts = new Set<String>();

                    if(driveMap.containsKey(sobjectId)){
                        evDetails.eventName = driveMap.get(sobjectId).sked_Account__r.Name;
                        String siteAddress = '';
                        if(String.isNotBlank(driveMap.get(sobjectId).sked_Drive_Site__r.sked_Address_1__c)){
                            siteAddress = driveMap.get(sobjectId).sked_Drive_Site__r.sked_Address_1__c;
                        }
                        if(String.isNotBlank(driveMap.get(sobjectId).sked_Drive_Site__r.sked_City__c)){
                            if(String.isNotBlank(siteAddress)){
                                siteAddress += ', ';
                            }
                            siteAddress += driveMap.get(sobjectId).sked_Drive_Site__r.sked_City__c;
                        }
                        if(String.isNotBlank(driveMap.get(sobjectId).sked_Drive_Site__r.sked_County__c)){
                            if(String.isNotBlank(siteAddress)){
                                siteAddress += ', ';
                            }
                            siteAddress += driveMap.get(sobjectId).sked_Drive_Site__r.sked_County__c;
                        }
                        if(String.isNotBlank(driveMap.get(sobjectId).sked_Drive_Site__r.sked_State__c)){
                            if(String.isNotBlank(siteAddress)){
                                siteAddress += ', ';
                            }
                            siteAddress += driveMap.get(sobjectId).sked_Drive_Site__r.sked_State__c;
                        }
                        if(String.isNotBlank(siteAddress)){
                            evDetails.eventName += '\n' + siteAddress;
                        }
                        evDetails.projProc = String.valueOf(driveMap.get(sobjectId).sked_Total_Procedures_Projected__c);
                        evDetails.staffReq = String.valueOf(driveMap.get(sobjectId).sked_Total_Staff_Requested__c);
                        evDetails.assignedMachineCount = String.valueOf(driveMap.get(sobjectId).sked_Equipment_Allocated__c);
                        evDetails.hours = getFormattedTime(driveMap.get(sobjectId).sked_Start_Time__c.hour(),driveMap.get(sobjectId).sked_Start_Time__c.minute()) 
                                    + ' - ' + getFormattedTime(driveMap.get(sobjectId).sked_End_Time__c.hour(),driveMap.get(sobjectId).sked_End_Time__c.minute());
                        evDetails.eventVehicles = driveVehicleMap.containsKey(sobjectId) ? driveVehicleMap.get(sobjectId) : '';
                        evDetails.autoMachines = driveEquipmentMap.containsKey(sobjectId) ? driveEquipmentMap.get(sobjectId) : '';
                    }
                    

                    for(sked__Job_Allocation__c jba : driveAllocationMap.get(sobjectId)){
                        ResourceDetails rsDetails = new ResourceDetails();

                        rsDetails.resourceName = BSF_Utilities.capitalizeName(jba.sked__Resource__r.Name, isForPDF);

                        rsDetails.shiftStart = jba.sked_Start_Time__c != null ? getFormattedTime(jba.sked_Start_Time__c.hour(),jba.sked_Start_Time__c.minute()) : '';//Changed for HRP-13091
                        rsDetails.shiftEnd = jba.sked_Set_End_Time__c != null ? getFormattedTime(jba.sked_Set_End_Time__c.hour(),jba.sked_Set_End_Time__c.minute()) : '';//Changed for HRP-13091

                        List<String> roleList = new List<String>{jba.sked__Job__r.sked_Resource_Role__c};
                        if(String.isNotBlank(jba.sked__Job__r.sked_Dual_Role__c)){
                            roleList.add(jba.sked__Job__r.sked_Dual_Role__c);
                        }
                        if(String.isNotBlank(jba.sked_Additional_Roles__c)){
                            roleList.addall(jba.sked_Additional_Roles__c.split(';'));
                        }
                        if(roleList.size() > 0){
                            List<String> roleListNoDupes = new List<String>(new Set<String>(roleList));
                            rsDetails.resourceRole = String.join(roleListNoDupes,', ');
                        }

                        Integer arrivalTimeInMinutes = 0;
                        if(jba.sked__Job__r.sked_Setup_Time__c != null){
                            arrivalTimeInMinutes += Integer.valueOf(jba.sked__Job__r.sked_Setup_Time__c);
                        }
                        if(jba.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c == true
                                &&jba.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c != null){
                                    arrivalTimeInMinutes += Integer.valueOf(jba.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c);
                        }

                        Time arrivalTime = jba.sked__Job__r.sked_Drive_Shift__r.sked_Start_Time__c.addMinutes(0 - arrivalTimeInMinutes);

                        rsDetails.staffArrivalTime = getFormattedTime(arrivalTime.hour(),arrivalTime.minute());

                        if(jba.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c == true){
                            rsDetails.staffArrivalTime += '*';
                        }
                        
                        resourceDistricts.add(resourceDistrictMap.get(jba.sked__Resource__c));
                        evDetails.resources.add(rsDetails);
                    }

                    evDetails.eventName += '\n' + String.join(resourceDistricts,', ');
                }else if(availabilityMap.containsKey(sobjectId)){
                    evDetails.isDrive = false;
                    evDetails.eventName = availabilityMap.get(sobjectId).sked__Type__c;
                    evDetails.hours = getFormattedTime(availabilityMap.get(sobjectId).sked_Start_Time__c.hour(),availabilityMap.get(sobjectId).sked_Start_Time__c.minute()) 
                                    + ' - ' + getFormattedTime(availabilityMap.get(sobjectId).sked_Finish_Time__c.hour(),availabilityMap.get(sobjectId).sked_Finish_Time__c.minute());
                    evDetails.eventVehicles = '';
                    evDetails.autoMachines = '';

                    ResourceDetails rsDetails = new ResourceDetails();
                    rsDetails.resourceName = BSF_Utilities.capitalizeName(availabilityMap.get(sobjectId).sked__Resource__r.Name, isForPDF);
                    rsDetails.resourceRole = '';
                    rsDetails.staffArrivalTime = '';
                    rsDetails.shiftStart = getFormattedTime(availabilityMap.get(sobjectId).sked_Start_Time__c.hour(),availabilityMap.get(sobjectId).sked_Start_Time__c.minute());
                    rsDetails.shiftEnd = getFormattedTime(availabilityMap.get(sobjectId).sked_Finish_Time__c.hour(),availabilityMap.get(sobjectId).sked_Finish_Time__c.minute());
                    evDetails.resources.add(rsDetails);
                }else if(activityMap.containsKey(sobjectId)){
                    evDetails.isDrive = false;
                    evDetails.eventVehicles = '';
                    evDetails.autoMachines = '';
                    Set<String> resourceDistricts = new Set<String>();
                    Boolean eventNameAdded = false;

                    for(sked__Activity_Resource__c actr : activityMap.get(sobjectId)){
                        if(!eventNameAdded){
                            evDetails.eventName = actr.sked__Activity__r.sked__Type__c;
                            if(String.isNotBlank(actr.sked__Activity__r.sked__Notes__c)){
                                evDetails.eventName += '-' + actr.sked__Activity__r.sked__Notes__c;
                            }
                            if(actr.sked_Start_Time__c != NULL && actr.sked_End_Time__c != NULL){
                                evDetails.hours = getFormattedTime(actr.sked_Start_Time__c.hour(),actr.sked__Activity__r.sked_Start_Time__c.minute()) 
                                                + ' - ' + getFormattedTime(actr.sked_End_Time__c.hour(),actr.sked_End_Time__c.minute());
                                }
                            else{
                                evDetails.hours = getFormattedTime(actr.sked_Start_Time__c.hour(),actr.sked__Activity__r.sked_Start_Time__c.minute()) 
                                            + ' - ' + getFormattedTime(actr.sked__Activity__r.sked_End_Time__c.hour(),actr.sked__Activity__r.sked_End_Time__c.minute());
                            }
                                evDetails.hours = getFormattedTime(actr.sked__Activity__r.sked_Start_Time__c.hour(),actr.sked__Activity__r.sked_Start_Time__c.minute()) 
                                                + ' - ' + getFormattedTime(actr.sked__Activity__r.sked_End_Time__c.hour(),actr.sked__Activity__r.sked_End_Time__c.minute());
                                eventNameAdded = true;
                        }

                        ResourceDetails rsDetails = new ResourceDetails();
                        rsDetails.resourceName = BSF_Utilities.capitalizeName(actr.sked__Resource__r.Name, isForPDF);
                        rsDetails.resourceRole = '';
                        rsDetails.staffArrivalTime = '';
                        if(actr.sked_Start_Time__c != NULL && actr.sked_End_Time__c != NULL){
                            rsDetails.shiftStart = getFormattedTime(actr.sked_Start_Time__c.hour(),actr.sked_Start_Time__c.minute());
                            rsDetails.shiftEnd = getFormattedTime(actr.sked_End_Time__c.hour(),actr.sked_End_Time__c.minute());
                        }
                        else{
                            rsDetails.shiftStart = getFormattedTime(actr.sked__Activity__r.sked_Start_Time__c.hour(),actr.sked__Activity__r.sked_Start_Time__c.minute());
                        	rsDetails.shiftEnd = getFormattedTime(actr.sked__Activity__r.sked_End_Time__c.hour(),actr.sked__Activity__r.sked_End_Time__c.minute());
                        }    
                        resourceDistricts.add(resourceDistrictMap.get(actr.sked__Resource__c));
                        evDetails.resources.add(rsDetails);
                    }

                    evDetails.eventName += '\n' + String.join(resourceDistricts,', ');
                }
                evDetails.resources = sortByResourceName(evDetails.resources);
                wrapper.eventDetails.add(evDetails);
            }

            data.add(wrapper);
        }
        //data = addBlankResources(data);
        return calculateRowSpan(data);                                                 
    }

    public static List<WeeklyStaffingRTReportWrapper> calculateRowSpan(List<WeeklyStaffingRTReportWrapper> data){
        if(data != null){
            for(WeeklyStaffingRTReportWrapper wrapper : data){
                Integer wrapperRowSpan = 1;
                if(wrapper.eventDetails != null){
                    for(EventDetails evDetails : wrapper.eventDetails){
                        evDetails.rowspan = (evDetails.resources != null) ? (evDetails.resources.size() + 1) : 1;
                        wrapperRowSpan += evDetails.rowspan;
                    }
                }
                wrapper.rowspan = wrapperRowSpan;
            }
        }
        return data;
    }
    public static List<WeeklyStaffingRTReportWrapper> addBlankResources(List<WeeklyStaffingRTReportWrapper> data){
        if(data != null){
            for(WeeklyStaffingRTReportWrapper wrapper : data){
                if(wrapper.eventDetails != null){
                    for(EventDetails evDetails : wrapper.eventDetails){
                        Integer min_row = (evDetails.isDrive == true) ? 
                            				Integer.valueOf(Custom_Report_Config__mdt.getInstance('RoleTimeReportDriveBlankRows').Value__c) : 
                                            Integer.valueOf(Custom_Report_Config__mdt.getInstance('RoleTimeReportNonDriveBlankRows').Value__c);
                        if(evDetails.resources != null && evDetails.resources.size() < min_row){
                            Integer blank_row = min_row - evDetails.resources.size();
                            for(Integer i = 0; i<blank_row; i++){
                                ResourceDetails resd = new ResourceDetails();
                                resd.resourceName = ' -';
                                resd.resourceRole = ' -';
                                resd.staffArrivalTime = ' -';
                                resd.shiftStart = ' -';
                                resd.shiftEnd = ' -';
                                evDetails.resources.add(resd);
                            }
                        }
                    }
                }
            }
        }
        return data;
    }

    public static List<ResourceDetails> sortByResourceName(List<ResourceDetails> resourceList){
        List<ResourceDetails> sortedList = new List<ResourceDetails>();
        if(resourceList != null && !resourceList.isEmpty()){
            Map<String, ResourceDetails> resourceMAp = new Map<String, ResourceDetails>();
            for(ResourceDetails resourceData : resourceList){
                resourceMAp.put(resourceData.resourceName,resourceData);
            }
            List<String> resourceNameList = new List<String>();
            resourceNameList.addAll(resourceMAp.keySet());
            resourceNameList.sort();
            for(String resName : resourceNameList){
                sortedList.add(resourceMAp.get(resName));
            }
        }
        return sortedList;
    }

     /*public static String capitalizeName(String unformatedName, Boolean isForPDF){
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
    }*/

    public static String dateFormat(date preDate){
        String result = '';
        if(preDate != null){
            DateTime dDate = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day());
            result = dDate.format('M/d/yyyy');
        }
        return result;
    }
    
    public static String dateFormat2(date preDate){
        String result = '';
        if(preDate != null){
            DateTime dDate = DateTime.newInstance(preDate.year(),preDate.month(),preDate.day());
            result = dDate.format('M/d/yyyy EEEE');
        }
        return result;
    }

    public static String getFormattedTime(Integer hour, Integer minutes){
        String st;
        if(hour == 0){
            hour = 12;
            st = 'AM';
        }else if(hour < 12){
            st = 'AM';
        }else if(hour == 12){
            st = 'PM';
        }else if(hour > 12){
            hour = hour - 12;
            st = 'PM';
        }
        if(minutes < 10){
            System.debug('final --> '+hour+':0'+minutes+st);
            return hour+':0'+minutes+' '+st;
        }else{
            System.debug('final --> '+hour+':'+minutes+st);
            return hour+':'+minutes+' '+st;
        }
    }

    public static List<Sobject> renameDuplicates(List<Sobject> shortedDataList){
        Schema.SObjectType territoryType = Schema.sked_Territory__c.getSObjectType();
        for(Sobject record : shortedDataList){
            if(record.getSObjectType() == territoryType && record.isSet('Name') && record.get('Name') != null 
                    && String.isNotBlank((String)record.get('Name')) && record.isSet('Start_Date__c') && record.isSet('End_Date__c')){
                        String formattedStartDate = record.get('Start_Date__c') != null ? dateFormat((Date)record.get('Start_Date__c')) : 'N/A';
                        String formattedEndDate = record.get('End_Date__c') != null ? dateFormat((Date)record.get('End_Date__c')) : 'N/A';
                        String newName = (String)record.get('Name') + ' ('+ formattedStartDate +' - '+ formattedEndDate + ')';
                        record.put('Name',newName);
            }
        }
        return shortedDataList;
    }

    
    public class WeeklyStaffingRTReportWrapper{
        @AuraEnabled public String eventDate {get; set;}
        @AuraEnabled public Integer rowspan {get; set;}
        @AuraEnabled public List<EventDetails> eventDetails {get; set;}
    }
    public class EventDetails{
        @AuraEnabled public String eventName {get; set;}
        @AuraEnabled public Boolean isDrive {get; set;}
        @AuraEnabled public String projProc {get; set;}
        @AuraEnabled public String assignedMachineCount {get; set;}
        @AuraEnabled public String staffReq {get; set;}
        @AuraEnabled public String hours {get; set;}
        @AuraEnabled public String eventVehicles {get; set;}
        @AuraEnabled public String autoMachines {get; set;}
        @AuraEnabled public Integer rowspan {get; set;}
        @AuraEnabled public List<ResourceDetails> resources {get; set;}
    }
    public class ResourceDetails{
        @AuraEnabled public String resourceName {get; set;}
        @AuraEnabled public String resourceRole {get; set;}
        @AuraEnabled public String staffArrivalTime {get; set;}
        @AuraEnabled public String shiftStart {get; set;}
        @AuraEnabled public String shiftEnd {get; set;}
    }
}