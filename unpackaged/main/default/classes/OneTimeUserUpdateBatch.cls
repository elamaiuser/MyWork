public class OneTimeUserUpdateBatch implements Database.Batchable<sObject>{

 	public Database.QueryLocator start(Database.BatchableContext BC){
			return Database.getQueryLocator ([select id, name from User where isActive =true and id not in ('0051J000007h6fXQAQ','00505000001smVFAAY','00505000001sILoAAM','005o0000004aUJxAAM','00505000001snToAAI','00505000001sILyAAM','00505000001snToAAI','00505000001sILyAAM','00505000001snTAAAY','00505000001sILjAAM','0055c0000080FwRAAU','00505000001sILtAAM','00505000001uB62AAE')]);
       }
    
     public void execute(Database.BatchableContext BC, List<sObject> scope){
		
           for(sObject obj:scope){
               User u = (User) obj;
               u.isActive=false;
           }
         Database.update(scope, false);
     }
    
     public void finish(Database.BatchableContext BC){
           
       }
    
    }