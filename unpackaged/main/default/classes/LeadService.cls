// do NOT add with Sharing Key word here
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 
 *  03/08/2023				 Kishore Das		        Users other than System Admin should not have any delete record permissions(Logic for HRP-10572)(Deleted)

 *  20/10/2023               Krapy Tuli                 Logic for HRP-10880 (Update Leads to consume New Taxonomy - Geo Realignment)
 *************************************************************************************************************************************************
*/

public class LeadService {
    
    private static final string LEAD_QUEUE_UNASSIGNED = 'Unassigned';
    
    /* purpose: When leads are inserted or updated and don't yet have a Chapter specified,
     * look up the appropriate chapter from the Chapter Zipcode table using the new lead's 
     * postal code to find the correct Chapter it belongs to.
     * author: mike.demeglio@redcross.org
     * date: 1/31/2017
     */ 
     public static void setAccountRecordType(List<Lead> newLeads, Map<Id,Lead> oldMap){
          Set < Id > setAccountIds = new Set < Id >();

        for ( Lead objLead :newLeads) {

        /* Getting Account Ids from the Lead after conversion .
           ConvertedAccountId in Lead contains the Account Id to which the Lead is converted.
        */
        if ( objLead.IsConverted && objLead.IsConverted != oldMap.get( objLead.Id ).IsConverted )
            setAccountIds.add( objLead.ConvertedAccountId );

    }
    if ( setAccountIds.size() > 0 ) {

        Id extRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Mobile Account' ).getRecordTypeId();
        List < Account > listAcctForUpdate = new List < Account >();

        /* Fetching the accounts which are created as part of lead conversion and record type is not External */
        for ( Account objAccount : [ SELECT Id, RecordTypeId FROM Account WHERE Id IN: setAccountIds  ] ) {

            /* Setting the Record Type Id to Account's External Record Type Id */
            listAcctForUpdate.add( new Account( Id = objAccount.Id, RecordTypeId = extRecordTypeId ) );

        }

        if ( listAcctForUpdate.size() > 0 ){
           
                update listAcctForUpdate;//dml for security
                        
        }
            
     }
     }
         public static void setLeadTerritory(List<Lead> newLeads, Map<Id,Lead> oldMap){
        
        final string logTag = '[LeadService:setLeadTerritory]';
        //System.debug(logTag + 'Starting - ' + newLeads.size() + ' leads to process.');
        
        List<Lead> leadUpdates = new List<Lead>(); // a fresh list for only the leads that need to be udpated.
        Set<String> zipSet = new Set<String>(); // a Set to hold all the zipcodes that need to be looked up later
        String leadOwnerId;
        Date startDate; // HRP-10880 start
        Date endDate;
        Map<String,String> taxonomyMapZipVsDRDTerritoryCode = new Map<String,String> ();
        Map<String,String> taxonomyMapZipVsCollectionOppCode = new Map<String,String> ();
        Map<String,String> taxonomyMapZipVsDistrictCode = new Map<String,String> ();
        Map<String,String> taxonomyMapZipVsARCRegionCode = new Map<String,String> ();
        Map<String,String> bSFPortfolioPortfolioCodeVsId = new Map<String,String> ();
        Map<String,String> collectionOppCodeVsId = new Map<String,String> (); // HRP-10880 end
        // Check each new Lead and if the Postal Code is present, add them to a List for further processing, also build a list of all 
        // the unique postal codes for later use..
        for(Lead newLead:newLeads){
            
            Lead oldLead = new Lead();
            System.debug('newLead postalCode->'+newLead.PostalCode);

            // Has this lead has been updated? If so, set "oldLead" equal the old lead record instance.
            if(oldMap != null && newLead.Id != null && oldMap.containsKey(newLead.Id)){
                oldLead = oldMap.get(newLead.Id);
            }
            
             
            // If it's a brand new Lead - OR - an old Lead with a new Zipcode, we want to keep track of it and update it later on.
            if(newLead.PostalCode != null || newLead.PostalCode != oldLead.PostalCode){
               // System.debug(logTag + 'Lead postalcode is new or has changed: old: [' + oldLead.PostalCode + '], new: [' + newLead.PostalCode + ']');
                zipSet.add(newLead.PostalCode);
                
                if((startDate == null) || (startDate >= newLead.CreatedDate)){ // HRP-10880 start
                    startDate = newLead.CreatedDate == null ? system.today() : date.newinstance(newLead.CreatedDate.year(), newLead.CreatedDate.month(), newLead.CreatedDate.day());
                }
                if((endDate == null)||(endDate <= newLead.CreatedDate)){
                    endDate = newLead.CreatedDate == null ? system.today() : date.newinstance(newLead.CreatedDate.year(), newLead.CreatedDate.month(), newLead.CreatedDate.day());
                } // HRP-10880 end
               // System.debug(logTag + ' adding Lead [' + newLead.FirstName + ' ' + newLead.LastName + '] to leadUpdates list for processing..');
                leadUpdates.add(newLead);    
                
            } else {
              //  System.debug(logTag + 'Lead not added to leadUpdates: ' + newLead.LastName + ' (zipCode: ' + newLead.PostalCode + ')');
            }
            
        }
        
        
        
        // Make a map of Zipcode to Blood Region for later lookup.
        Map<String,Chapter_Blood_Region_Zip_Match__c> chapterMap = new Map<String,Chapter_Blood_Region_Zip_Match__c>();
        for(Chapter_Blood_Region_Zip_Match__c zm : [select Chapter__c, Blood_Region__c, Chapter__r.Name, Zip__c from Chapter_Blood_Region_Zip_Match__c where Zip__c IN :zipSet  ]){
            chapterMap.put(zm.Zip__c, zm); // this will allow us to quickly look up the chapter blood region zip match for a given zipcode.
        }
        
        
        // Similarly, make a map of Zipcode to Territory for later lookup
        Map<string,Collections_Territory__c> territoryMap = new Map<string,Collections_Territory__c>();
            System.debug('zipSet being passed ->'+zipSet);
        for(Collections_Territory__c ct : [select Id, Name, BDM__c, Zip__c, Region__r.Name from Collections_Territory__c where sked_start_date__c <= today and sked_End_Date__c >= today and Zip__c IN :zipSet]){ // HRP-10880
            System.debug('Collections Territory fetched->'+ct);
            territoryMap.put(ct.Zip__c, ct);
        }

        // HRP-10880 start
        
        for(Taxonomy__c taxo : [SELECT Zip_Code__c, Collection_Operation_Code__c, Division_Code__c, DS_Region_Code__c, District_Code__c, DRD_Territory_Code__c,RecordType.Name FROM Taxonomy__c where End_Date__c >=: endDate AND Start_Date__c <=: startDate AND (RecordType.Name = 'Bio Recruitment CD' OR RecordType.Name = 'Bio Collection BSF') AND Zip_Code__c IN :zipSet]){
            if(taxo.RecordType.Name == 'Bio Recruitment CD'){
                taxonomyMapZipVsDRDTerritoryCode.put(taxo.Zip_Code__c,taxo.DRD_Territory_Code__c);
            } else if(taxo.RecordType.Name == 'Bio Collection BSF'){
                taxonomyMapZipVsCollectionOppCode.put(taxo.Zip_Code__c,taxo.Collection_Operation_Code__c);
                String districtCodeString = 'Bio_Collection_BSF_District_'+taxo.Division_Code__c+'_'+taxo.DS_Region_Code__c+'_'+taxo.District_Code__c;
                String aRCRegionCodeString = 'Bio_Collection_BSF_ARC Region_'+taxo.Division_Code__c+'_'+taxo.DS_Region_Code__c;
                taxonomyMapZipVsDistrictCode.put(taxo.Zip_Code__c,districtCodeString);
                taxonomyMapZipVsARCRegionCode.put(taxo.Zip_Code__c,aRCRegionCodeString);
            }
            
        }
        
        List<sked_Territory__c> aRCRegionANDDistrictList = [SELECT Id, RecordType.Name, End_Date__c, Start_Date__c, External_Id_BackEnd__c FROM sked_Territory__c where (RecordType.Name ='ARC Region' OR RecordType.Name ='District') AND End_Date__c >=: endDate AND Start_Date__c <=: startDate AND (External_Id_BackEnd__c IN: taxonomyMapZipVsARCRegionCode.Values() or External_Id_BackEnd__c IN: taxonomyMapZipVsDistrictCode.Values()) ];
        system.debug('aRCRegionANDDistrictList ::'+aRCRegionANDDistrictList);
        for(BSF_Portfolio__c portfolio : [SELECT Id, End_Date__c, Start_Date__c, Territory_Portfolio__c, Portfolio_Code__c FROM BSF_Portfolio__c where Portfolio_Code__c IN: taxonomyMapZipVsDRDTerritoryCode.Values() AND Territory_Portfolio__c = true AND End_Date__c >=: endDate AND Start_Date__c <=: startDate]){
            bSFPortfolioPortfolioCodeVsId.put(portfolio.Portfolio_Code__c,portfolio.Id);
        }
        
        for(Biomed_Collection_Op_Center__c collOpp : [SELECT Id, Biomed_Collection_Op_Code_Center_ID__c FROM Biomed_Collection_Op_Center__c where Biomed_Collection_Op_Code_Center_ID__c IN: taxonomyMapZipVsCollectionOppCode.Values()]){
            System.debug('BSF Portfolio fetched->'+collOpp);
            collectionOppCodeVsId.put(collOpp.Biomed_Collection_Op_Code_Center_ID__c,collOpp.Id);
        }
        
        // HRP-10880 end
        // Now we can loop through all the leads again and assign the correct Chapter to them.
        for(Lead l:leadUpdates){
            
            
            // Look up the Chapter_Blood_Region_Zip_Match__c for this lead's zipcode.. 
            Chapter_Blood_Region_Zip_Match__c zp = chapterMap.get(l.PostalCode);
            if(zp != null){
                // Set the Chapter and Blood Region..
                l.Chapter__c = zp.Chapter__c;
                l.Blood_Region__c = zp.Blood_Region__c;
               // System.debug(logTag + 'Lead ' + l.LastName + ' assigned to Chapter ' + zp.Chapter__c);
            } else {
                // System.debug(logTag + 'Blood Region not found for zipcode: ' + l.PostalCode);
            }
            
            
            // Look up the Collections Territory from the map we created earlier
            Collections_Territory__c territory = territoryMap.get(l.PostalCode);
            
            if(territory != null){

              //  System.debug(logTag + 'Lead territory found: ' + territory.Name);
                l.Collections_Territory__c = territory.Id;

            } else {
              //  System.debug(logTag + 'NO TERRITORY FOUND FOR LEAD WITH ZIPCODE: ' + l.PostalCode);
            }
            // HRP-10880 start
            
            if(!aRCRegionANDDistrictList.isEmpty()){

                for(sked_Territory__c ter : aRCRegionANDDistrictList){
                    Date startDate1; // HRP-10880 start
                    //Date endDate1;
                    startDate1 = l.CreatedDate == null ?  system.today() : date.newinstance(l.CreatedDate.year(), l.CreatedDate.month(), l.CreatedDate.day());
                    if(ter.Start_Date__c <= startDate1 && ter.End_Date__c >= startDate1){
                        System.debug('sked_Territory__c inside if createdate->');
                        if(ter.RecordType.Name == 'ARC Region' && taxonomyMapZipVsARCRegionCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == taxonomyMapZipVsARCRegionCode.get(l.PostalCode)){
                                l.Lead_Region_Name__c = ter.ID;
                                System.debug('sked_Territory__c inside if RecordType->');
                            }else if(ter.RecordType.Name == 'District' && taxonomyMapZipVsDistrictCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == taxonomyMapZipVsDistrictCode.get(l.PostalCode)){
                                l.Lead_District__c = ter.ID;
                                System.debug('sked_Territory__c inside else RecordType->');
                            }
                         } else{
                            System.debug('There are no ARC Region territory associated with this');
                         }
                     }
  
              } else {
                 System.debug(logTag + 'There are no ARC Region territory record found ' + l.PostalCode);
              }

              if(!bSFPortfolioPortfolioCodeVsId.isEmpty()){
                l.Lead_AM_Porfolio__c = taxonomyMapZipVsDRDTerritoryCode.get(l.PostalCode) != null ? bSFPortfolioPortfolioCodeVsId.get(taxonomyMapZipVsDRDTerritoryCode.get(l.PostalCode)) : null;
              } else {
                 System.debug(logTag + 'There are no BSF portfolio territory record found ' + l.PostalCode);
              }
              
              if(!collectionOppCodeVsId.isEmpty()){
                l.Lead_Collection_Operation__c = taxonomyMapZipVsCollectionOppCode.get(l.PostalCode) != null ? collectionOppCodeVsId.get(taxonomyMapZipVsCollectionOppCode.get(l.PostalCode)) : null;
              } else {
                 System.debug(logTag + 'There are no BSF Collection Opperation record found ' + l.PostalCode);
              }
            // HRP-10880 end
        }

        // for(Lead l:leadUpdates){
        //     l.Lead_Region_Name__c = 'a3N5c0000048cakEAA';
        // }
                
        
    }
    
    
    
    public static void createTimelineEvents(List<Lead> newLeads, Map<Id,Lead> oldMap, String op){
        
        final string logTag = '[LeadService:createTimelineEvents]';
        //System.debug(logTag + 'Starting - ' + newLeads.size() + ' leads to process.');
        
        List<Lead> createEventList = new List<Lead>();
        List<Lead> surveyEventList = new List<Lead>();
        List<Event> newEventList = new List<Event>();
        
        for(Lead newLead:newLeads){
            Lead oldLead = new Lead();
            if(op.equals('UPDATE')){
                oldLead = oldMap.get(newLead.Id);
            }
            
            
            // Create a "Lead created event" on hte timeline for brand new leads
            if(op.equals('INSERT')){ // a brand new lead is being inserted
               // system.debug(logTag + 'New lead, creating an event on the timeline.');
                createEventList.add(newLead);
            } /*else { // updates
             
                // If it's a brand new Lead - OR - an old Lead with a new Zipcode, we want to keep track of it and update it later on.
                if( (oldLead.Interest_Survey_Completed_Date__c == null && newLead.Interest_Survey_Completed_Date__c != null) || (newLead.Interest_Survey_Completed_Date__c != oldLead.Interest_Survey_Completed_Date__c)) {
                    system.debug(logTag + 'Survey completed. Adding an event on the timeline.');
                    surveyEventList.add(newLead);
                }
            }*/
        }
        
        // Process all the leads
        for(Lead l:createEventList){
            newEventList.add(
                new Event(WhoId = l.Id, Subject='Lead created', StartDateTime=datetime.now(),EndDateTime=datetime.now())
            );
        }
        
        /*
        for(Lead l:surveyEventList){
            newEventList.add(
                new Event(WhoId = l.Id, Subject='Interest Survey completed', StartDateTime=datetime.now(),EndDateTime=datetime.now())
            );
        }
        */

        // System.debug(logTag + 'newEventList size: ' + newEventList.size());
        Database.Saveresult[] lsr = Database.insert(newEventList,false);
        for(Database.SaveResult sr:lsr){
            if(sr.isSuccess()){
              //  System.debug(logTag + 'Event created successfully with id ' + sr.getId());
            } else {
               // System.debug(logTag + 'Event not created. ' + sr.getErrors()[0].getMessage());
            }
        }
        
    }
    

    
    public static void sendAutoResponseEmail(List<Lead> newLeads){

        if(newLeads.size() > 1 ){
            System.debug('Auto-reponse emails are for single lead inserts from the web only.');
            return;
        }

        Lead newLead = newLeads[0];
        if(String.isNotBlank(newLead.LeadSource) && newLead.LeadSource.equalsIgnoreCase('Redcrossblood.org')){

            EmailTemplate template;

            // Look up the Lead auto-response template
            try{
                template = [select Id, Name, DeveloperName from EmailTemplate where DeveloperName = 'Lead_Auto_Response'  limit 1];
               // System.debug('Found email template [' + template.Name + ' (' + template.Id + '] for lead auto-response email use.');
            } catch(Exception e){
              //  System.debug('ERROR: unable to find email template for lead auto-response. ' + e);
                return;
            }

            //New instance of a single email message
            Messaging.SingleEmailMessage mail = 
                new Messaging.SingleEmailMessage();
     
            // Who you are sending the email to
            mail.setTargetObjectId(newLead.Id);

            // The email template ID used for the email
            mail.setTemplateId(template.Id);
              
            //mail.setWhatId(newLead.Id);    
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setReplyTo('no-response@redcrossblood.org');
            mail.setSenderDisplayName('American Red Cross');
            mail.setSaveAsActivity(false);  
     
            try{
                if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch (Exception e){
                //System.debug('ERROR SENDING WELCOME EMAIL TO LEAD: ' + e);
            }

        }

    }  
    

    public static void sendQueueAssignmentNotifications(List<Lead> newLeads, Map<Id,Lead> oldMap){
        
        final string logTag = '[LeadService:sendQueueAssignmentNotifications]';
        //System.debug(logTag + 'Starting - ' + newLeads.size() + ' leads to process.');
        
        Set<Id> queueIdSet = new Set<Id>();
        //Map<Id,List<Lead>> queueLeadMap = new Map<Id,List<Lead>>();
        List<Lead> leadList = new List<Lead>();

        for(Lead newLead:newLeads){
            Lead oldLead = oldMap.get(newLead.Id);
            if(oldLead == null) return; // just in case this is fired from an INSERT trigger
            
            if(newLead.OwnerID != oldLead.OwnerId){
                String newOwnerId = newLead.ownerId;
                //System.debug(logTag + 'Lead owner has changed from ' + oldLead.OwnerId + ' to ' + newOwnerId);
                if(newOwnerId.startsWith('00G')){
                    // owned by a queue
                    queueIdSet.add(newOwnerId);
                    /* NOT SURE WE NEED THIS MAP
                    if(queueLeadMap.containsKey(newOwnerId)){
                        queueLeadMap.get(newOwnerId).add(newLead); // Add the lead to the list of leads owned by this queue.
                    } else {
                        queueLeadMap.put(newOwnerId, new List<Lead>{newLead});
                    }
                    */
                    leadList.add(newLead); 
                }
            }
            
        }


        Map<Id,Group> queueMap = new Map<Id,Group>([select Id, Name, Email, Type from Group where Id IN :queueIdSet]);


        //System.debug(logTag + 'queueMap: ' + queueMap);
        //System.debug(logTag + 'queueLeadMap: ' + queueLeadMap);

        //EmailTemplate template = [Select id from EmailTemplate where name = 'AM Leads' limit 1];
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();

        // First, reserve email capacity for the current Apex transaction to ensure
        // that we won't exceed our daily email limits when sending email after
        // the current transaction is committed.
        Messaging.reserveSingleEmailCapacity(leadList.size());

        List<Lead> leadsToDelete = new List<Lead>();

        for(Lead l:leadList){

            Group leadQueue = queueMap.get(l.OwnerId);
            
            // Create a temporary lead so we can have a object for hte WhatId and use an Email template
            /*Lead tempLead = createTempLead(leadQueue.Email);
            if(tempLead.Id == null){
                System.debug(LoggingLevel.Error,'Error: temp lead not created.');
                continue;
            }
            */

            // Check first if the Group actually has an Email specified
            if(leadQueue.Email == null){
               // System.debug(logTag + 'Lead queue email is blank, skipping lead ' + l.Id);
                continue;
            }

            Messaging.SingleEmailMessage msg = createNotificationMessage(leadQueue, l, leadQueue);
            if(msg != null){
               // System.debug('Adding message for ' + l.LastName + ' for '+ leadQueue.Email);
                msgList.add(msg);
            } else {
               // System.debug('msg is null, nothing to send.');
            }

            //leadsToDelete.add(tempLead);
        }

        

        if(!msgList.isEmpty() && !Test.isRunningTest()){
            //System.debug('There are ' + msgList.size() + ' emails to send out.');
            Messaging.sendEmail(msgList,false);
        } else {
           // System.debug('msgList is empty or we are running a test, no email will be sent.');
        }


        // Dispose of temp leads
        if(!leadsToDelete.isEmpty()){
           // System.debug('Deleting ' + leadsToDelete.size()+ ' leads..');
          
                delete(leadsToDelete);//dml for security
           
        }


    }


    private static Messaging.SingleEmailMessage createNotificationMessage(Group grp, Lead lead, Group recipient){
        
        String leadName = lead.FirstName + ' ' + lead.LastName;
        // System.debug('Email for ' + leadName + ' will go to ' + recipient.Email);
            
        // Processes and actions involved in the Apex transaction occur next,
        // which conclude with sending a single email.

        // Now create a new single email message object
        // that will send out a single email to the addresses in the To, CC & BCC list.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Strings to hold the email addresses to which you are sending the email.
        String[] toAddresses = new String[] {grp.Email}; 
        //String[] ccAddresses = new String[] {'smith@gmail.com'};
        
        
        /*
        mail.setTargetObjectId(recipient.Id);

        // Select the template to user
        EmailTemplate tmpl;
        try{
            tmpl = [select Id from EmailTemplate where DeveloperName = 'Lead_Assignment'];
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Error: unable to find email template named Lead_Assignment');
            return null;
        }
        mail.setTemplateId(tmpl.Id);

        // Set the lead for the template's merge fields
        mail.setWhatId(lead.Id);
        */

        // Assign the addresses for the To and CC lists to the mail object.
        mail.setToAddresses(toAddresses);
        //mail.setCcAddresses(ccAddresses);

        // Specify the address used when the recipients reply to the email. 
        mail.setReplyTo('no-reply@redcross.org');

        // Specify the name used as the display name.
        mail.setSenderDisplayName('Salesforce Lead Notification');

        // Specify the subject line for your email address.
        mail.setSubject('New Lead  : ' + leadName + ' in ' + lead.City + ', ' + lead.StateCode);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);

        // Optionally append the salesforce.com email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        // Specify the text content of the email.
        //mail.setPlainTextBody('A new lead: ' + leadName + ' has been assigned to your territory.');

        mail.setHtmlBody(
            'A new lead has been assigned to your territory:<br/>' +
            '<h3>Lead Information</h3>' + 
            '<b>Name: </b>' + leadName + '<br/>' +
            '<b>Title: </b>' + lead.Title + '<br/>' + 
            '<b>Organization Name: </b> ' + lead.Company + '<br/>' + 
            '<b>Email: </b>' + lead.Email + '<br/>' +
            '<b>Phone: </b>' + lead.Phone + '<br/>' +
            '<b>Phone Type: </b>' + lead.Phone_Type__c + '<br/>' + 
            '<b>Referrer: </b>' + lead.Referrer__c + '<br/>' + 
            '<b>Source: </b>' + lead.LeadSource + '<br/>' + 

            '<h3>Location / Region Information</h3>' + 
            '<b>City: </b>' + lead.City + '<br/>' +
            '<b>State: </b>' + lead.StateCode + '<br/>' +
            '<b>Zip code: </b>' + lead.PostalCode + '<br/>' + 
            '<b>Territory: </b>' + lead.Territory_Name__c + '<br/>' +
            '<b>District: </b>' + lead.District__c + '<br/>'  + 
            '<b>Region: </b>' + lead.Region_Name__c + '<br/>' + 
            '<b>Blood Region: </b>' + lead.Blood_Region__c + '<br/>' + 
            '<b>Blood Chapter: </b>' + lead.Chapter__c + '<br/>' + 

            '<h3>Company / Organization Information:</h3>' + 
            '<b>Company Type: </b>' + lead.Company_Type__c + '<br/>' +
            '<b>Sub-Type: </b>' + lead.Company_Sub_Type__c + '<br/>' +
            '<b>Type (if Other): </b>' + lead.Company_Type_Other__c + '<br/>' +
            '<b>Organization/Company Size: </b>' + lead.Company_Size__c + '<br/>' +

            '<h3>Lead Scoring</h3>' + 
            '<b>Score (0=poor, 100=great): </b>' + lead.leadScoring__Lead_Score__c + '<br/>' + 
            '<b>Has hosted before? </b>' + lead.Hosted_Before__c + '<br/>' + 
            '<b>Has other Red Cross relationships: </b>' + lead.Other_Redcross_Relationships__c + '<br/>' +
            '<b>Has personal story? </b>' + lead.Has_Personal_Story__c + '<br/>' + 
            '<b>Personal Story: </b>' + lead.Personal_Story__c + '<br/>' + 
            '<b>Comments provided: </b>' + lead.Comments__c

        );
        

            

        return mail;

            
    }

    @TestVisible
    private static Lead createTempLead(string email){

        Lead tmpLead;
        List<Lead> existingLeads = [select Id from Lead where Email = :email  LIMIT 1];
        if(existingLeads.isEmpty()){ 
            System.debug('Creating a temp lead for ' + email);
            tmpLead =   new Lead(
            FirstName = 'LeadService', 
            LastName='Tests2323',
            Company='TestComany',
            City='Raleigh',
            StateCode='NC',
            PostalCode='27560',
            CountryCode='US');
        tmpLead.Parent_Campaign__c = null;
        tmpLead.Campaign_member_status__c = null;
        tmpLead.Email=email;
        
        } else {
           // System.debug('Found lead with the email address ' + email );
            tmpLead = existingLeads[0]; // just take the first record since all we care about is that there is a lead and the email matches 
        }

        try{
            
                insert(tmpLead);//dml for security
            
        } catch (Exception e){
            //System.debug('Error creating temp lead for email notification: ' + e.getMessage());
            return null;
        }
        return tmpLead;
    }
    
    /*AS-012902->SYSTEM: Presenting DRD AM Campaign pick list when creating lead  
     * */
    public static void createOrUpdateCampaignMember(List<Lead> newLeads, Map<Id,Lead> oldMap, 
                                                    Map<Id,Lead> newMap, String op){
         final string logTag = '[LeadService:createOrUpdateCampaignMember]';
         //System.debug(logTag + 'Starting - ' + newLeads.size() + ' leads to process.');
        List<CampaignMember> newCampaignMemberList = new List<CampaignMember>();
        //List<CampaignMember> neCampaignMemberList = new List<CampaignMember>();
        List<CampaignMember>  existingCampaignMembersUpdatedList = new List<CampaignMember>();//captures all existing members whose status got updated
        List<CampaignMember>  existingCampaignMembersToDeleteList = new List<CampaignMember>();//captures all existing members who got deleted

        Map<Id, CampaignMember> existingCampaignMemberMap = new Map<Id, CampaignMember>();                                                
        if(op.equals('UPDATE')){
            List<CampaignMember> existingCampaignMemberList = [select id,Status,LeadId,CampaignId from CampaignMember where  LeadId in :newMap.keyset()  ];
            if(existingCampaignMemberList.size()>0){
                for(CampaignMember existingCampaignMember:existingCampaignMemberList) {
                        // System.debug('Adding existingCampaignMember to list:'+existingCampaignMember);
                        existingCampaignMemberMap.put(existingCampaignMember.CampaignId,existingCampaignMember);//NOTE: we are inserting campaign Id instead of campaignmember id
                } 
            }
                             
        }
        for(Lead newLead:newLeads){
            Map<ID,Schema.RecordTypeInfo> rt_Map = Lead.sObjectType.getDescribe().getRecordTypeInfosById();  
            if(rt_map.get(newLead.recordTypeID).getName().containsIgnoreCase('Biomed Recruitment') == false){
                continue;//applicable only for Biomed recruitment type
            }
            if(newLead.Parent_Campaign__c == null && newLead.Campaign_member_status__c != null){
                newLead.addError('You must select a Campaign, if Campaign member status is selected, or unselect both');
                continue;
            }
            if(newLead.Parent_Campaign__c != null && newLead.Campaign_member_status__c == null){
                newLead.addError('You must select a Campaign member status, if Campaign is selected, or unselect both');
                continue;
            }
            
            
            Lead oldLead = new Lead();
            if(op.equals('UPDATE')){
                oldLead = oldMap.get(newLead.Id);
                if(newLead.Parent_Campaign__c == null && oldLead.Parent_Campaign__c != null){
                   CampaignMember existingMember = existingCampaignMemberMap.get(oldLead.Parent_Campaign__c);
                   existingCampaignMembersToDeleteList.add(existingMember);
                   continue;
                }
                if(oldLead.Parent_Campaign__c != newLead.Parent_Campaign__c
                    && existingCampaignMemberMap.get(newLead.Parent_Campaign__c)==null){ //only if it doesn't exist already in list
                    System.debug('campaign id updated for lead record id '+newLead.id);
                    CampaignMember campaignMember = new CampaignMember();
                    campaignMember.CampaignId=newLead.Parent_Campaign__c;
                    campaignMember.LeadId = newLead.id;
                    campaignMember.Status=newLead.Campaign_member_status__c;
                    newCampaignMemberList.add(campaignMember);
                    }else if(oldLead.Parent_Campaign__c != newLead.Parent_Campaign__c
                        && existingCampaignMemberMap.get(newLead.Parent_Campaign__c)!=null){//if it already exists, just compare status
                        CampaignMember existingMember = existingCampaignMemberMap.get(newLead.Parent_Campaign__c);
                            if(existingMember.Status != newLead.Campaign_member_status__c){
                                existingMember.status = newLead.Campaign_member_status__c;
                                existingCampaignMembersUpdatedList.add(existingMember);
                            } 
                        
                    }else if (existingCampaignMemberMap.size()>0 && oldLead.Parent_Campaign__c == newLead.Parent_Campaign__c
                          && oldLead.Campaign_member_status__c != newLead.Campaign_member_status__c){
                           System.debug('Campaig member Status updated for lead'+newLead);   
                    //when status got updated          
                          CampaignMember existingMember=    existingCampaignMemberMap.get(newLead.Parent_Campaign__c);
                              //update status
                          existingMember.Status=newLead.Campaign_member_status__c;
                         // System.debug('Campaig member Status updated for member'+existingMember); 
                          existingCampaignMembersUpdatedList.add(existingMember);
                }
            }
            else if(op.equals('INSERT')){ // a brand new lead is being inserted
                if(newLead.Parent_Campaign__c == null)
                    continue;
                // system.debug(logTag + 'New lead, creating a new Campaign member record ');
                CampaignMember campaignMember = new CampaignMember();
                campaignMember.CampaignId=newLead.Parent_Campaign__c;
                campaignMember.LeadId = newLead.id;
                campaignMember.Status=newLead.Campaign_member_status__c;
                newCampaignMemberList.add(campaignMember);
            } 
        
        }//end of for loop
        if(newCampaignMemberList.size()>0)
            insert newCampaignMemberList;
        if(existingCampaignMembersUpdatedList.size()>0)
            update existingCampaignMembersUpdatedList;
        if(existingCampaignMembersToDeleteList.size()>0)
            delete existingCampaignMembersToDeleteList;
                                                        
        
    }




    /*
    public static void handleConversion(List<Lead> updatedLeads){
        List<Account> acctUpdates = new List<Account>();
        for(Lead l:updatedLeads){
            if(l.IsConverted){
                // Copy the Lead's "Company Size" value to the Accounts "NumberOfEmployees" field
                if(l.convertedAccountId != null && l.Company_Size__c != null){
                    Integer numEmployees = Integer.valueOf(l.Company_Size__c);
                    acctUpdates.add( new Account(Id = l.convertedAccountId, NumberOfEmployees = numEmployees) );
                }
            }
        }

        if(acctUpdates.isEmpty()){
            System.debug('No accounts to update after lead conversion.');
            return;
        } else {
            System.debug('Updating ' + acctUpdates.size() + ' accounts after lead conversion.');
            Update(acctUpdates);
        }
    }
    */

   //AS-013042-Address standardization, will be called from before insert and before update
   
    public static void standardizeAddress(List<Lead> newLeads, Map<Id,Lead> oldMap, 
                                       Map<Id,Lead> newMap,String op){
                                           
             System.debug('Entered method standardizeAddress with oldMap and newMap'+oldMap+' : '+newMap);
             if(System.isFuture()){//extremely important,only run for first time otherwise will get exception future cannot be called from future
                 return;
             }                              
             //collects all leads which need to be evaluated for clean address                               
             List<Id> evaluateAddressLeadList =  new List<Id>();                             
             for(Lead newLead:newLeads){
                 
                 boolean isEmptyAddress = AddressUtility.isEmptyAddress(newLead,AddressUtility.LeadAddressFieldsMap);
                 if(isEmptyAddress == null){
                   System.debug('Address is null for incoming Lead');
                   continue;
                 }
                 InformaticaStandardAddress stdAddr = null;
                 if(op.equals('INSERT')){ 
                     System.debug('Coming in for first time insert without empty address for lead object:'+newLead);
                     evaluateAddressLeadList.add(newLead.id);//this is called from after insert, so id will be there always
                 }else if(op.equals('UPDATE')){
                     System.debug('Coming in as update');
                     Lead oldLead = oldMap.get(newLead.id);
                     boolean isAddressChanged = AddressUtility.isAddresssChanged(oldLead, newLead,AddressUtility.LeadAddressFieldsMap);
                     System.debug('isAddressChanged:'+isAddressChanged);
                     if(isAddressChanged == true){
                         evaluateAddressLeadList.add(newLead.id);//this is called from after insert/after update, so id will be there always
                     }
                 }
                //Call Informatica API and clean addresses
                  AddressUtility.cleanLeadAddress(evaluateAddressLeadList);
            }                             
      }
    
    
    public static void convertToOpportunities(Map<Id,Lead> triggerOldMap, List<Lead> leads){
        System.debug('Entered method convertToOpportunities');

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Lead ld : leads) {
            if(ld.isConverted && triggerOldMap != null &&
               triggerOldMap.get(ld.id).isConverted) {
                continue; //only process newly converted leads
            }
             if (ld.ConvertedOpportunityId != null) {
                 Opportunity opp = new Opportunity(Id = ld.ConvertedOpportunityId);
                 System.debug('ld.ConvertedAccountId->'+ld.ConvertedAccountId);
                 opp.AccountId = ld.ConvertedAccountId;
                 opp.CampaignId = ld.Parent_Campaign__c;
                
                 oppsToUpdate.add(opp);
            }
        }
            if (!oppsToUpdate.isEmpty()) {
                 update oppsToUpdate;
            }       
    }
    //HRP-10880 start check if ARC region check if change it will run the assignment rule on lead.
    public static void checkForArcRegionChange(List<Lead> newLeads, Map<Id,Lead> oldMap){
        System.debug('Entered method checkForArcRegionChange');
        if(oldMap.isEmpty()){
            system.debug('checkForArcRegionChange skip');
            return;
        }
        List<Id> ids = new List<Id>();
        for(Lead newLead:newLeads){
            
            Lead oldLead = new Lead();
            System.debug('newLead postalCode->'+newLead.PostalCode);

            // Has this lead has been updated? If so, set "oldLead" equal the old lead record instance.
            if(oldMap != null && newLead.Id != null && oldMap.containsKey(newLead.Id)){
                oldLead = oldMap.get(newLead.Id);
            }
            
             
            // If it's a brand new Lead - OR - an old Lead with a new Zipcode, we want to keep track of it and update it later on.
            if(newLead.PostalCode != null && newLead.PostalCode != oldLead.PostalCode){
               
                ids.add(newLead.Id);
            
            } else {
              //  System.debug(logTag + 'Lead not added to leadUpdates: ' + newLead.LastName + ' (zipCode: ' + newLead.PostalCode + ')');
            }
            if(!ids.isEmpty()){
                LeadService.assignLeads(ids);
                System.debug('lead assignment rule is run done for postal code '+newLead.PostalCode);
            } else{
                System.debug('lead assignment rule does not run done for postal code '+newLead.PostalCode);
            }
            
        }   
    }
        @InvocableMethod
        public static void assignLeads(List<Id> leadIds){
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
            List<Lead> toAssign = [SELECT Id FROM Lead WHERE Id = :leadIds];
            Database.update(toAssign,dmo);
        } //HRP-10880 end
}