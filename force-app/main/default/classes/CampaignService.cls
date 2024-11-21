public class CampaignService {

    public static List<Campaign> findByField(String fieldName, String fieldVal){
        List<Campaign> result = new List<Campaign>();
        
        if(String.isEmpty(fieldName) || String.isEmpty(fieldVal)){
            System.debug('Invalid parameters: ' + fieldName + ', ' + fieldVal);
            return result;
        }
        
        String qry = 'select Id, Name,ParentId,External_Campaign_Id__c,External_Med__c,Status from Campaign where ' + fieldName + ' = :fieldVal';
        System.debug('Query: ' + qry);
        try{
	        result = Database.query(qry);
        } catch (Exception ex){
            System.debug('Error with query: ' + ex.getMessage());
        }
        return result;
    }
}