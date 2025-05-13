// do NOT add with Sharing Key word here
/* 
 * Modification Log 
 * Date                      Developer Name              Comments
 * ***********************************************************************************************************************************************
 * 
 *  03/08/2023               Kishore Das                Users other than System Admin should not have any delete record permissions(Logic for HRP-10572)(Deleted)

 *  20/10/2023               Krapy Tuli                 Logic for HRP-10880 (Update Leads to consume New Taxonomy - Geo Realignment)
 *  02/19/2024               Anil K                     HRP-12024-> Check Future Taxonomy records if a particular zip code is falling in non collection area
 *  03/27/2024               Apurba Bhattacgarjee       Modified logic for HRP-12321
 *  03/27/2024               Apurba Bhattacgarjee       Changes for  HRP-11347
 *  08/14/2024               Priti Jana                 Logic for HRP-12190
 *  10/22/2024				 Balaji N				  	Logic for HRP-13603 handleLeadStageStatus method call
 *  12/09/2024               Priti Jana                 Logic for HRP-13602
 *  03/10/2025               Souvik Mukherjee           Logic for HRP-14331 - only consider Leads of Record Type Marketing Manager for conversion to Feeder Group
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

    // HRP-13602 -> Restructured method to incorporate changes for Account.Feeder_Account_Type__c
    public static void setAccountRecordType(List<Lead> newLeads, Map<Id,Lead> oldMap){
        Map<Id, Boolean> map_convertedAccountId_isFeederLead = new Map<Id, Boolean>();
        List<String> feederGroupLeadStatus = System.Label.Potential_Feeder_Group_Lead_Status.split(',');
        System.debug('*****feederGroupLeadStatus : ' + System.Label.Potential_Feeder_Group_Lead_Status);
        for (Lead objLead : newLeads) {

            /* Getting Account Ids from the Lead after conversion .
            ConvertedAccountId in Lead contains the Account Id to which the Lead is converted.
            */
            if (objLead.IsConverted && objLead.IsConverted != oldMap.get( objLead.Id ).IsConverted) {
                Id marketManagerLeadId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Market Manager').getRecordTypeId();        //Changed for HRP-14331
                System.debug('******marketManagerLeadId : ' + marketManagerLeadId);
                System.debug('******OldLead.RecordTypeId : ' + oldMap.get( objLead.Id ).RecordTypeId);
                System.debug('******oldMap.get(objLead.Id).Status within Feeder Group Status List ? : ' + feederGroupLeadStatus.contains(oldMap.get(objLead.Id).Status));
                Boolean isFeederLeadConverted = oldMap.get( objLead.Id ).RecordTypeId == marketManagerLeadId ? feederGroupLeadStatus.contains(oldMap.get(objLead.Id).Status) : false;       //Changed for HRP-14331
                map_convertedAccountId_isFeederLead.put(objLead.ConvertedAccountId, isFeederLeadConverted);
                System.debug('******isFeederLeadConverted : ' + isFeederLeadConverted);
            }
        }

        if (map_convertedAccountId_isFeederLead != NULL && !map_convertedAccountId_isFeederLead.isEmpty()) {
            Id mobileRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId();
            List<Account> listAcctForUpdate = [SELECT Id, RecordTypeId, Feeder_Account_Type__c FROM Account WHERE Id IN :map_convertedAccountId_isFeederLead.keySet()];
            for (Account objAccount :  listAcctForUpdate) {
                objAccount.RecordTypeId = mobileRecordTypeId; //Updating account record type to "Mobile"
                System.debug('******objAccount.Feeder_Account_Type__c : ' + objAccount.Feeder_Account_Type__c);
                if(map_convertedAccountId_isFeederLead.get(objAccount.Id) && String.isBlank(objAccount.Feeder_Account_Type__c)) {
                    System.debug('******bjAccount.Feeder_Account_Type__c Set To FEEDER ONLY');
                    objAccount.Feeder_Account_Type__c = BSF_Constants.FEEDER_ONLY_ACCOUNT; //Updating feeder account type to "Feeder Only" if a feeder lead is converted
                }
            }

            if (listAcctForUpdate.size() > 0) {
                update listAcctForUpdate;       
            }     
        }
    }

    public static void setLeadTerritory(List<Lead> newLeads, Map<Id,Lead> oldMap) {
        
        final string logTag = '[LeadService:setLeadTerritory]';
        //System.debug(logTag + 'Starting - ' + newLeads.size() + ' leads to process.');
        
        List<Lead> leadUpdates = new List<Lead>(); // a fresh list for only the leads that need to be udpated.
        Set<String> zipSet = new Set<String>(); // a Set to hold all the zipcodes that need to be looked up later
        String leadOwnerId;
        Date startDate; // HRP-10880 start
        Date endDate;
        Map<String,String> taxonomyMapZipVsDRDTerritoryCode = new Map<String,String>();
        Map<String,String> taxonomyMapZipVsCollectionOppCode = new Map<String,String>();
        //HRP-12024-begin
        Map<String,String> futureTaxonomyMapZipVsCollectionOppCode = new Map<String,String>();
        Map<String,String> futureTaxonomyMapZipVsARCRegionCode = new Map<String,String>();
        Map<String,String> futureTaxonomyMapZipVsDistrictCode = new Map<String,String>();
        Map<String,String> futureTaxonomyMapZipVsDivisionCode = new Map<String,String>(); //HRP-12190
        Map<String,String> futureTaxonomyMapZipVsDRDTerritoryCode = new Map<String,String>();
        Map<String,String> futureBSFPortfolioPortfolioCodeVsId = new Map<String,String>();
        Map<String,String> futureCollectionOppCodeVsId = new Map<String,String>(); // HRP-10880 end

        //HRP-12024-end

        Map<String,String> taxonomyMapZipVsDistrictCode = new Map<String,String>();
        Map<String,String> taxonomyMapZipVsARCRegionCode = new Map<String,String>();
        Map<String,String> taxonomyMapZipVsDivisionCode = new Map<String,String>(); //HRP-12190
        Map<String,String> bSFPortfolioPortfolioCodeVsId = new Map<String,String>();

        Map<String,String> collectionOppCodeVsId = new Map<String,String> (); // HRP-10880 end
        // Check each new Lead and if the Postal Code is present, add them to a List for further processing, also build a list of all 
        // the unique postal codes for later use..
        for(Lead newLead:newLeads){
            
            Lead oldLead = new Lead();

            // Has this lead has been updated? If so, set "oldLead" equal the old lead record instance.
            if(oldMap != null && newLead.Id != null && oldMap.containsKey(newLead.Id)){
                oldLead = oldMap.get(newLead.Id);
            }
            
             
            // If it's a brand new Lead - OR - an old Lead with a new Zipcode, we want to keep track of it and update it later on.
            if( (oldLead == null && !String.isBlank(newLead.PostalCode))  || (newLead.PostalCode != oldLead.PostalCode && !String.isBlank(newLead.PostalCode))  ){ // HRP-12321 - Modification in logic
                zipSet.add(newLead.PostalCode);
                
                if((startDate == null) || (startDate >= newLead.CreatedDate)){ // HRP-10880 start
                    startDate = newLead.CreatedDate == null ? system.today() : date.newinstance(newLead.CreatedDate.year(), newLead.CreatedDate.month(), newLead.CreatedDate.day());
                }
                if((endDate == null)||(endDate <= newLead.CreatedDate)){
                    endDate = newLead.CreatedDate == null ? system.today() : date.newinstance(newLead.CreatedDate.year(), newLead.CreatedDate.month(), newLead.CreatedDate.day());
                } // HRP-10880 end
                leadUpdates.add(newLead);    
                
            }  
        }
 
        // Make a map of Zipcode to Blood Region for later lookup.
        Map<String,Chapter_Blood_Region_Zip_Match__c> chapterMap = new Map<String,Chapter_Blood_Region_Zip_Match__c>();
        for(Chapter_Blood_Region_Zip_Match__c zm : [select Chapter__c, Blood_Region__c, Chapter__r.Name, Zip__c from Chapter_Blood_Region_Zip_Match__c where Zip__c IN :zipSet  ]){
            chapterMap.put(zm.Zip__c, zm); // this will allow us to quickly look up the chapter blood region zip match for a given zipcode.
        }
        
        
        // Similarly, make a map of Zipcode to Territory for later lookup
        Map<string,Collections_Territory__c> territoryMap = new Map<string,Collections_Territory__c>();
        for(Collections_Territory__c ct : [select Id, Name, BDM__c, Zip__c, Region__r.Name from Collections_Territory__c where sked_start_date__c <= today and sked_End_Date__c >= today and Zip__c IN :zipSet]){ // HRP-10880
            territoryMap.put(ct.Zip__c, ct);
        }

        // HRP-10880 start
        //HRP-12024-> Check Future Taxonomy records if a particular zip code is falling in non collection area

        List<Taxonomy__c> allTaxonomies = [SELECT Zip_Code__c, Collection_Operation_Code__c, Division_Code__c, DS_Region_Code__c, District_Code__c, DRD_Territory_Code__c,RecordType.Name, 
                                            Collection_Operation_Name__c,District_Name__c,Division_Name__c,DS_Region_Name__c FROM Taxonomy__c 
                                            /*where Collection_Operation_Name__c != :nonServiceArea and District_Name__c != :nonServiceArea 
                                            and Division_Name__c != :nonServiceArea and DS_Region_Name__c != :nonServiceArea and City__c!=null and State__c != null*/
                                            WHERE End_Date__c >=: endDate AND Start_Date__c <=: startDate
                                            AND (RecordType.Name = 'Bio Recruitment CD' OR RecordType.Name = 'Bio Collection BSF') 
                                            AND Zip_Code__c IN :zipSet
                                        ];
        
        Map<String,Map<String,Taxonomy__c>> taxonomyMap = segragateTaxonomies(allTaxonomies, startDate);                   
        Map<String,Taxonomy__c> currentTaxonomies = taxonomyMap.get('Current');
        if(currentTaxonomies == null) {
            currentTaxonomies = new Map<String,Taxonomy__c> ();
        }
        Map<String,Taxonomy__c> futureTaxonomies = taxonomyMap.get('Future');
        if(futureTaxonomies == null) {
            futureTaxonomies = new Map<String,Taxonomy__c> ();
        }

        Date endDate4000 = Date.newInstance(4000, 12, 31);
        for(Taxonomy__c taxo : currentTaxonomies.Values()) { //HRP 12024        
            if(taxo.RecordType.Name == 'Bio Recruitment CD') {
                taxonomyMapZipVsDRDTerritoryCode.put(taxo.Zip_Code__c,taxo.DRD_Territory_Code__c);
            } else if(taxo.RecordType.Name == 'Bio Collection BSF') {
                taxonomyMapZipVsCollectionOppCode.put(taxo.Zip_Code__c,taxo.Collection_Operation_Code__c);
                String districtCodeString = 'Bio_Collection_BSF_District_'+taxo.Division_Code__c+'_'+taxo.DS_Region_Code__c+'_'+taxo.District_Code__c;
                String aRCRegionCodeString = 'Bio_Collection_BSF_ARC Region_'+taxo.Division_Code__c+'_'+taxo.DS_Region_Code__c;
                String divisionCodeString = 'Bio_Collection_BSF_Division_'+taxo.Division_Code__c; //HRP-12190
                taxonomyMapZipVsDistrictCode.put(taxo.Zip_Code__c, districtCodeString);
                taxonomyMapZipVsARCRegionCode.put(taxo.Zip_Code__c, aRCRegionCodeString);
                taxonomyMapZipVsDivisionCode.put(taxo.Zip_Code__c, divisionCodeString); //HRP-12190
            }
            
        }
        for(Taxonomy__c taxo : futureTaxonomies.Values()) { //HRP 12024               
            if(taxo.RecordType.Name == 'Bio Recruitment CD') {
                futureTaxonomyMapZipVsDRDTerritoryCode.put(taxo.Zip_Code__c,taxo.DRD_Territory_Code__c);
            } else if(taxo.RecordType.Name == 'Bio Collection BSF') {
                futureTaxonomyMapZipVsCollectionOppCode.put(taxo.Zip_Code__c,taxo.Collection_Operation_Code__c);
                String districtCodeString = 'Bio_Collection_BSF_District_'+taxo.Division_Code__c+'_'+taxo.DS_Region_Code__c+'_'+taxo.District_Code__c;
                String aRCRegionCodeString = 'Bio_Collection_BSF_ARC Region_'+taxo.Division_Code__c+'_'+taxo.DS_Region_Code__c;
                String divisionCodeString = 'Bio_Collection_BSF_Division_'+taxo.Division_Code__c; //HRP-12190
                futureTaxonomyMapZipVsDistrictCode.put(taxo.Zip_Code__c, districtCodeString);
                futureTaxonomyMapZipVsARCRegionCode.put(taxo.Zip_Code__c, aRCRegionCodeString);
                futureTaxonomyMapZipVsDivisionCode.put(taxo.Zip_Code__c, divisionCodeString); //HRP-12190
            }
            
        }

        List<sked_Territory__c> currentTerritoryList = new List<sked_Territory__c>();
        if(currentTaxonomies.size() > 0) {
            currentTerritoryList = [SELECT Id, RecordType.Name, End_Date__c, Start_Date__c, External_Id_BackEnd__c 
                                    FROM sked_Territory__c 
                                    WHERE End_Date__c >=: endDate 
                                    AND Start_Date__c <=: startDate 
                                    AND (External_Id_BackEnd__c IN: taxonomyMapZipVsARCRegionCode.Values() 
                                            OR External_Id_BackEnd__c IN: taxonomyMapZipVsDistrictCode.Values()
                                            OR External_Id_BackEnd__c IN: taxonomyMapZipVsDivisionCode.Values()
                                        )
                                    ];

            for(BSF_Portfolio__c portfolio : [SELECT Id, End_Date__c, Start_Date__c, Territory_Portfolio__c, Portfolio_Code__c FROM BSF_Portfolio__c where Portfolio_Code__c IN: taxonomyMapZipVsDRDTerritoryCode.Values() AND Territory_Portfolio__c = true AND End_Date__c >=: endDate AND Start_Date__c <=: startDate]) {
                bSFPortfolioPortfolioCodeVsId.put(portfolio.Portfolio_Code__c,portfolio.Id);
            }
            
            for(Biomed_Collection_Op_Center__c collOpp : [SELECT Id, Biomed_Collection_Op_Code_Center_ID__c FROM Biomed_Collection_Op_Center__c where Biomed_Collection_Op_Code_Center_ID__c IN: taxonomyMapZipVsCollectionOppCode.Values()]) {
                collectionOppCodeVsId.put(collOpp.Biomed_Collection_Op_Code_Center_ID__c,collOpp.Id);
            }
        }

        //HRP-12024
        List<sked_Territory__c> futureTerritoryList = new List<sked_Territory__c>();

        if(futureTaxonomies.size() > 0) {
            futureTerritoryList = [SELECT Id, RecordType.Name, End_Date__c, Start_Date__c, External_Id_BackEnd__c 
                                    FROM sked_Territory__c 
                                    WHERE End_Date__c = :endDate4000 
                                    AND  (External_Id_BackEnd__c IN: futureTaxonomyMapZipVsARCRegionCode.Values() 
                                            OR External_Id_BackEnd__c IN: futureTaxonomyMapZipVsDistrictCode.Values()
                                            OR External_Id_BackEnd__c IN: futureTaxonomyMapZipVsDivisionCode.Values()
                                        )
                                    ];

            for(BSF_Portfolio__c portfolio : [SELECT Id, End_Date__c, Start_Date__c, Territory_Portfolio__c, Portfolio_Code__c FROM BSF_Portfolio__c where Portfolio_Code__c IN: futureTaxonomyMapZipVsDRDTerritoryCode.Values() AND Territory_Portfolio__c = true AND End_Date__c =: endDate4000 ]){
                futureBSFPortfolioPortfolioCodeVsId.put(portfolio.Portfolio_Code__c,portfolio.Id);
            }

            for(Biomed_Collection_Op_Center__c collOpp : [SELECT Id, Biomed_Collection_Op_Code_Center_ID__c FROM Biomed_Collection_Op_Center__c where Biomed_Collection_Op_Code_Center_ID__c IN: futureTaxonomyMapZipVsCollectionOppCode.Values()]){
                futureCollectionOppCodeVsId.put(collOpp.Biomed_Collection_Op_Code_Center_ID__c,collOpp.Id);
            }
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
            } 
            
            // Look up the Collections Territory from the map we created earlier
            Collections_Territory__c territory = territoryMap.get(l.PostalCode);
            
            if(territory != null){

              //  System.debug(logTag + 'Lead territory found: ' + territory.Name);
                l.Collections_Territory__c = territory.Id;

            }
            // HRP-10880 start
            
            if(!currentTerritoryList.isEmpty()) {
                for(sked_Territory__c ter : currentTerritoryList) {
                        if(ter.RecordType.Name == BSF_Constants.TERRITORY_TYPE_ARC_REGION && taxonomyMapZipVsARCRegionCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == taxonomyMapZipVsARCRegionCode.get(l.PostalCode)){
                                l.Lead_Region_Name__c = ter.ID;
                        } else if(ter.RecordType.Name == BSF_Constants.TERRITORY_TYPE_DISTRICT && taxonomyMapZipVsDistrictCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == taxonomyMapZipVsDistrictCode.get(l.PostalCode)){
                                l.Lead_District__c = ter.ID;
                        } 
                        // HRP-12190 --> starts Here
                        else if(ter.RecordType.Name == BSF_Constants.TERRITORY_TYPE_DIVISION && taxonomyMapZipVsDivisionCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == taxonomyMapZipVsDivisionCode.get(l.PostalCode)) {
                            l.Lead_Division_Name__c = ter.ID;
                        }
                        // HRP-12190 --> Ends Here
                     }
              }
            if(!futureTerritoryList.isEmpty()) {
                for(sked_Territory__c ter : futureTerritoryList){
                if(ter.RecordType.Name == BSF_Constants.TERRITORY_TYPE_ARC_REGION && futureTaxonomyMapZipVsARCRegionCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == futureTaxonomyMapZipVsARCRegionCode.get(l.PostalCode)) {
                    l.Lead_Region_Name__c = ter.ID;
                }else if(ter.RecordType.Name == BSF_Constants.TERRITORY_TYPE_DISTRICT && futureTaxonomyMapZipVsDistrictCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == futureTaxonomyMapZipVsDistrictCode.get(l.PostalCode)) {
                    l.Lead_District__c = ter.ID;
                }       
                // HRP-12190 --> starts Here
                else if(ter.RecordType.Name == BSF_Constants.TERRITORY_TYPE_DIVISION && futureTaxonomyMapZipVsDistrictCode.get(l.PostalCode) != NULL && ter.External_Id_BackEnd__c == futureTaxonomyMapZipVsDivisionCode.get(l.PostalCode)) {
                    l.Lead_Division_Name__c = ter.ID;
                }
                // HRP-12190 --> Ends Here
              }
            }

              if(!bSFPortfolioPortfolioCodeVsId.isEmpty()) {
                l.Lead_AM_Porfolio__c = taxonomyMapZipVsDRDTerritoryCode.get(l.PostalCode) != null ? bSFPortfolioPortfolioCodeVsId.get(taxonomyMapZipVsDRDTerritoryCode.get(l.PostalCode)):null;
              } else if(!futureBSFPortfolioPortfolioCodeVsId.isEmpty()) {
                l.Lead_AM_Porfolio__c = futureTaxonomyMapZipVsDRDTerritoryCode.get(l.PostalCode) != null ? futureBSFPortfolioPortfolioCodeVsId.get(futureTaxonomyMapZipVsDRDTerritoryCode.get(l.PostalCode)):null ;
              }else {
                 System.debug(logTag + 'There are no BSF portfolio territory record found ' + l.PostalCode);
              }
              
              if(!collectionOppCodeVsId.isEmpty()) {
                l.Lead_Collection_Operation__c = taxonomyMapZipVsCollectionOppCode.get(l.PostalCode) != null ? collectionOppCodeVsId.get(taxonomyMapZipVsCollectionOppCode.get(l.PostalCode)):null;
              }if(!futureCollectionOppCodeVsId.isEmpty()) {
                l.Lead_Collection_Operation__c =  (futureTaxonomyMapZipVsCollectionOppCode.get(l.PostalCode) != null ? futureCollectionOppCodeVsId.get(futureTaxonomyMapZipVsCollectionOppCode.get(l.PostalCode)):null );
              } else {
                System.debug(logTag + 'There are no BSF Collection Opperation record found ' + l.PostalCode);
              }
            // HRP-10880 end
        }    
        
    }
    /**
     * HRP -12024 This method makes two maps
     * first is map of Current -> Current Taxonomies. Current means all zips with current effective taxonomy AND zips that does not have future taxonomies and are currently in Non Service Area 
     * second is map of Future->Future Taxonomies. This means only zip codes that do not have current effective taxonomy but has future effective ones
     */

    public static  Map<String,Map<String,Taxonomy__c>> segragateTaxonomies(List<Taxonomy__c> fullTaxonomyList,Date startDate){
       Date endDate4000 = Date.newInstance(4000, 12, 31);
       String nonServiceArea=Label.NonCollectionArea_Label;
       Map<String,Map<String,Taxonomy__c>> taxonomyMap = new Map<String,Map<String,Taxonomy__c>>();
       Map<String,Taxonomy__c> fullTaxonomyMap = getZipToTaxonomyMap(fullTaxonomyList);

        Map<String,List<Taxonomy__c>> currentCollectionAreaTaxonomies =  new Map<String,List<Taxonomy__c>>();
        Map<String,List<Taxonomy__c>> futureCollectioAreaTaxonomies =  new Map<String,List<Taxonomy__c>>();
        List<Taxonomy__c> futureEffectiveTaxonomies = new List<Taxonomy__c>();
        Map<String,Taxonomy__c> futureTaxonomyMap = new Map<String,Taxonomy__c>();

        if(fullTaxonomyList.size()<1){
            return taxonomyMap;
        }
        Set<String> checkForFutureTaxoZips = new Set<String>();
        for(Taxonomy__c taxonomy:fullTaxonomyList){
            if(taxonomy.Collection_Operation_Name__c == nonServiceArea || taxonomy.District_Name__c == nonServiceArea
               || taxonomy.Division_Name__c == nonServiceArea || taxonomy.Division_Name__c == nonServiceArea){
                checkForFutureTaxoZips.add(taxonomy.Zip_Code__c);
               }
        }
        if(checkForFutureTaxoZips.size() >0) {  //meaning any zip codes do not have currently effective taxonomies
          futureEffectiveTaxonomies = [SELECT Zip_Code__c, Collection_Operation_Code__c, Division_Code__c, DS_Region_Code__c, District_Code__c, DRD_Territory_Code__c,RecordType.Name FROM Taxonomy__c 
            where Collection_Operation_Name__c != :nonServiceArea and District_Name__c != :nonServiceArea 
            and Division_Name__c != :nonServiceArea and DS_Region_Name__c != :nonServiceArea and City__c!=null and State__c != null  
            and End_Date__c =: endDate4000 AND Start_Date__c >=: startDate
            AND (RecordType.Name = 'Bio Recruitment CD' OR RecordType.Name = 'Bio Collection BSF') AND Zip_Code__c IN :checkForFutureTaxoZips];

            futureTaxonomyMap = getZipToTaxonomyMap(futureEffectiveTaxonomies);
        
        }

        for(String futureTaxoZip:futureTaxonomyMap.keySet()){ //for each future entry remove it from all taxonomy list to end up with all current taxo list
            if(fullTaxonomyMap.containsKey(futureTaxoZip)){
               fullTaxonomyMap.remove(futureTaxoZip);
            }
        }

        taxonomyMap.put('Current',fullTaxonomyMap);//Current means all zips with current effective taxonomy AND zips that does not have future taxonomies and are currently in Non Service Area 
        
        if(futureTaxonomyMap.size()>0){
            taxonomyMap.put('Future',futureTaxonomyMap);
        }
        return taxonomyMap;

    }
    
    //HRP-12024-returns a map with key is zip+recordtypeid and value is taxonomy
    public static Map<String,Taxonomy__c> getZipToTaxonomyMap( List<Taxonomy__c> currentlyEffectiveTaxonomies){
        Map<String,Taxonomy__c> zipToTaxonomyMap = new Map<String,Taxonomy__c>();
        if(currentlyEffectiveTaxonomies == null || currentlyEffectiveTaxonomies.size()<1)
            return zipToTaxonomyMap;

        for(Taxonomy__c taxonomy:currentlyEffectiveTaxonomies)  {
            zipToTaxonomyMap.put(taxonomy.Zip_Code__c+taxonomy.recordTypeID,taxonomy);
        } 
        return zipToTaxonomyMap;
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
        System.debug('sendAutoResponseEmail called size='+newLeads.size());
        if(newLeads.size() > 1 ){
            System.debug('Auto-reponse emails are for single lead inserts from the web only.');
            return;
        }

        Lead newLead = newLeads[0];
        System.debug('sendAutoResponseEmail newLead.LeadSource='+newLead.LeadSource);
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
            Messaging.SingleEmailMessage mail;
     
            if(template.Id != null){
                mail = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage tempMessage = Messaging.renderStoredEmailTemplate(template.Id, null, newLead.Id);
                mail.setSubject(tempMessage.getSubject());
                mail.setHtmlBody(tempMessage.getHtmlBody() == null ? tempMessage.getPlainTextBody() : tempMessage.getHtmlBody());
                mail.setToAddresses(new String[] {newLead.Email});
            }       
             
     
            try{
                // if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                System.debug('sendAutoResponseEmail call BSF_EmailNotification=');
                if(!Test.isRunningTest() && mail!=null){
                    BSF_EmailNotification.sendEmails(new Messaging.SingleEmailMessage[] { mail },'WebLeadAutoResponse',null); //Changes for  HRP-11608 

                } 
            } catch (Exception e){
                //System.debug('ERROR SENDING WELCOME EMAIL TO LEAD: ' + e);
            }

        }

    }  
    
    public static void sendQueueAssignmentNotifications(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        System.debug('SendQA=');
        final string logTag = '[LeadService:sendQueueAssignmentNotifications]';
    
        Set<Id> queueIdSet = new Set<Id>();
        List<Lead> leadList = new List<Lead>();
    
        for (Lead newLead : newLeads) {
            Lead oldLead = oldMap.get(newLead.Id);
            if (oldLead == null) return;
    
            String newOwnerId = newLead.OwnerId;
            System.debug('SendQA=' + logTag + 'Lead owner has changed from ' + oldLead.OwnerId + ' to ' + newOwnerId);
            if (newLead.OwnerId != oldLead.OwnerId && newOwnerId.startsWith('00G')) {
                queueIdSet.add(newLead.OwnerId);
                leadList.add(newLead);
            }
        }
    
        Map<Id, Group> queueMap = new Map<Id, Group>([
            SELECT Id, Name, Email, Type, DoesSendEmailToMembers 
            FROM Group 
            WHERE Id IN :queueIdSet
        ]);
    
        System.debug('SendQA= queueMap ::' + queueMap);
    
        EmailTemplate template;
        try {
            template = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = 'Spark_Lead_Assignment_Sample' LIMIT 1];
        } catch (Exception e) {
            return;
        }
    
        // Step 1: Get all members of each queue (users or groups)
        List<GroupMember> queueMembers = [
            SELECT GroupId, UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId IN :queueIdSet
        ];
    
        // Step 2: Identify nested Public Groups to resolve
        Set<Id> publicGroupIds = new Set<Id>();
        for (GroupMember gm : queueMembers) {
            if (String.valueOf(gm.UserOrGroupId).startsWith('00G')) {
                publicGroupIds.add(gm.UserOrGroupId);
            }
        }
    
        // Step 3: Get all user members from those Public Groups
        Map<Id, Set<Id>> publicGroupToUserIds = new Map<Id, Set<Id>>();
        if (!publicGroupIds.isEmpty()) {
            for (GroupMember pgm : [
                SELECT GroupId, UserOrGroupId 
                FROM GroupMember 
                WHERE GroupId IN :publicGroupIds
            ]) {
                if (String.valueOf(pgm.UserOrGroupId).startsWith('005')) {
                    if (!publicGroupToUserIds.containsKey(pgm.GroupId)) {
                        publicGroupToUserIds.put(pgm.GroupId, new Set<Id>());
                    }
                    publicGroupToUserIds.get(pgm.GroupId).add(pgm.UserOrGroupId);
                }
            }
        }
    
        // Step 4: Resolve all Queue → User IDs
        Map<Id, Set<Id>> resolvedQueueUserIds = new Map<Id, Set<Id>>();
        for (GroupMember gm : queueMembers) {
            if (!resolvedQueueUserIds.containsKey(gm.GroupId)) {
                resolvedQueueUserIds.put(gm.GroupId, new Set<Id>());
            }
    
            if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                resolvedQueueUserIds.get(gm.GroupId).add(gm.UserOrGroupId);
            } else if (String.valueOf(gm.UserOrGroupId).startsWith('00G')) {
                Set<Id> pgUsers = publicGroupToUserIds.get(gm.UserOrGroupId);
                if (pgUsers != null) {
                    resolvedQueueUserIds.get(gm.GroupId).addAll(pgUsers);
                }
            }
        }
    
        // Step 5: Build and send emails
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>();
        for (Lead l : leadList) {
            Group leadQueue = queueMap.get(l.OwnerId);
            if (leadQueue == null || !leadQueue.DoesSendEmailToMembers) continue;
    
            Set<Id> userIds = resolvedQueueUserIds.get(leadQueue.Id);
            if (userIds != null) {
                for (Id userId : userIds) {
                    msgList.add(createNotificationMessage(template.Id, l, new Map<String, String>{'destinationId' => userId}));
                }
            }
    
            if (leadQueue.Email != null) {
                msgList.add(createNotificationMessage(template.Id, l, new Map<String, String>{'destinationEmail' => leadQueue.Email}));
            }
        }
    
        System.debug('SendQA= msgList :::' + msgList.isEmpty() + ' Body:' + msgList);
        if (!msgList.isEmpty() && !Test.isRunningTest()) {
            System.debug('There are ' + msgList.size() + ' emails to send out.');
            BSF_EmailNotification.sendEmails(msgList, 'LeadCreation', null);
        }
    }

    private static Messaging.SingleEmailMessage createNotificationMessage(String templateId, Lead lead, Map<String,String> destinationMap){
           
        final string logTag = '[LeadService:createNotificationMessage]';
        String leadName = lead.FirstName + ' ' + lead.LastName;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses;
        if(destinationMap.containsKey('destinationEmail'))
        mail.setToAddresses(new String[] {destinationMap.get('destinationEmail')}); 
        else if(destinationMap.containsKey('destinationId')){
            mail.treatTargetObjectAsRecipient = true;
            mail.setTargetObjectId(destinationMap.get('destinationId')); // Who you are sending the email to
        }
        
        if(templateId != null){
            Messaging.SingleEmailMessage tempMessage = Messaging.renderStoredEmailTemplate(templateId, null, lead.Id);
            mail.setSubject(tempMessage.getSubject());
            mail.setHtmlBody(tempMessage.getHtmlBody() == null ? tempMessage.getPlainTextBody() : tempMessage.getHtmlBody());
        }

        // Assign the addresses for the To and CC lists to the mail object.
        // mail.setToAddresses(toAddresses);
        //mail.setCcAddresses(ccAddresses);

        // Specify the address used when the recipients reply to the email. 
        // mail.setReplyTo('no-reply@redcross.org');

        // Specify the name used as the display name.
        // mail.setSenderDisplayName('Salesforce Lead Notification');

        // Specify the subject line for your email address.
        // mail.setSubject('New Lead  : ' + leadName + ' in ' + lead.City + ', ' + lead.StateCode);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);

        // Optionally append the salesforce.com email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

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
            if( (oldLead == null && !String.isBlank(newLead.PostalCode))  || (newLead.PostalCode != oldLead.PostalCode && !String.isBlank(newLead.PostalCode))  ){ // HRP-12321 - Modification in logic
               
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
    
    //HRP-13603 Start 10/22/2024
    public static void handleLeadStageStatus(List<Lead> newLeads, Map<Id,Lead> oldMap)
    {
        List<String> focusedLeadStatus = new List<String>{'Contacted','Qualified'};
        for(Lead newLead : newLeads)
        {
            if(newLead.Status != oldMap.get(newLead.Id).status && focusedLeadStatus.contains(newLead.Status))
            {
                newLead.Last_Modified_Date_Status__c = System.Today();
            }
        }
    }
    //HRP-13603 End

    /*HRP-13602 - Starts Here
    @Description : The following validation will restrict users to convert potential feeders into Non-Feeder accounts
    */
    public static void restrictPotentionFeedersToGetConvertedToNonFeederAccounts(List<Lead> newLeads, Map<Id,Lead> oldLeadsMap) {
        List<String> feederGroupLeadStatus = System.Label.Potential_Feeder_Group_Lead_Status.split(',');
        String restrictionMsg = Custom_Messages__mdt.getInstance('Non_Feeder_Acc_Convert_Validation').Value__c;
        Set<Id> accountIdsToValidate = new Set<Id>();
        Id marketManagerLeadId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Market Manager').getRecordTypeId();        //Changed for HRP-14331
        if(newLeads != NULL && !newLeads.isEmpty()) {
            for(Lead objLead : newLeads) {
                //Changed for HRP-14331
                if(oldLeadsMap.get( objLead.Id ).RecordTypeId == marketManagerLeadId && feederGroupLeadStatus.contains(oldLeadsMap.get(objLead.Id).Status) && objLead.IsConverted && objLead.IsConverted != oldLeadsMap.get(objLead.Id).IsConverted) {
                    accountIdsToValidate.add(objLead.convertedAccountId);
                }
            }
        }

        if(accountIdsToValidate != NULL && !accountIdsToValidate.isEmpty()) {
            Map<Id, Account> map_accountId_accountInfo = new Map<Id, Account>([SELECT Id, Feeder_Account_Type__c, RecordTypeId, CreatedDate FROM Account WHERE ID IN :accountIdsToValidate]);
            for(Lead objLead : newLeads) {
                if(map_accountId_accountInfo.containsKey(objLead.convertedAccountId)) {
                    Account associatedAccount =  map_accountId_accountInfo.get(objLead.convertedAccountId);
                    if(!checkRecursive.isNewlyCreatedAccount && String.isBlank(associatedAccount.Feeder_Account_Type__c)) {
                        objLead.addError(restrictionMsg);
                    }
                }
            }
        }
    }
    //HRP-13602 - Ends Here
}