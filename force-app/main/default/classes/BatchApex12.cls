global class BatchApex12 implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String id='00505000001tAgZAAU';
        String id1='00505000001tAgaAAE';
        list<String> idlist=new list<String>();
        idlist.add(id);
         idlist.add(id1);
        String query = 'select id,name,MobilePhone, Phone from user where MobilePhone !=null AND Id NOT IN:idlist limit 405';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<user> UserList) {
        
        for(user u:UserList){
            u.MobilePhone=u.MobilePhone.replaceAll('[()\\s-]+', '');
            
        }
        database.update(UserList);
    }   
    
    global void finish(Database.BatchableContext BC) {
        
    }
}