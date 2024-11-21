trigger AccountContactRoleTrigger on AccountContactRoleChangeEvent (after insert) {

    /*set<id> acrIDs = new set<id>();
    
    for(AccountContactRoleChangeEvent e : trigger.new){
        EventBus.ChangeEventHeader changeEventHeader = e.ChangeEventHeader;
        system.debug('--->changeEventHeader'+changeEventHeader);
        //Checking if the if the record is created or updated
        if(changeEventHeader.changetype == 'CREATE' || changeEventHeader.changetype == 'UPDATE'){
            if(changeEventHeader.getRecordIds().size()==1){
                acrIDs.add(changeEventHeader.getRecordIds()[0]);
            }
        }
        
    }
    
    if(acrIDs.size()>0) {
        OpportunityService.setCallListRecipientFlag(acrIDs);
    }*/
        
}