/* @Description: This class is useed to show Account and Site required field validation error messages to opportunity banner and plan a drive flow.
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* **************************************************************************************************************************************************
* 12/08/2023					 Barnojit Sharma		  Out of Sync_Add Validation & Banner on Account & BDO/DOC/Site. (HRP-11179)
* 12/27/2023					 Barnojit Sharma		  Show Banner if Opportunities violating 56 Day Rule. (HRP-11640)
* 2/1/2024					     Fitsum Worku		      Updated logic for 56 day rule so that 56th day itself is considered eligible (HRP-12034)
* 2/29/2024						 Venkat Dangeti	          Added recordtype check for BPL validation to exclude fixed sites(HRP-12238)
****************************************************************************************************************************************************
*/
public without sharing class DriveValidationService {
    
    public Date driveDate;
    public Boolean acceptBlankMilitaryNamePhone = false;
    public Boolean accept56DayRuleViolation = false;
    public Boolean fiftySixDayRuleViolated = false;// added for HRP-11640 
    public Boolean isFixedSite = false;
    public Boolean isRecurringDrive = false;
    public Id oppId;
    public Account accRec;
    public sked__Location__c siteRec;
    public List<String> accMissingfieldList = new List<String>();
    public List<String> siteMissingfieldList = new List<String>();
    public List<String> millityMissingfieldList = new List<String>();
    public List<Date> driveDates = new List<Date>();
    public List<String> MissingBPLdriveDates = new List<String>();

    @AuraEnabled
    public static String validateOpportunityOnBanner(String recordId){
        if(String.isBlank(recordId)){
            return '';
        }
        try{
            List<Opportunity> OppList = [SELECT Id, 
                                                AcceptblankMilitaryAuthNamePhone__c,
                                                Accept_56_Day_Rule_Violation__c,// added for HRP-11640 
                                                Drive_Date__c,
                                                AccountId,
                                                Account.Name,
                                                Account.Type,
                                                Account.Industry_Code__c,
                                                Account.Accepts_Automation2__c,
                                                Account.Internal_Name__c,
                                                Account.Military_Authority_Name__c,
                                                Account.Military_Authority_Phone__c,
                                                Account.RecordTypeId,
                                                Drive_Site__c,
                                                Drive_Site__r.Name,
                                                Drive_Site__r.RecordTypeId,
                                                Drive_Site__r.sked_Directions_From_CollectionOperation__c,
                                                Drive_Site__r.sked_Floor_Description__c,
                                                Drive_Site__r.sked_Outside_stairs__c,
                                                Drive_Site__r.sked_Physical_Location_Type__c,
                                                Drive_Site__r.sked_Site_Main_Phone__c,
                                                Drive_Site__r.sked_Automation_Suitability__c,
                                                Drive_Site__r.sked_Room_Name__c,
                                                Drive_Site__r.sked_Site_Building_Name__c,
                                                Drive_Site__r.sked_Site_Contact__c,
                                                Drive_Site__r.Operation_Type__c,
                                                Drive_Site__r.sked_Inside_stairs__c, 
                                                Drive_Site__r.sked_Staff_Personal_Parking_Directions__c
                                        FROM Opportunity
                                        WHERE Id =: recordId];
            if(OppList.isEmpty() || OppList.get(0).Drive_Date__c <= Date.Today()){
                return '';
            }

            DriveValidationService classObj = new DriveValidationService();
            classObj.oppId = OppList.get(0).Id;
            classObj.accRec = OppList.get(0).Account;
            classObj.siteRec = OppList.get(0).Drive_Site__r;
            classObj.driveDate = OppList.get(0).Drive_Date__c;
            classObj.acceptBlankMilitaryNamePhone = OppList.get(0).AcceptblankMilitaryAuthNamePhone__c;
            classObj.accept56DayRuleViolation = OppList.get(0).Accept_56_Day_Rule_Violation__c;// added for HRP-11640 
            if(OppList.get(0).Account.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()){
                classObj.isFixedSite = true;
            }
            classObj.validateAccount();
            classObj.validateSite();
            if(classObj.isFixedSite != true){
                classObj.checkAccept56DaysVoilation();// added for HRP-11640 
            }

            return classObj.getErrorMessageOnBanner();
        }catch(Exception expx){
            System.debug(expx.getMessage());
            return expx.getMessage();
        }
    }

    @InvocableMethod(label='Validate Plan A Drive' description='Validate before plannning a drive that required fields are not missing.')
    public static List<String> validatePlanADrive(List<ValidatePlanADriveWrapper> wrapper){
        List<String> result = new List<String>();
        if(wrapper == null || wrapper.isEmpty()){
            return result;
        }
        for(ValidatePlanADriveWrapper data : wrapper){
            if(String.isBlank(data.accountId)){
                continue;
            }
            List<Account> accList = [SELECT Id,
                                            Name,
                                            Type,
                                            Industry_Code__c,
                                            Accepts_Automation2__c,
                                            Internal_Name__c,
                                            Military_Authority_Name__c,
                                            Military_Authority_Phone__c,
                                            RecordTypeId
                                    FROM Account
                                    WHERE Id =: data.accountId];
            if(accList.isEmpty()){
                continue;
            }
            try{
                DriveValidationService classObj = new DriveValidationService();
                classObj.accRec = accList.get(0);
                if(accList.get(0).RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId()){
                    classObj.isFixedSite = true;
                }
                if(String.isNotBlank(data.siteId)){
                    List<sked__Location__c> siteList = [SELECT Id,
                                                                    Name,
                                                                    RecordTypeId,
                                                                    sked_Directions_From_CollectionOperation__c,
                                                                    sked_Floor_Description__c,
                                                                    sked_Outside_stairs__c,
                                                                    sked_Physical_Location_Type__c,
                                                                    sked_Site_Main_Phone__c,
                                                                    sked_Automation_Suitability__c,
                                                                    sked_Room_Name__c,
                                                                    sked_Site_Building_Name__c,
                                                                    sked_Site_Contact__c,
                                                                    sked_Inside_stairs__c,
                                                                    Operation_Type__c,
                                                                    sked_Staff_Personal_Parking_Directions__c
                                                        FROM sked__Location__c
                                                        WHERE Id =: data.siteId];
                    if(!siteList.isEmpty()){
                        classObj.siteRec = siteList.get(0);
                    }
                }
                if(String.isNotBlank(data.templateId)){
                    List<Opportunity> tempList = [SELECT Id,
                                                            AcceptblankMilitaryAuthNamePhone__c
                                                        FROM Opportunity
                                                        WHERE Id =: data.templateId];
                    if(!tempList.isEmpty()){
                        classObj.acceptBlankMilitaryNamePhone = tempList.get(0).AcceptblankMilitaryAuthNamePhone__c;
                    }
                }else if(data.siteTBD == true){
                    classObj.acceptBlankMilitaryNamePhone = false;
                }else{
                    classObj.acceptBlankMilitaryNamePhone = true;
                }
                if(data.driveDate != null){
                    classObj.driveDate = data.driveDate;
                }
                if(data.recurringDrive != null){
                    classObj.isRecurringDrive = data.recurringDrive;
                }else{
                    classObj.isRecurringDrive = false;
                }
                if(data.driveDateList != null && data.driveDateList.size() > 0){
                    classObj.driveDates = data.driveDateList;
                }
                classObj.validateAccount();
                classObj.validateSite();
                result.add(classObj.getErrorMessage());
            }catch(Exception exp){
                result.add(exp.getMessage());
            }
        }
        return result;
    }

    public String getErrorMessage(){
        String genericMessage = '';
        if((!accMissingfieldList.isEmpty() || !siteMissingfieldList.isEmpty())){
            genericMessage = Custom_Messages__mdt.getInstance('Opportunity_Validation_Message').value__c;
            if(!accMissingfieldList.isEmpty() && !siteMissingfieldList.isEmpty()){
                genericMessage = genericMessage.replace('{objectName}','Account & Site');
                accMissingfieldList.addAll(siteMissingfieldList);
                genericMessage = genericMessage.replace('{errorFields}',String.join(accMissingfieldList, ', '));
            }else if(!accMissingfieldList.isEmpty()){
                genericMessage = genericMessage.replace('{objectName}','Account');
                genericMessage = genericMessage.replace('{errorFields}',String.join(accMissingfieldList, ', '));
            }else if(!siteMissingfieldList.isEmpty()){
                genericMessage = genericMessage.replace('{objectName}','Site');
                genericMessage = genericMessage.replace('{errorFields}',String.join(siteMissingfieldList, ', '));
            }
        }
        if(!MissingBPLdriveDates.isEmpty()){
            genericMessage = genericMessage +'\n'+ Custom_Messages__mdt.getInstance('Opportunity_Validation_Message_BPL').value__c;
            genericMessage = genericMessage.replace('{driveDates}',String.join(MissingBPLdriveDates, ', '));
        }
        if(!millityMissingfieldList.isEmpty()){
            if(isFixedSite){
                genericMessage = genericMessage +'\n'+ Custom_Messages__mdt.getInstance('Opportunity_Validation_Message_Mil_Fixed').value__c;
            }else{
                genericMessage = genericMessage +'\n'+ Custom_Messages__mdt.getInstance('Opportunity_Validation_Message_Military').value__c;
            }
            genericMessage = genericMessage.replace('{militaryFields}',String.join(millityMissingfieldList, ', '));
        }
        if(fiftySixDayRuleViolated){
            genericMessage = genericMessage +' '+ Custom_Messages__mdt.getInstance('Opportunity_Banner_Message_56_day_Rule').value__c;
        }
        return genericMessage;
    }
    public String getErrorMessageOnBanner(){
        String genericMessage = '';
        if((!accMissingfieldList.isEmpty() || !siteMissingfieldList.isEmpty())){
            genericMessage = Custom_Messages__mdt.getInstance('Opportunity_Banner_Message').value__c;
            if(!accMissingfieldList.isEmpty() && !siteMissingfieldList.isEmpty()){
                genericMessage = genericMessage.replace('{objectName}','Account & Site');
                accMissingfieldList.addAll(siteMissingfieldList);
                genericMessage = genericMessage.replace('{errorFields}',String.join(accMissingfieldList, ', '));
            }else if(!accMissingfieldList.isEmpty()){
                genericMessage = genericMessage.replace('{objectName}','Account');
                genericMessage = genericMessage.replace('{errorFields}',String.join(accMissingfieldList, ', '));
            }else if(!siteMissingfieldList.isEmpty()){
                genericMessage = genericMessage.replace('{objectName}','Site');
                genericMessage = genericMessage.replace('{errorFields}',String.join(siteMissingfieldList, ', '));
            }
        }
        if(!MissingBPLdriveDates.isEmpty()){
            genericMessage = genericMessage +' '+ Custom_Messages__mdt.getInstance('Opportunity_Banner_Message_BPL').value__c;
            genericMessage = genericMessage.replace('{driveDates}',String.join(MissingBPLdriveDates, ', '));
        }
        if(!millityMissingfieldList.isEmpty()){
            genericMessage = genericMessage +' '+ Custom_Messages__mdt.getInstance('Opportunity_Banner_Message_Military').value__c;
            genericMessage = genericMessage.replace('{militaryFields}',String.join(millityMissingfieldList, ', '));
        }
        /*
        * HRP-11640 changes starts here
        */
        if(fiftySixDayRuleViolated){
            genericMessage = genericMessage +' '+ Custom_Messages__mdt.getInstance('Opportunity_Banner_Message_56_day_Rule').value__c;
        }
        /*
        * HRP-11640 changes ends here
        */
        return genericMessage;
    }

    public void validateAccount(){
        List<String> accFieldList = new List<String>();
        if(accRec == null){
            return;
        }
        if(String.isBlank(accRec.Type)){
            accFieldList.add(Account.Type.getDescribe().getLabel());
        }
        if(String.isBlank(accRec.Industry_Code__c)){
            accFieldList.add(Account.Industry_Code__c.getDescribe().getLabel());
        }
        if(String.isBlank(accRec.Accepts_Automation2__c)){
            accFieldList.add(Account.Accepts_Automation2__c.getDescribe().getLabel());
        }
        if(String.isBlank(accRec.Internal_Name__c)){
            accFieldList.add(Account.Internal_Name__c.getDescribe().getLabel());
        }
        if(!acceptBlankMilitaryNamePhone && String.isNotBlank(accRec.Type) && accRec.Type.equals('Military') && String.isBlank(accRec.Military_Authority_Name__c)){
            millityMissingfieldList.add(Account.Military_Authority_Name__c.getDescribe().getLabel());
        }
        if(!acceptBlankMilitaryNamePhone && String.isNotBlank(accRec.Type) && accRec.Type.equals('Military') && String.isBlank(accRec.Military_Authority_Phone__c)){
            millityMissingfieldList.add(Account.Military_Authority_Phone__c.getDescribe().getLabel());
        }
        
        //HRP-12238
        if(this.isFixedSite == FALSE && ((!isRecurringDrive && driveDate != null) || (isRecurringDrive && !driveDates.isEmpty()))){
            
            List<Account_Service_Role__c> bplList = [SELECT Id,
                                                        End_Date__c,
                                                        Start_Date__c 
                                                    FROM Account_Service_Role__c 
                                                    WHERE Account_Service_Role__c = 'Blood Program Leader' 
                                                    AND Account__c =: accRec.Id 
                                                    AND Start_Date__c != null];
            if(isRecurringDrive){
                for(Date ddate : driveDates){
                    Boolean bplExists = false;
                    for(Account_Service_Role__c bpl : bplList){
                        if(bpl.Start_Date__c <= ddate && (bpl.End_Date__c == null || bpl.End_Date__c >= ddate)){
                            bplExists = true;
                            break;
                        }
                    }
                    if(!bplExists){
                        MissingBPLdriveDates.add(ddate.month()+ '/' + ddate.day() + '/' + ddate.year());
                    }
                }
            }else{
                Boolean bplExists = false;
                for(Account_Service_Role__c bpl : bplList){
                    if(bpl.Start_Date__c <= driveDate && (bpl.End_Date__c == null || bpl.End_Date__c >= driveDate)){
                        bplExists = true;
                        break;
                    }
                }
                if(!bplExists){
                    MissingBPLdriveDates.add(driveDate.month()+ '/' + driveDate.day() + '/' + driveDate.year());
                }
            }
        }
        if(!accFieldList.isEmpty()){
            accMissingfieldList.addAll(accFieldList);
        }
    }
    public void validateSite(){
        List<String> siteFieldList = new List<String>();
        if(siteRec == null){
            return;
        }
        if(String.isBlank(siteRec.sked_Physical_Location_Type__c)){
            siteFieldList.add(sked__Location__c.sked_Physical_Location_Type__c.getDescribe().getLabel());
        }
        if(String.isBlank(siteRec.sked_Room_Name__c)){
            siteFieldList.add(sked__Location__c.sked_Room_Name__c.getDescribe().getLabel());
        }
        if(String.isBlank(siteRec.sked_Site_Building_Name__c)){
            siteFieldList.add(sked__Location__c.sked_Site_Building_Name__c.getDescribe().getLabel());
        }
        if(siteRec.RecordTypeId == Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId()){
            if(String.isBlank(siteRec.sked_Directions_From_CollectionOperation__c)){
                siteFieldList.add(sked__Location__c.sked_Directions_From_CollectionOperation__c.getDescribe().getLabel());
            }
            if(String.isBlank(siteRec.sked_Floor_Description__c)){
                siteFieldList.add(sked__Location__c.sked_Floor_Description__c.getDescribe().getLabel());
            }
            /*if(siteRec.sked_Inside_stairs__c == null){
                siteFieldList.add(sked__Location__c.sked_Inside_stairs__c.getDescribe().getLabel());
            }
            if(siteRec.sked_Outside_stairs__c == null){
                siteFieldList.add(sked__Location__c.sked_Outside_stairs__c.getDescribe().getLabel());
            }
            if(siteRec.sked_Site_Main_Phone__c == null){
                siteFieldList.add(sked__Location__c.sked_Site_Main_Phone__c.getDescribe().getLabel());
            }*/
            if(String.isBlank(siteRec.sked_Automation_Suitability__c)){
                siteFieldList.add(sked__Location__c.sked_Automation_Suitability__c.getDescribe().getLabel());
            }
            if(siteRec.sked_Site_Contact__c == null){
                siteFieldList.add(sked__Location__c.sked_Site_Contact__c.getDescribe().getLabel());
            }
            /*if(String.isBlank(siteRec.sked_Staff_Personal_Parking_Directions__c)){
                siteFieldList.add(sked__Location__c.sked_Staff_Personal_Parking_Directions__c.getDescribe().getLabel());
            }*/
        }else if(siteRec.RecordTypeId == Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()){
            if(String.isBlank(siteRec.Operation_Type__c)){
                siteFieldList.add(sked__Location__c.Operation_Type__c.getDescribe().getLabel());
            }
        }
        if(!siteFieldList.isEmpty()){
            siteMissingfieldList.addAll(siteFieldList);
        }
    }
    /*
    * HRP-11640 changes starts here
    */
    public void checkAccept56DaysVoilation(){
        System.debug('Check 123 : '+driveDate);
        System.debug('Check 1234 : '+oppId);
        if(!accept56DayRuleViolation && driveDate != null && accRec != null && accRec.Id != null && !isFixedSite){
            Integer oppCount = 0;
            Date fiftySixDaysBefore = driveDate;
            Date fiftySixDaysAfter = driveDate;
            fiftySixDaysBefore = fiftySixDaysBefore.addDays(-56);
            fiftySixDaysAfter = fiftySixDaysAfter.addDays(56);
            System.debug('Check fiftySixDaysBefore : '+fiftySixDaysBefore);
            System.debug('Check fiftySixDaysAfter : '+fiftySixDaysAfter);
            if(oppId == null){
                oppCount = [SELECT Count() 
                            FROM Opportunity 
                            WHERE StageName != 'Cancelled'
                            AND DriveStatus__c != 'Cancel'
                            AND Accept_56_Day_Rule_Violation__c = false
                            AND Is_Template__c = false
                            AND Drive_Date__c != null
                            AND AccountId =: accRec.Id
                            AND Drive_Date__c >: fiftySixDaysBefore  //HRP-12034
                            AND Drive_Date__c <: fiftySixDaysAfter]; //HRP-12034
            }else{
                oppCount = [SELECT Count() 
                            FROM Opportunity 
                            WHERE StageName != 'Cancelled'
                            AND DriveStatus__c != 'Cancel'
                            AND Accept_56_Day_Rule_Violation__c = false
                            AND Is_Template__c = false
                            AND Drive_Date__c != null
                            AND AccountId =: accRec.Id
                            AND Id !=: oppId
                            AND Drive_Date__c >: fiftySixDaysBefore  //HRP-12034
                            AND Drive_Date__c <: fiftySixDaysAfter]; //HRP-12034
            }
            System.debug('Check 12345 : '+oppCount);
            if(oppCount > 0){
                fiftySixDayRuleViolated = true;
            }
        }
    }
    /*  
    * HRP-11640 changes ends here
    */
    public class ValidatePlanADriveWrapper{
        @InvocableVariable (label='Account Record Id' required=true)
        public String accountId;
        @InvocableVariable (label='Site Record Id')
        public String siteId;
        @InvocableVariable (label='Drive Template Record Id')
        public String templateId;
        @InvocableVariable (label='Drive Date')
        public Date driveDate;
        @InvocableVariable (label='Site TBD')
        public Boolean siteTBD;
        @InvocableVariable (label='Recurring Drive')
        public Boolean recurringDrive;
        @InvocableVariable (label='Recurring Drive Date')
        public List<Date> driveDateList;
    }
}