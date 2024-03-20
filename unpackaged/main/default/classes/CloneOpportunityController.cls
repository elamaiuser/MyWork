public  with sharing class CloneOpportunityController {
    
    /**
* Build a query of createable fields and clone opportunity, then return unsaved clone to component
* @param opportunityId : Opportunity Id to clone
* @param fieldsJson : Values of fields as inputted by the user
* @return String : Id of the cloned opp
* */
    @AuraEnabled
    public static String cloneOpportunityFields(String opportunityId, String opportunityJson, Boolean isTemplate) {
        Opportunity clonedOppValues = (Opportunity)JSON.deserialize(opportunityJson, Opportunity.class);
        Map<String, Object> fieldsToValue = clonedOppValues.getPopulatedFieldsAsMap();
        //System.debug('fieldsToValue====='+fieldsToValue);
        
        List<String> fields = new List<String>(Opportunity.SObjectType.getDescribe().fields.getMap().keySet());
        
        String opportunityQuery = 'SELECT '+String.join(fields, ',') ;
        opportunityQuery = opportunityQuery.removeEnd(', ');
        //System.debug('opportunityQuery====='+opportunityQuery);
        opportunityQuery += ' FROM Opportunity WHERE Id = :opportunityId';
        //get and clone the opp so we can use getCloneSourceId and isClone on the new opp
        Opportunity originalOpp = Database.query( String.escapeSingleQuotes(opportunityQuery) );
        Opportunity newOpp = originalOpp.clone(false, true);
        
        //apply new field values to cloned opportunity
        for( String fieldName : fieldsToValue.keySet() ) {
            newOpp.put(fieldName, fieldsToValue.get(fieldName));
        }
        
        newOpp.Parent_Template_Id__c = originalOpp.Parent_Template_Id__c == null ? originalOpp.Id : originalOpp.Parent_Template_Id__c;
        // HRP-6506, Added By Prasenjit
		newOpp.Data_Source__c = 'BSFApplication';
		
        try {
            // System.debug('newOpp====' + newOpp);
            if(isTemplate){
                newOpp.is_template__c = true ;
            }
            newOpp.Is_Template__c = false ;
            newOpp.Accept_56_Day_Rule_Violation__c =true;
            newOpp.StageName = 'Discovery';
            // Added to fix Dissue for HRP-5951
            // root cause: unique value required for Migration ID
            newOpp.migration_id__c = '';
            if(newOpp.Flow_End_Time_Field__c != null){
                String endval = newOpp.Flow_End_Time_Field__c;
                //System.debug('newOpp ==='+endval);
                //System.debug('endval ==='+endval.subString(0,2)+'======'+endval.right(2));
                newOpp.End_Time__c = Time.newInstance(Integer.valueOf(endval.subString(0,2)), Integer.valueOf(endval.right(2)), 0, 0);
                
            }
            if(newOpp.Flow_Start_Time_Field__c != null){
                String startval = newOpp.Flow_Start_Time_Field__c;
                newOpp.Start_Time__c = Time.newInstance(Integer.valueOf(startval.subString(0,2)), Integer.valueOf(startval.right(2)), 0, 0);
                
            }
            if(test.isRunningTest()){
                newOpp.id=null;
            }
            // System.debug('newOpp ==='+newOpp.End_Time__c);
            // System.debug('newOpp ==='+newOpp.Start_Time__c);
            // System.debug('newOpp === JSON : ' + JSON.serialize(newOpp));
            // Schema.DescribeSObjectResult ds = Opportunity.sObjectType.getDescribe();
            //if(ds.isCreatable()){}
            insert newOpp;
        }catch(Exception e){
            throwException(e.getMessage());
        }
        
        return newOpp.Id;
    }
    
    public static void throwException(String message){
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        throw ahe;
    }
    
    @AuraEnabled
    public static Opportunity activeOpportunity(String opportunityId){
        Opportunity opp = [select id,Template_Status__c,Is_Template__c from Opportunity where id =:opportunityId ];
        
        return opp ;
    }
}