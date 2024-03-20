/***************************************************************************************************** 
Class    :  PrepareMySandbox
Developer:  Ivo Dimov (ivo.dimov@redcross.org)
Created  :  Feb 01, 2018
Modified :  
Objective:  This will be a post-sandbox refresh step which corrects System Administrator user email addresses. 
            It is utilizing the sandboxPostCopy Interface

*****************************************************************************************************/

global with sharing class PrepareMySandbox implements SandboxPostCopy {
    
    global void runApexClass(SandboxContext context) {
        System.debug('Org ID: ' + context.organizationId());
        System.debug('Sandbox ID: ' + context.sandboxId());
        System.debug('Sandbox Name: ' + context.sandboxName());
        fixAdminEmail();
    }
    
    global static void fixAdminEmail(){
        // This query that identifies admin records to be updated and are added to a list
        List<User>adminsList = [select id, name, email from User where Profile.Name = 'System Administrator' and IsActive = true and Email like '%redcross.org.invalid'];
        System.debug('There are [' + adminsList.size() + '] active System Administrator users currently.');
        List<user> updatedAdminList = new List<user>();
        
        for(User sa : adminsList){
            
            //removing the appended value
            String removePhrase='.invalid'; //Update by Ivo 3/28/19 AS-007194
            sa.Email=sa.email.remove(removePhrase);
            updatedAdminList.add(sa);
            
            System.debug('These are the updated users: ' + updatedAdminList);   
        }
        
            update(updatedAdminList);
        
    }
}