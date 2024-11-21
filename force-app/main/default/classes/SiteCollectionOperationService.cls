public without sharing class SiteCollectionOperationService {
    private static SiteCollectionOperationService instance = null;

    private SiteCollectionOperationService(){}
    
    public static SiteCollectionOperationService getInstance(){
        if(instance == null){
            instance = new SiteCollectionOperationService();
        }
        return instance;
    }
    public sked_Site_Collection_Operation__c getInvalidTravelTimeFlag(sked_Site_Collection_Operation__c collop){
        sked_Site_Collection_Operation__c newRecord = new sked_Site_Collection_Operation__c(Id = collop.Id);
        try{
            if(String.isBlank(collop.sked_Travel_Time_Breakdown_JSON__c) && String.isBlank(collop.sked_Travel_Time_Breakdown_JSON_2__c)){
                return newRecord;
            }
            if((String.isNotBlank(collop.sked_Travel_Time_Breakdown_JSON__c) && isBlankTravelTimePresent(collop.sked_Travel_Time_Breakdown_JSON__c))
                    || (String.isNotBlank(collop.sked_Travel_Time_Breakdown_JSON_2__c) && isBlankTravelTimePresent(collop.sked_Travel_Time_Breakdown_JSON_2__c))){
                        newRecord.Is_Travel_Time_Invalid__c = true;
            }else{
                newRecord.Is_Travel_Time_Invalid__c = false;
            }
        }catch(Exception exp){
            System.debug(exp.getMessage()+exp.getLineNumber());
        }
        return newRecord;
    }
    @TestVisible
    private Boolean isBlankTravelTimePresent(String json_str){
        System.debug('json_str : '+json_str);
        if(String.isBlank(json_str)){
            return false;
        }
        try{
            List<Object> result = new List<Object>();
            try{
                result = (List<Object>)JSON.deserializeUntyped(json_str); 
            }catch(Exception e){
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(json_str);
                result.add(data);
            }

            for(Object obj : result) { 
                Map<String,Object> map1 = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(obj)); 
                for(String key : map1.keyset()) { 
                    if(String.isNotBlank(key) && key.equalsIgnoreCase('travelTime')
                            && (map1.get(key) == null || Double.valueOf(map1.get(key)) == 0)){
                                return true;
                    }
                } 
            }
        }catch(Exception exp){
            System.debug(exp.getMessage()+exp.getLineNumber());
        }
        return false;
    }
}