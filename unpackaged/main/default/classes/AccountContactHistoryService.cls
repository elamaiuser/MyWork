/**
* This Class makes entries in the Account Contact History object, whenever there is a change in Account Service Role
* 
* */
public class AccountContactHistoryService { //do not add with sharing 
    
    //Capture the change and make a new record entry for each change 
    public static void handleChangeEntry(Map<Id,Account_Service_Role__c> oldMap, List<Account_Service_Role__c> newList){
        System.debug('Entered handleChangeEntry newList Size->'+newList.size());
        //each new update will make an entry in history object
        List<Account_Contact_History__c> accountContactHistoryList = new  List<Account_Contact_History__c>();
        for(Account_Service_Role__c accountServiceRole:newList){
            Account_Contact_History__c accountContactHistory = new Account_Contact_History__c();
            accountContactHistory.role__c = accountServiceRole.account_service_role__c;
            accountContactHistory.Contact__c = accountServiceRole.contact__c;
            accountContactHistory.Start_Date__c = accountServiceRole.start_date__c;
            accountContactHistory.account__c = accountServiceRole.account__c;
            accountContactHistory.End_Date__C = accountServiceRole.End_Date__C;
            accountContactHistoryList.add(accountContactHistory);
            
        }
        //Schema.DescribeSObjectResult ds = Account_Contact_History__c.sObjectType.getDescribe();if( ds.isCreateable() ){}
        
        insert accountContactHistoryList;
        
        
    }
    
    //Capture the delete and make a new record entry for each delete 
    public static void handleAccountServiceRoleDelete(List<Account_Service_Role__c> oldList){
        //each new update will make an entry in history object
        List<Account_Contact_History__c> accountContactHistoryList = new  List<Account_Contact_History__c>();
        for(Account_Service_Role__c accountServiceRole:oldList){
            System.debug('accountServiceRole## '+accountServiceRole);
            System.debug('accountServiceRole Id## '+accountServiceRole.Id);
            System.debug('accountServiceRole Contact ## '+accountServiceRole.contact__c);
            Account_Contact_History__c accountContactHistory = new Account_Contact_History__c();
            if(accountServiceRole.Contact__c !=null){
                accountContactHistory.role__c = accountServiceRole.account_service_role__c;
                accountContactHistory.Contact__c = accountServiceRole.contact__c;
                accountContactHistory.Start_Date__c = accountServiceRole.start_date__c;
                accountContactHistory.account__c = accountServiceRole.account__c;
                accountContactHistory.is_Service_Role_Deleted_Permanently__c = true;
            }
            accountContactHistoryList.add(accountContactHistory); 
        }
        //Schema.DescribeSObjectResult ds = Account_Contact_History__c.sObjectType.getDescribe();if( ds.isCreateable() ){}
        system.debug('accountContactHistoryList## '+accountContactHistoryList);
        Database.insert(accountContactHistoryList,false) ;
        
        
    }
    
    
    //Capture the change and make a new record entry for each change 
    /*public static void handleChangeEntry(Map<Id,AccountContactRelation> oldMap, List<AccountContactRelation> newList){
//each new update will make an entry in history object
List<Account_Contact_History__c> accountContactHistoryList = new  List<Account_Contact_History__c>();
for(AccountContactRelation accountContactRelationObj:newList){
System.debug('Roles received:'+accountContactRelationObj.Roles);
List<String> rolesList = new List<String>();
if(String.isNotBlank(accountContactRelationObj.Roles)){
rolesList = accountContactRelationObj.Roles.split(';');//split colon seperated string into multiple records
for(String role:rolesList){
Account_Contact_History__c accountContactHistory = new Account_Contact_History__c();
accountContactHistory.role__c = role;
accountContactHistory.Contact__c = accountContactRelationObj.ContactId;
accountContactHistory.Start_Date__c = accountContactRelationObj.StartDate;
accountContactHistory.End_Date__c = accountContactRelationObj.EndDate;
accountContactHistory.End_Reason__c = accountContactRelationObj.Account_Service_End_Reason__c;
accountContactHistory.account__c = accountContactRelationObj.AccountId;
accountContactHistoryList.add(accountContactHistory);
}
}else{//when incoming rules is null
Account_Contact_History__c accountContactHistory = new Account_Contact_History__c();
accountContactHistory.role__c = accountContactRelationObj.Roles;
accountContactHistory.Contact__c = accountContactRelationObj.ContactId;
accountContactHistory.Start_Date__c = accountContactRelationObj.StartDate;
accountContactHistory.End_Date__c = accountContactRelationObj.EndDate;
accountContactHistory.End_Reason__c = accountContactRelationObj.Account_Service_End_Reason__c;
accountContactHistory.account__c = accountContactRelationObj.AccountId;
accountContactHistoryList.add(accountContactHistory);
}


}
insert accountContactHistoryList;
}*/
    
}