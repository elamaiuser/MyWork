public class skedBiomedCollectionOpUtils {
    public static String getBiomedCollectionOpWaitlistStatus(Id collectionOpId) {
        Biomed_Collection_Op_Center__c collectionOp = [
            SELECT Id, sked_Waitlist_Enabled__c
            FROM Biomed_Collection_Op_Center__c
            WHERE Id = :collectionOpId
        ];

        return collectionOp.sked_Waitlist_Enabled__c ? skedConstants.AVAILABILITY_STATUS_WAITLIST : skedConstants.AVAILABILITY_STATUS_DECLINED;
    }
}