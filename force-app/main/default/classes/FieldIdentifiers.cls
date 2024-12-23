/*
 * 
 */ 
global class FieldIdentifiers {
    
    @AuraEnabled
    global Id OppId;
    
    @AuraEnabled
    global Date Drive_Date;

    @AuraEnabled  
    global String Drive_Status; 
    
    @AuraEnabled
    global String Start_Time;
    
    @AuraEnabled
    global String End_Time;
    
    @AuraEnabled
    global String Drive_Site;
    
    @AuraEnabled
    global Integer Anticipated_Registered_Donors;
    
    @AuraEnabled
    global Integer WB_Projected_Procedures;
    
    @AuraEnabled
    global Integer X2RBC_Projected_Procedures;
    
    @AuraEnabled
    global String AnticipatedRegisterDonorChangeReason;
    
    @AuraEnabled
    global String WholeBloodProcedureProjectedChangeReason;
    
    @AuraEnabled
    global String DoubleRedProceduresProjectedChangeReason;
    
    @AuraEnabled
    global Integer Platelet_Projected; //Apheresis_Projected_Units__c//
        
    @AuraEnabled
    global Integer Plasma_Pheresis_Projected; //Other_Projected_Units__c//
    
    @AuraEnabled
    global Integer Number_of_2RBC_Assets;
    
    @AuraEnabled
    global Integer Number_of_Plasma_Assets;
    
    @AuraEnabled
    global Integer Number_of_Platelet_Assets;
    
    @AuraEnabled
    global String Account_Manager;
    
    @AuraEnabled
    global String Cancellation_Reason;
    
    @AuraEnabled
    global Integer Anticipated_Registered_Donors_Template;
    
    @AuraEnabled
    global String Additional_Description; 
    
    @AuraEnabled
    global Id Sked_Drive_Id;
    
    @AuraEnabled
    global String Sked_Cancellation_Reason;
    
    @AuraEnabled
    global String sked_Drive_Owner;
    
    @AuraEnabled 
    global Decimal sked_Historical_Registered_Donors; 
    
    @AuraEnabled 
    global Boolean Is_Recursion_On; 
    
    @AuraEnabled
    global Id Parent_Template_Id;
    
    @AuraEnabled 
    global String driveDateChangeReason;////HRP-12063
    
    @AuraEnabled
    global String StageName;
    
    @AuraEnabled
    global String Initiated_By;
    
    @AuraEnabled 
    global Integer Platelet_Projected_Procedure; //HRP-10514 Platelet_Projected_Procedures__c//
    
    @AuraEnabled 
    global Integer Plasma_Pheresis_Projected_Procedure; //HRP-10659 Plasma_Pheresis_Projected_Procedure__c//

    // HRP-12011 --> Starts Here
    @AuraEnabled 
    global Decimal Slot_Generator;

    @AuraEnabled 
    global String Slot_Generator_Change_Reason;
    // HRP-12011 --> Ends Here
    
    // HRP-13190 --> Starts Here
    @AuraEnabled 
    global Boolean APT_Required; 

    @AuraEnabled 
    global Decimal APT_Quantity;

    @AuraEnabled 
    global String APT_Change_Reason;
    // HRP-13190 --> Ends Here
    
    global Set<String> updatedDataKeys = new Set<string>();
}