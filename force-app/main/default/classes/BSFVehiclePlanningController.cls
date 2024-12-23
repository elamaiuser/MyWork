/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 08/09/2024			Raktim Ghosal		 Report For Vehicle Planning (HRP-12921)
 *****************************************************************************************************************************************************************************
*/
public class BSFVehiclePlanningController {
    public vehicleResourceDataWrapper wrapper{ get; set; }
    public String renderAs {get; set;}
   
    public BSFVehiclePlanningController(){
        Date sdate;
        Date edate;
        String startDate = Apexpages.currentPage().getParameters().get('startdate');
        String endDate = Apexpages.currentPage().getParameters().get('enddate');
        String collOpIds = Apexpages.currentPage().getParameters().get('collopids');
        String render = Apexpages.currentPage().getParameters().get('renderas');

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
		if(String.isNotBlank(render)){
            render = String.escapeSingleQuotes(render);
            render = render.escapeHtml4();
        }else{
            render = 'html';
        }
        
        this.renderAs = render;
        this.wrapper = BSFVehiclePlanningController.getAllResourceDataWithDate(sdate,edate,collOpIds);
         
        if(ApexPages.currentPage().getParameters().get('force_download') != null 
                    && ApexPages.currentPage().getParameters().get('force_download') == 'true'
            		&& ApexPages.currentPage().getParameters().get('renderas') != null
                    && String.isNotBlank(render) && render.equalsIgnoreCase('pdf')){
                        ApexPages.currentPage().getHeaders().put('Content-Disposition', 'attachment; filename="VehiclePlanningReport.pdf"');
        } 
    }
    
    @AuraEnabled
    public static vehicleResourceDataWrapper getAllResourceDataWithDate(Date startDate, Date endDate, String collOpIdList) {
        vehicleResourceDataWrapper wrapper = new vehicleResourceDataWrapper();
        List<Map<String,String>> ListwrapperMap = new List<Map<String,String>>();
        Map<Id,sked__Resource__c> resourceMap = new Map<Id,sked__Resource__c>();
        Map<Id,Map<Date,String>> resourceDetailsMap = new  Map<Id,Map<Date,String>>();
        Set<String> collOpIds= new Set<String>(collOpIdList.split(','));
        List<String> availabilityType = Custom_Report_Config__mdt.getInstance('Vehicle_Availability_Type').Value__c.split(',');
        
        if(startDate == null || endDate == null){
                String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Date_Null').Value__c;
                String sdate_str = startDate == null ? 'null' : String.valueOf(startDate);
                String edate_str = endDate == null ? 'null' : String.valueOf(endDate);
                errMsg = errMsg.replace('{{startDate}}',sdate_str);
                errMsg = errMsg.replace('{{endDate}}',edate_str);
                throw new AuraHandledException(errMsg);
            }

            if(String.isBlank(collOpIdList)){
                String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_CollOp').Value__c;
                errMsg = errMsg.replace('{{collop}}',String.valueOf(collOpIdList));
                throw new AuraHandledException(errMsg);
            }
        
        Map<Date,String> dateMap = new  Map<Date,String>();
        Integer i = 0;
         for(Date dt = startDate ; dt <= endDate ; dt = dt.addDays(1)){
             dateMap.put(dt,'eventDate'+i);
             i++;
         }
        
        List<sked__Job_Allocation__c> jobAllocations = [
        												SELECT Id,
                                                        sked_Start_Time__c,
                        								sked_Set_End_Time__c,
                                                        sked__Job__r.sked_Drive__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Date__c,
                                                        sked__Job__r.sked_Drive__r.Name,
                                                        sked__Job__r.sked_Drive__r.sked_Status__c,
                                                        sked__Job__r.sked_Drive__r.sked_Total_Procedures_Projected__c,
                                                        sked__Job__r.sked_Drive__r.sked_Total_Staff_Requested__c,
                                                        sked__Job__r.sked_Drive__r.sked_Total_Equipment_Requested__c,
                                                        sked__Job__r.sked_Drive__r.sked_Equipment_Allocated__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Productivity_Planned__c,
                                                        sked__Job__r.sked_Drive__r.sked_Start_Time__c,
                                                        sked__Job__r.sked_Drive__r.sked_End_Time__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Address_1__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_City__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_County__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_State__c,
                                                        sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Zip_Code__c,
            											sked__Job__r.sked_Drive__r.sked_Travel_Time_CO_To_Site__r.sked_Average_Travel_Time__c,
                                                        sked__Job__r.sked_Travel_Time__c,
                                                        sked__Resource__c,
                                                        sked__Resource__r.Name,
                                                        sked__Resource__r.sked__Resource_Type__c,
                                                        sked__Resource__r.sked_Asset_Type__c,
                                                        sked__Resource__r.RecordTypeId,
                                                        sked__Resource__r.RecordType.Name,
                                                        sked__Resource__r.sked__Primary_Region__c,
                                                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__c,
                                                        sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name
                                                    FROM sked__Job_Allocation__c
                                                    WHERE sked__Status__c NOT IN ('Deleted','Declined') 
                                                    AND sked__Resource__c != null
                                                    AND sked__Resource__r.sked__Resource_Type__c = 'Asset'
                                                    AND sked__Resource__r.RecordType.Name = 'Asset'
                                                    AND sked__Resource__r.sked_Asset_Type__c = 'Vehicle'
                                                    AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                                                    AND sked__Job__r.sked_Drive__c != null
                                                    AND sked__Job__r.sked_Drive__r.sked_Status__c != 'Cancel'
                                                    AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c != null
                                                    AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c >= :startDate
                                                    AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c <= :endDate];
        
        List<sked__Activity_Resource__c> activityList = [SELECT Id,
                                                                sked__Activity__c,
                                                                sked_Start_Time__c,
                                                                sked_End_Time__c,
                                                                sked_Start_Date__c,
                                                                sked_End_Date__c,
                                                                sked__Activity__r.Name,
                                                          		sked__Activity__r.sked_Start_Time__c,
                            									sked__Activity__r.sked_End_Time__c,
                                                         		sked__Activity__r.sked__Address__c,
                                                                sked__Resource__c,
                                                                sked__Resource__r.Name,
                                                                sked__Resource__r.sked__Resource_Type__c,
                                                                sked__Resource__r.sked_Asset_Type__c,
                                                                sked__Resource__r.RecordTypeId,
                                                                sked__Resource__r.RecordType.Name,
                                                                sked__Resource__r.sked__Primary_Region__c,
                                                                sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                                sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__c,
                                                                sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name
                                                            FROM sked__Activity_Resource__c
                                                            WHERE sked__Resource__c != null
                                                            AND sked__Resource__r.sked__Resource_Type__c = 'Asset'
                                                            AND sked__Resource__r.RecordType.Name = 'Asset'
                                                            AND sked__Resource__r.sked_Asset_Type__c = 'Vehicle'
                                                            AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                                                            AND sked_Start_Date__c >=: startDate 
                                                            AND sked_Start_Date__c <=: endDate 
                                                            ORDER BY sked__Activity__r.sked_Start_Time__c ASC];
        
        List<sked__Availability__c> availabilityList = [SELECT Id,
                                                            Name,
                                                            sked_Start_Date__c,
                                                            sked_Finish_Date__c,
                                                            sked_Start_Time__c,
                                                            sked_Finish_Time__c,
                                                            sked__Type__c,
                                                            sked__Resource__c,
                                                            sked__Resource__r.Name,
                                                            sked__Resource__r.sked__Resource_Type__c,
                                                            sked__Resource__r.RecordTypeId,
                                                            sked__Resource__r.RecordType.Name,
                                                        	sked__Resource__r.sked__Primary_Region__c,
                                                            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                                            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__c,
                                                            sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Territory__r.Name
                                                            FROM sked__Availability__c 
                                                            WHERE sked__Resource__c != null
                                                            AND sked__Resource__r.sked__Resource_Type__c = 'Asset'
                                                            AND sked__Resource__r.RecordType.Name = 'Asset'
                                                            AND sked__Resource__r.sked_Asset_Type__c = 'Vehicle'
                                                        	AND sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collOpIds
                                                            AND sked__Type__c IN :availabilityType
                                                            AND sked__Status__c = 'Approved'
                                                            AND sked_Start_Date__c >= :startDate 
                                                            AND sked_Start_Date__c <= :endDate 
                                                            ORDER BY sked_Start_Time__c ASC];
        
        for(sked__Job_Allocation__c jba : jobAllocations) {
            resourceMap.put(jba.sked__Resource__c,jba.sked__Resource__r);
            if(!resourceDetailsMap.containsKey(jba.sked__Resource__c)){
                resourceDetailsMap.put(jba.sked__Resource__c, new Map<Date,String>());
            }
            String detailsForJobAllocation = detailsForJobAllocation(jba);
            updateResourceDetailsMap(jba.sked__Resource__c, jba.sked__Job__r.sked_Drive__r.sked_Drive_Date__c, detailsForJobAllocation, resourceDetailsMap);
        }
        
        for(sked__Activity_Resource__c act: activityList) {
            resourceMap.put(act.sked__Resource__c,act.sked__Resource__r);
            if(!resourceDetailsMap.containsKey(act.sked__Resource__c)){
                resourceDetailsMap.put(act.sked__Resource__c, new Map<Date,String>());
            }
            String detailsForActivity = detailsForActivity(act);
              if (act.sked_Start_Date__c == act.sked_End_Date__c) {
                updateResourceDetailsMap(act.sked__Resource__c, act.sked_Start_Date__c, detailsForActivity, resourceDetailsMap);
            } else {
                Date currentDate = act.sked_Start_Date__c;
                while (currentDate <= act.sked_End_Date__c && currentDate <= endDate) {
                    if (currentDate >= startDate) {
                        updateResourceDetailsMap(act.sked__Resource__c, currentDate, detailsForActivity, resourceDetailsMap);
                    }
                    currentDate = currentDate.addDays(1);
                }
            }
        }
        
        for(sked__Availability__c avl: availabilityList) {
            resourceMap.put(avl.sked__Resource__c, avl.sked__Resource__r);
            if(!resourceDetailsMap.containsKey(avl.sked__Resource__c)) {
                resourceDetailsMap.put(avl.sked__Resource__c, new Map<Date,String>());
            }
            String detailsForAvailability = detailsForAvailability(avl);
            
            if (avl.sked_Start_Date__c == avl.sked_Finish_Date__c) {
                updateResourceDetailsMap(avl.sked__Resource__c, avl.sked_Start_Date__c, detailsForAvailability, resourceDetailsMap);
            } else {
                Date currentDate = avl.sked_Start_Date__c;
                while (currentDate <= avl.sked_Finish_Date__c && currentDate <= endDate) {
                    if (currentDate >= startDate) {
                        updateResourceDetailsMap(avl.sked__Resource__c, currentDate, detailsForAvailability, resourceDetailsMap);
                    }
                    currentDate = currentDate.addDays(1);
                }
            }
        }
        
        List<Date> dateList = new List<Date>();
        Integer indx = 0;
        
        for(Id resourceId : resourceDetailsMap.keySet()){
            Map<String,String> wrapperMap = new Map<String,String>();
            wrapperMap.put('Id',resourceId);
            wrapperMap.put('Name',resourceMap.get(resourceId).Name);
                for(Date dt : dateMap.keySet()){
                if(resourceDetailsMap.get(resourceId).containsKey(dt)){
                    wrapperMap.put(dateMap.get(dt),resourceDetailsMap.get(resourceId).get(dt));
                }else{
                    wrapperMap.put(dateMap.get(dt),'');
                }
             }
                ListwrapperMap.add(wrapperMap);
           }
        
        wrapper.headerWrapper = new List<String>();
        wrapper.headerWrapper.add('Vehicle Name');
        for(Date dt = startDate ; dt <= endDate ; dt = dt.addDays(1)){
            DateTime sDateTime = DateTime.newInstance(dt.year(),dt.month(),dt.day());
            String formattedDT = sDateTime.format('M/d/yyyy');
            wrapper.headerWrapper.add(formattedDT);
            //columnDataInstances.resourceDataWithDate.add(formattedDT);
            dateList.add(dt);
            indx++;
        }
        
        wrapper.dataWrapper = new List<List<String>>();
        if(ListwrapperMap != null && !ListwrapperMap.isEmpty()){
            for(Map<String,String> data : ListwrapperMap){                 
                List<String> rowData1 = new List<String>();   
                rowData1.add('<b>'+data.get('Name')+'</b>');
                for(Date key : dateList){
                    rowData1.add(data.get(dateMap.get(key)));
                }
                wrapper.dataWrapper.add(rowData1);
            }
        }
        return wrapper;
    }
    
    public static String detailsForJobAllocation(sked__Job_Allocation__c jba){
        String details = '';
            details = jba.sked__Job__r.sked_Drive__r.Name;
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
            if(String.isNotBlank(jba.sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Zip_Code__c)){
                if(String.isNotBlank(siteAddress)){
                    siteAddress += ' ';
                }
                siteAddress += jba.sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Zip_Code__c;
            }
            if(String.isNotBlank(siteAddress)){
                details += '\n' + siteAddress + '\n';
            }
            
            if(String.isNotBlank(String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Total_Staff_Requested__c))){
                details += '<b>Staff: </b>'+ String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Total_Staff_Requested__c) + '\n';
            }
            if(String.isNotBlank(String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Total_Equipment_Requested__c))){
                details += '<b>2RBC Machines: </b>'+String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Total_Equipment_Requested__c) + '\n';
            }
            if(String.isNotBlank(String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Drive_Productivity_Planned__c))){
                details += '<b>Planned Productivity: </b>'+String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Drive_Productivity_Planned__c.stripTrailingZeros()) + '\n';
            }
            if(String.isNotBlank(jba.sked__Job__r.sked_Drive__r.sked_Status__c)){
                details += '<b>Status: </b>'+jba.sked__Job__r.sked_Drive__r.sked_Status__c + '\n';
            }
            
                 
            details += '<b>Drive Hours: </b>'+getFormattedTime(jba.sked__Job__r.sked_Drive__r.sked_Start_Time__c) + ' - ' +
                        getFormattedTime(jba.sked__Job__r.sked_Drive__r.sked_End_Time__c) + '\n';
            
            if(String.isNotBlank(String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Travel_Time_CO_To_Site__r.sked_Average_Travel_Time__c))){
               details += '<b>Planned Travel Time: </b>'+String.valueOf(jba.sked__Job__r.sked_Drive__r.sked_Travel_Time_CO_To_Site__r.sked_Average_Travel_Time__c) + '\n';                
            }
        return details;
    }
    
    public static String detailsForActivity(sked__Activity_Resource__c act) {
        String details = act.sked__Resource__r.Name;
        String siteAddress = parseAddress(act.sked__Activity__r.sked__Address__c);
        
        if (String.isNotBlank(siteAddress)) {
            details += '\n' + siteAddress + '\n';
        }

        details += '<b>Activity Hours: </b>';
        if (act.sked_Start_Time__c != null && act.sked_End_Time__c != null) {
            details += getFormattedTime(act.sked_Start_Time__c) + ' - ' + getFormattedTime(act.sked_End_Time__c) + '\n';
        } else {
            details += getFormattedTime(act.sked__Activity__r.sked_Start_Time__c) + ' - ' + 
                       getFormattedTime(act.sked__Activity__r.sked_End_Time__c) + '\n';
        }

        return details;
    }
    
    public static String detailsForAvailability(sked__Availability__c avl){
        String details = '';
                details = avl.sked__Type__c;
                details += '\n'+'<b>Hours: </b>'+getFormattedTime(avl.sked_Start_Time__c) + ' - ' + 
                                                            getFormattedTime(avl.sked_Finish_Time__c)+'\n';
        return details;
    }
    
    public static void updateResourceDetailsMap(Id resourceId, Date currentDate, String details, Map<Id,Map<Date,String>> resourceDetailsMap) {
        if(!resourceDetailsMap.get(resourceId).containsKey(currentDate)) {
            resourceDetailsMap.get(resourceId).put(currentDate, details);
        } else {
            String allDetails = resourceDetailsMap.get(resourceId).get(currentDate);
            allDetails += '\n\n' + details;
            resourceDetailsMap.get(resourceId).put(currentDate, allDetails);
        }
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
   
    public static String parseAddress(String fullAddress) {
        String address = fullAddress.substringBeforeLast(',').trim();
        String zipCode = address.substringAfterLast(' ').trim();
        String stateCode = address.substringBeforeLast(' ').substringAfterLast(' ').trim();
        String city = address.substringBeforeLast(', ').substringAfterLast(',').trim();
        return String.format('{0}, {1} {2}', new List<String>{city, stateCode, zipCode});
	}
	
    public class vehicleResourceDataWrapper{
        @AuraEnabled public List<String> headerWrapper { get; set; }
        @AuraEnabled public List<List<String>> dataWrapper { get; set; }
    }
}