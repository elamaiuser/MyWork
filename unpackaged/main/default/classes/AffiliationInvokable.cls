public class AffiliationInvokable 
{
     @InvocableMethod
    public static List<List<Drive_Marketing_Programs__c>> deleteDriveAffiliationOnBookingDateChange(List
                                                                 <Id> AffId)
    {
        List<Drive_Marketing_Programs__c> relatedDriveAff = [select id,Blood_Drive_Opportunity__c,Blood_Drive_Opportunity__r.Drive_Date__c,Marketing_Program__c from Drive_Marketing_Programs__c where Marketing_Program__c =:Affid];
        List<List<Drive_Marketing_Programs__c>> relatedDriveAffList = new List<List<Drive_Marketing_Programs__c>>();
        relatedDriveAffList.add(relatedDriveAff);
        return relatedDriveAffList;
    }

}