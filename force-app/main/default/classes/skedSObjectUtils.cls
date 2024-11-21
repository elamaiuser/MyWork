public class skedSObjectUtils {

    public static Set<Id> getRecordIds(List<SObject> records) {
        Set<Id> recordIds = new Set<Id>();
        for (SObject record : records) {
            recordIds.add(record.Id);
        }
        
        return recordIds;
    }
}