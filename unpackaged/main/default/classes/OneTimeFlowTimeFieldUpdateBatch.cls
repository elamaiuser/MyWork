public class OneTimeFlowTimeFieldUpdateBatch implements Database.Batchable<sObject>{

     Map<Id,String> updateFailedRecords = new Map<Id,String>();
     String query = 'select id, createdDate,Flow_Start_Time_Field__c, Start_Time__c, End_Time__c, Flow_End_Time_Field__c from opportunity where ( (Flow_Start_Time_Field__c=null and  Start_Time__c != null) or (Flow_End_Time_Field__c=null and End_Time__c != null))';	
     Static final String leadingZero='0';
      
  
     public Database.QueryLocator start(Database.BatchableContext BC){
			return Database.getQueryLocator (query);
       }
    
       public void execute(Database.BatchableContext BC, List<sObject> scope){
		
           for(sObject obj:scope){
               Opportunity opp = (Opportunity) obj;
               if(opp.Flow_Start_Time_Field__c == null){ //fix flow start time
                  opp.Flow_Start_Time_Field__c =  getFlowTime(opp.Start_Time__c);
               }
               if(opp.End_Time__c == null){ //fix flow end time
                  opp.Flow_End_Time_Field__c =  getFlowTime(opp.End_Time__c);
               }
           }
          Database.SaveResult[] srList =  Database.update(scope, false);
          for(Integer i=0; i <srList.size();i++){
             Database.SaveResult sr = srList.get(i); 
              if (sr.isSuccess() == false){ //collect failed records
                   for(Database.Error err : sr.getErrors()) {
                     System.debug('The following error has occurred.');                    
                     System.debug(err.getStatusCode() + ': ' + err.getMessage());
                     System.debug('Opportunity fields that affected this error: ' + err.getFields());
        		}
              }else{
                 System.debug('Succesfully processed Opp Id ->'+sr.getId()); 
              }
          }
          
       }
    
       public void finish(Database.BatchableContext BC){
           
       }
    
   public static String getFlowTime(Time actualTime){

	String newHour = String.valueOf(actualTime.hour());
	newHour = newHour.length()<2?(leadingZero+newHour):newHour;
	System.debug('newHour->'+newHour);
	Integer minute = actualTime.minute();
    System.debug('newMinute->'+minute);
    String newMinutes ='00';//default to 00 
	if(minute > 0 && minute <= 15){
    	newMinutes = '15';
    }else if(minute > 15 && minute <= 30){
    	newMinutes = '30';
    }else if(minute > 30 && minute <= 45){
        newMinutes = '45';
    }
	String updatedFlowTime =newHour+newMinutes;
    System.debug('updatedFlowTime->'+updatedFlowTime);  
    return updatedFlowTime;  
  }
}