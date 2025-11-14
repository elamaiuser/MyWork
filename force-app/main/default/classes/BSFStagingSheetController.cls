public without sharing class BSFStagingSheetController {
    private static Map<String, Staging_Sheet_Config__mdt> config = Staging_Sheet_Config__mdt.getAll();
    public List<BSFStagingSheetWrapper> wrapper {get; set;}
    public String renderAs {get; set;}
    public Boolean showBackToSearchButton {get; set;}
    public Boolean showAllButtons {get; set;}
    public PageParameters pageParams {get; set;}
    public PageReference pf;

    public BSFStagingSheetController(){
        Date sdate;
        Date edate;
        if(String.isBlank(this.renderAs)){
            this.pf = ApexPages.currentPage();
            this.pageParams = new PageParameters();
            this.showBackToSearchButton = false;
            this.showAllButtons = false;

            System.debug('page params all : '+this.pf.getParameters());
            this.pageParams.startDate = this.pf.getParameters().get('startdate');
            this.pageParams.endDate = this.pf.getParameters().get('enddate');
            this.pageParams.collOpIds = this.pf.getParameters().get('collopids');
            this.pageParams.appeal = this.pf.getParameters().get('appeal');
            this.pageParams.driveufid = this.pf.getParameters().get('ufid');
            this.pageParams.render = this.pf.getParameters().get('renderas');
            this.pageParams.moeRegion = this.pf.getParameters().get('moe');
            this.pageParams.backToSearch = this.pf.getParameters().get('backToSearch');
            List<String> jobIdParams = new List<String>{'jobid','jobId','JobId','JOBID','JobID'};
            for(String param : jobIdParams){
                if(String.isNotBlank(this.pf.getParameters().get(param))){
                    this.pageParams.jobid = this.pf.getParameters().get(param);
                    break;
                }
            }
        }

        System.debug('startDate : '+this.pageParams.startDate);
        System.debug('endDate : '+this.pageParams.endDate);
        System.debug('appeal : '+this.pageParams.appeal);
        System.debug('collOpIds : '+this.pageParams.collOpIds);
        System.debug('driveufid : '+this.pageParams.driveufid);
        System.debug('render : '+this.pageParams.render);
        System.debug('jobid : '+this.pageParams.jobid);
        System.debug('moe : '+this.pageParams.moeRegion);
        System.debug('pageParams : '+this.pageParams);

        if(String.isNotBlank(this.pageParams.startDate)){
            this.pageParams.startDate = String.escapeSingleQuotes(this.pageParams.startDate);
            this.pageParams.startDate = this.pageParams.startDate.escapeHtml4();
            sdate = Date.valueOf(this.pageParams.startDate);
        }
        if(String.isNotBlank(this.pageParams.endDate)){
            this.pageParams.endDate = String.escapeSingleQuotes(this.pageParams.endDate);
            this.pageParams.endDate = this.pageParams.endDate.escapeHtml4();
            edate = Date.valueOf(this.pageParams.endDate);
        }
        if(String.isNotBlank(this.pageParams.collOpIds)){
            this.pageParams.collOpIds = String.escapeSingleQuotes(this.pageParams.collOpIds);
            this.pageParams.collOpIds = this.pageParams.collOpIds.escapeHtml4();
        }
        if(String.isNotBlank(this.pageParams.driveufid)){
            this.pageParams.driveufid = String.escapeSingleQuotes(this.pageParams.driveufid);
            this.pageParams.driveufid = this.pageParams.driveufid.escapeHtml4();
        }
        if(String.isNotBlank(this.pageParams.moeRegion)){
            this.pageParams.moeRegion = String.escapeSingleQuotes(this.pageParams.moeRegion);
            this.pageParams.moeRegion = this.pageParams.moeRegion.escapeHtml4();
        }
        if(String.isNotBlank(this.pageParams.backToSearch)){
            this.pageParams.backToSearch = String.escapeSingleQuotes(this.pageParams.backToSearch);
            this.pageParams.backToSearch = this.pageParams.backToSearch.escapeHtml4();
        }
        if(String.isNotBlank(this.pageParams.appeal)){
            this.pageParams.appeal = String.escapeSingleQuotes(this.pageParams.appeal);
            this.pageParams.appeal = this.pageParams.appeal.escapeHtml4();
        }else{
            this.pageParams.appeal = 'Yes';
        }

        if(String.isNotBlank(this.pageParams.render)){
            this.pageParams.render = String.escapeSingleQuotes(this.pageParams.render);
            this.pageParams.render = this.pageParams.render.escapeHtml4();
        }else{
            this.pageParams.render = 'html';
        }

        if(String.isNotBlank(this.pageParams.jobid)){
            this.pageParams.jobid = String.escapeSingleQuotes(this.pageParams.jobid);
            this.pageParams.jobid = this.pageParams.jobid.escapeHtml4();
        }
        System.debug('input jobid : '+this.pageParams.jobid);
        if(String.isNotBlank(this.pageParams.jobid)){
            this.renderAs = this.pageParams.render;
            this.wrapper = BSFStagingSheetController.getWrapperData(null, null, null, null, null,this.pageParams.jobid,this.pageParams.moeRegion);
            if(String.isNotBlank(this.pageParams.render) && this.pageParams.render.equalsIgnoreCase('html')){
                this.showAllButtons = true;
                if(String.isBlank(this.pageParams.backToSearch) || this.pageParams.backToSearch.equalsIgnoreCase('true')){
                    this.showBackToSearchButton = true;
                }
            }
        }else{
            Boolean validated = BSFStagingSheetController.validateInput(sdate, edate, this.pageParams.collOpIds, this.pageParams.driveufid, this.pageParams.appeal);
            if(validated){
                this.renderAs = this.pageParams.render;
                this.wrapper = BSFStagingSheetController.getWrapperData(sdate, edate, this.pageParams.collOpIds, this.pageParams.driveufid, this.pageParams.appeal,null,this.pageParams.moeRegion);
            }
        }

        
        

        if(ApexPages.currentPage().getParameters().get('force_download') != null 
                    && ApexPages.currentPage().getParameters().get('force_download') == 'true'
                    && ApexPages.currentPage().getParameters().get('renderas') != null
                    && String.isNotBlank(this.pageParams.render) && this.pageParams.render.equalsIgnoreCase('pdf')){
                        ApexPages.currentPage().getHeaders().put('Content-Disposition', 'attachment; filename="StagingSheet.pdf"');
        } 
    }

    @AuraEnabled
    public static Boolean validateInput(Date startDate, Date endDate, String collOpIdList, String ufid, String appeal){
        System.debug('startDate : '+startDate);
        System.debug('endDate : '+endDate);
        System.debug('collOpIdList : '+collOpIdList);
        System.debug('ufid : '+ufid);
        System.debug('appeal : '+appeal);

        Boolean result = false;
        Set<String> collOpIds= new Set<String>();

        if(String.isBlank(appeal) || (!appeal.equals('Yes') && !appeal.equals('No'))){
            throw new AuraHandledException('Invalid Appeal : '+appeal);
        }

        if(String.isBlank(ufid)){
        
            if(startDate == null || endDate == null){
                String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Date_Null').Value__c;
                String sdate_str = startDate == null ? 'null' : String.valueOf(startDate);
                String edate_str = endDate == null ? 'null' : String.valueOf(endDate);
                errMsg = errMsg.replace('{{startDate}}',sdate_str);
                errMsg = errMsg.replace('{{endDate}}',edate_str);
                throw new AuraHandledException(errMsg);
            }

            if(startDate > endDate){
                throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Start_Date_greater').Value__c);
            }

            if(startDate.daysBetween(endDate) >= Integer.valueOf(label.RoleTimeMaxDateDifference)){
                throw new AuraHandledException(Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_date_range').Value__c);
            }
            

            if(String.isBlank(collOpIdList)){
                String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_CollOp').Value__c;
                errMsg = errMsg.replace('{{collop}}',String.valueOf(collOpIdList));
                throw new AuraHandledException(errMsg);
            }

            
            for(String clop: collOpIdList.split(',')){
                if(String.isNotBlank(clop)){
                    collOpIds.add(clop);
                }else{
                    String errMsg = Custom_Report_Config__mdt.getInstance('Report_ErrMsg_Invalid_CollOp').Value__c;
                    errMsg = errMsg.replace('{{collop}}',clop);
                    throw new AuraHandledException(errMsg);
                }
            }

            Integer driveCount = [SELECT count() 
                                    FROM sked_Drive__c 
                                    WHERE sked_Collection_Operation__c IN:collOpIds 
                                    AND sked_Status__c = 'Confirmed'
                                    AND sked_Drive_Date__c >= :startDate 
                                    AND sked_Drive_Date__c <= :endDate];
            if(driveCount > 0){
                result = true;
            }else{
                String errMsg = 'No Confirmed Drive found with the selected collection operation';

                if(collOpIds.size() > 1){
                    errMsg = errMsg + 's';
                }

                if(startDate != endDate){
                    errMsg = errMsg + ' within '+startDate.format()+' to '+endDate.format();
                }else{
                    errMsg = errMsg + ' on '+startDate.format();
                }

                throw new AuraHandledException(errMsg);
            }

        }else{
            Integer driveCount = [SELECT count() 
                                    FROM sked_Drive__c 
                                    WHERE sked_UFID__c =:ufid ];
            if(driveCount > 0){
                result = true;
            }else{
                throw new AuraHandledException('No Drive found with UFID : '+ufid);
            }
        }
        
        return result;
    }

    public static List<BSFStagingSheetWrapper> getWrapperData(Date startDate, Date endDate, String collOpIdList, String ufid, String appeal,  String jobId, String moeReg){
        List<BSFStagingSheetWrapper> wrapperListObj = new List<BSFStagingSheetWrapper>();
        List<sked_Drive__c> driveList = new List<sked_Drive__c>();
        Map<Id, Set<String>> driveTypeMap = new Map<Id, Set<String>>();
        Map<Id, Set<String>> driveDriverMap = new Map<Id, Set<String>>();
        Map<Id, List<String>> driveVehicleMap = new Map<Id, List<String>>();
        Map<Id, List<String>> driveEquipmentMap = new Map<Id, List<String>>();
        Map<Id, Set<Id>> driveVehicleJobMap = new Map<Id, Set<Id>>();
        List<String> nonMoeregionList = getNonMoeRegions();
        System.debug('method jobid : '+jobid);
        if(String.isNotBlank(ufid)){
            driveList = [SELECT Id,
                                sked_Drive_External_Id__c,
                                sked_UFID__c,
                                sked_Collection_Operation__c,
                                sked_Collection_Operation__r.sked_Territory__c,
                                sked_Collection_Operation__r.sked_Territory__r.sked_Parent__c,
                                sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name,
                                sked_Drive_Date__c,
                                sked_Day_of_Week__c,
                                sked_Start_Time__c,
                                sked_End_Time__c,
                                sked_Staff_Capacity__c,
                                sked_WB_Projected_Procedures__c,
                                sked_2RBC_Projected_Procedures__c,
                                sked_Equipment_Allocated__c,
                                sked_Total_Staff_Requested__c,
                                sked_Staff_Allocated__c,
                                sked_Projected_Registered_Donors__c,
                                sked_Total_Vehicle_Requested__c,
                                sked_Vehicles_Allocated__c,
                                sked_Purple_Top_Drive__c,
                                sked_Opportunity__c,
                                sked_Opportunity__r.Additional_Drive_Logistics__c,
                                sked_Opportunity__r.Drive_Logistics_Other__c,
                                sked_Account__c,
                                sked_Account__r.Industry_Code__c,
                                sked_Drive_Site__c,
                                sked_Drive_Site__r.Name,
                                sked_Drive_Site__r.sked_City__c,
                                sked_Drive_Site__r.sked_Inside_stairs__c,
                                sked_Drive_Site__r.sked_Outside_stairs__c,
                                sked_Drive_Site__r.sked_Wireless_Policy__c,
                                (SELECT Id,
                                        sked_Min_Shift_Start_Time__c
                                FROM sked_Drive_Shifts__r),
                                (SELECT Id,
                                        sked_Type__c,
                                        (SELECT Id, 
                                                sked_Bag_Type__c
                                        FROM sked_Drive_Bags__r)
                                FROM sked_Drive_Delivery_Jobs__r
                                WHERE sked_Type__c IN ('Pick Up','VOL Pick Up','Bag'))
                            FROM sked_Drive__c 
                            WHERE sked_UFID__c =:ufid ];
        }else if(String.isNotBlank(jobId)){
            Id drvId;
            List<sked__Job__c> jobList = [SELECT Id, 
                                                    sked_Drive__c 
                                            FROM sked__Job__c 
                                            WHERE Id =:jobId
                                            AND sked_Drive__c != null];
            if(!jobList.isEmpty()){
                drvId = jobList[0].sked_Drive__c;
            }
            System.debug('jobList : '+jobList);
            driveList = [SELECT Id,
                                sked_Drive_External_Id__c,
                                sked_UFID__c,
                                sked_Collection_Operation__c,
                                sked_Collection_Operation__r.sked_Territory__c,
                                sked_Collection_Operation__r.sked_Territory__r.sked_Parent__c,
                                sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name,
                                sked_Drive_Date__c,
                                sked_Day_of_Week__c,
                                sked_Start_Time__c,
                                sked_End_Time__c,
                                sked_Staff_Capacity__c,
                                sked_WB_Projected_Procedures__c,
                                sked_2RBC_Projected_Procedures__c,
                                sked_Equipment_Allocated__c,
                                sked_Total_Staff_Requested__c,
                                sked_Staff_Allocated__c,
                                sked_Projected_Registered_Donors__c,
                                sked_Total_Vehicle_Requested__c,
                                sked_Vehicles_Allocated__c,
                                sked_Purple_Top_Drive__c,
                                sked_Opportunity__c,
                                sked_Opportunity__r.Additional_Drive_Logistics__c,
                                sked_Opportunity__r.Drive_Logistics_Other__c,
                                sked_Account__c,
                                sked_Account__r.Industry_Code__c,
                                sked_Drive_Site__c,
                                sked_Drive_Site__r.Name,
                                sked_Drive_Site__r.sked_City__c,
                                sked_Drive_Site__r.sked_Inside_stairs__c,
                                sked_Drive_Site__r.sked_Outside_stairs__c,
                                sked_Drive_Site__r.sked_Wireless_Policy__c,
                                (SELECT Id,
                                        sked_Min_Shift_Start_Time__c
                                FROM sked_Drive_Shifts__r),
                                (SELECT Id,
                                        sked_Type__c,
                                        (SELECT Id, 
                                                sked_Bag_Type__c
                                        FROM sked_Drive_Bags__r)
                                FROM sked_Drive_Delivery_Jobs__r
                                WHERE sked_Type__c IN ('Pick Up','VOL Pick Up','Bag'))
                            FROM sked_Drive__c 
                            WHERE Id =:drvId ];
        }else if(startDate != null && endDate != null && String.isNotBlank(collOpIdList)){
            List<String> collOpList = collOpIdList.split(',');
            driveList = [SELECT Id,
                                sked_Drive_External_Id__c,
                                sked_UFID__c,
                                sked_Collection_Operation__c,
                                sked_Collection_Operation__r.sked_Territory__c,
                                sked_Collection_Operation__r.sked_Territory__r.sked_Parent__c,
                                sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name,
                                sked_Drive_Date__c,
                                sked_Day_of_Week__c,
                                sked_Start_Time__c,
                                sked_End_Time__c,
                                sked_Staff_Capacity__c,
                                sked_WB_Projected_Procedures__c,
                                sked_2RBC_Projected_Procedures__c,
                                sked_Equipment_Allocated__c,
                                sked_Total_Staff_Requested__c,
                                sked_Staff_Allocated__c,
                                sked_Projected_Registered_Donors__c,
                                sked_Total_Vehicle_Requested__c,
                                sked_Vehicles_Allocated__c,
                                sked_Purple_Top_Drive__c,
                                sked_Opportunity__c,
                                sked_Opportunity__r.Additional_Drive_Logistics__c,
                                sked_Opportunity__r.Drive_Logistics_Other__c,
                                sked_Account__c,
                                sked_Account__r.Industry_Code__c,
                                sked_Drive_Site__c,
                                sked_Drive_Site__r.Name,
                                sked_Drive_Site__r.sked_City__c,
                                sked_Drive_Site__r.sked_Inside_stairs__c,
                                sked_Drive_Site__r.sked_Outside_stairs__c,
                                sked_Drive_Site__r.sked_Wireless_Policy__c,
                                (SELECT Id,
                                        sked_Min_Shift_Start_Time__c
                                FROM sked_Drive_Shifts__r),
                                (SELECT Id,
                                        sked_Type__c,
                                        (SELECT Id, 
                                                sked_Bag_Type__c
                                        FROM sked_Drive_Bags__r)
                                FROM sked_Drive_Delivery_Jobs__r
                                WHERE sked_Type__c IN ('Pick Up','VOL Pick Up','Bag'))
                            FROM sked_Drive__c 
                            WHERE sked_Collection_Operation__c IN:collOpList 
                            AND sked_Status__c = 'Confirmed'
                            AND sked_Drive_Date__c >= :startDate 
                            AND sked_Drive_Date__c <= :endDate];
        }
        System.debug('driveList : '+driveList);
        if(!driveList.isEmpty()){
            Set<Id> driveIds = (new Map<Id,sked_Drive__c>(driveList)).keySet();
            List<sked__Job_Allocation__c> vehicleAllocations =  [SELECT Id, 
                                                                        sked_Additional_Roles__c,
                                                                        sked__Job__c,
                                                                        sked__Job__r.sked_Drive__c,
                                                                        sked__Job__r.sked__Type__c,
                                                                        sked__Job__r.sked_Dual_Role__c,
                                                                        sked__Job__r.sked_Resource_Role__c,
                                                                        sked__Resource__c,
                                                                        sked__Resource__r.sked_Asset_Type__c,
                                                                        sked__Resource__r.sked__Category__c,
                                                                        sked__Resource__r.sked__Resource_Type__c,
                                                                        sked__Resource__r.Name,
                                                                        sked__Resource__r.sked_Preferred_First_Name__c,
                                                                        sked__Resource__r.sked_First_Name__c,
                                                                        sked__Resource__r.sked_Last_Name__c
                                                                FROM sked__Job_Allocation__c
                                                                WHERE sked__Status__c != 'Deleted' 
                                                                AND sked__Resource__c != null
                                                                AND sked__Job__r.sked_Drive__c IN :driveIds]; 
        
            for(sked__Job_Allocation__c jba : vehicleAllocations){
                if(jba.sked__Job__r.sked__Type__c == 'Vehicle'){
                    if(!driveVehicleJobMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                        driveVehicleJobMap.put(jba.sked__Job__r.sked_Drive__c, new Set<Id>());
                    }
                    driveVehicleJobMap.get(jba.sked__Job__r.sked_Drive__c).add(jba.sked__Job__c);
                    if(String.isNotBlank(jba.sked__Resource__r.Name)){
                        if(!driveVehicleMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                            driveVehicleMap.put(jba.sked__Job__r.sked_Drive__c, new List<String>());
                        }
                        driveVehicleMap.get(jba.sked__Job__r.sked_Drive__c).add(jba.sked__Resource__r.Name);
                    }
                    if(String.isNotBlank(jba.sked__Resource__r.sked__Category__c)){
                        if(!driveTypeMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                            driveTypeMap.put(jba.sked__Job__r.sked_Drive__c, new Set<String>());
                        }
                        driveTypeMap.get(jba.sked__Job__r.sked_Drive__c).add(jba.sked__Resource__r.sked__Category__c);
                    }
                }else if(jba.sked__Job__r.sked__Type__c == 'Equipment'){
                    if(String.isNotBlank(jba.sked__Resource__r.Name)){
                        if(!driveEquipmentMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                            driveEquipmentMap.put(jba.sked__Job__r.sked_Drive__c, new List<String>());
                        }
                        driveEquipmentMap.get(jba.sked__Job__r.sked_Drive__c).add(jba.sked__Resource__r.Name);
                    }
                }else if(jba.sked__Resource__r.sked__Resource_Type__c == 'Person'){
                    if(String.isNotBlank(jba.sked__Resource__r.Name)){
                        List<String> roleList = new List<String>();
                        if(String.isNotBlank(jba.sked__Job__r.sked_Resource_Role__c)){
                            roleList.add(jba.sked__Job__r.sked_Resource_Role__c);
                        }
                        if(String.isNotBlank(jba.sked__Job__r.sked_Dual_Role__c)){
                            roleList.add(jba.sked__Job__r.sked_Dual_Role__c);
                        }
                        if(String.isNotBlank(jba.sked_Additional_Roles__c)){
                            roleList.addall(jba.sked_Additional_Roles__c.split(';'));
                        }
                        if(!roleList.isEmpty() && roleList.contains('Driver')){
                            if(!driveDriverMap.containsKey(jba.sked__Job__r.sked_Drive__c)){
                                driveDriverMap.put(jba.sked__Job__r.sked_Drive__c, new Set<String>());
                            }
                            String firstName = String.isNotBlank(jba.sked__Resource__r.sked_Preferred_First_Name__c) ? jba.sked__Resource__r.sked_Preferred_First_Name__c : jba.sked__Resource__r.sked_First_Name__c;
                            driveDriverMap.get(jba.sked__Job__r.sked_Drive__c).add(BSF_Utilities.capitalizeName(firstName+' '+jba.sked__Resource__r.sked_Last_Name__c, true));
                        }
                        
                    }
                }
            }

            
            for(sked_Drive__c drive : driveList){
                BSFStagingSheetWrapper data = new BSFStagingSheetWrapper();
                Boolean setAppeal = false;
                Boolean twoRBCDrive = false;
                Boolean hsCollDrive  = false;
                Boolean rcplDrive  = false;
                data.moeregion = true;
                if(String.isNotBlank(moeReg) && moeReg.equalsIgnoreCase('true')){
                    data.moeregion = true;
                }else if(String.isNotBlank(moeReg) && moeReg.equalsIgnoreCase('false')){
                    data.moeregion = false;
                }else if(drive.sked_Collection_Operation__c != null && drive.sked_Collection_Operation__r.sked_Territory__c != null && drive.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__c != null
                         && String.isNotBlank(drive.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name)){
                        	
                            if(!nonMoeregionList.isEmpty() && nonMoeregionList.contains(drive.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name.trim())){
                                data.moeregion = false;
                            }
                }

                if(String.isNotBlank(appeal) && appeal.equalsIgnoreCase('Yes')){
                    setAppeal = true;
                }
                if(drive.sked_2RBC_Projected_Procedures__c != null && drive.sked_2RBC_Projected_Procedures__c > 0){
                    twoRBCDrive = true;
                }

                data.driveufid = String.isNotBlank(drive.sked_Drive_External_Id__c) ? drive.sked_Drive_External_Id__c : '';
                data.dayofweek = String.isNotBlank(drive.sked_Day_of_Week__c) ? drive.sked_Day_of_Week__c : '';
                data.wbproj = drive.sked_WB_Projected_Procedures__c != null ? String.valueOf(drive.sked_WB_Projected_Procedures__c) : '';
                data.drcproj = drive.sked_2RBC_Projected_Procedures__c != null ? String.valueOf(drive.sked_2RBC_Projected_Procedures__c) : '';
                data.var_tspboxes = ' - ';
                data.var_tspinserts = ' - ';

                if(drive.sked_Drive_Date__c != null){
                    data.drivedate = BSFWeeklyStaffingRoleTimeController.dateFormat(drive.sked_Drive_Date__c);
                }

                if(drive.sked_Opportunity__c != null){
                    if(String.isNotBlank(drive.sked_Opportunity__r.Additional_Drive_Logistics__c)){
                        data.addrivelog = drive.sked_Opportunity__r.Additional_Drive_Logistics__c;
                    }
                    if(String.isNotBlank(drive.sked_Opportunity__r.Drive_Logistics_Other__c)){
                        data.drivelogOthr = drive.sked_Opportunity__r.Drive_Logistics_Other__c;
                    }
                }

                if(drive.sked_Start_Time__c != null && drive.sked_End_Time__c != null){
                    data.ophours = WeeklyStaffScheduleReportController.getFormattedTime(drive.sked_Start_Time__c) + ' - '+
                                    WeeklyStaffScheduleReportController.getFormattedTime(drive.sked_End_Time__c);
                    data.drivelength = WeeklyStaffScheduleReportController.getTimeDifference(drive.sked_Start_Time__c,drive.sked_End_Time__c) + ' hrs';
                }

                if(drive.sked_Account__c != null){
                    if(String.isNotBlank(drive.sked_Account__r.Industry_Code__c) && drive.sked_Account__r.Industry_Code__c.equals('High School')){
                        hsCollDrive = true;
                        data.hsdrive = 'Yes';
                        data.collunivjcdrive = 'No';
                    }else if(String.isNotBlank(drive.sked_Account__r.Industry_Code__c) && (drive.sked_Account__r.Industry_Code__c.equals('Vocational/Trade School')
                            || drive.sked_Account__r.Industry_Code__c.equals('College / University') 
                            || drive.sked_Account__r.Industry_Code__c.equals('Community / Junior College'))){
                                hsCollDrive = true;
                                data.hsdrive = 'No';
                                data.collunivjcdrive = 'Yes';
                    }else{
                        data.hsdrive = 'No';
                        data.collunivjcdrive = 'No';
                    }

                }

                if(drive.sked_Drive_Site__c != null){
                    if(String.isNotBlank(drive.sked_Drive_Site__r.Name)){
                        data.locationname = String.isNotBlank(drive.sked_Drive_Site__r.sked_City__c) ? drive.sked_Drive_Site__r.Name+' ('+drive.sked_Drive_Site__r.sked_City__c+')': drive.sked_Drive_Site__r.Name;
                    }
                    if(String.isNotBlank(drive.sked_Drive_Site__r.sked_Wireless_Policy__c)){
                        data.wirelesspolicy = drive.sked_Drive_Site__r.sked_Wireless_Policy__c;
                        if(drive.sked_Drive_Site__r.sked_Wireless_Policy__c.equals('Accepted')){
                            data.wiredkits = '0';
                        }else if(!driveVehicleMap.isEmpty() && driveVehicleMap.containsKey(drive.Id)){
                            data.wiredkits = String.valueOf(driveVehicleMap.get(drive.Id).size());
                        }else{
                            data.wiredkits = '0';
                        }
                    }
                    data.staresinside = drive.sked_Drive_Site__r.sked_Inside_stairs__c != null ? String.valueOf(drive.sked_Drive_Site__r.sked_Inside_stairs__c) : '';
                    data.stairsoutside = drive.sked_Drive_Site__r.sked_Outside_stairs__c != null ? String.valueOf(drive.sked_Drive_Site__r.sked_Outside_stairs__c) : '';
                }

                if(!driveVehicleMap.isEmpty() && driveVehicleMap.containsKey(drive.Id)){
                    data.vehicles = String.join(driveVehicleMap.get(drive.Id),', ');
                }

                if(!driveEquipmentMap.isEmpty() && driveEquipmentMap.containsKey(drive.Id)){
                    data.automachines = String.valueOf(driveEquipmentMap.get(drive.Id).size());
                }else{
                    data.automachines = '0';
                }

                if(!driveVehicleJobMap.isEmpty() && driveVehicleJobMap.containsKey(drive.Id)){
                    data.veh = String.valueOf(driveVehicleJobMap.get(drive.Id).size());
                }else{
                    data.veh = '0';
                }

                if(!driveTypeMap.isEmpty() && driveTypeMap.containsKey(drive.Id)){
                    List<String> driveTypeList = new List<String>(driveTypeMap.get(drive.Id));
                    driveTypeList.sort();
                    data.type = String.join(driveTypeList,', ');
                } 

                if(!driveDriverMap.isEmpty() && driveDriverMap.containsKey(drive.Id)){
                    data.driver = String.join(driveDriverMap.get(drive.Id),', ');
                }
                Integer shiftCounter = 0;
                List<Time> shiftStartTimeList = new List<Time>();
                if(drive.sked_Drive_Shifts__r != null){
                    for(sked_Drive_Shift__c shift : drive.sked_Drive_Shifts__r){
                        if(shift.sked_Min_Shift_Start_Time__c != null){
                            shiftStartTimeList.add(shift.sked_Min_Shift_Start_Time__c);
                        }
                        shiftCounter++;
                    }
                }
                data.var_2lbboi = String.valueOf(shiftCounter);
                if(!shiftStartTimeList.isEmpty()){
                    shiftStartTimeList.sort();
                    data.shiftstarttime = WeeklyStaffScheduleReportController.getFormattedTime(shiftStartTimeList.get(0));
                }

                Integer shutCount = 0;
                List<String> bagtypes = new List<String>();
                if(drive.sked_Drive_Delivery_Jobs__r != null){
                    for(sked_Drive_Delivery_Job__c deljob : drive.sked_Drive_Delivery_Jobs__r){
                        if(String.isNotBlank(deljob.sked_Type__c) && (deljob.sked_Type__c.equals('Pick Up') || deljob.sked_Type__c.equals('VOL Pick Up'))){
                            shutCount++;
                        }else if(String.isNotBlank(deljob.sked_Type__c) && deljob.sked_Type__c.equals('Bag') && deljob.sked_Drive_Bags__r != null){
                            for(sked_Drive_Bag__c drvbag : deljob.sked_Drive_Bags__r){
                                if(String.isNotBlank(drvbag.sked_Bag_Type__c) ){//&& (bagtypes.isEmpty() || !bagtypes.contains(drvbag.sked_Bag_Type__c))){
                                    bagtypes.add(drvbag.sked_Bag_Type__c);
                                }
                            }
                        }
                    }
                }
                if(!bagtypes.isEmpty()){
                    bagtypes.sort();
                    data.typebags = String.join(bagtypes,', ');
                }else{
                    rcplDrive = true;
                }
                data.shut = String.valueOf(shutCount);

                if(drive.sked_Staff_Capacity__c != null){
                    data.donorcapacity = String.valueOf(drive.sked_Staff_Capacity__c);
                    Decimal driveCapacity = drive.sked_Staff_Capacity__c;
                    if(setAppeal){
                        Decimal percentage = (Decimal)getConfig('Appeal','Percentage',data.moeregion);
                        driveCapacity = driveCapacity * ((100.00 + percentage)/100.00);
                    }
                    Decimal bloodbagsCapacity = driveCapacity;
                    data.snacktotes = String.valueOf((driveCapacity/(Decimal)getConfig('Snacktotes','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    data.glovetotes = String.valueOf((driveCapacity/(Decimal)getConfig('Glovetotes','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    data.supervisortotes = String.valueOf((driveCapacity/(Decimal)getConfig('Supervisortotes','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    data.processingtote = String.valueOf((driveCapacity/(Decimal)getConfig('Processingtote','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    data.var_7lbboi = String.valueOf(((driveCapacity/(Decimal)getConfig('SevenLBBOI','Divisor',data.moeregion))*(Decimal)getConfig('SevenLBBOI','Multiplicand',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    data.var_plb = String.valueOf(((driveCapacity/(Decimal)getConfig('PLB','Divisor',data.moeregion))*(Decimal)getConfig('PLB','Multiplicand',data.moeregion)).round(System.RoundingMode.DOWN).intValue());
                    data.var_e120bx = String.valueOf((driveCapacity/(Decimal)getConfig('E120BX','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    if(drive.sked_Purple_Top_Drive__c){
                        data.var_e120bx = String.valueOf(Integer.valueOf(data.var_e120bx)+1);
                    }
                    if(twoRBCDrive){
                        data.vptotes = String.valueOf((driveCapacity/(Decimal)getConfig('VPtotes_2RBC','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.hhtotes = String.valueOf((driveCapacity/(Decimal)getConfig('HHtotes_2RBC','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.qctote1 = String.valueOf((driveCapacity/(Decimal)getConfig('QCtote1_2RBC','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.qctote2 = String.valueOf((driveCapacity/(Decimal)getConfig('QCtote2_2RBC','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    }else{
                        data.vptotes = String.valueOf((driveCapacity/(Decimal)getConfig('VPtotes','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.hhtotes = String.valueOf((driveCapacity/(Decimal)getConfig('HHtotes','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.qctote1 = String.valueOf((driveCapacity/(Decimal)getConfig('QCtote1','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.qctote2 = String.valueOf((driveCapacity/(Decimal)getConfig('QCtote2','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    }
                    data.gallonsharpescontainers = String.valueOf((driveCapacity/(Decimal)getConfig('GallonSharpesContainers','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    if(drive.sked_Equipment_Allocated__c != null){
                        data.gallonsharpescontainers = String.valueOf(((driveCapacity/(Decimal)getConfig('GallonSharpesContainers','Divisor',data.moeregion))
                                                     + (drive.sked_Equipment_Allocated__c / (Decimal)getConfig('GallonSharpesContainer_E','Divisor',data.moeregion))).round(System.RoundingMode.CEILING).intValue());
                        String slTotesVal = String.valueOf(drive.sked_Equipment_Allocated__c.intValue());
                        data.solutiontoteslist = new List<SolutionTotes>();
                        SolutionTotes slTotesObj = new SolutionTotes();
                        slTotesObj.solutiontotes = slTotesVal;
                        data.solutiontoteslist.add(slTotesObj);
                        data.drctotes = String.valueOf((drive.sked_Equipment_Allocated__c /(Decimal)getConfig('DRCtotes','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        data.drccollectionsetcase = String.valueOf(drive.sked_Equipment_Allocated__c.intValue());
                    }
                    if(hsCollDrive){
                        data.waterbottles = String.valueOf(((driveCapacity * (Decimal)getConfig('Waterbottles_HSD','Multiplicand',data.moeregion))/(Decimal)getConfig('Waterbottles','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        bloodbagsCapacity = bloodbagsCapacity * (Decimal)getConfig('Bloodbags_HS','Multiplicand',data.moeregion);
                    }else{
                        data.waterbottles = String.valueOf(((driveCapacity * (Decimal)getConfig('Waterbottles','Multiplicand',data.moeregion))/(Decimal)getConfig('Waterbottles','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    }
                    data.juice = String.valueOf((driveCapacity/(Decimal)getConfig('Juice','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());

                    if(rcplDrive){
                        data.var_9lbboi = '0';
                        if(twoRBCDrive){
                            data.bloodbags = String.valueOf((bloodbagsCapacity/(Decimal)getConfig('Bloodbags_2RBC_RCPL','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        }else{
                            data.bloodbags = String.valueOf((bloodbagsCapacity/(Decimal)getConfig('Bloodbags_RCPL','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        }
                    }else{
                        data.var_9lbboi = String.valueOf(Integer.valueOf(data.var_e120bx)*2);
                        if(twoRBCDrive){
                            data.bloodbags = String.valueOf((bloodbagsCapacity/(Decimal)getConfig('Bloodbags_2RBC','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        }else{
                            data.bloodbags = String.valueOf((bloodbagsCapacity/(Decimal)getConfig('Bloodbags','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                        }
                    }
                }
                if(drive.sked_Total_Staff_Requested__c != null || drive.sked_Staff_Allocated__c != null){
                    Decimal staffCount = 0;
                    if(drive.sked_Total_Staff_Requested__c != null){
                        staffCount = drive.sked_Total_Staff_Requested__c;
                    }
                    if(drive.sked_Staff_Allocated__c != null && drive.sked_Staff_Allocated__c > staffCount){
                        staffCount = drive.sked_Staff_Allocated__c;
                    }
                    data.masters = (staffCount < 50) ? '1' : '2';

                    List<Decimal> duplexprinterRangeList = (List<Decimal>)getConfig('Duplexprinter','Range',data.moeregion);
                    Decimal dpprev = 0;
                    Integer dpcounter = 2;
                    Boolean dpmatched = false;
                    for(Decimal temp : duplexprinterRangeList){
                        if(staffCount > dpprev && staffCount <= temp){
                            dpmatched = true;
                            break;
                        }
                        dpprev = temp;
                        dpcounter++;
                    }
                    if(dpmatched){
                        data.duplexprinter = String.valueOf(dpcounter);
                    }else{
                        data.duplexprinter = '0';
                    }

                    if(!data.moeregion){
                        List<Decimal> clientcaseRangeList = (List<Decimal>)getConfig('Clientcase','Range',data.moeregion);
                        Decimal ccprev = 0;
                        Integer cccounter = 1;
                        Boolean ccmatched = false;
                        for(Decimal temp : clientcaseRangeList){
                            if(staffCount > ccprev && staffCount <= temp){
                                ccmatched = true;
                                break;
                            }
                            ccprev = temp;
                            cccounter++;
                        }
                        if(ccmatched){
                            data.clientcase = String.valueOf(cccounter);
                        }else{
                            data.clientcase = '0';
                        }

                        List<Decimal> phlebotomycaseRangeList = (List<Decimal>)getConfig('Phlebotomycase','Range',data.moeregion);
                        Decimal pcprev = 0;
                        Integer pccounter = 1;
                        Boolean pcmatched = false;
                        for(Decimal temp : phlebotomycaseRangeList){
                            if(staffCount > pcprev && staffCount <= temp){
                                pcmatched = true;
                                break;
                            }
                            pcprev = temp;
                            pccounter++;
                        }
                        if(pcmatched){
                            data.phlebotomycase = String.valueOf(pccounter);
                        }else{
                            data.phlebotomycase = '0';
                        }
                    }

                }
                if(drive.sked_Projected_Registered_Donors__c != null){
                    if(data.moeregion){
                        data.clientcase = String.valueOf((drive.sked_Projected_Registered_Donors__c /(Decimal)getConfig('Clientcase','Divisor',data.moeregion)).round(System.RoundingMode.CEILING).intValue());
                    }
                }

                if(drive.sked_Total_Vehicle_Requested__c != null || drive.sked_Vehicles_Allocated__c != null){
                    Decimal vehicleCount = 0;
                    if(drive.sked_Total_Vehicle_Requested__c != null){
                        vehicleCount = drive.sked_Total_Vehicle_Requested__c;
                    }
                    if(drive.sked_Vehicles_Allocated__c != null && drive.sked_Vehicles_Allocated__c > vehicleCount){
                        vehicleCount = drive.sked_Vehicles_Allocated__c;
                    }
                    if(data.moeregion){
                        data.phlebotomycase = String.valueOf(vehicleCount.intValue());
                    }
                }
                
                wrapperListObj.add(data);
            }
        }

        return wrapperListObj;
    }

    public static Object getConfig(String instName, String varName, Boolean moeRegion){
        Object result;
        if(String.isNotBlank(instName) && String.isNotBlank(varName)){
            String metadataName = instName+'_'+varName;
            if(moeRegion == true){
                metadataName += '_MOE';
            }
            if(config != null && config.containsKey(metadataName)){
                if(varName.equalsIgnoreCase('multiplicand') || varName.equalsIgnoreCase('divisor') || varName.equalsIgnoreCase('percentage')){
                    result = config.get(metadataName).Decimal_Value__c;
                }else if(varName.equalsIgnoreCase('constant') || varName.equalsIgnoreCase('literal')){
                    result = config.get(metadataName).String_Value__c;
                }else if(varName.equalsIgnoreCase('range')){
                    String rangestr = config.get(metadataName).String_Value__c;
                    List<Decimal> rangeList = new List<Decimal>();
                    for(String item : rangestr.split(',')){
                        rangeList.add(Decimal.valueOf(item));
                    }
                    result = rangeList;
                }
            }else{
                if(varName.equalsIgnoreCase('multiplicand') || varName.equalsIgnoreCase('divisor') || varName.equalsIgnoreCase('percentage')){
                    result = 1.00;
                }else if(varName.equalsIgnoreCase('constant') || varName.equalsIgnoreCase('literal')){
                    result = '';
                }else if(varName.equalsIgnoreCase('range')){
                    result = new List<Decimal>();
                }
            }
        }
        return result;
    }
    
    public static List<String> getNonMoeRegions(){
        List<String> nonmoeRegions = new List<String>();
        List<Staging_Sheet_Config__mdt> metadata = [SELECT Id, String_Long_Value__c FROM Staging_Sheet_Config__mdt WHERE DeveloperName = 'NON_MOE_Regions'];
        if(!metadata.isEmpty() && String.isNotBlank(metadata.get(0).String_Long_Value__c)){
           
            for(String region : metadata.get(0).String_Long_Value__c.split(',')){
                nonmoeRegions.add(region.trim());
            }
        }
        return nonmoeRegions;
    }

    public PageReference OpenSearchPanel(){
        PageReference pr = new PageReference('/apex/BSFStagingSheetSearchVF');
        pr.setRedirect(true);
        return pr;
    }
    public PageReference downloadPdf(){
        this.renderAs = 'pdf';
        this.pf.getParameters().put('renderas','pdf');
        this.pf.getParameters().put('force_download','true');
        this.pf.setRedirect(true);
        return this.pf;
    }

    public class BSFStagingSheetWrapper{
        public Boolean moeregion {get; set;}

        public String driveufid {get; set;}
        public String dayofweek {get; set;}
        public String drivedate {get; set;}
        public String locationname {get; set;}
        public String wirelesspolicy {get; set;}
        public String stairsoutside {get; set;}
        public String staresinside {get; set;}
        public String wiredkits {get; set;}
        public String vehicles {get; set;}
        public String ophours {get; set;}
        public String type {get; set;}
        public String driver {get; set;}
        public String shiftstarttime {get; set;}
        public String automachines {get; set;}
        public String drivelength {get; set;}

        public String donorcapacity {get; set;}
        public String wbproj {get; set;}
        public String drcproj {get; set;}
        public String shut {get; set;}
        public String veh {get; set;}
        public String hsdrive {get; set;}
        public String collunivjcdrive {get; set;}
        public String typebags {get; set;}

        public String snacktotes {get; set;}
        public String glovetotes {get; set;}
        public String supervisortotes {get; set;}
        public String processingtote {get; set;}
        public String vptotes {get; set;}
        public String hhtotes {get; set;}
        public String gallonsharpescontainers {get; set;}
        public String waterbottles {get; set;}
        public String juice {get; set;}

        public String qctote1  {get; set;}
        public String qctote2  {get; set;}
        public String drctotes  {get; set;}
        public String drccollectionsetcase  {get; set;}
        public String bloodbags  {get; set;}

        public String masters {get; set;}
        public String clientcase {get; set;}
        public String duplexprinter {get; set;}
        public String phlebotomycase {get; set;}

        public String var_e120bx  {get; set;}
        public String var_9lbboi  {get; set;}
        public String var_7lbboi  {get; set;}
        public String var_2lbboi  {get; set;}
        public String var_plb  {get; set;}
        public String var_tspboxes  {get; set;}
        public String var_tspinserts  {get; set;}

        public String addrivelog  {get; set;}
        public String drivelogOthr  {get; set;}

        public List<SolutionTotes> solutiontoteslist {get; set;}
    }
    public class SolutionTotes{
        public String solutiontotes  {get; set;}
    }
    public class PageParameters{
        String startDate {get; set;}
        String endDate {get; set;}
        String collOpIds {get; set;}
        String appeal {get; set;}
        String driveufid {get; set;}
        String render {get; set;}
        String moeRegion {get; set;}
        String backToSearch {get; set;}
        String jobid {get; set;}
    }
}