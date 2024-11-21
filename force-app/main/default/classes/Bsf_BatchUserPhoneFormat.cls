global class Bsf_BatchUserPhoneFormat implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        string inVar='(';
		string tempInput = '%' + inVar + '%';
        
        String query = 'select id,name,MobilePhone, Phone from user where MobilePhone !=null AND MobilePhone Like:tempInput';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<user> UserList) {
        system.debug('UserList1');
        for(user u:UserList){
            system.debug('uu'+u.MobilePhone);
            u.MobilePhone=u.MobilePhone.replaceAll('[()\\s-]+', '');
            
        }
        database.update(UserList);
    }   
    
    global void finish(Database.BatchableContext BC) {
        
    }

}