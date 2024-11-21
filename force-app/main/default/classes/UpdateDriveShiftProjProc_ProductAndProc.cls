Global class UpdateDriveShiftProjProc_ProductAndProc implements Database.Batchable<sObject>, Database.Stateful{
    /*

	For instruction go to end :::

   */
    String query;
    Date toDate; 
    Date fromDate;
    String typeOfDrive;
    Boolean driveShiftUpdate = false;
    Boolean onlyTotalProcedureUpdate = false;
    Boolean onlyTotalProcedureUpdateForDrive = false;
    
    
    public UpdateDriveShiftProjProc_ProductAndProc(Date toDate, Date fromDate, String typeOfDrive, Boolean driveShiftUpdate){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.typeOfDrive = typeOfDrive;
        this.driveShiftUpdate = true;

        this.query = 'SELECT Id, sked_Type_of_Drive__c, sked_Operation_Type__c,sked_Platelet_Rounds__c, sked_WB_Projected_Procedures__c,'+
                        'sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,sked_2RBC_Projected_Procedures__c,'+
                        'sked_Drive_Shift_Count__c,sked_Start_Time__c, sked_End_Time__c,sked_Drive_Date__c, (SELECT Id, Name, '+
                        'sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, '+
                        'sked_Plasma_Projected_Procedures__c, sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c FROM '+
                        'sked_Drive_Shifts__r ORDER BY Name ) FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND '+
                        'sked_Drive_Date__c <= :fromDate AND sked_Type_of_Drive__c = :typeOfDrive';
    }

    public UpdateDriveShiftProjProc_ProductAndProc(Date toDate, Date fromDate, String typeOfDrive, Boolean driveShiftUpdate, Boolean onlyTotalProcedureUpdate){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.typeOfDrive = typeOfDrive;
        this.onlyTotalProcedureUpdate = true;
        
        this.query = 'SELECT Id, sked_WB_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, sked_Drive_Date__c, '+
                     '( SELECT Id, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c, '+
                     'sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c FROM sked_Drive_Shifts__r ORDER BY Name ) FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND '+
                     'sked_Drive_Date__c <= :fromDate AND sked_Type_of_Drive__c = :typeOfDrive';
    }

    public UpdateDriveShiftProjProc_ProductAndProc(Date toDate, Date fromDate, String typeOfDrive, Boolean driveShiftUpdate, Boolean onlyTotalProcedureUpdate, Boolean onlyTotalProcedureUpdateForDrive){
        this.toDate = toDate;
        this.fromDate = fromDate;
        this.typeOfDrive = typeOfDrive;
        this.onlyTotalProcedureUpdateForDrive = true;
        
        this.query = 'SELECT Id, sked_WB_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, sked_Drive_Date__c, '+
                     'sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c FROM sked_Drive__c WHERE sked_Drive_Date__c >= :toDate AND '+
                     'sked_Drive_Date__c <= :fromDate AND sked_Type_of_Drive__c = :typeOfDrive';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {   
        return Database.getQueryLocator(this.query);        
    }
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        // this will update drive shift if the projected procedures and sked_Total_Procedures_Projected__c and sked_Total_Products_Projected__c are wrong on drive shift
        if(this.driveShiftUpdate){
            Map<Id, Map<String, Decimal>> map_driveId_shiftProcedureVsValue = new Map<Id, Map<String, Decimal>>();
            Map<String, Decimal> map_shiftProcedure_procedureValue = new Map<String, Decimal>();
            Map<Id, sked_Drive_Shift__c> map_driveShiftId_driveShiftUpdate = new Map<Id, sked_Drive_Shift__c>();
            for(sked_Drive__c drive : driveList) {
            try{
                if(drive.sked_Drive_Shifts__r.isEmpty()) continue;
                Decimal totalRounds = 0;
                Decimal tempDoubleRed = 0;
                Decimal tempWholeBlood = 0;
                Decimal tempPlatelet = 0;
                Decimal tempPlasma = 0;
                Decimal doubleRedProcedurePerShift = 0;
                Decimal wholeBloodProcedurePerShift = 0;
                Decimal plateletProcedurePerShift = 0;
                Decimal plasmaProcedurePerShift = 0;
                Decimal doubleRedForDrive = drive.sked_2RBC_Projected_Procedures__c != NULL ? drive.sked_2RBC_Projected_Procedures__c : 0;
                Decimal wholeBloodForDrive = drive.sked_WB_Projected_Procedures__c != NULL ? drive.sked_WB_Projected_Procedures__c : 0;
                Decimal plateletForDrive = drive.sked_Platelet_Projected_Procedures__c != NULL ? drive.sked_Platelet_Projected_Procedures__c : 0;
                Decimal plasmaForDrive = drive.sked_Plasma_Projected_Procedures__c != NULL ? drive.sked_Plasma_Projected_Procedures__c : 0;
                
                if(drive.get('sked_Platelet_Rounds__c') == NULL && drive.sked_Type_of_Drive__c != 'Mobile') {
                    DateTime drawStart = DateTime.newInstanceGmt(drive.sked_Drive_Date__c, drive.sked_Start_Time__c);
                    DateTime drawEnd = DateTime.newInstanceGmt(drive.sked_Drive_Date__c, drive.sked_End_Time__c);
                    Decimal shiftlength = skedDateTimeUtils.getDifferentMinutes(drawStart, drawEnd) / 60;
                    if(shiftlength <= 3) {
                        totalRounds = 1;
                    } else if(shiftlength > 3 && shiftlength <= 6) {
                        totalRounds = 2;
                    } else if (shiftlength > 6 && shiftlength <= 9) {
                        totalRounds = 3;
                    } else if(shiftlength > 9 && shiftlength <= 12) {
                        totalRounds = 4;
                    } else {
                        totalRounds = 5;
                    }
                } else {
                    totalRounds = drive.sked_Platelet_Rounds__c;
                }
                
                if(drive.sked_Type_of_Drive__c == 'Fixed Site' && drive.sked_Operation_Type__c!= 'Non Integrated WB') {
                    doubleRedProcedurePerShift = Math.ceil(doubleRedForDrive/ totalRounds * drive.sked_Drive_Shift_Count__c);
                    wholeBloodProcedurePerShift = Math.ceil(wholeBloodForDrive / totalRounds * drive.sked_Drive_Shift_Count__c);
                    plateletProcedurePerShift = Math.ceil(plateletForDrive / totalRounds * drive.sked_Drive_Shift_Count__c);
                    plasmaProcedurePerShift = Math.ceil(plasmaForDrive / totalRounds * drive.sked_Drive_Shift_Count__c);
                } else if(drive.sked_Type_of_Drive__c == 'Mobile' || (drive.sked_Type_of_Drive__c == 'Fixed Site' && drive.sked_Operation_Type__c == 'Non Integrated WB')) {
                    doubleRedProcedurePerShift = Math.ceil(doubleRedForDrive/ drive.sked_Drive_Shift_Count__c);
                    wholeBloodProcedurePerShift = Math.ceil(wholeBloodForDrive / drive.sked_Drive_Shift_Count__c);
                }
                for(Integer i = 0; i < drive.sked_Drive_Shift_Count__c; i++) {
                    sked_Drive_Shift__c driveShift = drive.sked_Drive_Shifts__r[i];
                    Decimal currentDriveShiftXRBC = driveShift.sked_2RBC_Projected_Procedures__c != NULL ? driveShift.sked_2RBC_Projected_Procedures__c : 0;
                    Decimal currentDriveShiftWB = driveShift.sked_WB_Projected_Procedures__c != NULL ? driveShift.sked_WB_Projected_Procedures__c : 0;
                    Decimal currentDriveShiftPlatelet = driveShift.sked_Platelet_Projected_Procedures__c != NULL ? driveShift.sked_Platelet_Projected_Procedures__c : 0;
                    Decimal currentDriveShiftPlasma = driveShift.sked_Plasma_Projected_Procedures__c != NULL ? driveShift.sked_Plasma_Projected_Procedures__c : 0;
                    if(i == drive.sked_Drive_Shift_Count__c - 1) {
                        if(currentDriveShiftXRBC != (doubleRedForDrive - tempDoubleRed)) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_2RBC', (doubleRedForDrive - tempDoubleRed));
                        }
                        if(currentDriveShiftWB != (wholeBloodForDrive - tempWholeBlood)) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_WB', (wholeBloodForDrive - tempWholeBlood));
                        }
                        if(currentDriveShiftPlatelet != (plateletForDrive - tempPlatelet)) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_PLATELET', (plateletForDrive - tempPlatelet));
                        }
                        if(currentDriveShiftPlasma != (plasmaForDrive - tempPlasma)) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_PLASMA', (plasmaForDrive - tempPlasma));
                        }
                    } else {
                        if(currentDriveShiftXRBC != doubleRedProcedurePerShift) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_2RBC', doubleRedProcedurePerShift);
                        }
                        if(currentDriveShiftWB != wholeBloodProcedurePerShift) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_WB', wholeBloodProcedurePerShift);
                        }
                        if(currentDriveShiftPlatelet != plateletProcedurePerShift) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_PLATELET', plateletProcedurePerShift);
                        }
                        if(currentDriveShiftPlasma != plasmaProcedurePerShift) {
                            map_shiftProcedure_procedureValue.put(driveShift.Id+'_PLASMA', plasmaProcedurePerShift);
                        }
                    }
                    tempDoubleRed+= doubleRedProcedurePerShift;
                    tempWholeBlood+= wholeBloodProcedurePerShift;
                    tempPlatelet+= plateletProcedurePerShift;
                    tempPlasma+= plasmaProcedurePerShift;
                }
                if(!map_shiftProcedure_procedureValue.isEmpty()) {
                    map_driveId_shiftProcedureVsValue.put(drive.Id, map_shiftProcedure_procedureValue);
                }
                } catch(exception e){
                    system.debug('The Exception is covered'+e.getMessage());
                    BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                    debugLog.ApexClass__c = 'UpdateDriveShiftProjProc_ProductAndProc';
                    debugLog.Method__c = e.getLineNumber() == 95 ? 'Error sked_Platelet_Rounds__c catch line #'+e.getLineNumber() : 'Error at catch line #' + e.getLineNumber();
                    debugLog.Error_Description__c = 'The Exception is covered :: '+e.getMessage(); //
                    debugLog.Error_Description_Long__c = String.valueOf(drive);
                    insert debugLog;
                }
            }
            
            for(String procedure : map_shiftProcedure_procedureValue.keySet()) {
                String driveShiftId = procedure.split('_')[0];
                String procedureType = procedure.split('_')[1];
                sked_Drive_Shift__c driveShift ;
                if(map_driveShiftId_driveShiftUpdate.containsKey(driveShiftId)) {
                    driveShift = map_driveShiftId_driveShiftUpdate.get(driveShiftId);
                } else {
                    driveShift = new sked_Drive_Shift__c(Id = driveShiftId);
                }
                if(procedureType.equalsIgnoreCase('WB')) {
                    driveShift.sked_WB_Projected_Procedures__c = map_shiftProcedure_procedureValue.get(procedure);
                } else if(procedureType.equalsIgnoreCase('2RBC')) {
                    driveShift.sked_2RBC_Projected_Procedures__c = map_shiftProcedure_procedureValue.get(procedure);
                } else if(procedureType.equalsIgnoreCase('PLATELET')) {
                    driveShift.sked_Platelet_Projected_Procedures__c = map_shiftProcedure_procedureValue.get(procedure);
                } else if(procedureType.equalsIgnoreCase('PLASMA')) {
                    driveShift.sked_Plasma_Projected_Procedures__c = map_shiftProcedure_procedureValue.get(procedure);
                }
                map_driveShiftId_driveShiftUpdate.put(driveShift.Id, driveShift);
            }
            Map<Id, sked_Drive_Shift__c> map_shiftId_shift = new Map<Id, sked_Drive_Shift__c>([SELECT Id, sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
                                                                                                sked_Platelet_Projected_Procedures__c, sked_Plasma_Projected_Procedures__c,
                                                                                                sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c, sked_Drive__c
                                                                                                FROM sked_Drive_Shift__c WHERE ID IN :map_driveShiftId_driveShiftUpdate.keySet()]);
            for(sked_Drive_Shift__c driveShift : map_driveShiftId_driveShiftUpdate.values()) {
                sked_Drive_Shift__c driveShiftWxisting = map_shiftId_shift.get(driveShift.Id);
                Decimal currentDriveShiftXRBC = driveShift.sked_2RBC_Projected_Procedures__c != NULL ? driveShift.sked_2RBC_Projected_Procedures__c : (driveShiftWxisting.sked_2RBC_Projected_Procedures__c != NULL ? driveShiftWxisting.sked_2RBC_Projected_Procedures__c : 0);
                Decimal currentDriveShiftWB = driveShift.sked_WB_Projected_Procedures__c != NULL ? driveShift.sked_WB_Projected_Procedures__c : (driveShiftWxisting.sked_WB_Projected_Procedures__c != NULL ? driveShiftWxisting.sked_WB_Projected_Procedures__c : 0);
                Decimal currentDriveShiftPlatelet = driveShift.sked_Platelet_Projected_Procedures__c != NULL ? driveShift.sked_Platelet_Projected_Procedures__c : (driveShiftWxisting.sked_Platelet_Projected_Procedures__c != NULL ? driveShiftWxisting.sked_Platelet_Projected_Procedures__c : 0);
                Decimal currentDriveShiftPlasma = driveShift.sked_Plasma_Projected_Procedures__c != NULL ? driveShift.sked_Plasma_Projected_Procedures__c : (driveShiftWxisting.sked_Plasma_Projected_Procedures__c != NULL ? driveShiftWxisting.sked_Plasma_Projected_Procedures__c : 0);
                driveShift.sked_Total_Procedures_Projected__c = currentDriveShiftWB + 
                                                                currentDriveShiftXRBC + currentDriveShiftPlatelet + 
                                                                currentDriveShiftPlasma;
                driveShift.sked_Total_Products_Projected__c = currentDriveShiftWB + 
                                                                currentDriveShiftXRBC * 2 + currentDriveShiftPlatelet + 
                                                                currentDriveShiftPlasma;
            }
             
            system.debug('map_driveShiftId_driveShiftUpdate '+map_driveShiftId_driveShiftUpdate.size());
            if(map_driveShiftId_driveShiftUpdate.size()>0){
                BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
            	debugLog.ApexClass__c = 'UpdateDriveShiftProjProc_ProductAndProc';
            	debugLog.Method__c = 'UpdateDriveShiftProjProc_ProductAndProc';
            	debugLog.Error_Description__c = String.valueOf(map_driveShiftId_driveShiftUpdate.size()); //
            	debugLog.Error_Description_Long__c = 'driveShiftUpdate size';
            	insert debugLog;
            }
            
            
            system.debug('map_driveShiftId_driveShiftUpdate '+map_driveShiftId_driveShiftUpdate);
            update map_driveShiftId_driveShiftUpdate.values();
        }
        // this will also update drive shift if the sked_Total_Procedures_Projected__c and sked_Total_Products_Projected__c are wrong on drive shift. But this need to run after Projected procedure is succefully updated on dirve shift.
        if(this.onlyTotalProcedureUpdate){
            List<sked_Drive_Shift__c> driveShiftListToUpdate = new List<sked_Drive_Shift__c>();
            for(sked_Drive__c drive : driveList) {
                if(drive.sked_Drive_Shifts__r.isEmpty()) continue;
                for(sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                    Decimal currentDriveShiftXRBC = driveShift.sked_2RBC_Projected_Procedures__c != NULL ? driveShift.sked_2RBC_Projected_Procedures__c : 0;
                    Decimal currentDriveShiftWB = driveShift.sked_WB_Projected_Procedures__c != NULL ? driveShift.sked_WB_Projected_Procedures__c : 0;
                    Decimal currentDriveShiftPlatelet = driveShift.sked_Platelet_Projected_Procedures__c != NULL ? driveShift.sked_Platelet_Projected_Procedures__c : 0;
                    Decimal currentDriveShiftPlasma = driveShift.sked_Plasma_Projected_Procedures__c != NULL ? driveShift.sked_Plasma_Projected_Procedures__c : 0;
                    Decimal expectedTotalProcProj = currentDriveShiftWB + currentDriveShiftXRBC + currentDriveShiftPlatelet + currentDriveShiftPlasma;
                    Decimal expectedTotalProdProj = currentDriveShiftWB + currentDriveShiftXRBC * 2 + currentDriveShiftPlatelet + currentDriveShiftPlasma;
                    if(driveShift.sked_Total_Procedures_Projected__c != expectedTotalProcProj || driveShift.sked_Total_Products_Projected__c != expectedTotalProdProj) {
                        driveShift.sked_Total_Products_Projected__c = expectedTotalProdProj;
                        driveShift.sked_Total_Procedures_Projected__c = expectedTotalProcProj;
                        driveShiftListToUpdate.add(driveShift);
                    }
                }
            }

            system.debug('driveShiftListToUpdate '+driveShiftListToUpdate.size());
            if(driveShiftListToUpdate.size()>0){
                BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                debugLog.ApexClass__c = 'UpdateDriveShiftProjProc_ProductAndProc';
                debugLog.Method__c = 'UpdateDriveShiftProjProc_ProductAndProc';
                debugLog.Error_Description__c = String.valueOf(driveShiftListToUpdate.size());
                debugLog.Error_Description_Long__c = 'driveShift for sked_Total_Products_Projected__c sked_Total_Procedures_Projected__c size ';
                insert debugLog; 
            }
            

            system.debug('map_driveShiftId_driveShiftUpdate '+driveShiftListToUpdate);
            update driveShiftListToUpdate;

        }
    List<sked_Drive__c> driveToBeUpdate = new List<sked_Drive__c>();
        if(this.onlyTotalProcedureUpdateForDrive){
            for(sked_Drive__c drive : driveList) {
                Decimal currentDriveXRBC = drive.sked_2RBC_Projected_Procedures__c != NULL ? drive.sked_2RBC_Projected_Procedures__c : 0;
                Decimal currentDriveWB = drive.sked_WB_Projected_Procedures__c != NULL ? drive.sked_WB_Projected_Procedures__c : 0;
                Decimal currentDrivePlatelet = drive.sked_Platelet_Projected_Procedures__c != NULL ? drive.sked_Platelet_Projected_Procedures__c : 0;
                Decimal currentDrivePlasma = drive.sked_Plasma_Projected_Procedures__c != NULL ? drive.sked_Plasma_Projected_Procedures__c : 0;
                Decimal expectedTotalProcProj = currentDriveWB + currentDriveXRBC + currentDrivePlatelet + currentDrivePlasma;
                Decimal expectedTotalProdProj = currentDriveWB + currentDriveXRBC * 2 + currentDrivePlatelet + currentDrivePlasma;
                if(drive.sked_Total_Procedures_Projected__c != expectedTotalProcProj || drive.sked_Total_Products_Projected__c != expectedTotalProdProj) {
                    drive.sked_Total_Products_Projected__c = expectedTotalProdProj;
                    drive.sked_Total_Procedures_Projected__c = expectedTotalProcProj;
                    driveToBeUpdate.add(drive);
                }
            }

            system.debug('driveListToUpdate '+driveToBeUpdate.size());
            if(driveToBeUpdate.size()>0){
                BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                debugLog.ApexClass__c = 'UpdateDriveShiftProjProc_ProductAndProc';
                debugLog.Method__c = 'UpdateDriveShiftProjProc_ProductAndProc';
                debugLog.Error_Description__c = String.valueOf(driveToBeUpdate.size());
                debugLog.Error_Description_Long__c = 'drive for sked_Total_Products_Projected__c sked_Total_Procedures_Projected__c size ';
                insert debugLog; 
            }
            

            system.debug('map_driveShiftId_driveShiftUpdate '+driveToBeUpdate);
            update driveToBeUpdate;

        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}

/*

___________
Run one by one and mark as done expacted record and time mention in when run in ProdCopy

///////
Mobile drive shift update 
Projected Value
/////

1)
Date date1 = Date.newInstance(2023,01,30);
Date date2 = Date.newInstance(2023,06,01);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);

678

9/23/2024 10:53 AM

9/23/2024 10:59 AM

2)


Date date1 = Date.newInstance(2023,06,02);
Date date2 = Date.newInstance(2023,12,31);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);

1133

9/23/2024 11:00 AM

9/23/2024 11:11 AM
	
	
3)


Date date1 = Date.newInstance(2024,01,01);
Date date2 = Date.newInstance(2024,06,01);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);

842

9/23/2024 11:12 AM

9/23/2024 11:19 AM

4)


Date date1 = Date.newInstance(2024,06,02);
Date date2 = Date.newInstance(2024,09,23);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);

649

9/23/2024 11:22 AM

9/23/2024 11:33 AM

______________________________________________________________________________________-
mobile future


5)

Date date1 = Date.newInstance(2024,09,23);
Date date2 = Date.newInstance(2060,10,15);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);


1448

9/30/2024 4:38 AM

9/30/2024 4:47 AM




______________________________________________________________________________________-

Mobile Drive shift Total projected and product

1)


Date date1 = Date.newInstance(2023,01,30);
Date date2 = Date.newInstance(2023,12,31);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
Database.executeBatch(batchObject,100);

1810

9/23/2024 11:41 AM

9/23/2024 12:41 PM

2)

Date date1 = Date.newInstance(2024,01,01);
Date date2 = Date.newInstance(2024,09,23);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
Database.executeBatch(batchObject,100);


1490

9/23/2024 12:43 PM


9/23/2024 12:59 PM

______________________________________________________________________________________-

Mobile Total projected Furture


Date date1 = Date.newInstance(2024,09,23);
Date date2 = Date.newInstance(2060,10,15);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
Database.executeBatch(batchObject,100);


1448

9/30/2024 5:29 AM

9/30/2024 5:54 AM


______________________________________________________________________________________-



Fixed Site projected procedure


1)

Date date1 = Date.newInstance(2023,01,30);
Date date2 = Date.newInstance(2023,12,31);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);

448

9/23/2024 1:05 PM


9/23/2024 1:25 PM

2)

Date date1 = Date.newInstance(2024,01,01);
Date date2 = Date.newInstance(2024,09,23);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);

486


9/23/2024 1:28 PM

9/23/2024 1:49 PM

______________________________________________________________________________________-


Fixed site future


3)

Date date1 = Date.newInstance(2024,09,23);
Date date2 = Date.newInstance(2060,10,15);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = true;
Boolean onlyTotalProcedureUpdate = false;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate);
Database.executeBatch(batchObject,100);



568

9/30/2024 6:03 AM


9/30/2024 6:12 AM

______________________________________________________________________________________-



Fixed Site Drive shift total proc and product




1)

Date date1 = Date.newInstance(2023,01,30);
Date date2 = Date.newInstance(2023,12,31);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
Database.executeBatch(batchObject,100);


448

9/23/2024 1:53 PM


9/23/2024 2:07 PM

2)



Date date1 = Date.newInstance(2024,01,01);
Date date2 = Date.newInstance(2024,09,23);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
Database.executeBatch(batchObject,100);



486


9/23/2024 2:08 PM


9/23/2024 2:17 PM

______________________________________________________________________________________-


Fixed site future


3)



Date date1 = Date.newInstance(2024,09,23);
Date date2 = Date.newInstance(2060,10,15);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate);
Database.executeBatch(batchObject,100);


568

9/30/2024 6:15 AM


9/30/2024 6:18 AM


______________________________________________________________________________________-


Mobile drive total proc amnd total product update




Date date1 = Date.newInstance(2023,01,30);
Date date2 = Date.newInstance(2024,09,23);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = false;
Boolean onlyTotalProcedureUpdateForDrive = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate, onlyTotalProcedureUpdateForDrive);
Database.executeBatch(batchObject,100);


3299
3819


9/27/2024 11:11 AM
9/27/2024 11:31 AM


9/27/2024 11:16 AM
9/27/2024 11:37 AM



______________________________________________________________________________________-


Future Mobile Drive


Date date1 = Date.newInstance(2024,09,23);
Date date2 = Date.newInstance(2060,10,15);
String typeOfDrive = 'Mobile';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = false;
Boolean onlyTotalProcedureUpdateForDrive = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate, onlyTotalProcedureUpdateForDrive);
Database.executeBatch(batchObject,100);


1448


9/30/2024 6:21 AM


9/30/2024 6:25 AM


______________________________________________________________________________________-

Fixed Site

Date date1 = Date.newInstance(2023,01,30);
Date date2 = Date.newInstance(2024,09,23);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = false;
Boolean onlyTotalProcedureUpdateForDrive = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate, onlyTotalProcedureUpdateForDrive);
Database.executeBatch(batchObject,100);


1100
934


9/27/2024 11:26 AM
9/27/2024 12:34 PM	

9/27/2024 11:28 AM

______________________________________________________________________________________-


Furture Fixed Site Drive Total Product



Date date1 = Date.newInstance(2024,09,23);
Date date2 = Date.newInstance(2060,10,15);
String typeOfDrive = 'Fixed Site';
Boolean driveShiftUpdate = false;
Boolean onlyTotalProcedureUpdate = false;
Boolean onlyTotalProcedureUpdateForDrive = true;

UpdateDriveShiftProjProc_ProductAndProc batchObject = new UpdateDriveShiftProjProc_ProductAndProc(date1, date2, typeOfDrive, driveShiftUpdate, onlyTotalProcedureUpdate, onlyTotalProcedureUpdateForDrive);
Database.executeBatch(batchObject,100);


568


9/30/2024 6:31 AM


9/30/2024 6:32 AM




*/