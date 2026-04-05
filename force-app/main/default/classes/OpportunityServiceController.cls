public without sharing class OpportunityServiceController {

    public static void syncOppsWithDrives(List<Opportunity> lstOpps){
        List<FieldIdentifiers> fieldsUpdated = mapRequiredFields(lstOpps);
        sync (fieldsUpdated);
    }

    public static List<FieldIdentifiers> mapRequiredFields(List<Opportunity> lstOpps){
        //Prepare data for the update event container
        List<FieldIdentifiers> oppFieldsList = new List<FieldIdentifiers>();
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418
        
        try{
            //HRP-10514 : added Platelet_Projected_Procedures__c for 'DriveSync' issue.
            Map<Id, Opportunity> mapOfOpportunity = new Map<Id, Opportunity>([SELECT Id, Drive_Status__c,Drive_Date_Change_Reason__c, Initiated_By__c, StageName,Platelet_Projected_Procedures__c,Plasma_Pheresis_Projected_Procedures__c, Anticipated_Registered_Donors__c, 
                                                                              WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Accepts_Automation__c, Automation_Suitability__c   FROM Opportunity WHERE Id In :lstOpps]);
            //HRP-10515-Query latest values on DOC for changed fields and update on Opportunity, when request comes from DOC update
            List<sked_Drive__c> docList = [select sked_Drive_Date__c,sked_Status__c,sked_Start_Time__c,sked_End_Time__c,sked_Drive_Site__c,sked_Replacement_Drive__c,sked_Projected_Registered_Donors__c,sked_WB_Projected_Procedures__c,sked_2RBC_Projected_Procedures__c,sked_Platelet_Projected_Procedures__c,sked_Plasma_Projected_Procedures__c,sked_Number_of_2RBC_Assets__c,
                                           sked_Number_of_Plasma_Assets__c,sked_Number_of_Platelet_Assets__c,sked_Cancellation_Reason__c,sked_Opportunity__c from sked_Drive__c 
                                           where sked_Opportunity__c in : lstOpps and sked_Is_Surrogate__c = false];
            /*if(Test.isRunningTest()){
                sked_Drive__c skedDr =  new sked_Drive__c(sked_Opportunity__c=lstOpps.get(0).id,sked_WB_Projected_Procedures__c=2,sked_Status__c='Draft',sked_Drive_Date__c=system.today().addDays(55));
                List<sked_Drive__c> skedDrList = new List<sked_Drive__c>();
                skedDrList.add(skedDr);
                docList= skedDrList;
                
            } */           
            Map<Id, sked_Drive__c> docOppMap   =  getDocOppMap(docList);  //HRP-10515     
            if (lstOpps <> null && lstOpps.size() > 0) {
                
                string valueToLog = Json.Serialize(lstOpps);
                system.debug('###FWO... valueToLog ' + valueToLog);
                BSF_Error_Log__c log = new BSF_Error_Log__c (
                    Process_Name__c = 'Sync Opps With Drives',
                    ApexClass__c = 'OpportunityService',
                    Method__c = 'syncOppsWithDrives',
                    Type__c = 'Debug Log',
                    Error_Description__c = 'Sync Request From DoC'
                );
                log.Error_Description_Long__c = valueToLog.length() > 2500 ? valueToLog.subString(0,2500) : valueToLog;
                insert log;
                
                for (Opportunity oppRec : lstOpps) {      
                    Boolean arcUpdated = false;
                    Boolean wbcUpdated = false;
                    //Boolean pltUpdated = false;
                    Boolean doubleRbcUpdated = false;
                    Map<string, object> data = oppRec.getPopulatedFieldsAsMap();
                    system.debug('#### Inside syncOppsWithDrives. Data is => ' + data);
                    //FieldIdentifiers is a Apex Class named as :'FieldIdentifiers.apexc'
                    FieldIdentifiers oppField = new FieldIdentifiers();
                    oppField.OppId = oppRec.id;
                    for (String key : data.keySet()) {
                        oppField.updatedDataKeys.add(key);
                    }
                    sked_Drive__c doc = docOppMap.get(oppRec.Id);//HRP-10515
                    
                    //HRP-10515- begin-> Update with latest values on DOC 
                    //HRP-10312 -begin-> First check if the field came in as part of drive change request, only then process it
                    if(data.containsKey('Is_Recursion_On__c') == true && //HRP-10312
                       data.get('Is_Recursion_On__c') != null && oppRec.Is_Recursion_On__c != null) {
                           oppField.Is_Recursion_On = oppRec.Is_Recursion_On__c; //HRP-10515 -> this is not a DOC object field, populated directly on Opp from SkedDriveHandler
                       }
                    if(data.containsKey('Drive_Status__c') == true && //HRP-10312
                       data.get('Drive_Status__c') != null && string.isNotBlank(oppRec.Drive_Status__c)) {// oppRec.Drive_Status__c != null) {
                           oppField.Drive_Status = doc != null? doc.sked_Status__c : oppRec.Drive_Status__c;
                           System.debug('Updating Drive_Status  to->'+oppField.Drive_Status);   
                       }
                    if(data.containsKey('Drive_Date__c') == true && data.get('Drive_Date__c') != null && oppRec.Drive_Date__c != null) { //HRP-10312
                        oppField.Drive_Date = doc != null? doc.sked_Drive_Date__c : oppRec.Drive_Date__c; //HRP-12063
                        DateTime now = DateTime.now();//HRP-12063
                        String formattedDateTime = now.format('yyyy-MM-dd HH:mm:ss');//HRP-12063
                        oppField.driveDateChangeReason='Changed from DOC on '+formattedDateTime;//HRP-12063
                        //system.debug('check the reason and drive date '+oppField.driveDateChangeReason+'drive date '+oppField.Drive_Date+'opp rec '+oppRec.Drive_Date__c+'opp rec reason'+oppRec.Drive_Date_Change_Reason__c);
                    }
                    if(data.containsKey('Start_Time__c') == true && data.containsKey('Start_Time__c') == true && data.get('Start_Time__c') != null && oppRec.Start_Time__c != null) { //HRP-10312
                        oppField.Start_Time = OneTimeFlowTimeFieldUpdateBatch.getFlowTime(doc != null? doc.sked_Start_Time__c : oppRec.Start_Time__c);
                        system.debug('#### Inside syncOppsWithDrives. oppField.Start_Time => ' + oppField.Start_Time);
                    }
                    if(data.containsKey('End_Time__c') == true && data.get('End_Time__c') != null && oppRec.End_Time__c != null) { //HRP-10312                    
                        oppField.End_Time = OneTimeFlowTimeFieldUpdateBatch.getFlowTime(doc != null? doc.sked_End_Time__c : oppRec.End_Time__c);
                    }
                    
                    
                   system.debug('#### data.containsKey(Drive_Site__c) == true => ' + String.valueOf(data.containsKey('Drive_Site__c') == true));
                   system.debug('#### data.containsKey(Anticipated_Registered_Donors__c) == true => ' + String.valueOf(data.containsKey('Anticipated_Registered_Donors__c') == true));

                    if(data.containsKey('Drive_Site__c') == true && data.get('Drive_Site__c') != null && oppRec.Drive_Site__c != null) { //HRP-10312
                        oppField.Drive_Site = doc != null? doc.sked_Drive_Site__c : oppRec.Drive_Site__c;
                    }
                    if(data.containsKey('Anticipated_Registered_Donors__c') == true){ //HRP-10312 begin
                        arcupdated = true;//HRP-10312 
                        if(oppRec.Anticipated_Registered_Donors__c != null){
                            oppField.Anticipated_Registered_Donors = Integer.valueOf(oppRec.Anticipated_Registered_Donors__c);
                        }
                        //HRP-10312 Begin
                        else{
                            oppField.Anticipated_Registered_Donors = null;
                        }
                        //HRP-10312 end
                        
                    }
                    //HRP-10312 begin
                    if(data.containsKey('WB_Projected_Procedures__c') == true){
                        wbcUpdated = true;
                        //HRP-10312 end
                        if(oppRec.WB_Projected_Procedures__c != null){
                            oppField.WB_Projected_Procedures = Integer.valueOf(oppRec.WB_Projected_Procedures__c);
                        }//HRP-10312 begin
                        else{
                            oppField.WB_Projected_Procedures = null;
                        }
                        //HRP-10312 end
                    }
                    //HRP-10312 begin
                    if(data.containsKey('X2RBC_Projected_Procedures__c') == true){
                        doubleRbcUpdated = true; //HRP-10312 end
                        if(oppRec.X2RBC_Projected_Procedures__c != null){
                            oppField.X2RBC_Projected_Procedures = Integer.valueOf(oppRec.X2RBC_Projected_Procedures__c);
                        } //HRP-10312 begin
                        else{
                            oppField.X2RBC_Projected_Procedures = null;
                        }//HRP-10312 end
                    }
                    
                    if(data.containsKey('Apheresis_Projected_Units__c') == true){//HRP-10312 
                        if(data.get('Apheresis_Projected_Units__c') != null && oppRec.Apheresis_Projected_Units__c != null) {
                            oppField.Platelet_Projected = Integer.valueOf(oppRec.Apheresis_Projected_Units__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Platelet_Projected = null;
                        }//HRP-10312 end
                    }
                    
                    if(data.containsKey('Other_Projected_Units__c') == true){//HRP-10312
                        if(data.get('Other_Projected_Units__c') != null && oppRec.Other_Projected_Units__c != null) {
                            //TODO prod has this as ->  oppField.Plasma_Pheresis_Projected = Integer.valueOf(oppRec.Other_Projected_Units__c);
                            oppField.Plasma_Pheresis_Projected = Integer.valueOf(oppRec.Other_Projected_Units__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Plasma_Pheresis_Projected = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Number_of_2RBC_Assets__c') == true){//HRP-10312
                        if(data.get('Number_of_2RBC_Assets__c') != null && oppRec.Number_of_2RBC_Assets__c != null) {
                            oppField.Number_of_2RBC_Assets = Integer.valueOf(oppRec.Number_of_2RBC_Assets__c);
                        }//HRP-10312 begin 
                        else{
                            oppField.Number_of_2RBC_Assets = null;
                        }
                        //HRP-10312 end
                    }
                    if(data.containsKey('Number_of_Plasma_Assets__c') == true){//HRP-10312 
                        
                        if(data.get('Number_of_Plasma_Assets__c') != null && oppRec.Number_of_Plasma_Assets__c != null) {
                            oppField.Number_of_Plasma_Assets = Integer.valueOf(oppRec.Number_of_Plasma_Assets__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Number_of_Plasma_Assets = null; 
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Number_of_Platelet_Assets__c') == true){//HRP-10312 begin
                        if(data.get('Number_of_Platelet_Assets__c') != null && oppRec.Number_of_Platelet_Assets__c != null) {  
                            oppField.Number_of_Platelet_Assets = Integer.valueOf(oppRec.Number_of_Platelet_Assets__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Number_of_Platelet_Assets = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Anticipated_Registered_Donors_Template__c') == true){//HRP-10312 begin
                        if(data.get('Anticipated_Registered_Donors_Template__c') != null && oppRec.Anticipated_Registered_Donors_Template__c != null) {  
                            oppField.Anticipated_Registered_Donors_Template = Integer.valueOf(oppRec.Anticipated_Registered_Donors_Template__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Anticipated_Registered_Donors_Template = null;
                        }//HRP-10312 end
                    }  
                    
                    
                    //HRP-10514 Start->>
                    if(data.containsKey('Platelet_Projected_Procedures__c') == true){//HRP-10312 
                        if(data.get('Platelet_Projected_Procedures__c') != null && oppRec.Platelet_Projected_Procedures__c != null) {  
                            oppField.Platelet_Projected_Procedure = Integer.valueOf(oppRec.Platelet_Projected_Procedures__c);
                        }//HRP-10312 begin
                        else{
                            oppField.Platelet_Projected_Procedure = null;
                        }//HRP-10312 end
                    } 
                    //HRP-10514 <<-End
                    //HRP-10659 Start ->>
                    if(data.containsKey('Plasma_Pheresis_Projected_Procedures__c') == true){//HRP-10312 
                        if(data.get('Plasma_Pheresis_Projected_Procedures__c') != null && oppRec.Plasma_Pheresis_Projected_Procedures__c != null) {  
                            oppField.Plasma_Pheresis_Projected_Procedure = Integer.valueOf(oppRec.Plasma_Pheresis_Projected_Procedures__c);
                        }
                        else{
                            oppField.Plasma_Pheresis_Projected_Procedure = null;
                        }
                    } 
                    //HRP-10659 <<-End
                    
                    if(data.containsKey('AnticipatedRegisterDonorChangeReason__c') == true){//HRP-10312 begin
                        if(data.get('AnticipatedRegisterDonorChangeReason__c') != null && oppRec.AnticipatedRegisterDonorChangeReason__c != null && arcUpdated == true) {
                            oppField.AnticipatedRegisterDonorChangeReason = oppRec.AnticipatedRegisterDonorChangeReason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.AnticipatedRegisterDonorChangeReason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('WholeBloodProcedureProjectedChangeReason__c') == true){//HRP-10312 
                        if(data.get('WholeBloodProcedureProjectedChangeReason__c') != null && oppRec.WholeBloodProcedureProjectedChangeReason__c != null && wbcUpdated == true) {
                            oppField.WholeBloodProcedureProjectedChangeReason = oppRec.WholeBloodProcedureProjectedChangeReason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.WholeBloodProcedureProjectedChangeReason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('DoubleRedProceduresProjectedChangeReason__c') == true){ //HRP-10312 
                        if(data.get('DoubleRedProceduresProjectedChangeReason__c') != null && oppRec.DoubleRedProceduresProjectedChangeReason__c != null && doubleRbcUpdated == true) {
                            oppField.DoubleRedProceduresProjectedChangeReason = oppRec.DoubleRedProceduresProjectedChangeReason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.DoubleRedProceduresProjectedChangeReason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Account_Manager__c') == true){//HRP-10312 
                        if(data.get('Account_Manager__c') != null && oppRec.Account_Manager__c != null) {
                            oppField.Account_Manager = oppRec.Account_Manager__c;
                        }//HRP-10312 begin
                        else{
                            oppField.Account_Manager = null;
                        } //HRP-10312 end
                    }
                    if(data.containsKey('Parent_Template_Id') == true){ //HRP-10312 
                        if(data.get('Parent_Template_Id__c') != null && oppRec.Parent_Template_Id__c != null) {
                            oppField.Parent_Template_Id = oppRec.Parent_Template_Id__c;
                        }//HRP-10312 begin 
                        else{
                            oppField.Parent_Template_Id = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('sked_Cancellation_Reason__c') == true){//HRP-10312 
                        if(data.get('sked_Cancellation_Reason__c') != null && oppRec.sked_Cancellation_Reason__c != null && doc.sked_Cancellation_Reason__c != oppField.sked_Cancellation_Reason) {
                            oppField.sked_Cancellation_Reason = doc != null? doc.sked_Cancellation_Reason__c : oppRec.sked_Cancellation_Reason__c;
                        }//HRP-10312 begin
                        else{
                            oppField.sked_Cancellation_Reason = null;
                        }//HRP-10312 end
                    }
                    if(data.containsKey('Initiated_By__c') == true){//HRP-10312 
                        if(data.get('Initiated_By__c') != null && oppRec.Initiated_By__c != null && oppField.Initiated_By != oppRec.Initiated_By__c) {
                            oppField.Initiated_By = oppRec.Initiated_By__c;
                        }//HRP-10312 begin 
                        else{
                            oppField.Initiated_By = null;
                        }//HRP-10312 end
                    }
                    else {
                        //Since at the moment, DOC isn't sending us the value for initiated_by, we are making sure to maintain the current value
                        if(mapOfOpportunity.ContainsKey(oppRec.Id) && mapOfOpportunity.get(oppRec.Id).Initiated_By__c != null) {
                            oppField.Initiated_By = mapOfOpportunity.get(oppRec.Id).Initiated_By__c;
                            oppField.updatedDataKeys.add('Initiated_By__c');
                        }
                    }
                    
                    
                    //if(data.get('Enable_APH_Web_Scheduling__c') != null && oppRec.Enable_APH_Web_Scheduling__c != null) {
                    //    oppField.Enable_APH_Web_Scheduling = oppRec.Enable_APH_Web_Scheduling__c;
                    //}
                    
                    if(data.containsKey('Drive_Status__c') == true && data.get('Drive_Status__c') != null && oppRec.Drive_Status__c != null &&
                       mapOfOpportunity != null && mapOfOpportunity.ContainsKey(oppRec.Id)) {//HRP-10312 
                           
                           String latestDriveStatus = doc != null? doc.sked_Status__c : oppRec.Drive_Status__c;
                           if(latestDriveStatus == 'Cancel' && mapOfOpportunity.get(oppRec.Id).StageName != 'Cancelled') {
                               oppField.StageName = 'Cancelled';
                               oppField.updatedDataKeys.add('StageName');
                           }
                           if(latestDriveStatus == 'Tentative' && mapOfOpportunity.get(oppRec.Id).StageName != 'Committed') {
                               oppField.StageName = 'Committed';
                               oppField.updatedDataKeys.add('StageName');
                               if(mapOfOpportunity.get(oppRec.Id).Initiated_By__c != null) {
                                   oppField.Sked_Cancellation_Reason = '';
                                   oppField.Initiated_By = '';
                                   oppField.updatedDataKeys.add('Initiated_By__c');    
                                   oppField.updatedDataKeys.add('sked_Cancellation_Reason__c');
                               }
                           }
                           if(latestDriveStatus == 'Confirmed' && mapOfOpportunity.get(oppRec.Id).StageName != 'Closed') {
                               oppField.StageName = 'Closed';
                               oppField.updatedDataKeys.add('StageName');
                               if(mapOfOpportunity.get(oppRec.Id).Initiated_By__c != null) {
                                   oppField.Sked_Cancellation_Reason = '';
                                   oppField.Initiated_By = '';
                                   oppField.updatedDataKeys.add('Initiated_By__c');    
                                   oppField.updatedDataKeys.add('sked_Cancellation_Reason__c');
                               }
                           }
                           if((mapOfOpportunity.get(oppRec.Id).Drive_Status__c == 'Draft' && latestDriveStatus == 'Hold') || 
                              (mapOfOpportunity.get(oppRec.Id).Drive_Status__c == 'Hold' && latestDriveStatus == 'Draft')) {
                                  //if((oppRec.Drive_Status__c == 'Draft' || oppRec.Drive_Status__c == 'Hold') && mapOfOpportunity.get(oppRec.Id).StageName != 'Solicitation') {
                                  oppField.StageName = 'Solicitation';
                                  oppField.updatedDataKeys.add('StageName');
                              }
                       }
                    
                    oppFieldsList.add(oppField);
                }
            }
        }catch(Exception ex){
            System.debug('#### Inside ex line  => ' + ex.getLineNumber());
            System.debug('#### Inside ex  => ' + ex);
        }
        return oppFieldsList;
    }

    public static List<Opportunity> generateOppList(List<FieldIdentifiers> oppFieldsList){
        List<Opportunity> lstOppToUpdate = new List<Opportunity>();
        for(FieldIdentifiers oppFields : oppFieldsList) {
            Opportunity recOpp = new Opportunity();  //HRP-10010 moved this inside the loop for the fields
            recOpp.Id = oppFields.OppId;
            if(oppFields.updatedDataKeys.contains('Drive_Status__c')) { //HRP-10312
                recOpp.Drive_Status__c = oppFields.Drive_Status;
            }
            if(oppFields.updatedDataKeys.contains('sked_Cancellation_Reason__c')) { //HRP-10312
                recOpp.sked_Cancellation_Reason__c = oppFields.Sked_Cancellation_Reason;
            }
            if(oppFields.updatedDataKeys.contains('Initiated_By__c')) { //HRP-10312
                recOpp.Initiated_By__c = oppFields.Initiated_By;
            }
            if(oppFields.updatedDataKeys.contains('StageName')) { //HRP-10312
                recOpp.StageName = oppFields.StageName;                   
            }
            if(oppFields.updatedDataKeys.contains('Drive_Date__c')) { //HRP-10312
                recOpp.Drive_Date__c = oppFields.Drive_Date;
               // if(oppFields.driveDateChangeReason !=null){
                   recOpp.Drive_Date_Change_Reason__c = oppFields.driveDateChangeReason;//HRP-12063 
               // }
            }
            if(oppFields.updatedDataKeys.contains('Flow_Start_Time_Field__c') || oppFields.updatedDataKeys.contains('Start_Time__c')) { //HRP-10312 & //HRP-10659
                recOpp.Flow_Start_Time_Field__c = oppFields.Start_Time;
            }
            if(oppFields.updatedDataKeys.contains('Flow_End_Time_Field__c') || oppFields.updatedDataKeys.contains('End_Time__c')) { //HRP-10312 & //HRP-10659
                recOpp.Flow_End_Time_Field__c = oppFields.End_Time;
            }
            if(oppFields.updatedDataKeys.contains('Drive_Site__c')) { //HRP-10312
                recOpp.Drive_Site__c = oppFields.Drive_Site;
            }
            if(oppFields.updatedDataKeys.contains('Anticipated_Registered_Donors__c')) { //HRP-10312
                recOpp.Anticipated_Registered_Donors__c = oppFields.Anticipated_Registered_Donors;
            }
            if(oppFields.updatedDataKeys.contains('WB_Projected_Procedures__c')) { //HRP-10312
                recOpp.WB_Projected_Procedures__c = oppFields.WB_Projected_Procedures;
            }
            if(oppFields.updatedDataKeys.contains('X2RBC_Projected_Procedures__c')) { //HRP-10312
                recOpp.X2RBC_Projected_Procedures__c = oppFields.X2RBC_Projected_Procedures;
            }
            if(oppFields.updatedDataKeys.contains('AnticipatedRegisterDonorChangeReason__c')) { //HRP-10312
                recOpp.AnticipatedRegisterDonorChangeReason__c = oppFields.AnticipatedRegisterDonorChangeReason;
            }
            if(oppFields.updatedDataKeys.contains('WholeBloodProcedureProjectedChangeReason__c')) { //HRP-10312
                recOpp.WholeBloodProcedureProjectedChangeReason__c = oppFields.WholeBloodProcedureProjectedChangeReason;
            }
            if(oppFields.updatedDataKeys.contains('DoubleRedProceduresProjectedChangeReason__c')) { //HRP-10312
                recOpp.DoubleRedProceduresProjectedChangeReason__c = oppFields.DoubleRedProceduresProjectedChangeReason;
            }
            if(oppFields.updatedDataKeys.contains('Apheresis_Projected_Units__c')) { //HRP-10312
                recOpp.Apheresis_Projected_Units__c = oppFields.Platelet_Projected;
            }
            if(oppFields.updatedDataKeys.contains('Other_Projected_Units__c')) { //HRP-10312
                recOpp.Other_Projected_Units__c = oppFields.Plasma_Pheresis_Projected;
            }
            if(oppFields.updatedDataKeys.contains('Number_of_2RBC_Assets__c')) { //HRP-10312
                recOpp.Number_of_2RBC_Assets__c = oppFields.Number_of_2RBC_Assets;
            }
            if(oppFields.updatedDataKeys.contains('Number_of_Plasma_Assets__c')) { //HRP-10312
                recOpp.Number_of_Plasma_Assets__c = oppFields.Number_of_Plasma_Assets;
            }
            if(oppFields.updatedDataKeys.contains('Number_of_Platelet_Assets__c')) { //HRP-10312
                recOpp.Number_of_Platelet_Assets__c = oppFields.Number_of_Platelet_Assets;
            }
            if(oppFields.updatedDataKeys.contains('Platelet_Projected_Procedures__c')) { //HRP-10312
                recOpp.Platelet_Projected_Procedures__c = oppFields.Platelet_Projected_Procedure;
            }
            if(oppFields.updatedDataKeys.contains('Plasma_Pheresis_Projected_Procedures__c')) { //HRP-10312
                recOpp.Plasma_Pheresis_Projected_Procedures__c = oppFields.Plasma_Pheresis_Projected_Procedure;
            }
            if(oppFields.updatedDataKeys.contains('Account_Manager__c')) { //HRP-10312
                recOpp.Account_Manager__c = oppFields.Account_Manager;
            }
            if(oppFields.updatedDataKeys.contains('Anticipated_Registered_Donors_Template__c')) { //HRP-10312
                recOpp.Anticipated_Registered_Donors_Template__c = oppFields.Anticipated_Registered_Donors_Template;
            }
            if(oppFields.updatedDataKeys.contains('Is_Recursion_On__c')) { //HRP-10312
                recOpp.Is_Recursion_On__c = oppFields.Is_Recursion_On;
            }
            if(oppFields.updatedDataKeys.contains('Parent_Template_Id__c')) { //HRP-10312
                recOpp.Parent_Template_Id__c = oppFields.Parent_Template_Id;
            }
            System.debug('recOpp being updated->'+recOpp);
            
            lstOppToUpdate.add(recOpp);
        }
        return lstOppToUpdate;
    }

    public static Map<Id, sked_Drive__c> getDocOppMap(List<sked_Drive__c> docList){
        
        Map<Id, sked_Drive__c> docOppMap = new Map<Id, sked_Drive__c>();
        if(docList !=null && docList.size()>0){
            
            for(sked_Drive__c doc:docList){
                docOppMap.put(doc.sked_Opportunity__c,doc);
            }
        }
        return docOppMap;
    }

    public static void sync(List<FieldIdentifiers> oppFieldsList){
            List<Opportunity> opps = generateOppList(oppFieldsList);
            if(!opps.isEmpty()) {
                update opps;
            }
    }

    public static void populateLatestValuesUponTemplateChange(Opportunity newOpportunity, Opportunity templateOpportunity, String templateChangeText) {
        if(newOpportunity != null && templateOpportunity != null) {
            newOpportunity.WholeBloodProceduresProjectedTemplate__c = templateOpportunity.WB_Projected_Procedures__c;
            newOpportunity.Double_Red_Procedures_Projected_Template__c = templateOpportunity.X2RBC_Projected_Procedures__c;
            newOpportunity.Anticipated_Registered_Donors_Template__c = templateOpportunity.Anticipated_Registered_Donors__c;
            newOpportunity.Direct_Donors_To__c = templateOpportunity.Direct_Donors_To__c;
            
            if(newOpportunity.WB_Projected_Procedures__c != templateOpportunity.WB_Projected_Procedures__c) {
                newOpportunity.WB_Projected_Procedures__c = templateOpportunity.WB_Projected_Procedures__c;
                newOpportunity.WholeBloodProcedureProjectedChangeReason__c = templateChangeText;
            }
            if(newOpportunity.X2RBC_Projected_Procedures__c != templateOpportunity.X2RBC_Projected_Procedures__c) {
                newOpportunity.X2RBC_Projected_Procedures__c = templateOpportunity.X2RBC_Projected_Procedures__c;
                newOpportunity.DoubleRedProceduresProjectedChangeReason__c = templateChangeText;
            }
            if(newOpportunity.Anticipated_Registered_Donors__c != templateOpportunity.Anticipated_Registered_Donors__c) {
                newOpportunity.Anticipated_Registered_Donors__c = templateOpportunity.Anticipated_Registered_Donors__c;
                newOpportunity.AnticipatedRegisterDonorChangeReason__c = templateChangeText;
            }
        }
    }
}