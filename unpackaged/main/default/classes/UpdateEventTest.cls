/*
 *  
 */ 
@isTest
public class UpdateEventTest {

    @isTest 
    static void testParse()
    {		        
		String json = '{'+
		'\"objectName\" : \"opportunity\",'+
		'\"objectFields\" : ['+
		'			{'+
		'				\"OppId\" : \"0067h00000Bn9dzAAB\",'+
		'				\"Additional_Description\" : \"From Platform Event\",'+
		'				\"drive_status\" : \"Cancel\"'+
		'			},'+
        '			{'+
		'				\"OppId\" : \"0063F00000PWDsDQAX\",'+
		'				\"Additional_Description\" : \"From Platform Event\",'+
		'				\"drive_status\" : \"Cancel\"'+
		'			}'+    
		'		]'+
		'}';

		UpdateEvent objOpp = UpdateEvent.parse(json);
        system.debug('=> Opp is: ' + objOpp);
		System.assert(objOpp != null);
        System.assert(objOpp.objectName == 'Opportunity');
		System.assert(objOpp.objectFields.size() == 2);
        System.assert(objOpp.objectFields[0].OppId == '0067h00000Bn9dzAAB');
        //system.assert(objOpp.Drive_Status == 'Draft');
        
        List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 
        //Prepare platform event to publish
        Update_Event__e event = new Update_Event__e(
            Object_Data__c = json
        );
        updateEventList.add(event);
        
        if(!updateEventList.isEmpty()) {
            List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);
        }
        
        /*
        Map<string, object> mapJson = new Map<string, object>();
		mapJson.put('Drive_Date', '2021-11-01');
        mapJson.put('Drive_Status','Pending');
        mapJson.put('Start_Time','12am');
        mapJson.put('End_Time','1am');
        mapJson.put('Drive_Site','Test2');
        string result = SYSTEM.JSON.Serialize(mapJson);
        
        OpportunityJSONWrapper objOpp2 = OpportunityJSONWrapper.parse(result);
        System.assert(objOpp2 != null);
        system.assert(objOpp2.Drive_Status == 'Pending'); */
        
        
        /*
        //step 1 - publish event
        List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 
        Map<string, object> mapOppJson = new Map<string, object>();
        
		mapOppJson.put('Drive Date', '2021-11-01');
        mapOppJson.put('Drive Status','Pending');
        mapOppJson.put('Start Time','12am');
        mapOppJson.put('End Time','1am');
        mapOppJson.put('Drive Site','Test2');
        string eventData = SYSTEM.JSON.Serialize(mapJson);
        
        Update_Event__e event = new Update_Event__e(
            object_Name__c = 'Opportunity',
            Object_Data__c = eventData
        );
        updateEventList.add(event);
        
        if(!updateEventList.isEmpty()) {
            List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);
            
            for(Database.SaveResult eventPubResult : eventPubResultList) {
                
                if(eventPubResult.isSuccess()) {
                    System.debug('#### Events published successfully  => ' + eventPubResult);
                }
                else {
                    for(Database.Error pubError : eventPubResult.getErrors()) {
                        System.debug('#### Event publishing failed => ' + pubError.getStatusCode() + ' => ' + pubError.getMessage());
                    }
                }
            }
        } */
        
        /*Step 2 - Listen for the event and perform post processing
			trigger UpdateEventTrigger on Update_Event__e(after insert) {
			
				private set<String> opportunityId = new set<String>();

				for(Update_Event__e updateEvent : Trigger.New) {
					if(updateEvent.object_Name__c == 'Opportunity') {
						//Perform post processing via helper/service and pass a list of object_data
					}
				}
			}
        	
        */
        
        //process builder:  name it.... Opportunity Update Listener
        //The process starts when a "Platform Even Occurs"
     }
}





/*bulkify
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<Update_Event__e> updateEventList = new List<Update_Event__e>(); */


/*
 String json = '{'+
		'\"objectName\" : \"opportunity\",'+
		'\"objectFields\" : ['+
		'			{'+
		'				\"OppId\" : \"0067h00000Bn9dzAAB\",'+
        '				\"Drive_Date\" : \"2021-10-11\",'+
    	'				\"drive_status\" : \"Cancel\",'+
        '				\"Start_Time\" : \"0000\",'+
        '				\"End_Time\" : \"0430\",'+
        '				\"Drive_Site\" : \"a133F000005mHgdQAE\",'+
    	'				\"Anticipated_Registered_Donors\" : \"5\",'+
    	'				\"WB_Procedures_Projected\" : \"6\",'+
    	'				\"X2RBC_Procedures_Projected\" : \"7\",'+
    	'				\"Anticipated_Registered_Donors_Change_Reason\" : \"Reason 1\",'+
    	'				\"WB_Procedures_Projected_Change_Reason\" : \"Reason 2\",'+
    	'				\"X2RBC_Procedures_Projected_Change_Reason\" : \"Reason 3\",'+
    	'				\"Platelet_Projected\" : \"3\",'+
    	'				\"Plasma_Pheresis_Projected\" : \"4\",'+
    	'				\"Number_of_2RBC_Assets\" : \"6\",'+
    	'				\"Number_of_Plasma_Assets\" : \"7\",'+
    	'				\"Number_of_Platelet_Assets\" : \"8\",'+
    	'				\"Account_Manager\" : \"\",'+
    	'				\"Cancellation_Reason\" : \"\",'+
    	'				\"Anticipated_Registered_Donors_Template\" : \"8\",'+
		'				\"Additional_Description\" : \"From Platform Event2\"'+
		'			},'+
        '			{'+
		'				\"OppId\" : \"0067h00000BnTsVAAV\",'+
        '				\"Drive_Date\" : \"2021-10-11\",'+
    	'				\"drive_status\" : \"Cancel\",'+
        '				\"Start_Time\" : \"0530\",'+
        '				\"End_Time\" : \"0730\",'+
    	'				\"Drive_Site\" : \"a133F000005mHgdQAE\",'+
    	'				\"Anticipated_Registered_Donors\" : \"8\",'+
    	'				\"WB_Projected_Procedures\" : \"9\",'+
    	'				\"X2RBC_Procedures_Projected\" : \"10\",'+
        '				\"Anticipated_Registered_Donors_Change_Reason\" : \"Reason 4\",'+
    	'				\"WB_Procedures_Projected_Change_Reason\" : \"Reason 5\",'+
    	'				\"X2RBC_Procedures_Projected_Change_Reason\" : \"Reason 6\",'+
        '				\"Platelet_Projected\" : \"6\",'+
    	'				\"Plasma_Pheresis_Projected\" : \"7\",'+
    	'				\"Number_of_2RBC_Assets\" : \"6\",'+
    	'				\"Number_of_Plasma_Assets\" : \"7\",'+
    	'				\"Number_of_Platelet_Assets\" : \"8\",'+
    	'				\"Account_Manager\" : \"\",'+
    	'				\"Cancellation_Reason\" : \"\",'+
    	'				\"Anticipated_Registered_Donors_Template\" : \"8\",'+
		'				\"Additional_Description\" : \"From Platform Event2\"'+
		'			}'+    
		'		]'+
		'}';

List<Update_Event__e> updateEventList = new List<Update_Event__e>(); 

//Prepare platform event to publish
Update_Event__e event = new Update_Event__e(
    Object_Data__c = json
);
updateEventList.add(event);

if(!updateEventList.isEmpty()) {
    List<Database.SaveResult> eventPubResultList = EventBus.publish(updateEventList);
    System.debug('\n #### eventPubResultList Size  => ' + eventPubResultList.size());
    
    for(Database.SaveResult eventPubResult : eventPubResultList) {
        if(eventPubResult.isSuccess()) {
            System.debug('\n #### Events published successfully  => ' + eventPubResult);
        }
        else {
            for(Database.Error pubError : eventPubResult.getErrors()) {
                System.debug('\n #### Event publishing failed => ' + pubError.getStatusCode() + ' => ' + pubError.getMessage());
            }
        }
    }
}

String j = JSON.serialize(
  new Map<String, Object> {
    'objectName' => 'DrivesOnCalendar',
    'objectFields' => new Object[] {
      new Map<String, Object> {
        'Sked_Drive_Id' => 'a1Z3F000000mfE5UAI',
        'Sked_Cancellation_Reason' => 'COVID'
      },
	  new Map<String, Object> {
        'Sked_Drive_Id' => 'a1Z3F000000mfEAUAY',
        'Sked_Cancellation_Reason' => 'COVID'     
	  }
    }
  }
);

Map<String, Object> m = new Map<String, Object>();
m.put('property', 'name');
m.put('value', 'mike');

Map<String, Object> m2 = new Map<String, Object>();
m2.put('property', 'age');
m2.put('value', 47);

List<Object> x = new List<Map<String, Object>>();
x.add(m);
x.add(m2);
*/