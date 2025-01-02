/*
*    Date					Developer Name			             Comments
 * ***************************************************************************************************************************************************************************
 * 07/15/2024				Barnojit Sharma				Weekly Staffing Schedule by Employee & Weekly Staffing Role Time Back up Reports shift start and end times are incorrect (HRP-13091)
 * 12/31/2024				Priti Jana					Logic for HRP-13121
 *****************************************************************************************************************************************************************************
*/
public without sharing class WeeklyStaffScheduleReportController {
    public DatablePDFWrapper wrapper {get; set;}

    public WeeklyStaffScheduleReportController(){
        Date sdate;
        Date edate;

        String startDate = Apexpages.currentPage().getParameters().get('startdate');
        String endDate = Apexpages.currentPage().getParameters().get('enddate');
        String collOpIds = Apexpages.currentPage().getParameters().get('collopids');
        String driveType = Apexpages.currentPage().getParameters().get('drivetypes');
        String drivedispatch = Apexpages.currentPage().getParameters().get('dispatch');

        if(String.isNotBlank(startDate)){
            startDate = String.escapeSingleQuotes(startDate);
            startDate = startDate.escapeHtml4();
            sdate = Date.valueOf(startDate);
        }
        if(String.isNotBlank(endDate)){
            endDate = String.escapeSingleQuotes(endDate);
            endDate = endDate.escapeHtml4();
            edate = Date.valueOf(endDate);
        }
        if(String.isNotBlank(collOpIds)){
            collOpIds = String.escapeSingleQuotes(collOpIds);
            collOpIds = collOpIds.escapeHtml4();
        }
        if(String.isNotBlank(driveType)){
            driveType = String.escapeSingleQuotes(driveType);
            driveType = driveType.escapeHtml4();
        }
        if(String.isNotBlank(drivedispatch)){
            drivedispatch = String.escapeSingleQuotes(drivedispatch);
            drivedispatch = drivedispatch.escapeHtml4();
        }

        this.wrapper = WeeklyStaffScheduleReportController.getPdfReport(sdate,edate,drivedispatch,collOpIds,driveType);

        if(ApexPages.currentPage().getParameters().get('force_download') != null 
                    && ApexPages.currentPage().getParameters().get('force_download') == 'true'){
                        ApexPages.currentPage().getHeaders().put('Content-Disposition', 'attachment; filename="WeeklyStaffingSchedulebyEmployeReport.pdf"');
        } 
    }
    
    @AuraEnabled
    public static DatableConfigWrapper searchReport(Date startDate, Date endDate, String drivedispatch, String collOpIdList, String driveType){

        DatableConfigWrapper data = new DatableConfigWrapper();
        data.dataWrapper = new List<Map<String,String>>();
        data.columnsInfo = new List<Map<String,Object>>();
        Map<Date,String> dateMap = new  Map<Date,String>();
        Map<Id,Map<Date,String>> resourceDetailsMap = new  Map<Id,Map<Date,String>>();
        Map<Id,Decimal> resourceHoursMap = new  Map<Id,Decimal>();
        Map<Id,sked__Resource__c> resourceMap = new Map<Id,sked__Resource__c>();

        List<String> driveTypes= new List<String>();
        Set<String> collOpIds= new Set<String>();
        List<String> driveDispatchedStatus= new List<String>();
        List<Boolean> driveDispatchedCheckBox= new List<Boolean>();
        
        Integer recordCount = BSFWeeklyStaffingRoleTimeController.validateInputs(startDate,endDate,drivedispatch,collOpIdList,driveType);
        
        Map<String,String> driveDispatchedMap = new Map<String,String>();
        driveDispatchedMap.put('Yes',Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c);
        driveDispatchedMap.put('No',Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c);
        driveDispatchedMap.put('Both',Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c+','+
                                Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c);

        Map<String,String> driveTypeMap= new Map<String,String>{'mobile'=>'Mobile','fixed'=>'Fixed Site'};

        List<String> availabilityType = Custom_Report_Config__mdt.getInstance('AvailabilityType').Value__c.split(',');

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

        data.columnsInfo.add(new Map<String,Object>{'label'=>'Resource','fieldName'=>'Name','type'=>'text','wrapText'=>true,'hideDefaultActions'=>true});
        Integer i = 0;
        for(Date dt = startDate ; dt <= endDate ; dt = dt.addDays(1)){
            DateTime sDateTime = DateTime.newInstance(dt.year(),dt.month(),dt.day());
            String formattedDT = sDateTime.format('M/d/yyyy');
            Map<String,Object> columns = new Map<String,Object>();
            columns.put('label',formattedDT);
            columns.put('fieldName','eventDate'+i);
            dateMap.put(dt,'eventDate'+i);
            columns.put('type','text');
            columns.put('wrapText',true);
            columns.put('hideDefaultActions',true);
            data.columnsInfo.add(columns);
            i++;
        }

        data.columnsInfo.add(new Map<String,Object>{'label'=>'Total Hours','fieldName'=>'total','type'=>'text','wrapText'=>true,'hideDefaultActions'=>true});

		List<sked__Job_Allocation__c> jobAllocations =  BSFWeeklyStaffingRoleTimeController.getJobAllocations(startDate, endDate, driveDispatchedStatus, collOpIds, driveTypes, driveDispatchedCheckBox);

        for(sked__Job_Allocation__c jba : jobAllocations){
            resourceMap.put(jba.sked__Resource__c,jba.sked__Resource__r);
            if(!resourceDetailsMap.containsKey(jba.sked__Resource__c)){
                resourceDetailsMap.put(jba.sked__Resource__c, new Map<Date,String>());
                resourceHoursMap.put(jba.sked__Resource__c,0);
            }
            String allRoles = '';
            List<String> roleList = new List<String>{jba.sked__Job__r.sked_Resource_Role__c};
            if(String.isNotBlank(jba.sked__Job__r.sked_Dual_Role__c)){
                roleList.add(jba.sked__Job__r.sked_Dual_Role__c);
            }
            if(String.isNotBlank(jba.sked_Additional_Roles__c)){
                roleList.addall(jba.sked_Additional_Roles__c.split(';'));
            }
            if(roleList.size() > 0){
                List<String> roleListNoDupes = new List<String>(new Set<String>(roleList));
                allRoles = String.join(roleListNoDupes,', ');
            }
            Decimal timeDifference = getTimeDifference(jba.sked_Start_Time__c,jba.sked_Set_End_Time__c);//Changed for HRP-13091
            String details = jba.sked__Job__r.sked_Drive__r.sked_Account__r.Name;
            String siteAddress = '';
            if(String.isNotBlank(jba.sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_City__c)){
                siteAddress = jba.sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_City__c;
            }
            if(String.isNotBlank(jba.sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_State__c)){
                if(String.isNotBlank(siteAddress)){
                    siteAddress += ', ';
                }
                siteAddress += jba.sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_State__c;
            }
            if(String.isNotBlank(siteAddress)){
                details += '\n' + siteAddress;
            }
            details += '\n' + getFormattedTime(jba.sked_Start_Time__c) + ' - ' + //Changed for HRP-13091
                        getFormattedTime(jba.sked_Set_End_Time__c)+'\n'+ //Changed for HRP-13091
                        allRoles + '\n' + String.valueOf(timeDifference) +' hrs';
            if(!resourceDetailsMap.get(jba.sked__Resource__c).containsKey(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c)){
                resourceDetailsMap.get(jba.sked__Resource__c).put(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c,details);
            }else{
                String allDetails = resourceDetailsMap.get(jba.sked__Resource__c).get(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c);
                allDetails += '\n\n'+details;
                resourceDetailsMap.get(jba.sked__Resource__c).put(jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c,allDetails);
            }
            timeDifference = timeDifference + resourceHoursMap.get(jba.sked__Resource__c);
            resourceHoursMap.put(jba.sked__Resource__c,timeDifference);                 
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
        //HRP-13121 -> Ends Here

        List<sked__Activity_Resource__c> activityList = BSFWeeklyStaffingRoleTimeController.getActivities(startDate, endDate, territoryKeys); //HRP-13121 -> Changed Method Parameter
        
        for(sked__Activity_Resource__c act : activityList){
            resourceMap.put(act.sked__Resource__c,act.sked__Resource__r);
            if(!resourceDetailsMap.containsKey(act.sked__Resource__c)){
                resourceDetailsMap.put(act.sked__Resource__c, new Map<Date,String>());
                resourceHoursMap.put(act.sked__Resource__c,0);
            }
            //HRP-12921 --> Starts Here
            String details = '';
            Decimal timeDifference = 0.0;
            String notes = '';
            if(String.isNotBlank(act.sked__Activity__r.sked__Notes__c)){
                notes = '-' + act.sked__Activity__r.sked__Notes__c;
            }
                if(act.sked_Start_Time__c != NULL && act.sked_End_Time__c != NULL){
                    timeDifference = getTimeDifference(act.sked_Start_Time__c,act.sked_End_Time__c);
                    details = act.sked__Activity__r.sked__Type__c + '\n' + notes + '\n'+
                                        getFormattedTime(act.sked_Start_Time__c) + ' - ' + 
                                        getFormattedTime(act.sked_End_Time__c)+'\n'+
                                        String.valueOf(timeDifference) +' hrs';
                }
                else{
                    timeDifference = getTimeDifference(act.sked__Activity__r.sked_Start_Time__c,act.sked__Activity__r.sked_End_Time__c);
                     details = act.sked__Activity__r.sked__Type__c + '\n' + notes + '\n'+
                                getFormattedTime(act.sked__Activity__r.sked_Start_Time__c) + ' - ' + 
                                getFormattedTime(act.sked__Activity__r.sked_End_Time__c)+'\n'+
                                String.valueOf(timeDifference) +' hrs';
                }
            if (act.sked_Start_Date__c == act.sked_End_Date__c) {
                if(!resourceDetailsMap.get(act.sked__Resource__c).containsKey(act.sked__Activity__r.sked_Start_Date__c)){
                    resourceDetailsMap.get(act.sked__Resource__c).put(act.sked__Activity__r.sked_Start_Date__c,details);
                }else{
                    String allDetails = resourceDetailsMap.get(act.sked__Resource__c).get(act.sked__Activity__r.sked_Start_Date__c);
                    allDetails += '\n\n'+details;
                    resourceDetailsMap.get(act.sked__Resource__c).put(act.sked__Activity__r.sked_Start_Date__c,allDetails);
                }
                timeDifference = timeDifference + resourceHoursMap.get(act.sked__Resource__c);
                resourceHoursMap.put(act.sked__Resource__c,timeDifference);          
        }else {
                Date currentDate = act.sked_Start_Date__c;
                while (currentDate <= act.sked_End_Date__c && currentDate <= endDate) {
                    if (currentDate >= startDate) {
                            if(!resourceDetailsMap.get(act.sked__Resource__c).containsKey(currentDate)){
                                resourceDetailsMap.get(act.sked__Resource__c).put(currentDate,details);
                            }else{
                                String allDetails = resourceDetailsMap.get(act.sked__Resource__c).get(currentDate);
                                allDetails += '\n\n'+details;
                                resourceDetailsMap.get(act.sked__Resource__c).put(currentDate,allDetails);
                            }
                            timeDifference = timeDifference + resourceHoursMap.get(act.sked__Resource__c);
                            resourceHoursMap.put(act.sked__Resource__c,timeDifference);
                                    }
                    currentDate = currentDate.addDays(1);
                }
             }
            //HRP-12921 --> Continues          
        }
        
        List<sked__Availability__c> availabilityList = BSFWeeklyStaffingRoleTimeController.getavailabilities(startDate,endDate,availabilityType,collOpIds);
        
        for(sked__Availability__c avl : availabilityList){
            resourceMap.put(avl.sked__Resource__c,avl.sked__Resource__r);
            if(!resourceDetailsMap.containsKey(avl.sked__Resource__c)){
                resourceDetailsMap.put(avl.sked__Resource__c, new Map<Date,String>());
                resourceHoursMap.put(avl.sked__Resource__c,0);
            }
             //HRP-12921 --> Continues
            Decimal timeDifference = 0;
            if(avl.sked_Is_All_Day__c && avl.sked__Resource__r.sked_Daily_Time_Off_Hours__c != null){
                timeDifference = avl.sked__Resource__r.sked_Daily_Time_Off_Hours__c;
            }else{
                timeDifference = getTimeDifference(avl.sked_Start_Time__c,avl.sked_Finish_Time__c);
            }
            String details = avl.sked__Type__c + '\n' + String.valueOf(timeDifference) +' hrs';
            if (avl.sked_Start_Date__c == avl.sked_Finish_Date__c) {
            
            if(!resourceDetailsMap.get(avl.sked__Resource__c).containsKey(avl.sked_Start_Date__c)){
                resourceDetailsMap.get(avl.sked__Resource__c).put(avl.sked_Start_Date__c,details);
            }else{
                String allDetails = resourceDetailsMap.get(avl.sked__Resource__c).get(avl.sked_Start_Date__c);
                allDetails += '\n\n'+details;
                resourceDetailsMap.get(avl.sked__Resource__c).put(avl.sked_Start_Date__c,allDetails);
            }
            timeDifference = timeDifference + resourceHoursMap.get(avl.sked__Resource__c);
            resourceHoursMap.put(avl.sked__Resource__c,timeDifference); 
        }
            else {
                    // Create wrapper instances for all dates within the range
                    Date currentDate = avl.sked_Start_Date__c;
                    while (currentDate <= avl.sked_Finish_Date__c && currentDate <= endDate) {
                        if (currentDate >= startDate) {
                            if(!resourceDetailsMap.get(avl.sked__Resource__c).containsKey(currentDate)){
                                resourceDetailsMap.get(avl.sked__Resource__c).put(currentDate,details);
                            }else{
                                String allDetails = resourceDetailsMap.get(avl.sked__Resource__c).get(currentDate);
                                allDetails += '\n\n'+details;
                                resourceDetailsMap.get(avl.sked__Resource__c).put(currentDate,allDetails);
                            }
                            timeDifference = timeDifference + resourceHoursMap.get(avl.sked__Resource__c);
                            resourceHoursMap.put(avl.sked__Resource__c,timeDifference);
                        }
                        currentDate = currentDate.addDays(1);
                    }
            }
            //HRP-12921 --> Ends Here 
        }

        for(Id resourceId : resourceDetailsMap.keySet()){
            Map<String,String> wrapperMap = new Map<String,String>();
            wrapperMap.put('Id',resourceId);
            wrapperMap.put('Name',BSFWeeklyStaffingRoleTimeController.capitalizeName(resourceMap.get(resourceId).Name));
            wrapperMap.put('total',String.valueOf(resourceHoursMap.get(resourceId)));
            for(Date dt : dateMap.keySet()){
                if(resourceDetailsMap.get(resourceId).containsKey(dt)){
                    wrapperMap.put(dateMap.get(dt),resourceDetailsMap.get(resourceId).get(dt));
                }else{
                    wrapperMap.put(dateMap.get(dt),'');
                }
            }
            data.dataWrapper.add(wrapperMap);
        }

        data.dataWrapper = sortByName(data.dataWrapper);

        return data;                                                 
    }

    public static DatablePDFWrapper getPdfReport(Date startDate, Date endDate, String drivedispatch, String collOpIdList, String driveType){
        DatablePDFWrapper wrapper = new DatablePDFWrapper();
        Map<Date,String> dateMap = new  Map<Date,String>();
        List<Date> dateList = new List<Date>();
        Integer indx = 0;

        DatableConfigWrapper configWrapper = searchReport(startDate,endDate,drivedispatch,collOpIdList,driveType);
        
        wrapper.headerWrapper = new List<String>();
        wrapper.headerWrapper.add('Resource');
        for(Date dt = startDate ; dt <= endDate ; dt = dt.addDays(1)){
            DateTime sDateTime = DateTime.newInstance(dt.year(),dt.month(),dt.day());
            String formattedDT = sDateTime.format('M/d/yyyy');
            wrapper.headerWrapper.add(formattedDT);
            dateMap.put(dt,'eventDate'+indx);
            dateList.add(dt);
            indx++;
        }
        wrapper.headerWrapper.add('Total Hours');
        wrapper.dataWrapper = new List<List<String>>();
        if(configWrapper != null && configWrapper.dataWrapper != null && !configWrapper.dataWrapper.isEmpty()){
            for(Map<String,String> data : configWrapper.dataWrapper){
                List<String> rowData = new List<String>();
                rowData.add(data.get('Name'));
                for(Date key : dateList){
                    rowData.add(data.get(dateMap.get(key)).trim());
                }
                rowData.add(data.get('total'));
                wrapper.dataWrapper.add(rowData);
            }
        }

        return wrapper;
    }

    public static String getFormattedTime(Time timefield){
        String formattedTime = '';
        if(timefield != null){
            Integer hour = timefield.hour();
            Integer minutes = timefield.minute();
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
                formattedTime = hour+':0'+minutes+' '+st;
            }else{
                System.debug('final --> '+hour+':'+minutes+st);
                formattedTime = hour+':'+minutes+' '+st;
            }
        }
        return formattedTime;
    }
    public static Decimal getTimeDifference(Time startTime, Time endTime){
        Decimal timeDifference = 0;
        if(startTime != null && endTime != null){
            Decimal startHour = startTime.hour() + (startTime.minute()/60.0);
            System.debug('startHour --> '+startHour);
            Decimal endHour = endTime.hour() + (endTime.minute()/60.0);
            System.debug('endHour --> '+endHour);
            timeDifference = endHour - startHour;
            System.debug('timeDifference --> '+timeDifference);
        }
        return timeDifference.setScale(2, RoundingMode.HALF_UP);
    }
    public static List<Map<String,String>> sortByName(List<Map<String,String>> dataList){
        List<Map<String,String>> sortedList = new List<Map<String,String>>();
        if(dataList != null && !dataList.isEmpty()){
            Map<String, Map<String,String>> nameMap = new Map<String, Map<String,String>>();
            for(Map<String,String> data : dataList){
                nameMap.put(data.get('Name'),data);
            }
            List<String> nameList = new List<String>();
            nameList.addAll(nameMap.keySet());
            nameList.sort();
            for(String name : nameList){
                sortedList.add(nameMap.get(name));
            }
        }
        return sortedList;
    }

    public class DatableConfigWrapper {
        @AuraEnabled public List<Map<String,String>> dataWrapper { get; set; }
        @AuraEnabled public List<Map<String,Object>> columnsInfo { get; set; }
    }

    public class DatablePDFWrapper {
        public List<String> headerWrapper { get; set; }
        public List<List<String>> dataWrapper { get; set; }
    }
}