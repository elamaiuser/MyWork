public class skedCoSlWrapper {
    public Boolean isUpdate;

    public Boolean isStartDateChanged;
    public Boolean isEndDateChanged;

    public sked_Collection_Op_Staging_Location__c coSl;
    public sked_Collection_Op_Staging_Location__c oldCoSl;

    public skedCoSlWrapper(sked_Collection_Op_Staging_Location__c coSl) {
        this.coSl = coSl;
        this.isUpdate = false;
    }

    public skedCoSlWrapper(sked_Collection_Op_Staging_Location__c oldCosl, sked_Collection_Op_Staging_Location__c newCosl) {
        this.coSl = newCosl;
        this.oldCoSl = oldCosl;
        this.isUpdate = true;
        this.isStartDateChanged = oldCosl.sked_Start_Date__c != newCosl.sked_Start_Date__c;
        this.isEndDateChanged = oldCosl.sked_End_Date__c != newCosl.sked_End_Date__c;
    }
}