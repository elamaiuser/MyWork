/* This is a trigger on the platform event Update_Event__e.  It is needed because the original flow that subscribes to the 
 * platform event runs under a user context and causes issues when a collection or collection management user attempts to 
 * update an operations record which in turn tries to sync the status between Drives on Calendar and Opportunity.  The flow
 * has been updated to bypass collection and collection management profiles.  This trigger subscriber is now going to execute for
 * a collection or collection management user and can successfully update records b/c it will run in system context
  
 * Sample code to use for testing...
 
  List<Opportunity> updateOppList = new List<Opportunity>();
  Opportunity oppRec = new Opportunity(
    Id = '0068I0000045Pz1QAE',
    Drive_Status__c = 'Cancel',
    sked_Cancellation_Reason__c = 'Covid'
  ); 
  updateOppList.add(oppRec);
  if (!updateOppList.isEmpty()) {
     opportunityService.syncOppsWithDrives(updateOppList);
  } 

 * Modification Log 
 * 
 * Date                 Developer Name          Comments
 * ***************************************************************************************************************************************************************************
 * 5/24/2023                Fitsum Worku        Fix for HRP-10010. Fixed issue were multiple records per a sync request were appropriately processed
 * 8/2/2023					Anil Kallu			Fix for HRP-10312 Fixed sync issue to opportunity when DCR is rejected
 * 8/8/2023                 Krapy Tuli          Fix for HRP-10659 Drive Stage remains in Discovery after drive is submitted and Start Time does not revert back to original value when DCR is rejected
 * 10/27/2023			    Anil Kallu			Fix for HRP-11296 Capture error logs in case of DB failures and run time exceptions
 * 4/23/2024                Krapy Tuli          Update type field in catch block.
 * 4/23/2024                Krapy Tuli          Update logic to handle duplicate id error as part of (HRP-12422).
 * 06/06/2024				Priti Jana			Logic for HRP-12011 (Added Slot Generator Field to sync after DCR cancellation/rejection)
 *****************************************************************************************************************************************************************************
*/

trigger updateEventTrigger on Update_Event__e (After Insert) {
    
  try{
    
    system.debug('###FWO inside trigger for update event');
    
    List<UpdateEvent> lstUpdateEvent = new List<UpdateEvent>();
    
    for (Update_Event__e evt : Trigger.New) {  
        UpdateEvent objToUpdate = UpdateEvent.parse(evt.Object_Data__c);
        lstUpdateEvent.add(objToUpdate);
    }   

    system.debug('###FWO inside trigger for update event. lstUpdateEvent = ' + lstUpdateEvent);    
    
    Map<Id,Opportunity> mapOfOppToUpdate = new Map<Id,Opportunity>(); //HRP-12422
    List<sked_Drive__c> lstSkedDrives = new List<sked_Drive__c>();
    
    //Add logic for filter out collections
    For(UpdateEvent ev : lstUpdateEvent) {
        if(ev.objectName == 'Opportunity') {
            for(FieldIdentifiers oppFields : ev.objectFields) {
                Opportunity recOpp = new Opportunity();  //HRP-10010 moved this inside the loop for the fields
                recOpp.Id = oppFields.OppId;
                if(mapOfOppToUpdate.containsKey(recOpp.Id)){ //HRP-12422 start
                    recOpp = mapOfOppToUpdate.get(recOpp.Id);
                } //HRP-12422 end
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
                    recOpp.Drive_Date_Change_Reason__c = oppFields.driveDateChangeReason;//HRP-12063
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
                // HRP-12011 --> Starts here
                if(oppFields.updatedDataKeys.contains('Slot_Generator__c')) { 
                    recOpp.Slot_Generator__c = oppFields.Slot_Generator;
                }
                if(oppFields.updatedDataKeys.contains('Slot_Generator_Change_Reason__c')) { 
                    recOpp.Slot_Generator_Change_Reason__c = oppFields.Slot_Generator_Change_Reason;
                }
                // HRP-12011 --> Ends here
                
                // HRP-13190 --> Starts here
                if(oppFields.updatedDataKeys.contains('APT_Required__c')) { 
                    recOpp.APT_Required__c = oppFields.APT_Required;
                }
                if(oppFields.updatedDataKeys.contains('APT_Quantity__c')) { 
                    recOpp.APT_Quantity__c = oppFields.APT_Quantity;
                }
                // HRP-13190 --> Starts here
                System.debug('recOpp being updated->'+recOpp);
                
                mapOfOppToUpdate.put(recOpp.Id,recOpp);//HRP-12422
            }
        }
        else if(ev.objectName == 'DrivesOnCalendar'){
            sked_Drive__c recDrive = new sked_Drive__c();
            System.debug('Inside EV DOC->'+ev);
            for(FieldIdentifiers oppFields : ev.objectFields) {
                recDrive.Id = oppFields.Sked_Drive_Id;
                if(oppFields.Sked_Cancellation_Reason != null) {
                    recDrive.sked_Cancellation_Reason__c = oppFields.Sked_Cancellation_Reason;
                }
                if(oppFields.sked_Drive_Owner != null) {
                    recDrive.sked_Drive_Owner__c = oppFields.sked_Drive_Owner;
                }
                if(oppFields.sked_Historical_Registered_Donors != null) {
                    recDrive.sked_Historical_Registered_Donors__c = oppFields.sked_Historical_Registered_Donors;
                }
                lstSkedDrives.add(recDrive);
            }
        }
    }
    system.debug('###FWO inside trigger for update event.  final opp list to update.' + mapOfOppToUpdate);
    if(!mapOfOppToUpdate.isEmpty()) {//HRP-12422 start
        Database.SaveResult[] lsOpp = Database.update(mapOfOppToUpdate.values(), false);//HRP-12422 end
        System.debug('mapOfOppToUpdate being updated->'+mapOfOppToUpdate);
        //HRP-11296-Begin-Fix for HRP-11296 Capture error logs in case of DB failures and run time exceptions
        List<BSF_Error_Log__c> errorLog = BSF_Utilities.createErrorLog(lsOpp,'','updateEventTrigger','execute','Error','Error syncing Opportunity with Drives On Calendar');
		insert errorLog;
        //HRP-11296-End
    }
    else if (!lstSkedDrives.isEmpty()) {
        Database.SaveResult[] lsDrive = Database.update(lstSkedDrives, false);
        system.debug('lstSkedDrives:-'+lstSkedDrives);
        //HRP-11296-Begin-Fix for HRP-11296 Capture error logs in case of DB failures and run time exceptions

        List<BSF_Error_Log__c> errorLog =  BSF_Utilities.createErrorLog(lsDrive,'','updateEventTrigger','execute','Error','Error syncing Drives on Calendar with Opportunity');
		insert errorLog; 
    }
   }catch(Exception e){
        System.debug('Exception happened in updateEventTrigger->');
        BSF_Error_Log__c errorLog = BSF_Utilities.getErrorLog(null,'updateEventTrigger','execute','Error',e.getStackTraceString(), e.getMessage()); //HRP-12422
   		insert errorLog;
   }
   //HRP-11296-End
    
}