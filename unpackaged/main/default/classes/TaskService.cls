public with sharing class TaskService {
    
    /* HRP-5763
     * 	MVP: Custom Tasks do not populate on Fixed Sites records 
     *  
     */
    
    public static void validateTaskRecordTypeForFixSite(List<Task> newTaskList)
    {
        map<Id,String> mapOfRelatedToIdWithRecordTypeName = new map<Id,String>();
        map<Id, Id> mapOfTaskIdWithAccountId = new map<Id, Id>();
        map<Id, Id> mapOfTaskIdWithOpportunityId = new map<Id, Id>(); 
        system.debug('newTaskList '+ newTaskList);
        for(task t: newTaskList){
            String sobjectType ;
            if(t.WhatId != null)
                sobjectType  = t.WhatId.getSObjectType().getDescribe().getName();
            if( sobjectType  == 'Account'){
                mapOfTaskIdWithAccountId.put(t.Id, t.WhatId); 
            }else if(sobjectType  == 'Opportunity'){
                mapOfTaskIdWithOpportunityId.put(t.Id, t.WhatId);                 
            }           
        }
        for(Account acc: [SELECT Id, RecordType.Name, Name FROM Account Where Id IN:mapOfTaskIdWithAccountId.values()]){
            mapOfRelatedToIdWithRecordTypeName.put(acc.Id, acc.RecordType.Name);
        }
        for(Opportunity opp: [SELECT Id, RecordType.Name, Name FROM Opportunity Where Id IN:mapOfTaskIdWithOpportunityId.values()]){
            mapOfRelatedToIdWithRecordTypeName.put(opp.Id, opp.RecordType.Name);            
        }
        for(task t: newTaskList){
            system.debug('the task '+t);
            String getRelatedToRecordType;
            String sobjectName;
            if(t.WhatId != null)
                sobjectName =  t.WhatId.getSObjectType().getDescribe().getName();
            if(!mapOfRelatedToIdWithRecordTypeName.isEmpty()){
                if(sobjectName  == 'Account'){
                    getRelatedToRecordType =  mapOfRelatedToIdWithRecordTypeName.get(mapOfTaskIdWithAccountId.get(t.Id));
                }else if(sobjectName  == 'Opportunity'){
                    getRelatedToRecordType = mapOfRelatedToIdWithRecordTypeName.get(mapOfTaskIdWithOpportunityId.get(t.Id));
                }
                
                if(getRelatedToRecordType !=null && t.RecordTypeId !=null){
                    string taskRecordTypeName = Schema.SObjectType.Task.getRecordTypeInfosById().get(t.recordtypeid).getname();
                    if((taskRecordTypeName == '72 Hour Check In' || taskRecordTypeName == 'Recruitment Meeting')
                       && (getRelatedToRecordType == 'Fixed Site Account' || getRelatedToRecordType == 'Fixed Site Opp')){
                           t.addError('Cannot create 72 Hour Check In/Recruitment Meeting task for Fix Site Account/Opportunity.');
                    }
                }
           		 
            }
        }
    }
}