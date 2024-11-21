/**
 * @description: This is batch calls tooling api to update collection oparation global picklist value set, if collection oparation name changed.
**/
global class BSF_UpdateCollectionOperationsBatch implements Database.Batchable<Biomed_Collection_Op_Center__c>, Database.AllowsCallouts, Database.Stateful{
    public static final String apiVersion = '56.0'; 
    public static final String gvsName = 'sked_Collection_Operations'; 
    public static String globalValueSetUrl;
    public String triggerOparetion; 
    public static List<User> userList = new List<User>();
    public Map<Id, Biomed_Collection_Op_Center__c> collectionOpMap = new Map<Id, Biomed_Collection_Op_Center__c>();
    public Map<String, Object> MetadataMap = new Map<String, Object>{'description' => null, 'masterLabel' => 'Collection Operations',
                                                                     'fullName' => 'sked_Collection_Operations', 'sorted' => false,'urls' => null};
	

    global BSF_UpdateCollectionOperationsBatch(Map<Id, Biomed_Collection_Op_Center__c> collectionMap, String oparetion){
		this.triggerOparetion = oparetion;
        this.collectionOpMap = collectionMap;
	}

	global Iterable<Biomed_Collection_Op_Center__c> start(Database.BatchableContext BC){
        if(String.isNotBlank(this.triggerOparetion) && this.triggerOparetion.equalsIgnoreCase('UPDATE')){
		    return [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Id IN: this.collectionOpMap.keySet()];
        }else{
            return this.collectionOpMap.values();
        }
	}
	global void execute(Database.BatchableContext BC, List<Biomed_Collection_Op_Center__c> scope){

        if(String.isBlank(globalValueSetUrl)){
            String toolingQuery = '/services/data/v'+apiVersion+'/tooling/query/?q=select+id+from+globalvalueset+Where+developername=';
            toolingQuery = toolingQuery +'\''+gvsName+'\'';
            HttpResponse response = respond(toolingQuery,'GET',null);
            String jsonResponse = response.getBody();
            System.debug(jsonResponse);
            parseGlobalValueSetURL(jsonResponse);
        }

        //get list of all existing active picklist values
        List<Map<String, Object>> CustomValueMapList = new List<Map<String, Object>>();
        Map<String, String> collectionNamesMap = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = User.sked_Collection_Operations__c.getDescribe();
        List<Schema.PicklistEntry> plEntry = fieldResult.getPicklistValues();

        for(Biomed_Collection_Op_Center__c collOp : scope){
            if(String.isNotBlank(this.triggerOparetion) && (this.triggerOparetion.equalsIgnoreCase('INSERT') || this.triggerOparetion.equalsIgnoreCase('UPDATE'))){
                Map<String, Object> customValueMap = getCustomValueMap();
                customValueMap.put('label',collOp.Name);
                customValueMap.put('valueName',collOp.Name);
                CustomValueMapList.add(customValueMap);
                collectionNamesMap.put(collOp.Name,collOp.Name);
            }
            if(String.isNotBlank(this.triggerOparetion) && (this.triggerOparetion.equalsIgnoreCase('UPDATE') || this.triggerOparetion.equalsIgnoreCase('DELETE'))){
                String collectionNamesMapValue = this.triggerOparetion.equalsIgnoreCase('DELETE') ? null : collOp.Name;
                collectionNamesMap.put(collectionOpMap.get(collOp.Id).Name,collectionNamesMapValue);
            }
        }

        //get users need to updated
        for(User usr : [SELECT Id, sked_Collection_Operations__c FROM User WHERE sked_Collection_Operations__c IN : collectionNamesMap.keySet()]){
            usr.sked_Collection_Operations__c = collectionNamesMap.get(usr.sked_Collection_Operations__c);
            userList.add(usr);
        }

        for(Schema.PicklistEntry picklistValue : plEntry){
            if(picklistValue.isActive() && !collectionNamesMap.containsKey(picklistValue.getLabel())){
                Map<String, Object> customValueMap = getCustomValueMap();
                customValueMap.put('label',picklistValue.getLabel());
                customValueMap.put('valueName',picklistValue.getValue());
                CustomValueMapList.add(customValueMap);
            }
        }
        //create JSON request to tooling api
        this.MetadataMap.put('customValue',CustomValueMapList);
		String picklistInfoJSON = JSON.serialize(new Map<String, Object>{'Metadata' => this.MetadataMap});
        System.debug(picklistInfoJSON);

        if(String.isNotBlank(globalValueSetUrl)){
            HttpResponse toolingResponse = respond(globalValueSetUrl,'PATCH',picklistInfoJSON);
            System.debug('toolingResponse: '+toolingResponse);
            String errorResponse = toolingResponse.getBody();
            System.debug(errorResponse);
        }

	}

	global void finish(Database.BatchableContext BC){
        if(!userList.isEmpty()){
            update userList;
        }
    }

    private Map<String, Object> getCustomValueMap(){
        return new Map<String, Object>{
            'color' => null,
            'default' => false,
            'description' => null,
            'isActive' => true,
            'urls' => null
        };
    }

    //http callout method 
    private HttpResponse respond(String toolingURL, String reqType, String jsonBody){  
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json');      
        request.setEndpoint(URL.getOrgDomainUrl().toExternalForm()+toolingURL);
        request.setMethod(reqType);
        if(!reqType.equals('GET')){
            request.setBody(jsonBody); 
        }
        Http httpreq = new Http();
        response  = httpreq.send(request);
        return response;
    }
    //method to parse global picklist url from tooling api querry response 
    private void parseGlobalValueSetURL(String jsonRes){
        Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(jsonRes);
        String entityTypeName = (String)payload.get('entityTypeName');

        if(entityTypeName != null && entityTypeName.equalsIgnoreCase('GlobalValueSet')){
            for (Object data : (List<Object>)payload.get('records')){
                Map<String, Object> record = (Map<String, Object>)data;
                Object attributes = record.get('attributes');
                Map<String, Object> attributesMap = (Map<String, Object>)attributes;

                globalValueSetUrl = (String)attributesMap.get('url');
                System.debug('url-' + globalValueSetUrl);
            }
        }
    }
}