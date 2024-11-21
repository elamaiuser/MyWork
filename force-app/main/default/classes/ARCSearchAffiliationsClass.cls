public with sharing class ARCSearchAffiliationsClass implements ARCLocalAffiliationSelector  { // extends ARCNationalAffiliationSelector
    static String affiliationrecordtypeid;
    static List<Sobject> mprogramList = new List<Sobject>();
    static List<Marketing_Program__c> nationalmprogramList = new List<Marketing_Program__c>();
    static List<Marketing_Program__c> localmprogramList = new List<Marketing_Program__c>();
    static List<SObject> alllocalmprogramList = new List<Sobject>();
    static List<Collections_Territory__c> collectionTrList = new  List<Collections_Territory__c>();
    Static List<BSF_Portfolio__c> portfolioListForTerritory = new List<BSF_Portfolio__c>();
    Static List<BSF_Portfolio__c> portfolioListForRDSE = new List<BSF_Portfolio__c>();
    Static List<BSF_Portfolio__c> portfolioListForDistrict = new List<BSF_Portfolio__c>(); 
    static String currentuserprofilename;
    static String scope ;
    static Map<String,String> objectRtypeandNamemap = new Map<String,String>(); 

    static {
        List<Profile> curuserprofile = new List<Profile>();
        curuserprofile = [select Name from Profile where ID =: userinfo.getProfileId() ];//profile query security enforced not needed
        currentuserprofilename = curuserprofile[0].Name ;

        List<Affiliation_Object_Map__mdt> afflobjmetadata = new List<Affiliation_Object_Map__mdt>();
        afflobjmetadata = [select Id, Affiliation_Type__c, Object_Supports__c from Affiliation_Object_Map__mdt ];
        if( !afflobjmetadata.isEmpty() ){
            for(Affiliation_Object_Map__mdt aflobj : afflobjmetadata){
                if(!objectRtypeandNamemap.containsKey(aflobj.Affiliation_Type__c) ){
                    objectRtypeandNamemap.put(aflobj.Affiliation_Type__c, aflobj.Object_Supports__c);
                }
            }
        }
    }
    public static String getObjectName(Id objid ){
        return objid.getSObjectType().getDescribe().getName();
    }
    public static String convertObjectName(String objname, Boolean isTemplate ){
        if(objname.toLowerCase() == BSF_Constants.SOBJECT_OPPORTUNITY && isTemplate == false ){                     /* for Opportunity */    
            objname = BSF_Constants.SOBJECT_OPP_INTERNAL ;
            scope = BSF_Constants.SOBJECT_SCOPE_DRIVE ;
        }else if(objname.toLowerCase() == BSF_Constants.SOBJECT_OPPORTUNITY && isTemplate == true){                 /* for template */
            objname = BSF_Constants.SOBJECT_OPP_TEMPLATE_INTERNAL ;
            scope = BSF_Constants.SOBJECT_SCOPE_TEMPLATE ;
        }else{                                                                                                      /* for Account  */
            objname = BSF_Constants.SOBJECT_ACCOUNT_INTERNAL;
            scope = BSF_Constants.SOBJECT_SCOPE_ACCOUNT ;
        }
        return objname;
    }

    @AuraEnabled(cacheable=true)
    public static List<AffilaitionTypeWrapper> getAffiliationTypes(Id objid, Boolean isTemplate ){
        
        String objname = getObjectName(objid);
        objname = convertObjectName(objname,isTemplate);        
        List<AffilaitionTypeWrapper> afltypelist = new List<AffilaitionTypeWrapper>();
        AffilaitionTypeWrapper afltype;
        Schema.DescribeSObjectResult dsr = Marketing_Program__c.SObjectType.getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.getName() != 'Master'){                
                if( objectRtypeandNamemap.containsKey(rti.getDeveloperName()) && objectRtypeandNamemap.get(rti.getDeveloperName()).toLowercase().contains(objname) ){                    
                    afltype = new AffilaitionTypeWrapper();
                    afltype.rtypename = rti.getName() ;
                    afltype.rtypeid = rti.getRecordTypeId() ;
                    afltypelist.add(afltype);  
                }                              
            }            
        }
        return afltypelist;
    }
    
    public class AffilaitionTypeWrapper{
        @AuraEnabled
        public String rtypename;
        @AuraEnabled
        public String rtypeid;
    }
    
    
    @AuraEnabled
    public static List<Sobject> getAllLocalAffiliations( List<Id> parentidlist, String programtype  ){
        List<Id> dsd = new List<Id>(); 
        List<Id> drdt = new List<Id>();  
        List<Id> dist = new List<Id>();  
       /*
        if(collectionTrList.isEmpty() ){
            return null;
        }else{
            dsd = collectionTrList[0].Region__c;
            drdt = collectionTrList[0].DRD_Territory2__c;
            dist = collectionTrList[0].District__c;

        }
         */
        if(!portfolioListForTerritory.isEmpty() ){
            for(BSF_Portfolio__c bcf:portfolioListForTerritory){
                if(bcf.Portfolio_Type__c != null && bcf.Portfolio_Type__c =='Account Manager'){
                    system.debug('4');
                    drdt.add(bcf.Id);
                }
            }
        }
        if(!portfolioListForRDSE.isEmpty() ){
            for(BSF_Portfolio__c bcf:portfolioListForRDSE){
                if(bcf.Portfolio_Type__c != null && bcf.Portfolio_Type__c =='RDSE'){
                    system.debug('4');
                    dsd.add(bcf.Id);
                }
            }
        }
        if(!portfolioListForDistrict.isEmpty() ){
            for(BSF_Portfolio__c bcf:portfolioListForDistrict){
                if(bcf.Portfolio_Type__c != null && bcf.Portfolio_Type__c =='District Manager'){
                    system.debug('4');
                    dist.add(bcf.Id);
                }
            }
        }
        
        system.debug('drdt '+drdt);
        if( !dsd.isEmpty() && programtype == BSF_Constants.MARKETING_PROGRAM_REGION ){
            return getDonorServiceDivision( parentidlist, dsd  );
        }else if( !drdt.isEmpty() && programtype == BSF_Constants.MARKETING_PROGRAM_TERITORRY ){
            return getDRDTeritorry(parentidlist, drdt);
        }else if( !dist.isEmpty() && programtype == BSF_Constants.MARKETING_PROGRAM_DISTRICT ){
            return getDistrict(parentidlist, dist);
        }
        return null;
    }
    @AuraEnabled
    public static List<Sobject> getDonorServiceDivision( List<Id> parentidlist, List<Id> dsd  ){
        List<Marketing_Program_Region__c> mpRegion = new List<Marketing_Program_Region__c>();
        List<Marketing_Program_Region__c> mpRegionfiltered = new List<Marketing_Program_Region__c>();
        mpRegion = [select Id, Name, Marketing_Program_Profiles__c, Marketing_Program__c,
                        Marketing_Program__r.scope__c
                        from Marketing_Program_Region__c    
                        where 
                        BSF_Portfolio_Region__c IN: dsd and
                        Marketing_Program_Is_Active__c = true and
                        Marketing_Program__c in: parentidlist  
                   		ORDER BY Name ASC];

        for( Marketing_Program_Region__c mpr : mpRegion ){
            if( mpr.Marketing_Program__r.scope__c.contains(scope) ){
                if( mpr.Marketing_Program_Profiles__c.contains(currentuserprofilename) ){
                    mpRegionfiltered.add(mpr);
                }
            }           
        }
        return mpRegionfiltered;
    }
    @AuraEnabled
    public static List<Sobject> getDRDTeritorry( List<Id> parentidlist, List<Id> drdt  ){
        List<Marketing_Program_Territory__c> mpRegion = new List<Marketing_Program_Territory__c>();
        List<Marketing_Program_Territory__c> mpRegionfiltered = new List<Marketing_Program_Territory__c>();
        mpRegion = [select Id, Name, Marketing_Program_Profiles__c, Marketing_Program__c,
                        Marketing_Program__r.scope__c
                        from Marketing_Program_Territory__c     
                        where 
                        BSF_Portfolio_Territory__c IN: drdt and
                        Marketing_Program_Is_Active__c = true and
                        Marketing_Program__c in: parentidlist 
                   		ORDER BY Name ASC];

        for( Marketing_Program_Territory__c mpr : mpRegion ){
            if( mpr.Marketing_Program__r.scope__c.contains(scope) ){
                if( mpr.Marketing_Program_Profiles__c.contains(currentuserprofilename) ){
                    mpRegionfiltered.add(mpr);
                }
            }
            
        } 
        return mpRegionfiltered;
    }
    @AuraEnabled
    public static List<Sobject> getDistrict( List<Id> parentidlist, List<Id> dist  ){
        List<Marketing_Program_District__c> mpRegion = new List<Marketing_Program_District__c>();
        List<Marketing_Program_District__c> mpRegionfiltered = new List<Marketing_Program_District__c>();
        mpRegion = [select Id, Name, Marketing_Program_Profiles__c, Marketing_Program__c ,
                        Marketing_Program__r.scope__c 
                        from Marketing_Program_District__c  
                        where 
                        BSF_Portfolio_District__c IN: dist and
                        Marketing_Program_Is_Active__c = true and
                        Marketing_Program__c in: parentidlist 
                   		ORDER BY Name ASC];

        for( Marketing_Program_District__c mpr : mpRegion ){
            if( mpr.Marketing_Program__r.scope__c.contains(scope) ){
                if( mpr.Marketing_Program_Profiles__c.contains(currentuserprofilename) ){
                    mpRegionfiltered.add(mpr);
                }
            }
            
        } 

        return mpRegionfiltered;
    }
    @AuraEnabled
    public static List<Sobject> getFilteredAffiliationList( List<Sobject> mprogramList, String bval ){
        List<Sobject> localmplist = new List<Sobject>();
        if( !mprogramList.isEmpty() ){
            for( Sobject mp : mprogramList ){
                if( mp.get( BSF_Constants.SOBJECT_FIELD_NATIONWIDE_AFFILIATION_PROG ) == bval ){
                    localmplist.add(mp);
                }
            }
        }
        return localmplist;
    }
    

    @AuraEnabled
    public static List<Marketing_Program__c> getNationalAffiliationList(String affiliationrecordtype){
        List<Marketing_Program__c> affiliationList = new List<Marketing_Program__c>();
        List<Marketing_Program__c> affiliationListfilteredByProfile = new List<Marketing_Program__c>();
        try {
            if( affiliationrecordtype != null ){
                affiliationList = [ Select Id, Name,
                                    Allowed_Profiles__c,
                                   Nationwide_Marketing_Program__c,
                                   Scope__c 
                                   from Marketing_Program__c 
                                   where 
                                   RecordTypeId =: affiliationrecordtype
                                   AND
                                   Is_Active__c = true AND 
                                   Nationwide_Marketing_Program__c != null AND 
                                   RecordTypeId != null 
                                   AND 
                                   Scope__c != null ORDER BY Name ASC
                                   ]; 
            }else{
                affiliationList = [ Select Id, Name,
                                   Allowed_Profiles__c,
                                   Nationwide_Marketing_Program__c,
                                   Scope__c
                                   from Marketing_Program__c
                                   where
                                   Is_Active__c = true AND 
                                   Nationwide_Marketing_Program__c != null AND 
                                   RecordTypeId != null 
                                   AND 
                                   Scope__c != null ORDER BY Name ASC
                                   ]; 
            }

            for( Marketing_Program__c mpr : affiliationList ){
                if( mpr.Scope__c.contains(scope) ){
                    if( mpr.Allowed_Profiles__c != null && mpr.Allowed_Profiles__c.contains(currentuserprofilename) ){
                        affiliationListfilteredByProfile.add(mpr);
                    }
                }
                
            }

            
            return affiliationListfilteredByProfile;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }       
        
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Affiliationwrapper> getAffiliations(String affiliationrecordtype, String accountpostalcode, Id objid, Boolean isTemplate){
        String objname = getObjectName(objid);
        convertObjectName(objname,isTemplate);  

        affiliationrecordtypeid = affiliationrecordtype;
        List<Affiliationwrapper> affls = new List<Affiliationwrapper>();
        List<Sobject> localsobjectlist = new List<Sobject>();
        Affiliationwrapper affl  = new Affiliationwrapper();
        List<Marketing_Program__c> affiliationList = new List<Marketing_Program__c>();
        try { 
            /*
            collectionTrList = [select Region__c, DRD_Territory2__c, District__c 
                                                                from Collections_Territory__c
                                                                where 
                                                                Zip__c =: accountpostalcode];
			
            */
            
            
            
           // BsfPortfolioList = [select id, Portfolio_Type__c from BSF_Portfolio__c where Zip__c =:accountpostalcode limit 1];
            List<Taxonomy__c> taxonomyList = [SELECT Id,Zip_Code__c,Zip_Code_Key__c,Zip_Code_Name__c,Division_Code__c,DS_Region_Code__c,Team_Code__c,ABM_Code__c,ABM_Name__c,DRD_Territory_Code__c,DRD_Territory_Name__c,Start_Date__c,End_Date__c,RecordType.Name FROM Taxonomy__c WHERE Zip_Code__c  =:accountpostalcode AND End_Date__c > TODAY AND Start_Date__c<TODAY AND RecordType.Name =:BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE ORDER BY Start_Date__c];//start date<today
            List<String> Territory = new List<String>();
            List<String> District = new List<String>();
            List<String> RDSE = new List<String>();
            for(Taxonomy__c ta:taxonomyList){
                if(ta.Team_Code__c !=null){
                   District.add(ta.Team_Code__c); 
                }
                if(ta.DRD_Territory_Code__c !=null){
                    Territory.add(ta.DRD_Territory_Code__c);
                }
                if(ta.DS_Region_Code__c !=null){
                   RDSE.add(ta.DS_Region_Code__c);  
                }
            } 
             portfolioListForTerritory = [SELECT Id,Name,Portfolio_Type__c,External_Key__c,Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Portfolio_Code__c in:Territory ];
             portfolioListForRDSE = [SELECT Id,Name,Portfolio_Type__c,External_Key__c,Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Portfolio_Code__c in:RDSE ];
             portfolioListForDistrict = [SELECT Id,Name,Portfolio_Type__c,External_Key__c,Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Portfolio_Code__c in:District ];



            
            /*
            System.debug('taxonomyList: '+taxonomyList);
            
            Set<String> externalKeySet = new Set<String>();
            Map<String,Taxonomy__c> keyTaxoMap = new Map<String,Taxonomy__c>();
            Map<String,List<String>> zipExternalKeyMap = new Map<String,List<String>>();
            
            for(Taxonomy__c taxonomy:taxonomyList){
                String externalKey = null;
                externalKey = taxonomy.RecordType.Name;
                if(String.isNotBlank(taxonomy.Division_Code__c)){
                    externalKey = externalKey+'_'+taxonomy.Division_Code__c;
                    if(String.isNotBlank(taxonomy.DS_Region_Code__c)){
                        externalKey = externalKey+'_'+taxonomy.DS_Region_Code__c;
                        if(String.isNotBlank(taxonomy.Team_Code__c)){
                            externalKey = externalKey+'_'+taxonomy.Team_Code__c;
                            if(taxonomy.ABM_Name__c != null && taxonomy.ABM_Name__c != 'NA' && !taxonomy.ABM_Name__c.containsIgnoreCase('No ABM')){
                                externalKey = externalKey+'_'+taxonomy.ABM_Code__c;
                            }
                            if(String.isNotBlank(taxonomy.DRD_Territory_Code__c)){
                                externalKey = externalKey+'_'+taxonomy.DRD_Territory_Code__c;
                            }
                        }
                    }
                }
                externalKeySet.add(externalKey);
                if(keyTaxoMap.get(externalKey) != null){
                    keyTaxoMap.get(externalKey).End_Date__c = taxonomy.End_Date__c;
                }else{
                    keyTaxoMap.put(externalKey,taxonomy);
                }
                if(zipExternalKeyMap.get(taxonomy.Zip_Code__c) == null){
                    zipExternalKeyMap.put(taxonomy.Zip_Code__c,new List<String>());
                }
                zipExternalKeyMap.get(taxonomy.Zip_Code__c).add(externalKey);
            }

            portfolioList = [SELECT Id,Name,Portfolio_Type__c,External_Key__c,Portfolio_Code__c,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Parent_Portfolio__c FROM BSF_Portfolio__c WHERE External_Key__c IN:externalKeySet];
            system.debug('portfolioList 1 '+portfolioList);
            
			*/            
            
            
            mprogramList = getAffiliation();            
          
            // get Affiliation: where Nationwide_Marketing_Program__c == Yes
            localsobjectlist = getFilteredAffilaition(true); 
            if( localsobjectlist != null ){
                alllocalmprogramList.addAll(localsobjectlist);                
            }
            // get Affiliation: where Nationwide_Marketing_Program__c == No 
            List<Id> idlist = new List<Id>();
            List<Sobject> childobjectList = new List<Sobject>();
            Map<Id, Sobject> nonAfllist = new Map<Id, Sobject>();
            localsobjectlist = getFilteredAffilaition(false);
            
            // store List of Affiliation[where Nationwide_Marketing_Program__c == No] Ids into List
            if( localsobjectlist != null ){
                //alllocalmprogramList.addAll(localsobjectlist);
                for( Sobject afl : localsobjectlist ){
                    idlist.add(String.valueOf(afl.get(BSF_Constants.SOBJECT_FIELD_ID)) );
                    nonAfllist.put( (String)afl.get(BSF_Constants.SOBJECT_FIELD_ID), afl );
                }
            }


            Map<Id, List<Sobject>> idSobjectListmap = new Map<Id, List<Sobject>>();

            // get Marketing Program Region
            localsobjectlist = getLocalAffiliations(idlist, BSF_Constants.MARKETING_PROGRAM_REGION);                
            if( localsobjectlist !=null ){
                childobjectList.addAll(localsobjectlist);
            }
            //System.debug( 'Marketing Program Region ===>'+ childobjectList );
            // get Marketing Program Teritorry
            localsobjectlist = getLocalAffiliations(idlist, BSF_Constants.MARKETING_PROGRAM_TERITORRY);
            if( localsobjectlist !=null ){
                childobjectList.addAll(localsobjectlist);
            }
            //System.debug( 'Marketing Program Teritorry ===>'+ childobjectList );
            // get Marketing Program District
            localsobjectlist = getLocalAffiliations(idlist, BSF_Constants.MARKETING_PROGRAM_DISTRICT);
            if( localsobjectlist !=null ){
                childobjectList.addAll(localsobjectlist);
            }
            //System.debug( 'Marketing Program District ===>'+ childobjectList );

            // Map ===> { Affiliation_ID, List<child_Affiliation>}
            for(Sobject obj : childobjectList){
                if( !idSobjectListmap.containsKey( (String)obj.get(BSF_Constants.SOBJECT_FIELD_PARENTID)) ){
                    idSobjectListmap.put( (String)obj.get(BSF_Constants.SOBJECT_FIELD_PARENTID), new List<Sobject>() );
                }
                idSobjectListmap.get( (String)obj.get(BSF_Constants.SOBJECT_FIELD_PARENTID) ).add( obj );
            } 
            //System.debug( 'idSobjectListmap===>' + idSobjectListmap );
            // check if any child exists for Affiliation
            for( Id aflid : idlist ){ //local
                if( idSobjectListmap.containsKey(aflid) && !idSobjectListmap.get(aflid).isEmpty() && idSobjectListmap.get(aflid).size() > 0 ){
                    // do logic here
                    alllocalmprogramList.add( nonAfllist.get(aflid) );
                }
            }
            //System.debug( 'alllocalmprogramList===>' + alllocalmprogramList );
            if( !alllocalmprogramList.isEmpty() ){
                Map<String,String> alllocalmprogramMap = new Map<String,String>();
                List<String> alllocalmprogramNameList = new List<String>();
                for( Sobject afl : alllocalmprogramList ){
                    alllocalmprogramMap.put(String.valueOf(afl.get( BSF_Constants.SOBJECT_FIELD_NAME)),String.valueOf(afl.get( BSF_Constants.SOBJECT_FIELD_ID )));            
                }
                alllocalmprogramNameList.addAll(alllocalmprogramMap.keySet());
                alllocalmprogramNameList.sort();
                for( String afl : alllocalmprogramNameList ){
                    affl  = new Affiliationwrapper();
                    affl.recordid = alllocalmprogramMap.get(afl); //=id=18 
                    affl.recordname = afl;//=name
                    affls.add(affl);                    
                }
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return affls;
    }
    
    public static List<Sobject> getAffiliation(){
        return getNationalAffiliationList( affiliationrecordtypeid );
    }
    
    public static List<Sobject> getFilteredAffilaition(Boolean bval){
        String isnationaProgram = bval == true ? BSF_Constants.STRING_YES : BSF_Constants.STRING_NO;
        return getFilteredAffiliationList( mprogramList , isnationaProgram); 
    }
    
    public static List<Sobject> getLocalAffiliations(List<Id> parentid, String programtype){
        return getAllLocalAffiliations( parentid, programtype );
    } 

    public class Affiliationwrapper{
        @AuraEnabled
        public String recordname;
        @AuraEnabled
        public String recordid;
    }
}