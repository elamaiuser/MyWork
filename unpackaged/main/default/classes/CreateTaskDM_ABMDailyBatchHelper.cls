/*
 * 
 * 
 * 
 */

public with sharing class CreateTaskDM_ABMDailyBatchHelper {
    public static map<Id, Id> findABM(List<Opportunity> calenderBuildOppAccList){
        set<Id> accId = new set<Id>();
        map<Id, Id> accIdWithAbmIdMap = new map<Id, Id>();
        for(Opportunity opp: calenderBuildOppAccList){ 
            accId.add(opp.AccountId);
        }            
        list<AccountTeamMember> accTeamMemberList = [SELECT Id, AccountId, UserId, TeamMemberRole,Start_Date__c, End_Date__c 
                                                     FROM AccountTeamMember WHERE AccountId IN : accId AND 
                                                     TeamMemberRole = 'Area Booking Manager' ];
        if(accTeamMemberList.size() > 0){
            for(AccountTeamMember accTm: accTeamMemberList){ 
                if(accTm.Start_Date__c < system.today() && accTm.End_Date__c > system.today()){
                    if(!accIdWithAbmIdMap.values().contains(accTm.UserId))
                        accIdWithAbmIdMap.put(accTm.AccountId, accTm.UserId); 
                }
            }
        }        
        return accIdWithAbmIdMap;
    }
    
    public static list<Date> calculateDate(){
        list<Date> allDates = new Date[2];
        Date finalDate;
        Integer noOfDays;
        Date dateField = system.today();
        Date getTaskCreationDate;
        Date taskDueDate;
        
        Calendar_Build_Setting__mdt cbsm = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
           
        Integer maxDayOfCurrentMonth = Date.daysInMonth(dateField.year(), dateField.month());
        Date lastDateOfMonth = Date.newInstance(dateField.year(), dateField.month(), maxDayOfCurrentMonth);
        finalDate = calculateBusinessDays(lastDateOfMonth , Integer.valueOf(cbsm.Buffer_Days_For_System_Generated__c), 'add');                
        
        getTaskCreationDate = calculateBusinessDays(finalDate, Integer.valueOf(cbsm.Calendar_Build_Review_Days__c), 'minus');                 
        allDates[0] = getTaskCreationDate ;                
        taskDueDate = calculateBusinessDays(finalDate, 1, 'minus');                
        allDates[1] = taskDueDate;                

        return allDates;
    }
    static Date calculateBusinessDays(Date startDate, Integer businessDaysToMinus, String sign)
    {
        Date finalDate = startDate;
        Integer direction = businessDaysToMinus < 0 ? -1 : 1;
        while(businessDaysToMinus != 0)
        {
            if(sign == 'add'){
                finalDate = finalDate.addDays(direction);
            }
            if(sign == 'minus'){
                finalDate = finalDate.addDays(-direction);
            }
            if (!IsWeekend(finalDate))
            {
                businessDaysToMinus -= direction;
            }
        }
        return finalDate;
    }
    static Boolean IsWeekend(Date myDate)
    {
        String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);
    }  
    public static void createTask(list<Date> getAllDates, set<Id> allUserDmAbmId){
        list<Task> taskList = new list<Task>(); 
        System.debug('allUserDmAbmId '+allUserDmAbmId);                           
        for(Id uId: allUserDmAbmId){
            if(uId == null){
                continue;
            }
            Task t = new Task();
            t.Subject='Calendar Build Review';
            t.Status = 'Not Started';
            t.Priority = 'High';
            t.ActivityDate = getAllDates[1];
            t.OwnerId = uId;
            taskList.add(t);                
        }  
        /*if(schema.sobjectType.Task.fields.Subject.isCreateable() && schema.sobjectType.Task.fields.Status.isCreateable() &&
          schema.sobjectType.Task.fields.Priority.isCreateable() && schema.sobjectType.Task.fields.ActivityDate.isCreateable() &&
          schema.sobjectType.Task.fields.OwnerId.isCreateable())
        {}*/
        try{
            system.debug('comes here33##'+taskList);
            Database.insert(taskList,false); 
        }
        catch (Exception e){
            System.debug('Problem creating task due to: ' + e.getMessage());
        }
        
    } 
}