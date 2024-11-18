public class BSFWeeklyStaffingRTVFController {
    public string startDate{get; set;}
    public string endDate{get; set;}
    public string div{get; set;}
    public string reg{get; set;}
    public string dist{get; set;}
    public string coll{get; set;}
    public boolean vfdata{get; set;}

    public BSFWeeklyStaffingRTVFController(){
        Date startDate = Date.Today();
        Date endDate = Date.Today().addDays(Integer.valueof(system.label.DateOffset_for_WeeklyStaff));
        sked_Territory_Collection_Operation__c trCollOp;
        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName();
        Id divisionRecordTypeId = recordTypeMapByName.get('Division').getRecordTypeId();
        Id regionRecordTypeId = recordTypeMapByName.get('ARC Region').getRecordTypeId();
        Id districtRecordTypeId = recordTypeMapByName.get('District').getRecordTypeId();

        List<sked__Resource__c> resource =[SELECT id,
                                                sked__Primary_Region__c,
                                                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                                            FROM sked__Resource__c 
                                            WHERE sked__User__c =:UserInfo.getUserId() 
                                            AND sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c != null
                                            AND sked__Is_Active__c = true LIMIT 1];
        if(!resource.isEmpty()){
            List<sked_Territory_Collection_Operation__c> territoryCollOp = [SELECT Id,
                                                                                sked_Start_Date__c,
                                                                                sked_End_Date__c,
                                                                                sked_Collection_Operation__c, 
                                                                                sked_Collection_Operation__r.Id,
                                                                                sked_Collection_Operation__r.Name,
                                                                                sked_Territory__c, 
                                                                                sked_Territory__r.Id,
                                                                                sked_Territory__r.RecordTypeId,
                                                                                sked_Territory__r.Name,
                                                                                sked_Territory__r.Start_Date__c,
                                                                                sked_Territory__r.End_Date__c,
                                                                                sked_Territory__r.sked_Parent__c, 
                                                                                sked_Territory__r.sked_Parent__r.Id,
                                                                                sked_Territory__r.sked_Parent__r.RecordTypeId,
                                                                                sked_Territory__r.sked_Parent__r.Name,
                                                                                sked_Territory__r.sked_Parent__r.Start_Date__c,
                                                                                sked_Territory__r.sked_Parent__r.End_Date__c,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__c,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Id,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.RecordTypeId,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Name,
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.Start_Date__c, 
                                                                                sked_Territory__r.sked_Parent__r.sked_Parent__r.End_Date__c 
                                                                            FROM sked_Territory_Collection_Operation__c 
                                                                            WHERE sked_Collection_Operation__c = :resource[0].sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c 
                                                                            AND sked_Territory__c != null 
                                                                            AND sked_Territory__r.sked_Parent__c != null 
                                                                            AND sked_Territory__r.sked_Parent__r.sked_Parent__c != null 
                                                                            AND sked_Territory__r.RecordTypeId = :districtRecordTypeId
                                                                            AND sked_Territory__r.sked_Parent__r.RecordTypeId = :regionRecordTypeId
                                                                            AND sked_Territory__r.sked_Parent__r.sked_Parent__r.RecordTypeId = :divisionRecordTypeId
                                                                            AND ((sked_Start_Date__c <= :startDate 
                                                                            AND sked_End_Date__c >= :endDate) 
                                                                            OR (sked_Start_Date__c >= :startDate 
                                                                            AND sked_Start_Date__c < :endDate 
                                                                            AND sked_End_Date__c <= :endDate 
                                                                            AND sked_End_Date__c > :startDate)
                                                                            OR (sked_Start_Date__c <= :endDate 
                                                                            AND sked_Start_Date__c > :startDate 
                                                                            AND sked_End_Date__c > :endDate)
                                                                            OR (sked_Start_Date__c < :startDate 
                                                                            AND sked_End_Date__c <= :endDate 
                                                                            AND sked_End_Date__c > :startDate))];
            for(sked_Territory_Collection_Operation__c tco : territoryCollOp){
                trCollOp = tco;
                break;
            }
        }

        if(trCollOp != null){
            this.vfdata=true;
            this.startDate = string.valueof(startDate);
            this.endDate = string.valueof(endDate);
            this.coll= trCollOp.sked_Collection_Operation__c;
            this.dist= trCollOp.sked_Territory__c;
            this.reg = trCollOp.sked_Territory__r.sked_Parent__c;
            this.div = trCollOp.sked_Territory__r.sked_Parent__r.sked_Parent__c;
        }else{
            this.vfdata=false;
        }
    }
}