global class BSF_Batch_TemplateOrderExpiration implements Database.Batchable<sObject> {
  Date currentDate;
  Date dueDate;
  Task_Reassignment_Matrix__mdt metadata;
  User drdSystemUser;
  global BSF_Batch_TemplateOrderExpiration(){
    currentDate = Date.Today();
    metadata = Task_Reassignment_Matrix__mdt.getInstance('Template_Order_Task');
    Integer offsetNew = Integer.valueOf(metadata.Creation_Date_Offset__c);
    dueDate = currentDate.adddays(offsetNew) ;
    drdSystemUser = [select id from User where name=:BSF_constants.DRDSystemUser];
  }
 
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
      String query = 'SELECT ID ,EndDate,Opportunity.AccountId,OpportunityId ,Order_Due_Date__c , Opportunity.Is_Template__c From Order where Opportunity.Is_Template__c = TRUE ';
      query = query + 'AND EndDate >= :currentDate AND EndDate <= :dueDate';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<order> scope)
    { 
        System.debug('22 entering for scope: ' +scope);
        Set<Id> accountIds = new Set<Id>();
        List<Task> templateTask = new List<Task>();
        Map<Id,Map<String,Id>> atmMap = new Map<Id,Map<String,Id>>();

        Id taskrecordtypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get(metadata.Category__c).getRecordTypeId();

        for (Order ord : scope) {
            System.debug('30 entering for scope: ' + ord);
            if (ord.Opportunity != null && ord.Opportunity.AccountId != null) {
                 accountIds.add(ord.Opportunity.AccountId);
                  System.debug('33 entering for scope: ' + accountIds); 
            }
        }

        if(!accountIds.isEmpty()){
            List<AccountTeamMember> acTeam = [SELECT Id, 
                                                    UserId,
                                                    is_covering_recruiter__c,
                                                    TeamMemberRole,
                                                    AccountId,
                                                    End_Date__c,
                                                    Start_Date__c 
                                                FROM AccountTeamMember
                                                WHERE AccountId IN: accountIds
                                                AND Start_Date__c <= :Date.Today()
                                                AND End_Date__c >= :Date.Today()];
            for(AccountTeamMember atm : acTeam){
                System.debug('50 entering for scope: ' + atm); 
                if(atmMap.isEmpty() || !atmMap.containskey(atm.AccountId)){
                    System.debug('52 entering for scope: ' + atmMap);
                    atmMap.put(atm.AccountId, new Map<String,Id>());
                    
                }
                if((atmMap.get(atm.AccountId).isEmpty() || !atmMap.get(atm.AccountId).containskey(atm.TeamMemberRole))
                        || (atmMap.get(atm.AccountId).containskey(atm.TeamMemberRole) && atm.is_covering_recruiter__c)){
                            System.debug('58 entering for scope: ' + atmMap);
                            atmMap.get(atm.AccountId).put(atm.TeamMemberRole,atm.UserId);
                }
            }
        }


        for(Order odd : scope){
            System.debug('66 entering for scope: ' + odd);
            if (odd.Opportunity != null && odd.Opportunity.AccountId != null && !atmMap.isEmpty() && atmMap.containsKey(odd.Opportunity.AccountId)) {
                Task t = new Task(); 
                t.subject = metadata.Task_Subject__c;
                t.description = metadata.Description__c;
                t.whatId = odd.Id;
                t.activitydate = odd.EndDate.adddays(0 - integer.valueof(metadata.Due_Date_Offset__c)) ;
                t.priority = 'high';
                t.Status = 'Not Started';
                t.recordtypeId = taskrecordtypeId; 
                t.ownerId = ownerFromHierachy(atmMap.get(odd.Opportunity.AccountId));
                templateTask.add(t);
            }
        }

        if(!templateTask.isEmpty()){
            //insert templateTask;
             Database.SaveResult[] srList = Database.insert (templateTask,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Template Order Expiration','BSF_Batch_TemplateOrderExpiration','execute','Error','Error In Template Order Expiration');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }

    }
    global void finish(Database.BatchableContext BC) {}

    public Id ownerFromHierachy(Map<String,Id> teamMap){
        Id OwnerId;
        List<String> roleList = new List<String>{'Account Manager','Account Specialist','District Manager'};
        Boolean assign = false;
        System.debug('95 entering for scope: ' + assign);
        for(String role : roleList){
            System.debug('96 entering for scope: ' + role);
            if(role.equals(metadata.Assigned_To__c)){
               System.debug('99 entering for scope: ' + role); 
                assign = true;
            }
            
            if(OwnerId == null && assign && !teamMap.isEmpty() && teamMap.containsKey(role)){
                OwnerId = teamMap.get(role);
                System.debug('105 entering for scope: ' + OwnerId);
            }
        }
        if(OwnerId == null){
            OwnerId = drdSystemUser.Id;
        }
        return OwnerId;
    }
}