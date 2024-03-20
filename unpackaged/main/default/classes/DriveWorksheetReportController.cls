//@Description: This class is a controller class for Drive Worksheet Search VF page.
/* Modification Log 
 * 
 * Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 06/08/2023			Barnojit Sharma			Exclude Cancelled Drives from Drive Worksheet Report (Logic for HRP-10289)
 * 06/09/2023			Barnojit Sharma			Drive Worksheet Report only Pull Confirmed Drives (Logic for HRP-10259)
 * 11/28/2023			Barnojit Sharma			Drive Worksheet has the Incorrect Account and Site ID populated(Logic for HRP-11561)
 *****************************************************************************************************************************************************************************
*/
public class DriveWorksheetReportController {
    public List<ReportDataWrapper> ReportDataWrapperList {get; set;}
    public String errorMsg {get; set;}
    public String searchCollOp {get; set;}
    public Date searchStartDate {get; set;}
    public Date searchEndDate {get; set;}
    public String searchRegion {get; set;}
    public String searchType {get; set;}

    private List<sked__Region__c> regionList = new List<sked__Region__c>();
    private List<Biomed_Collection_Op_Center__c> collOperationList = new List<Biomed_Collection_Op_Center__c>();
    
    public class ReportDataWrapper {
        public sked_Drive__c drv {get; set;}      
        public Boolean isSelected{get; set;}
        
        public ReportDataWrapper(sked_Drive__c driv) {
            drv = driv;
            isSelected = false;
        }
    }
    public DriveWorksheetReportController(){
        collOperationList = [SELECT Id, 
                                        Name 
                                FROM Biomed_Collection_Op_Center__c 
                                WHERE Name != null 
                                ORDER BY Name ASC];
        regionList = [SELECT Id, 
                                Name 
                        FROM sked__Region__c 
                        WHERE Name != null 
                        ORDER BY Name ASC];
    }
    public List<SelectOption> getRegionlist() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--none--'));
        for(sked__Region__c lc : regionList){
            options.add(new SelectOption(lc.Id,lc.Name));
        }
        return options;
    }
    public List<SelectOption> getCollectionOperationlist() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--none--'));
        for(Biomed_Collection_Op_Center__c cp : collOperationList){
            options.add(new SelectOption(cp.Id,cp.Name));
        }
        return options;
    }
    public void search(){
        ReportDataWrapperList = null;
        String whereCondition;
        if(searchStartDate == null && searchEndDate == null && String.isBlank(searchCollOp) && String.isBlank(searchRegion)){
            errorMsg = 'No Input Found';
        }else if(searchStartDate != null && searchEndDate == null){
            errorMsg = 'Enter End date.';
        }else if(searchStartDate == null && searchEndDate != null){
            errorMsg = 'Enter Start date.';
        }else if(searchStartDate != null && searchEndDate != null && searchEndDate < searchStartDate){
            errorMsg = 'Start date must be less than End date.';
        }else if(searchStartDate != null && searchEndDate != null){
            whereCondition = ' WHERE sked_Drive_Date__c >=: searchStartDate AND sked_Drive_Date__c <=: searchEndDate';
        }
        if(String.isNotBlank(searchType) && (searchType.equals('Mobile') || searchType.equals('Fixed Site'))){
            searchType = String.escapeSingleQuotes(searchType);
            if(String.isBlank(whereCondition)){
                whereCondition = ' WHERE sked_Type_of_Drive__c =: searchType';
            }else{
                whereCondition = whereCondition+' AND sked_Type_of_Drive__c =: searchType';
            }
        }
        if(String.isNotBlank(searchCollOp)){
            searchCollOp = String.escapeSingleQuotes(searchCollOp);
            if(String.isBlank(whereCondition)){
                whereCondition = ' WHERE sked_Drive_Site__r.sked_Collection_Operation__c =: searchCollOp';
            }else{
                whereCondition = whereCondition+' AND sked_Drive_Site__r.sked_Collection_Operation__c =: searchCollOp';
            }
        }
        if(String.isNotBlank(searchRegion)){
            searchRegion = String.escapeSingleQuotes(searchRegion);
            if(String.isBlank(whereCondition)){
                whereCondition = ' WHERE sked_Drive_Site__r.sked__Region__c =: searchRegion';
            }else{
                whereCondition = whereCondition+' AND sked_Drive_Site__r.sked__Region__c =: searchRegion';
            }
        }
        if(String.isNotBlank(whereCondition) && String.isBlank(errorMsg)){// changes for HRP-11561
            errorMsg = null;
            list<sked_Drive__c> driveListResult = getDriveData(whereCondition);
            wrapDriveData(driveListResult);   
        }
        if (String.isNotBlank(errorMsg)){
            if(errorMsg.equalsIgnoreCase('No Input Found')){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,errorMsg));
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMsg));
            }
            errorMsg = null;// changes for HRP-11561
        }
    }

    list<sked_Drive__c> getDriveData(String condition){
        list<sked_Drive__c> driveList = new list<sked_Drive__c>();
        String qrry_str = 'SELECT Id,Name,sked_Type_of_Drive__c,sked_Account__r.Name,sked_Account__c,sked_Drive_Date__c,'+
            'sked_Drive_Site__c,sked_Drive_Site__r.sked_Collection_Operation__c,'+
            'sked_Drive_Site__r.sked_Collection_Operation__r.Name,sked_Drive_Site__r.sked__Region__c,'+
            'sked_Drive_Site__r.sked__Region__r.Name from sked_Drive__c '+ condition + 
            //' AND sked_Status__c != \'Cancel\' limit 999'; //Added for HRP-10289
            ' AND sked_Status__c IN ('+System.label.Drive_Worksheet_Report_Drive_Status +') limit 999'; //Added for HRP-10259
        System.debug('qrry_str ' + qrry_str);
        driveList = Database.query(qrry_str); 
        system.debug('driveList ' + driveList);
        if(driveList.size() == 0){
            errorMsg = 'No Input Found';
            return null;
        }
        return driveList;
    }
    void wrapDriveData(list<sked_Drive__c> driveList){
        if(ReportDataWrapperList == null && driveList != null) {
            ReportDataWrapperList = new List<ReportDataWrapper>();      
            for(sked_Drive__c driv: driveList) {
                ReportDataWrapperList.add(new ReportDataWrapper(driv));
            }
        }
        system.debug('ReportDataWrapperList ' + ReportDataWrapperList); 
    } 
    public PageReference ExportToPdf() {
        system.debug('called ref method');
        List<Id> driveIdList = new List<Id>();
        for(ReportDataWrapper wrapData : ReportDataWrapperList){
            if(wrapData.isSelected == true){
                driveIdList.add(wrapData.drv.Id);
            }                 
        } 
        PageReference pr = new PageReference('/apex/generateDriveWorksheetPdf');
        if(driveIdList.size() > 0){
            Set<Id> driveIdSet = new Set<Id>(driveIdList);
            Map<String, sked_Drive_Shift__c> sriveShiftsMap = new Map<String, sked_Drive_Shift__c>([SELECT Id
                                                        FROM sked_Drive_Shift__c 
                                                        WHERE sked_Drive__c IN: driveIdSet LIMIT 1000]);
            List<String> shiftIdList = new List<String>(sriveShiftsMap.keySet());
            String id_str = '{'+String.join(shiftIdList ,',')+'}'; 
            pr.getParameters().put('ids',id_str);
        }
		pr.setRedirect(true);
		return pr;
    }
}