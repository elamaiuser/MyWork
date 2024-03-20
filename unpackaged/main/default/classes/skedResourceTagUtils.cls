public class skedResourceTagUtils {
    public static Boolean resourceTagActiveForDate(sked__Resource_Tag__c rt, Date inputDate) {
        return (rt.sked_Start_Date__c <= inputDate) && (rt.sked_Expiry_Date__c == null || rt.sked_Expiry_Date__c >= inputDate);
    }
}