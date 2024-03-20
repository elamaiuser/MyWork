/* 
 * @description: This class is called from Different triggers handlers to format phone numbers limited to 10 digits.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 31/07/2023				 Barnojit Sharma		  Phone Numbers must be limited to 10 Numbers (Logic for HRP-10394)
 * 1/30/2024				 Fitsum Worku			  Per HRP-9847, updated the logic to format phone number so that special chars are removed
 ************************************************************************************************************************************************
*/
public inherited sharing class FormatPhoneNumbers {

    @TestVisible
    private Boolean format = false;

    @TestVisible
    private Boolean isUpdateContext = false;

    @TestVisible
    private List<Sobject> newRecords;

    @TestVisible
    private Map<Id, Sobject> oldRecords;

    @TestVisible
    private Map<Schema.SObjectType, List<String>> fieldMap = new Map<Schema.SObjectType, List<String>>();

    @TestVisible
    private Map<Schema.SObjectType, String> errorMsgMap = new Map<Schema.SObjectType, String>();

    @TestVisible
    private FormatPhoneNumbers(){
        if(!Test.isRunningTest() && Trigger.isExecuting && Trigger.isBefore && !Trigger.isDelete){
            this.newRecords = Trigger.new;
            this.oldRecords = Trigger.oldMap;
            this.isUpdateContext = Trigger.isUpdate;
            this.format = true;
            getObjectSettings();
        }
    }

    public static void format(){
        try{        
            new FormatPhoneNumbers().formatPhoneNumbers();
        }catch(Exception exp){
            System.debug(exp.getMessage());
        }
    }

    @TestVisible
    private void formatPhoneNumbers(){
        if(this.format && this.newRecords != null){
            for(Sobject rec : this.newRecords){
                if(!this.fieldMap.isEmpty() && this.fieldMap.containsKey(rec.getSObjectType())){
                    for(String field : this.fieldMap.get(rec.getSObjectType())){
                        boolean validated = true;
                        if(rec.get(field) == null){
                            continue;
                        }
                        if(this.oldRecords == null && !this.isUpdateContext){
                            validated = this.validatePhoneNumbers(FormatPhoneFieldUtility.removeSpecialCharacters((String) rec.get(field))); //HRP-9847
                        }else if(this.oldRecords != null && this.oldRecords.containsKey((Id) rec.get('Id'))){
                            if(rec.get(field) != this.oldRecords.get((Id) rec.get('Id')).get(field)){
                                validated = this.validatePhoneNumbers(FormatPhoneFieldUtility.removeSpecialCharacters((String) rec.get(field))); //HRP-9847
                            }
                        }
                        if(!validated){
                            this.addErrorMsg(rec,field);
                        }
                    }
                }
            }
        }
    }
    public static String formatPhoneNumbers(String unFormattedNo){
        String formattedNo = '';
        if(String.isNotBlank(unFormattedNo)){
            formattedNo = unFormattedNo.replaceAll('[^0-9]', '');
        }
        if(formattedNo.length() > 10){
            formattedNo = formattedNo.left(10);
        }
        return formattedNo;
    }
    @TestVisible
    private Boolean validatePhoneNumbers(String formattedNo){
        Boolean result = false;
        if(String.isNotBlank(formattedNo) && formattedNo.length() == 10 && formattedNo.isNumeric()){
            result = true;
        }
        return result;
    }
    @TestVisible
    private void addErrorMsg(Sobject rec, String field){
        String errMsg;
        if(rec != null && String.isNotBlank(field)){
            if(this.errorMsgMap.get(rec.getSObjectType()) != null){
                errMsg = this.errorMsgMap.get(rec.getSObjectType());
            }else{
                errMsg = System.label.Default_PhoneNumber_Validation_Message;
            }
            if(String.isNotBlank(errMsg)){
                errMsg = errMsg.replace('{{field_name}}',rec.getSObjectType().getDescribe().fields.getMap().get(field).getDescribe().getLabel());
                errMsg = errMsg.replace('{{field_api_name}}',field);
                errMsg = errMsg.replace('{{value}}',(String) rec.get(field));
            }
            rec.addError(errMsg);
        }
    }
    @TestVisible
    private void getObjectSettings(){
        for(Phone_Number_Formatting_Settings__mdt mtdt : [SELECT MasterLabel, Field_Names__c, Error_Message__c FROM Phone_Number_Formatting_Settings__mdt WHERE Is_Active__c = true]){
            if(String.isNotBlank(mtdt.Field_Names__c)){
                String fieldList = mtdt.Field_Names__c.replaceAll(' ','');
                this.fieldMap.put(Schema.getGlobalDescribe().get(mtdt.MasterLabel.trim()),fieldList.split(','));
                this.errorMsgMap.put(Schema.getGlobalDescribe().get(mtdt.MasterLabel.trim()),mtdt.Error_Message__c);
            }
        }
    }
}