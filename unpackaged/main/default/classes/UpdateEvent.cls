/*
 * Sample JSON format for opportunity
 * {
		"objectName" : "opportunity",
        "objectFields" : [
			{
				"OppId" : "OppId 1",
				"Field 1" : "Field 1 Value",
				"Field 2" : "Field 2 Value"
			},
 			{
				"OppId" : "OppId 2",
				"Field 1" : "Field 1 Value",
				"Field 2" : "Field 2 Value"
			}
		]
	} 
 */

global class UpdateEvent {

    @AuraEnabled
    global string objectName;
    
    @AuraEnabled
    global List<FieldIdentifiers> objectFields;
    
    public static UpdateEvent parse(String json) {
		return (UpdateEvent) System.JSON.deserialize(json, UpdateEvent.class);
	}
}