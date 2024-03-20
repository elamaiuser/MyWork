public with sharing class OpportunityLinkedDriveController {
    
    /*@AuraEnabled
    public static List<opportunity> fetchAllSingleDayDrives(Id oppId){ 
        
        opportunity slectedOpp = [SELECT Id, Name, Start_Time__c,Linked_Opportunity_Drives__c, Type_of_Drive__c,Drive_Name__c,Drive_Date__c , Drive_Site__c, End_Time__c  FROM Opportunity where id =:oppId ];
        
        List<opportunity> singleDayDriveList = [SELECT Id,Linked_Opportunity_Drives__c, Name, Start_Time__c, Type_of_Drive__c,Drive_Date__c ,Drive_Name__c, Drive_Site__c, End_Time__c  
                                                FROM Opportunity 
                                                where Drive_Date__c =:slectedOpp.Drive_Date__c AND Type_of_Drive__c='Mobile'];
        if(singleDayDriveList.size() > 0) return singleDayDriveList;
        return null;
    }
    
    
    @AuraEnabled
    public static List<opportunity> fetchSingleDayLinkedDrives(Id linkedRecordId){
        List<opportunity> oppList = [SELECT Id,Name,Linked_Opportunity_Drives__c  FROM Opportunity where Linked_Opportunity_Drives__c =:linkedRecordId ];
        
        if(oppList.size() > 0) return oppList;
        return null;
    }
    
    
    
    
    @AuraEnabled
    public static string createSingleDayLinkedDrives(Id oppId1,Id oppId2){
        
        List<opportunity> finalRecordtoUpdate = new List<opportunity>();
        List<opportunity> oppRecords = [SELECT Id,Linked_Opportunity_Drives__c,Start_Time__c,End_Time__c  FROM Opportunity where id =:oppId1 ];
        Opportunity oppRecords2 = [SELECT Id,Linked_Opportunity_Drives__c,Start_Time__c,End_Time__c  FROM Opportunity where id =:oppId2 ];
        
        if (!(oppRecords[0].Start_Time__c >= oppRecords2.End_Time__c || oppRecords2.Start_Time__c >= oppRecords[0].End_Time__c)){
            return 'Error: Same Day Linked Drives Opportunities cannot overlap in time';
        }
        
        Linked_Opportunity_Drives__c linkedRecord = new Linked_Opportunity_Drives__c();
        if(oppRecords[0].Linked_Opportunity_Drives__c == null){            
            linkedRecord.Linked_Drive_Type__c = 'Single Drive';
			
				insert linkedRecord; //dml for security
             
        }else{
            List<opportunity> exisitngLinkedOppRecords = [SELECT Id,Linked_Opportunity_Drives__c  FROM Opportunity where Linked_Opportunity_Drives__c =:oppRecords[0].Linked_Opportunity_Drives__c ];
            for(opportunity opp : exisitngLinkedOppRecords){
                opp.Linked_Opportunity_Drives__c = null;
                finalRecordtoUpdate.add(opp);
            }
            linkedRecord.id=oppRecords[0].Linked_Opportunity_Drives__c;
            if (finalRecordtoUpdate.size()>0){ 
				update finalRecordtoUpdate;//dml for security
            }	
        }
        
        
        List<opportunity> oppList = new List<opportunity>();
        
        opportunity opp1 = new opportunity(id= oppId1);
        opp1.Linked_Opportunity_Drives__c = linkedRecord.Id;
        
        opportunity opp2 = new opportunity(id= oppId2);
        opp2.Linked_Opportunity_Drives__c = linkedRecord.Id;
        
        oppList.add(opp1);
        oppList.add(opp2);
        
        try{
			update oppList;//dml for security
            
        }catch (exception e){
            return 'Error: '+e.getMessage();
        }
        
        return 'Sucess - Linked Drive created Sucessfully';
     }
    
    @AuraEnabled
    public static string deLinkSingleDayDrives(Id linkedId){
        
        List<opportunity> oppList = [SELECT Id,Linked_Opportunity_Drives__c  FROM Opportunity where Linked_Opportunity_Drives__c =:linkedId ];
        
        for(opportunity opp : oppList){
            opp.Linked_Opportunity_Drives__c = null;
        }
        
        try{
			
			update oppList;//dml for security
            
        }catch (exception e){
            return 'Error: '+e.getMessage();
        }
        
        return 'Sucess - Linked Drive created Sucessfully';
    }
    */
    
    /****************************************************************** MULTI DAY DRIVE ********************************************************/
    
   /* @AuraEnabled
    public static List<opportunity> fetchAllMultiDayDrives(Id oppId){
        
        opportunity slectedOpp = [SELECT Id, Name, Start_Time__c,Linked_Opportunity_Drives__c, Type_of_Drive__c,Drive_Name__c,Drive_Date__c , Drive_Site__c, End_Time__c  
                                  FROM Opportunity where id =:oppId ];
        Date maxDriveDateAllowed = slectedOpp.Drive_Date__c + 7;
        Boolean isDriveAlreadyLinked = false;
        if(slectedOpp.Linked_Opportunity_Drives__c != null) isDriveAlreadyLinked = true;
        system.debug('maxDriveDateAllowed------>'+maxDriveDateAllowed);
        List<opportunity> multiDayDriveList = new List<opportunity>();
        if(isDriveAlreadyLinked){
             multiDayDriveList = [SELECT Id,Linked_Opportunity_Drives__c, Name, Start_Time__c, Type_of_Drive__c,Drive_Date__c ,Drive_Name__c, Drive_Site__c, End_Time__c  
                                                   FROM Opportunity 
                                                   Where Drive_Date__c >= :slectedOpp.Drive_Date__c AND Drive_Date__c < :maxDriveDateAllowed  
                                                   AND Type_of_Drive__c='Mobile' 
                                  				AND (Linked_Opportunity_Drives__c = :slectedOpp.Linked_Opportunity_Drives__c OR Linked_Opportunity_Drives__c = null ) ];            
        }else{
            multiDayDriveList = [SELECT Id,Linked_Opportunity_Drives__c, Name, Start_Time__c, Type_of_Drive__c,Drive_Date__c ,Drive_Name__c, Drive_Site__c, End_Time__c  
                                                   FROM Opportunity 
                                                   Where Drive_Date__c >= :slectedOpp.Drive_Date__c AND Drive_Date__c < :maxDriveDateAllowed  
                                                   AND Type_of_Drive__c='Mobile'
                               					   AND Linked_Opportunity_Drives__c = null ];
        }

        system.debug('multiDayDriveList------>'+multiDayDriveList);
        if(multiDayDriveList.size() > 0) return multiDayDriveList;
        return null;
    }
    
    
    @AuraEnabled
    public static List<opportunity> fetchMultiDayLinkedDrives(Id linkedRecordId){
        List<opportunity> oppList = [SELECT Id,Name,Linked_Opportunity_Drives__c  FROM Opportunity where Linked_Opportunity_Drives__c =:linkedRecordId ];
        
        if(oppList.size() > 0) return oppList;
        return null;
    }
    
    @AuraEnabled
    public static string createMultiDayLinkedDrives(Id oppId1,Id oppId2){
        
        List<opportunity> finalRecordtoUpdate = new List<opportunity>();
        List<opportunity> oppList = new List<opportunity>();
        boolean validConsecutiveDrive = false;
        
        List<opportunity> oppRecords = [SELECT Id,Linked_Opportunity_Drives__c,Drive_Date__c,Start_Time__c,End_Time__c  FROM Opportunity where id =:oppId1 ];
        Opportunity oppRecords2 = [SELECT Id,Linked_Opportunity_Drives__c,Drive_Date__c,Start_Time__c,End_Time__c  FROM Opportunity where id =:oppId2 ];
        

        
        Linked_Opportunity_Drives__c linkedRecord = new Linked_Opportunity_Drives__c();
        if(oppRecords[0].Linked_Opportunity_Drives__c == null){ 
            if(oppRecords2.Drive_Date__c == (oppRecords[0].Drive_Date__c +1) || oppRecords2.Drive_Date__c == (oppRecords[0].Drive_Date__c -1)){
                validConsecutiveDrive = true;
            }
            linkedRecord.Linked_Drive_Type__c = 'Multi Drive';
			insert linkedRecord; //dml for security
            
        }else{
            List<opportunity> exisitngLinkedOppRecords = [SELECT Id,Linked_Opportunity_Drives__c,Drive_Date__c  
                                                          FROM Opportunity 
                                                          where Linked_Opportunity_Drives__c =:oppRecords[0].Linked_Opportunity_Drives__c order by Drive_Date__c desc];
            for(opportunity opp :exisitngLinkedOppRecords){
                if(oppRecords2.Drive_Date__c == (opp.Drive_Date__c +1) || oppRecords2.Drive_Date__c == (opp.Drive_Date__c -1)){
                    validConsecutiveDrive = true;
                }
            }
            if(exisitngLinkedOppRecords.size() > 7){
                return 'Error: Maximum of 7 drives can be linked in a multi day drive';
            }
            for(opportunity opp : exisitngLinkedOppRecords){
                if(opp.Drive_Date__c == oppRecords2.Drive_Date__c){
                    return 'Error: Date overlap between the drives';
                }
            }
            linkedRecord.id=oppRecords[0].Linked_Opportunity_Drives__c;
            
        }
        

        if(!validConsecutiveDrive){
            return 'Error: Drive Dates must be consecutive days';
        }

        
        opportunity opp1 = new opportunity(id= oppId1);
        opp1.Linked_Opportunity_Drives__c = linkedRecord.Id;
        
        opportunity opp2 = new opportunity(id= oppId2);
        opp2.Linked_Opportunity_Drives__c = linkedRecord.Id;
        
        oppList.add(opp1);
        oppList.add(opp2);
        
        try{
				update oppList;//dml for security
            
        }catch (exception e){
            return 'Error: '+e.getMessage();
        }
        
        return 'Success - Drive linked Sucessfully';
    }
    
    
        @AuraEnabled
    public static string deLinkMultiDayDrives(Id oppId1,Id oppId2){
        
        List<opportunity> oppList = [SELECT Id,Linked_Opportunity_Drives__c  FROM Opportunity where Id =:oppId2 ];
        
        for(opportunity opp : oppList){
            opp.Linked_Opportunity_Drives__c = null;
        }
        
        try{
				update oppList;
            
        }catch (exception e){
            return 'Error: '+e.getMessage();
        }
        
        return 'Success - Drive de-linked Sucessfully';
        
    }*/
}