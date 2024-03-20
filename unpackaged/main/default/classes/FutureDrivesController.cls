public with sharing class FutureDrivesController {
    @AuraEnabled
    public static List<FieldSetClass> getFieldsFromFieldSets(){
        List<FieldSetClass> fdlist = new List<FieldSetClass>();
        try {
            FieldSetClass fdset;
            for( Schema.FieldSetMember f : Schema.SObjectType.Opportunity.fieldSets.FieldsApplytoDrives.getFields() ){ 
                fdset = new FieldSetClass();
                fdset.fieldapiname = f.getFieldPath() ; 
                fdset.fieldlabel = f.getLabel() ;
                fdlist.add( fdset );
                //System.debug( ' label is ' + f.getFieldPath() + ' api name is ' + f.getLabel() ) ;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return fdlist ;
    }
    @AuraEnabled
    public static List<FutureDriveClass> getFutureDrives( String recordid ){
        List<FutureDriveClass> FutureDriveClassList = new List<FutureDriveClass>();
        FutureDriveClass fd;
        try {
            Date currentDate = System.Today();
            List<Opportunity> opprecord = new List<Opportunity>();
            String parentTemplateId;
            Date driveDate ;
            opprecord = [select Id, Parent_Template_Id__c, Drive_Date__c from Opportunity where Id =: recordid  ];
            parentTemplateId = opprecord[0].Parent_Template_Id__c;
            driveDate = opprecord[0].Drive_Date__c;
            List<Opportunity> opplist = new List<Opportunity>();
            opplist = [ select Id, Name, StageName, DriveStatus__c, Drive_Date__c, Drive_Site__r.Name
                       from Opportunity
                       where Parent_Template_Id__c =:recordid and
                       is_template__c = false and
                       Drive_Date__c > : currentDate  ];
            if( !opplist.isEmpty() ){
                for( Opportunity opp : opplist ){
                    fd = new FutureDriveClass();
                    fd.drivenanme = opp.Name ;
                    fd.driveid = opp.Id ;
                    fd.drivestage = opp.StageName ;
                    fd.drivestatus = opp.DriveStatus__c ;
                    fd.drivedate = String.valueOf(opp.Drive_Date__c);
                    fd.drivesite = opp.Drive_Site__r.Name ;
                    fd.isselected = false ;
                    FutureDriveClassList.add( fd );
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return FutureDriveClassList;
    }
    @AuraEnabled
    public static string applyChangestoFutureDrives( String FutureDriveClass, String recordid, List<String> fields ){
        try {
            String driverecordid = recordid;
            String fieldstoberetrieved = '';
            boolean isDriveAffiliationFound = false;
            boolean isDriveServiceRolesFound = false;
            boolean isEndTimeFound = false;
            boolean isWebscheduleStartDateFound = false;
            boolean isWebscheduleEndDateFound = false;
            boolean isWebscheduleEndTimeFound = false;
            List<String> fields2 = new List<String>();
            List<String> driveidset = new List<String>();
            List<Opportunity> updateopplist = new List<Opportunity>();
            List<Opportunity> sourceopplist = new List<Opportunity>();
            Map<Id, Opportunity> sourceopp = new Map<Id, Opportunity>();
            Map<Id, Opportunity> targetopp = new Map<Id, Opportunity>();
            GlobalWebSchedulingSettings__mdt globalWebScMetaData=opportunityService.fetchGlobalWebScheduleMetaDate();
            List<FutureDriveClass> fslist = (List<FutureDriveClass>)JSON.deserialize( FutureDriveClass, List<FutureDriveClass>.class );
            for( FutureDriveClass fd: fslist ){
                if( fd.driveid != null && fd.isselected == true ){
                    driveidset.add( fd.driveid );
                }
            }
            System.debug('fields12:'+fields);
            for( String str : fields ){
                if(str.equalsIgnoreCase('Drive Affiliations')){
                    isDriveAffiliationFound = true;
                }
                if(str.equalsIgnoreCase('Drive Service Roles')){
                    isDriveServiceRolesFound = true;
                }
                if(str.equalsIgnoreCase('End_Time__c')){
                    isEndTimeFound = true;
                }
                if(str.equalsIgnoreCase('Web_Schedule_EndDate__c')){
                    isWebscheduleEndDateFound = true;
                }
                if(str.equalsIgnoreCase('Web_Schedule_StartDate__c')){
                    isWebscheduleStartDateFound = true;
                }
                if(str.equalsIgnoreCase('Web_Schedule_End_Time__c')){
                    isWebscheduleEndTimeFound = true;
                }
                if((!str.contains('Drive Affiliations'))&&(!str.contains('Drive Service Roles'))){
                    //System.debug('STR::'+str);
                    fields2.add(str);
                }
            }
            System.debug('fields2:'+fields2);
            //set of mandatory fields in case of webschedule date updates in functionality
            set<string>fieldsNeeded=new set<string>{'End_Time__c','Web_Scheduling_Start_Time__c','TimeZone__c','Web_Schedule_Start_Date__c','Web_Schedule_End_Date__c','Web_Schedule_End_Time__c'};
                fieldsNeeded.addAll(fields2);
            system.debug('fieldsNeeded '+fieldsNeeded);
            for( String str : fieldsNeeded ){
                if(fieldstoberetrieved==''){
                    fieldstoberetrieved = str;
                }
                else{
                    fieldstoberetrieved = fieldstoberetrieved + ',' + str;
                }
            }
            fieldstoberetrieved = fieldstoberetrieved.replaceAll('null,', '');
            String[] fieldsarray;
            fieldsarray = fieldstoberetrieved.split( ',');
            system.debug('fieldsarray '+fieldsarray);
            fieldsarray.sort();// sorted so that webschedule fields comes last
            //System.debug('fieldstoberetrieved before query: '+fieldstoberetrieved);
            //System.debug('fieldstoberetrieved before query: '+fieldsNeeded);
            String sourcequery = '';
            if(fieldstoberetrieved.length()>0){
                //quering offset fields for calculation of webschedule dates
                     sourcequery = ' select Id,Web_Scheduling_Start_Date_Offset__c,Web_Scheduling_End_Date_Offset__c,Web_Scheduling_End_Time_Offset__c, ' + fieldstoberetrieved + ' from Opportunity where Id =:driverecordid' ;
                sourceopplist = Database.query( sourcequery );
            }
            else if(fieldstoberetrieved.length()==0 && (isDriveAffiliationFound == true || isDriveServiceRolesFound == true)){
                sourcequery = ' select Id from Opportunity where Id =:driverecordid' ;
                sourceopplist = Database.query( sourcequery );
            }
            for( Opportunity opp : sourceopplist ){
                sourceopp.put( opp.Id, opp );
            }
            String targetquery = '';
            if(fieldstoberetrieved.length()>0){
                targetquery = ' select Id,Drive_date__c,' + fieldstoberetrieved + ' from Opportunity where Id IN:driveidset' ;
                updateopplist = Database.query( targetquery );
            }
            else if(fieldstoberetrieved.length()==0 && (isDriveAffiliationFound == true || isDriveServiceRolesFound == true)){
                targetquery = ' select Id,Drive_date__c from Opportunity where Id IN:driveidset' ;
                updateopplist = Database.query( targetquery );
            }
            //HRP-5343: Apply Drive Affiliations or Drive Service Roles to selected future drives
            if(isDriveAffiliationFound == true || isDriveServiceRolesFound == true){
                rollAffiliationsOrServiceRoles(isDriveAffiliationFound,isDriveServiceRolesFound,recordid,updateopplist,driveidset);
            }
            //using this map to get the unmodified values of the opportunity to be updated
            map<id,Opportunity> updateOpplistMap = new map<id,Opportunity>();
            for(opportunity opp: updateopplist)
            {
                updateOpplistMap.put(opp.id,opp);
            }
            //System.debug('fieldsarray:'+fieldsarray);
            if(fieldsarray.size()>0){
                for( String s1 : fieldsarray ){
                    for( Opportunity opp : updateopplist )
                    {
                        opportunity oppty = new opportunity();
                        if(updateOpplistMap.get(opp.id)!=null)
                        {
                            oppty = updateOpplistMap.get(opp.id);
                            if(s1!=null && s1!='' && sourceopp!=null)
                            {
                                if((s1=='Web_Schedule_End_Date__c' && isWebscheduleEndDateFound==false)||
                                   (s1=='End_Time__c' && isEndTimeFound==false)||
                                   (s1=='Web_Schedule_StartDate__c' && isWebscheduleStartDateFound==false) ||
                                   (s1=='Web_Schedule_End_Time__c' && isWebscheduleEndTimeFound==false)){
                                    continue;
                                }
                                //these fields need not be stamped on opportunity instead used as a label to filter the calculation of the webschedule dates using offset values
                                if(s1!='Web_Schedule_EndDate__c' && s1!='Web_Schedule_StartDate__c'
                                   && s1!='Web_Schedule_End_Time__c' && s1 !='TimeZone__c' && s1 !='Web_Scheduling_Start_Time__c'
                                   && s1!='Web_Schedule_End_Date__c' && s1!='Web_Schedule_Start_Date__c' )
                                {
                                    opp.put(s1, sourceopp.get(driverecordid).get(s1));
                                }
                                //webschedule dates & time fields calculation
                                else if(s1=='Web_Schedule_StartDate__c'|| s1=='Web_Schedule_EndDate__c'|| s1=='Web_Schedule_End_Time__c')
                                {
                                    String S2='Web_Scheduling_Start_Date_Offset__c';
                                    String S3='Web_Scheduling_End_Date_Offset__c';
                                    String S4='Web_Scheduling_End_Time_Offset__c';
                                    Date driveDate=oppty.Drive_Date__c;
                                    String webStartTime = globalWebScMetaData.Web_Scheduling_Start_Time__c;
                                    DateTime wsStartDateTime;
                                    DateTime wsEndDateTime;
                                    if(s1=='Web_Schedule_StartDate__c')
                                    {
                                    //WebSchedule StartDate Calc 
                                    Time startTimeInstance= Time.newInstance(Integer.valueOf(webStartTime.left(2)),Integer.valueOf(webStartTime.right(2)),0,0);  
                                    
                                    Date driveDateAddStartDateOffSet=sourceopp.get(driverecordid).get(s2) != null?driveDate.addDays(Integer.valueOf(sourceopp.get(driverecordid).get(s2))):null;
                                    if(driveDateAddStartDateOffSet != null){    
                                        DateTime driveDateAddStartDateOffSetTime=driveDateAddStartDateOffSet;  
                                        DateTime webSchStartDate=driveDateAddStartDateOffSetTime.addHours(Integer.valueOf(webStartTime.left(2))).addMinutes(Integer.valueOf(webStartTime.right(2)));
                                        System.debug('webSchStartDate==='+webSchStartDate);
                                        
                                        
                                        if(opp.TimeZone__c!=null){
                                            wsStartDateTime= DateTimeConverter.convertDateTimeIntoGMT(oppty.TimeZone__c,driveDateAddStartDateOffSet,startTimeInstance);
                                            //system.debug('StartDateTime'+wsStartDateTime);
                                        } else {
                                            wsStartDateTime=webSchStartDate;
                                            //system.debug('StartDateTime'+wsStartDateTime);
                                        }
                                    }
                                    opp.put('Web_Schedule_Start_Time__c',startTimeInstance);
                                    opp.put('Web_Schedule_StartDate__c',driveDateAddStartDateOffSet);
                                    opp.put('Web_Schedule_Start_Date__c',wsStartDateTime);
                                    }
                                    if(s1=='Web_Schedule_EndDate__c' || s1=='Web_Schedule_End_Time__c')
                                    {
                                    //WebSchedule EndDate Calc
                                    Time endTime = oppty.End_Time__c;     
                                    Time calculatedEndTime= sourceopp.get(driverecordid).get(s4) != null?endTime.addHours(Integer.valueOf(sourceopp.get(driverecordid).get(s4))):null;
                                        
                                    Date driveDateAddEndDateOffSet=sourceopp.get(driverecordid).get(s3) != null?driveDate.addDays(Integer.valueOf(sourceopp.get(driverecordid).get(s3))):null;
                                    if(driveDateAddEndDateOffSet != null && calculatedEndTime != null){    
                                        DateTime driveDateAddEndDateOffSetTime=driveDateAddEndDateOffSet;
                                        DateTime webSchEndDate=driveDateAddEndDateOffSetTime.addHours(calculatedEndTime.hour()).addMinutes(calculatedEndTime.minute());
                                        System.debug('webSchEndDate==='+webSchEndDate);
                                        
                                        if(oppty.TimeZone__c!=null){
                                            wsEndDateTime= DateTimeConverter.convertDateTimeIntoGMT(oppty.TimeZone__c,driveDateAddEndDateOffSet,calculatedEndTime);
                                            //system.debug('StartDateTime'+wsEndDateTime);
                                        } else {
                                            wsEndDateTime=webSchEndDate; 
                                            //system.debug('StartDateTime'+wsEndDateTime);
                                        } 
                                    }
                                    opp.put('Web_Schedule_EndDate__c',driveDateAddEndDateOffSet);
                                    opp.put('Web_Schedule_End_Date__c',wsEndDateTime);
                                    opp.put('Web_Schedule_End_Time__c',calculatedEndTime);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //System.debug( 'updateopplist is now ' + updateOpplistMap.values() );
            if(!updateopplist.isEmpty())
            {
                //Schema.DescribeSObjectResult ds = Opportunity.sObjectType.getDescribe();
                //if( ds.isUpdateable() ){}
                update updateopplist;
            }
            //System.debug( 'query is ' + query );
            //System.debug( 'updateopplist is ' + updateopplist );
            //System.debug( 'fieldstoberetrieved is ' + fieldstoberetrieved );
            //System.debug( 'driveidset is ' + driveidset );
        } catch (Exception e) {
            System.debug('An error is occured:'+e.getLineNumber()+'___'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return 'success';
    }
    public static string rollAffiliationsOrServiceRoles(Boolean isDriveAffiliationFound,Boolean isDriveServiceRolesFound,String recordid, List<Opportunity> updateopplist,List<String> driveidset){
        try{
            List<Drive_Marketing_Programs__c> driveAffliationsToInsertList = new List<Drive_Marketing_Programs__c>();
            List<OpportunityContactRole> driveServiceRolesToInsertList = new List<OpportunityContactRole>();
            //Insert Drive Affliations(Drive_Marketing_Programs__c) to all the selected opportuntities
            if(isDriveAffiliationFound){
                //Delete existing the Drive Affliations(Drive_Marketing_Programs__c) from the selected opportunites first.
                List<Drive_Marketing_Programs__c> existingDriveAffliationsToDeleteList =[SELECT Id,Marketing_Program__c,Account__c,Migration_ID__c,
                                                                                         Date_Removed__c, Start_Date__c,End_Date__c,
                                                                                         Blood_Drive_Opportunity__c FROM Drive_Marketing_Programs__c
                                                                                         WHERE Blood_Drive_Opportunity__c IN:driveidset
                                                                                          ];
                if(existingDriveAffliationsToDeleteList.size()>0){
                    Database.delete(existingDriveAffliationsToDeleteList);
                }
                List<Drive_Marketing_Programs__c> driveAffiliationsList = [SELECT Marketing_Program__c,Account__c,Migration_ID__c,
                                                                           Date_Removed__c, Start_Date__c,End_Date__c,
                                                                           Blood_Drive_Opportunity__c FROM Drive_Marketing_Programs__c
                                                                           WHERE Blood_Drive_Opportunity__c =:recordid
                                                                            ];
                for(Drive_Marketing_Programs__c driveAffiliation:driveAffiliationsList){
                    for(Opportunity opty:updateopplist){
                        Drive_Marketing_Programs__c affiliationToInsert = new Drive_Marketing_Programs__c();
                        affiliationToInsert.Marketing_Program__c = driveAffiliation.Marketing_Program__c;
                        affiliationToInsert.Blood_Drive_Opportunity__c = opty.Id;
                        affiliationToInsert.Account__c = driveAffiliation.Account__c;
                        affiliationToInsert.Migration_ID__c = driveAffiliation.Migration_ID__c;
                        affiliationToInsert.Date_Removed__c = driveAffiliation.Date_Removed__c;
                        driveAffliationsToInsertList.add(affiliationToInsert);
                    }
                }
            }
            //Insert Drive Service Roles(OpportunityContactRole) to all the selected opportuntities
            if(isDriveServiceRolesFound){            
                
                //Delete existing the Drive Service Roles(AccountContactRole) from the selected opportunites first. 
                List<OpportunityContactRole> existingDriveServiceRoleToDeleteList = [SELECT OpportunityId,ContactId 
                                                                                     FROM OpportunityContactRole 
                                                                                     WHERE OpportunityId =:driveidset];
                if(existingDriveServiceRoleToDeleteList.size()>0){
                    //Schema.DescribeSObjectResult ds = OpportunityContactRole.sObjectType.getDescribe();
                    //if( ds.isUpdateable() ){}
                    Database.delete(existingDriveServiceRoleToDeleteList);
                }
                List<OpportunityContactRole> driveServiceRoleList = [SELECT OpportunityId,ContactId, Role
                                                                     FROM OpportunityContactRole
                                                                     WHERE OpportunityId =:recordid  ];
                for(OpportunityContactRole driveServiceRole:driveServiceRoleList){
                    for(Opportunity opty:updateopplist){
                        OpportunityContactRole driveServiceRoleToInsert = new OpportunityContactRole();
                        driveServiceRoleToInsert.ContactId = driveServiceRole.ContactId;
                        driveServiceRoleToInsert.OpportunityId = opty.Id;
                        driveServiceRoleToInsert.Role = driveServiceRole.Role;
                        driveServiceRolesToInsertList.add(driveServiceRoleToInsert);
                    }
                }
            }
            if(driveAffliationsToInsertList.size()>0){
                //System.debug('driveAffliationsToInsertList:'+driveAffliationsToInsertList);
                //Schema.DescribeSObjectResult ds = Drive_Marketing_Programs__c.sObjectType.getDescribe();
                //if( ds.isUpdateable() ){}
                Database.insert(driveAffliationsToInsertList);
            }
            if(driveServiceRolesToInsertList.size()>0){
                //System.debug('driveServiceRolesToInsertList:'+driveServiceRolesToInsertList);
                //Schema.DescribeSObjectResult ds = OpportunityContactRole.sObjectType.getDescribe();
                //if( ds.isUpdateable() ){}
                Database.insert(driveServiceRolesToInsertList);
            }
        }
        catch (Exception e) {
            //System.debug('An error is occured:'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        return 'success';
    }
    public class FutureDriveClass{
        @AuraEnabled public String drivenanme;
        @AuraEnabled public String driveid;
        @AuraEnabled public String drivedate;
        @AuraEnabled public String drivesite;
        @AuraEnabled public String drivestage;
        @AuraEnabled public String drivestatus;
        @AuraEnabled public Boolean isselected ;
    }
    public class FieldSetClass{
        @AuraEnabled public String fieldapiname;
        @AuraEnabled public String fieldlabel;
    }
}