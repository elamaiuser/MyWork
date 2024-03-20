public class OneTimeEmailUpdateBatch implements Database.Batchable<sObject>{
     String query = 'select username, email from user where email like \'%.invalid%\' and isActive=true';	

    public Database.QueryLocator start(Database.BatchableContext BC){
        if(Test.isRunningTest()){
            			return Database.getQueryLocator (query+' and title=\'TestTitle\' limit 1');

        }
			return Database.getQueryLocator (query);
       }
    
    
         public void execute(Database.BatchableContext BC, List<sObject> scope){
			for(sObject obj:scope){
               User u = (User) obj;
               //System.debug('u->'+u); 
               String email= u.email;
               String updatedEmail = email.removeEndIgnoreCase('.invalid');
               u.email = updatedEmail;
               //System.debug('updatedEmail->'+updatedEmail);
            }
            Database.update(scope, false); 
               
         }
    
    public void finish(Database.BatchableContext BC){
           
       }
}