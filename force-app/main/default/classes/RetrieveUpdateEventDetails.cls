/*
 * 
 * 
 */ 
global class RetrieveUpdateEventDetails {
    
     @InvocableMethod
    global static List<Results> GetUpdateEventDetails(List<String> updateEventData) {

        Results curResult = new Results();
        UpdateEvent curUpdateEvent = UpdateEvent.parse(updateEventData[0]);
        curResult.UpdateEvent = curUpdateEvent;
        
        List<Results> resultsList = new List<Results>();
        resultsList.add(curResult);
        return resultsList;
    } 
    
    global class Results {
        @InvocableVariable
        global UpdateEvent UpdateEvent;
    }
}