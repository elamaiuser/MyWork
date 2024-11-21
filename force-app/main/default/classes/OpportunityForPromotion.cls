public without sharing class OpportunityForPromotion {
	
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityDriveClass> getRegionDistricCollOpp(){
        List<OpportunityDriveClass> OpportunityDriveClass = new List<OpportunityDriveClass>();
        OpportunityDriveClass fd;
        List<opportunity> OppList = [   select id,DS_Region__c,District__c,Collection_Operation__c 
                                        from Opportunity 
                                        where 
                                        DS_Region__c != null OR 
                                        District__c != null OR 
                                        Collection_Operation__c != null
                                        limit 50000 ];
        
        if( !OppList.isEmpty() ){
            for( Opportunity opp : OppList ){
                fd = new OpportunityDriveClass();
                fd.driveid = opp.Id;
                fd.region = opp.DS_Region__c != null ? opp.DS_Region__c : 'null' ;
                fd.district = opp.District__c != null ? opp.District__c : 'null' ;
                fd.collOpp = opp.Collection_Operation__c != null ? opp.Collection_Operation__c : 'null' ;
                OpportunityDriveClass.add( fd );
            }
        }
        return OpportunityDriveClass;
        
    }
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityDriveClass> getOpptiesForPromotion(String recordid, String acctype,String recordtype,String region,String district,String collOpp){
        system.debug('entered555');
        /*
        system.debug('entered');
        List<String> newList=new List<String>();
        list<Object> abc= (list<Object>)JSON.deserializeUntyped(drivetype);
            for(Object a: abc){
               newList.add(String.valueOf(a));
            }
        */
        List<String> newList=new List<String>();
        
        system.debug('recordtype '+recordtype);
        if(recordtype=='Mobile Opp'){
            newList.add('Mobile Opp');
        }else If(recordtype=='Fixed Site Opp'){
            newList.add('Fixed Site Opp');
        }else if(recordtype=='Mobile Opp & Fixed Site Opp'){
           newList.add('Mobile Opp');
           newList.add('Fixed Site Opp'); 
        }else{
           newList=null; 
        }
        
       system.debug('recordid '+recordId+'acctype '+AccType+'drivetype '+ newList +'region '+region+'district '+ district + 'collection opp' +collOpp);
        
        List<Opportunity> allOpportunities = new List<Opportunity>();
        List<Promotion__c> prom= [select id,Start_Date__c,End_Date__c from Promotion__c where id =: recordid];
        Date startDate=prom[0].Start_Date__c;
        Date endDate=prom[0].End_Date__c;
        system.debug('startDate '+startDate);
        system.debug('endDate '+endDate);
        if(acctype==null && newList ==null && region ==null && district== null && collopp!= null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                               
                             AND Collection_Operation__c=:collOpp limit 50000]; 
            system.debug('all opp when region null 1'+ AllOpportunities);
        }else if(acctype==null && newList ==null && region ==null && district!= null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                              AND District__c=:district limit 50000]; 
            system.debug('all opp when district null 2'+ AllOpportunities );
        }else if(acctype==null && newList ==null && region!=null && district==null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                              AND DS_Region__c=:region limit 50000
                            ]; 
            system.debug('all opp when coll opp null 3'+ AllOpportunities);
        }else if(acctype==null && newList ==null && region!=null && district !=null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                             AND DS_Region__c=:region 
                            AND District__c=:district limit 50000]; 
            system.debug('all opp when coll opp null 4'+ AllOpportunities);
        }else if(acctype==null && newList ==null && region==null && district !=null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                              AND District__c=:district AND Collection_Operation__c=:collOpp limit 50000
                            ]; 
            system.debug('all opp when coll opp null 5'+ AllOpportunities);
        }else if(acctype==null && newList ==null && region!=null && district ==null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                              AND DS_Region__c=:region AND Collection_Operation__c=:collOpp limit 50000
                            ]; 
            system.debug('all opp when coll opp null 6'+ AllOpportunities+ 'region'+region);
        }else if(acctype==null && newList ==null && region!=null && district !=null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                              AND DS_Region__c=:region AND Collection_Operation__c=:collOpp AND District__c=:district limit 50000
                            ]; 
            system.debug('all opp when coll opp null 66'+ AllOpportunities);
        }
        
        
        else if(acctype!=null && newList ==null && region ==null && district== null && collopp!= null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype   
                             AND Collection_Operation__c=:collOpp limit 50000]; 
            system.debug('all opp when region null 7'+ AllOpportunities);
        }else if(acctype!=null && newList ==null && region ==null && district!= null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype AND  District__c=:district limit 50000]; 
            system.debug('all opp when district null 8'+ AllOpportunities);
        }else if(acctype!=null && newList ==null && region!=null && district==null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype  AND DS_Region__c=:region limit 50000 
                            ]; 
            system.debug('all opp when coll opp null 9'+ AllOpportunities);
        }else if(acctype!=null && newList ==null && region!=null && district !=null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype  AND DS_Region__c=:region 
                            AND District__c=:district limit 50000]; 
            system.debug('all opp when coll opp null 10'+ AllOpportunities);
        }else if(acctype!=null && newList ==null && region==null && district !=null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype AND Collection_Operation__c=:collOpp AND District__c=:district limit 50000
                            ]; 
            system.debug('all opp when coll opp null 11'+ AllOpportunities);
        }else if(acctype!=null && newList ==null && region!=null && district ==null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype AND DS_Region__c=:region AND Collection_Operation__c=:collOpp limit 50000
                            ]; 
            system.debug('all opp when coll opp null 12'+ AllOpportunities);
        }
        
         if(acctype==null && newList !=null && region ==null && district== null && collopp!= null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                             AND RecordType.Name IN:newList    
                             AND Collection_Operation__c=:collOpp limit 50000 ]; 
            system.debug('all opp when region null 13'+ AllOpportunities);
        }else if(acctype==null && newList !=null && region ==null && district!= null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND RecordType.Name IN:newList AND  District__c=:district limit 50000]; 
            system.debug('all opp when district null 14'+ AllOpportunities);
        }else if(acctype==null && newList !=null && region!=null && district==null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND RecordType.Name IN:newList  AND DS_Region__c=:region limit 50000
                            ]; 
            system.debug('all opp when coll opp null 15'+ AllOpportunities);
        }else if(acctype==null && newList !=null && region!=null && district !=null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND RecordType.Name IN:newList  AND DS_Region__c=:region  
                            AND District__c=:district limit 50000]; 
            system.debug('all opp when coll opp null 16'+ AllOpportunities);
        }else if(acctype==null && newList !=null && region==null && district !=null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND RecordType.Name IN:newList AND  District__c=:district AND Collection_Operation__c=:collOpp limit 50000
                            ]; 
            system.debug('all opp when coll opp null 17'+ AllOpportunities);
        }else if(acctype==null && newList !=null && region!=null && district ==null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND RecordType.Name IN:newList AND DS_Region__c=:region AND Collection_Operation__c=:collOpp limit 50000
                            ]; 
            system.debug('all opp when coll opp null 18'+ AllOpportunities);
        }
        
        
        
          
        
        else if(acctype!=null && newList ==null && region==null && district ==null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                            AND Account_Type__c =:acctype limit 50000]; 
            system.debug('all opp when coll opp null 19'+ AllOpportunities);
        }else if(acctype==null && newList !=null && region==null && district ==null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                             AND RecordType.Name IN:newList limit 50000]; 
            system.debug('all opp when coll opp null 20'+ AllOpportunities);
        }else if(acctype!=null && newList !=null && region==null && district ==null && collopp==null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                             AND RecordType.Name IN:newList AND Account_Type__c =:acctype limit 50000 ]; 
            system.debug('all opp when coll opp null 21'+ AllOpportunities);
        }else if(acctype!=null && newList !=null && region!=null && district !=null && collopp!=null){
           AllOpportunities=[select id, name,StageName,DriveStatus__c,Drive_Date__c from Opportunity where  Drive_Date__c >=: startDate AND Drive_Date__c <=: endDate
                             AND RecordType.Name IN:newList AND Account_Type__c =:acctype AND
                             DS_Region__c=:region AND Collection_Operation__c=:collOpp AND  District__c=:district limit 50000]; 
            system.debug('all opp when coll opp null 22'+ AllOpportunities);
        }
		
        List<OpportunityDriveClass> OpportunityDriveClass = new List<OpportunityDriveClass>();
        system.debug('OpportunityDriveClass '+OpportunityDriveClass);
        OpportunityDriveClass fd;
        
        if( !allOpportunities.isEmpty() ){
                for( Opportunity opp : allOpportunities ){
                    fd = new OpportunityDriveClass();
                    Opportunity_Promotion__c oppPro=new Opportunity_Promotion__c();
                    fd.deliveryId=oppPro.Delivery_ID__c;
                    fd.Quantity= oppPro.Quantity__c; 
                    fd.drivenanme = opp.Name ;
                    fd.driveid = opp.Id ;
                    fd.drivestage = opp.StageName ;
                    fd.drivestatus = opp.DriveStatus__c ;
                    fd.drivedate=opp.Drive_Date__c;
                    OpportunityDriveClass.add( fd );
                }
            }
        system.debug('OpportunityDriveClass##'+OpportunityDriveClass);
        return OpportunityDriveClass;

    }
    
    
    @AuraEnabled
    public static string applyOppPromotion( String Opportunities,String recordid){
        system.debug('Opportunities '+Opportunities+' '+'recordid '+recordid);
        List<String> OppIdList = new List<String>();
        List<OpportunityDriveClass> fslist = (List<OpportunityDriveClass>)JSON.deserialize( Opportunities, List<OpportunityDriveClass>.class );
        system.debug('fslist '+fslist);
        for( OpportunityDriveClass fd: fslist ){
                if( fd.driveid != null  ){//&& fd.isselected == true
                    OppIdList.add( fd.driveid );
                    
                    
                }
            }
        system.debug('recordid check'+recordid);
        Promotion__c Promotion=[select id,Quantity__c,name from Promotion__c where id=:recordid];
        system.debug('Promotion check '+Promotion);
        list<Opportunity_Promotion__c> OppPromotionList =new list<Opportunity_Promotion__c>();
        
        for (OpportunityDriveClass fd: fslist ){
		if( fd.driveid != null  ){//&& fd.isselected == true
                    
            Opportunity_Promotion__c oppPromotion= new Opportunity_Promotion__c();
            oppPromotion.Blood_Drive_Opportunity__c=fd.driveid;
            oppPromotion.Promotion__c=Promotion.Id;
            oppPromotion.Quantity__c=fd.Quantity;
	     	oppPromotion.Delivery_ID__c=fd.deliveryId;
            OppPromotionList.add(oppPromotion);
                   
           }
        }
        if(!OppPromotionList.isEmpty()){
                Database.insert(OppPromotionList);
         }
        system.debug('OppPromotionList '+OppPromotionList);
        return 'success';
    }
    
    public class OpportunityDriveClass{
        @AuraEnabled public String drivenanme;
        @AuraEnabled public String driveid;
        @AuraEnabled public String deliveryId;
        @AuraEnabled public Decimal Quantity;
        @AuraEnabled public String drivestage;
        @AuraEnabled public String drivestatus;
        @AuraEnabled public String region;
        @AuraEnabled public String district;
        @AuraEnabled public String collOpp;
        @AuraEnabled public Date drivedate;
              
    }
}