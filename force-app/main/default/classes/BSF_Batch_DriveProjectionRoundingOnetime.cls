global with sharing class BSF_Batch_DriveProjectionRoundingOnetime
implements Database.Batchable<SObject>, Database.Stateful  {
    
    global Decimal tolerance;
    global System.RoundingMode roundingMode;
    global Date driveDateOffset;
   
    global BSF_Batch_DriveProjectionRoundingOnetime() {
        Drive_Projection_Rounding_Config__mdt config =
            Drive_Projection_Rounding_Config__mdt.getInstance('Default');
        
        this.tolerance =
            (config.Tolerance__c != null) ? config.Tolerance__c : 1;
        
        this.roundingMode =
            (config.Rounding_Mode__c != null)
            ? System.RoundingMode.valueOf(config.Rounding_Mode__c)
            : System.RoundingMode.HALF_UP;
        
        if(config.Drive_Date_Offset__c != null)
        {
            Integer daysOffset = Integer.valueOf(config.Drive_Date_Offset__c);
            // Calculate date
            driveDateOffset = Date.today().addDays(-daysOffset);
            System.debug('driveDateOffset'+driveDateOffset);
        }
       
        
        
    }
    
    /* ================= START ================= */
    // Get the templates
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id,
            Anticipated_Registered_Donors__c,
            WB_Projected_Procedures__c,
            X2RBC_Projected_Procedures__c
            FROM Opportunity 
            WHERE Is_Template__c = true 
        ]);
    }
    
    /* ================= EXECUTE ================= */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<Opportunity> templates = (List<Opportunity>) scope;
            //  Round off template values
            Map<Id, Opportunity> templateMap = new Map<Id, Opportunity>();
            Set<Id> templateIds = new Set<Id>();
            List<Opportunity> oppTemplToUpdate = new List<Opportunity>();
            
            for (Opportunity tmpl : templates) {
                Boolean isUpdated = false;
                // Anticipated Registered Donors
                if (tmpl.Anticipated_Registered_Donors__c != null && tmpl.Anticipated_Registered_Donors__c != Math.floor(tmpl.Anticipated_Registered_Donors__c)) {
                    
                    tmpl.Anticipated_Registered_Donors__c = tmpl.Anticipated_Registered_Donors__c.setScale(0, this.roundingMode);
                    isUpdated = true;
                }
                
                // WB Projected Procedures
                if (tmpl.WB_Projected_Procedures__c != null &&  tmpl.WB_Projected_Procedures__c != Math.floor(tmpl.WB_Projected_Procedures__c)) {
                    
                    tmpl.WB_Projected_Procedures__c = tmpl.WB_Projected_Procedures__c.setScale(0, this.roundingMode);
                    isUpdated = true;
                }
                
                // 2RBC Projected Procedures
                if (tmpl.X2RBC_Projected_Procedures__c != null && tmpl.X2RBC_Projected_Procedures__c != Math.floor(tmpl.X2RBC_Projected_Procedures__c)) {
                    
                    tmpl.X2RBC_Projected_Procedures__c = tmpl.X2RBC_Projected_Procedures__c.setScale(0, this.roundingMode);
                    isUpdated = true;
                }
                if (isUpdated) {
                    oppTemplToUpdate.add(tmpl);
                }
                
                templateMap.put(tmpl.Id, tmpl);
                templateIds.add(tmpl.Id);
           
                
            }
            
            
            if(oppTemplToUpdate.size() >0){
                Database.Update(oppTemplToUpdate,false);
            }
            
            //opportunity
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<Opportunity> opp = [SELECT Id,
                                     Anticipated_Registered_Donors__c,
                                     WB_Projected_Procedures__c,
                                     X2RBC_Projected_Procedures__c,
                                     Parent_Template_Id__c,StageName
                                     FROM Opportunity
                                     WHERE Parent_Template_Id__c IN :templateIds
                                  AND Drive_Date__c >=: driveDateOffset
                                    ];
            
            
            for (Opportunity o : opp) {
                Boolean isUpdated = false;
                Opportunity tmpl = templateMap.get(o.Parent_Template_Id__c);
                // Template values (same record acts as template source)
                Decimal templateValRD   = tmpl.Anticipated_Registered_Donors__c;
                Decimal templateValWB   = tmpl.WB_Projected_Procedures__c;
                Decimal templateVal2RBC = tmpl.X2RBC_Projected_Procedures__c;
                
                // Current opportunity values
                Decimal oppValRD   = o.Anticipated_Registered_Donors__c;
                Decimal oppValWB   = o.WB_Projected_Procedures__c;
                Decimal oppVal2RBC = o.X2RBC_Projected_Procedures__c;
                
                // Differences
                Decimal diffRD   = Math.abs(oppValRD - templateValRD);
                Decimal diffWB   = Math.abs(oppValWB - templateValWB);
                Decimal diff2RBC = Math.abs(oppVal2RBC - templateVal2RBC);
                
                /* ================= Projected Registered Donors ================= */
                if (oppValRD != null && oppValRD != Math.floor(oppValRD)) {
                    if (diffRD < this.tolerance) {
                        
                        o.Anticipated_Registered_Donors__c = templateValRD.setScale(0, this.roundingMode);
                        o.AnticipatedRegisterDonorChangeReason__c = 'Systematic Value Rounding';
                        isUpdated = true;
                        
                        
                    }
                    else {
                        o.Anticipated_Registered_Donors__c =  oppValRD.setScale(0, this.roundingMode);
                        o.AnticipatedRegisterDonorChangeReason__c = 'Systematic Value Rounding';
                        isUpdated = true;
                        
                    }
                    
                }
                
                /* ================= WB Projected Procedures ================= */
                if (oppValWB != null && oppValWB != Math.floor(oppValWB)) {
                    if (diffWB < this.tolerance) {
                        o.WB_Projected_Procedures__c = templateValWB.setScale(0, this.roundingMode);
                        o.WholeBloodProcedureProjectedChangeReason__c = 'Systematic Value Rounding';  
                        isUpdated = true;
                        
                    } else {
                        o.WB_Projected_Procedures__c = oppValWB.setScale(0, this.roundingMode);
                        o.WholeBloodProcedureProjectedChangeReason__c = 'Systematic Value Rounding'; 
                        isUpdated = true;
                        
                    }
                }
                
                /* ================= 2RBC Projected Procedures ================= */
                if (oppVal2RBC != null && oppVal2RBC != Math.floor(oppVal2RBC)) {
                    if (diff2RBC < this.tolerance) {
                        o.X2RBC_Projected_Procedures__c = templateVal2RBC.setScale(0, this.roundingMode);
                        o.DoubleRedProceduresProjectedChangeReason__c = 'Systematic Value Rounding';
                        isUpdated = true;
                        
                    } else {
                        o.X2RBC_Projected_Procedures__c =  oppVal2RBC.setScale(0, this.roundingMode);
                        o.DoubleRedProceduresProjectedChangeReason__c = 'Systematic Value Rounding';
                        isUpdated = true;
                        
                    }
                }
                
                if (isUpdated) {
                    oppsToUpdate.add(o);
                }
                
            }
            
            /* ================= UPDATE ================= */
            if (!oppsToUpdate.isEmpty()) {
               
                Database.update(oppsToUpdate, false);
                
            
            }
        } catch (Exception ex) {
            Database.insert(
                new BSF_Error_Log__c[]{
                    BSF_Utilities.createBsfErrorLogForExceptions(
                        ex,
                        'DriveProjectionRoundingBatch',
                        'Execute',
                        'Error',
                        'DriveProjectionRoundingBatch failed',
                        'sked_Drive__c',
                        null
                    )
                        },
                false
            );
        }
    }
    
    /* ================= FINISH ================= */
    global void finish(Database.BatchableContext bc) {
        
    }
}