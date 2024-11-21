/**This controller has two VF pages.PersonalStaffSchedulereport and PersonalStaffSchedulereport_viewOnly.
* @description: This class is the controller class for PersonalStaffScheduleReport visualforce page.
**   Modification Log  ****
*  Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 07/06/2023			Barnojit Sharma			Populated Timezone field for both Activity and Job allocation in PDF (Logic for HRP-10247)
 * 11/17/2023			Kishore Das				Logic for HRP-11350(Collections staff PTO not displayed on Personal Staff Schedule Lightning report)
 * 05/27/2023			Barnojit Sharma			Event details misaligned & Total hours missing for drive for Personal Staff Schedule Report (Logic for HRP-12745)
 *****************************************************************************************************************************************************************************
*/
public without sharing class PersonalStaffScheduleReportController {
    public List<staffScheduleWrapper> staffScheduleList {get; set;}
    public Integer staffScheduleEndDate {get; set;}
    
    public PersonalStaffScheduleReportController(){
        staffScheduleEndDate = Integer.valueOf(System.Label.Personal_Staff_Schedule_Days);
        Date startDate = System.today();
        Date endDate = System.today() + staffScheduleEndDate;
        staffScheduleWrapper staffSchedule = new staffScheduleWrapper();
        List<staffScheduleWrapper> staffScheduleList2 = new List<staffScheduleWrapper>();
        staffSchedule.availabilityList = new List<sked__Availability__c>();
        List<ActivityRes> activityResList2 = new List<ActivityRes>();
        List<JobAlloc> jobAllocList2 = new List<JobAlloc>();
        List<sObjectWapr> allObjectData = new List<sObjectWapr>();
        List<sObjectWapr> allOrderObjectData = new List<sObjectWapr>();
        
        sked__Resource__c resourceId = [Select Id,sked__User__r.FirstName,sked__User__r.LastName from sked__Resource__c Where sked__User__c =: Userinfo.getUserId()];
        if(resourceId != null){
            List<sked__Availability__c> availabilityList = [Select Id,Name,sked_Start_Date__c,sked_Finish_Date__c,sked_Duration__c,sked__Type__c From sked__Availability__c Where sked__Resource__c =: resourceId.Id AND (sked__Type__c = 'PTO' OR sked__Type__c = 'Sick' OR sked__Type__c = 'Floating Holiday' OR sked__Type__c = 'Bereavement')
                                                            AND sked_Start_Date__c >=: startDate AND sked_Finish_Date__c <=: endDate AND sked__Status__c='Approved' order by sked_Start_Date__c ASC NULLS LAST LIMIT 10]; //Logic for HRP-11350
            
            
            staffSchedule.availabilityList =  availabilityList;
            System.debug('4567# : '+staffSchedule.availabilityList);
            for(sked__Activity_Resource__c actR : [Select Id,sked__Activity__r.Id,sked__Activity__r.Name,sked__Activity__r.sked__Type__c,sked__Activity__r.sked_Subtype__c,sked__Activity__r.sked_Start_Time__c,sked__Activity__r.sked_End_Time__c,
                                                    sked__Activity__r.sked__Timezone__c,  //Timezone field added for HRP-10247
                                                    sked__Activity__r.sked_Activity_Title__c, // Activity Title field added for HRP-12745
                                                   sked__Activity__r.sked__Address__c,sked__Activity__r.sked__Notes__c,sked__Activity__r.sked__Location__r.Name,sked__Activity__r.sked_Start_Date__c,sked__Activity__r.sked_End_Date__c From sked__Activity_Resource__c
                                                   Where sked__Resource__c =: resourceId.Id AND sked__Activity__r.sked_Start_Date__c >=: startDate AND sked__Activity__r.sked_End_Date__c <=: endDate order by sked__Activity__r.sked_Start_Time__c,sked__Activity__r.sked_Start_Date__c ASC NULLS LAST LIMIT 10]) 
            {
                sObjectWapr wrap = new sObjectWapr();
                activityResList2.add(new ActivityRes(actR));
                wrap.ActivityResource = new ActivityRes(actR);
                wrap.isActivityResource=true;
                wrap.isJobAllocation=false;
                wrap.recordDate = actR.sked__Activity__r.sked_Start_Date__c;
                wrap.recordTime = actR.sked__Activity__r.sked_Start_Time__c;
                allObjectData.add(wrap);
                System.debug('4568# : '+wrap);
            }
            System.debug('4569#');
            staffSchedule.activityResList= activityResList2;
            
                for(sked__Job_Allocation__c jobA : [Select Id,sked_Additional_Roles__c,sked_Start_Date__c,sked_Set_End_Date__c,sked_Start_Time__c,sked_Set_End_Time__c,
                                                    sked_Job_Timezone__c,  //Timezone field added for HRP-10247
                                                    sked__Status__c,sked__Job__r.sked__Type__c,sked__Job__r.sked_Drive__r.sked_Drive_Date__c,sked__Job__r.sked_Drive__r.sked_Drive_Site__r.Name,
                                                    sked__Job__r.sked_Drive_Shift__r.sked_Start_Time__c,sked__Job__r.sked_Drive_Shift__r.sked_End_Time__c,sked__Job__r.sked_Drive_Shift__r.Name,
                                                    sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c,sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c,
                                                    sked__Job__r.sked_Dual_Role__c,sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c,sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked__Address__c,
                                                    sked__Job__r.sked_Drive__r.sked_Drive_Site__r.sked_Directions_From_CollectionOperation__c,sked__Job__r.sked_Drive__r.sked_Operation_Notes__c From 
                                                    sked__Job_Allocation__c Where (sked__Status__c = 'Dispatched' OR sked__Status__c = 'Confirmed' OR sked__Status__c = 'En Route'  OR sked__Status__c = 'Checked In'
                                                                                   OR sked__Status__c = 'In Progress' OR sked__Status__c = 'Complete') AND sked__Resource__c =: resourceId.Id 
                                                    AND sked_Start_Date__c >=: startDate AND sked_Set_End_Date__c <=: endDate order by sked_Start_Time__c,sked_Start_Date__c ASC NULLS LAST LIMIT 10])     
                {
                    jobAllocList2.add(new JobAlloc(jobA));
                    sObjectWapr wrap2 = new sObjectWapr();
                    wrap2.JobAllocation = new JobAlloc(jobA);
                    wrap2.isJobAllocation=true;
                    wrap2.isActivityResource=false;
                    wrap2.recordDate = jobA.sked_Start_Date__c;
                    wrap2.recordTime = jobA.sked_Start_Time__c;
                    allObjectData.add(wrap2);
                    System.debug('45610# : '+wrap2);
                }
                System.debug('45611#');
            staffSchedule.jobAllocList= jobAllocList2;
            
            sObjectWapr newWrap = new sObjectWapr();
            for(Integer i=0;i<allObjectData.size();i++){
                for(Integer j=i+1;j<allObjectData.size();j++){
                    if(allObjectData[j].recordDate <=allObjectData[i].recordDate){
                            newWrap = allObjectData[i];
                            allObjectData[i] = allObjectData[j];
                        allObjectData[j] = newWrap;
                        system.debug('allObjectData[j].recordDate:-'+allObjectData[j].recordDate);
                        system.debug('allObjectData[i].recordDate:-'+allObjectData[i].recordDate);
                        system.debug('allObjectData[j].recordTime:-'+allObjectData[j].recordTime);
                        system.debug('allObjectData[i].recordTime:-'+allObjectData[i].recordTime);
                        if((allObjectData[j].recordDate == allObjectData[i].recordDate) && allObjectData[j].recordTime <allObjectData[i].recordTime){
                            newWrap = allObjectData[i];
                            allObjectData[i] = allObjectData[j];
                            allObjectData[j] = newWrap;
                        }
                        
                    }
                }
            }
            allOrderObjectData = allObjectData;
            staffSchedule.sObjectWapr= allOrderObjectData;
            staffScheduleList2.add(staffSchedule);
            staffScheduleList=staffScheduleList2;
        }
    }
    
    public class staffScheduleWrapper{
        public List<sked__Availability__c> availabilityList{get;set;}
        public List<JobAlloc> jobAllocList{get;set;}
        public List<ActivityRes> activityResList{get;set;}
        public List<sObjectWapr> sObjectWapr{get;set;}
    }
    public class JobAlloc{
        public string formattedStartTime{get;set;}
        public String formattedEndTime{get;set;}
        public String timeDifference{get;set;}
        public string formattedShiftSTime{get;set;}
        public String formattedShiftETime{get;set;}
        public string formattedShiftLunchSTime{get;set;}
        public String formattedShiftLunchETime{get;set;}
        public Decimal lunchBreakCalc{get;set;}
        public sked__Job_Allocation__c allocat{get;set;}
        
        public String getFormattedTime(Integer hour, Integer minutes){
            String st;
            if(hour == 0){
                hour = 12;
                st = ' AM';
            }else if(hour < 12){
                st = ' AM';
            }else if(hour == 12){
                st = ' PM';
            }else if(hour > 12){
                hour = hour - 12;
                st = ' PM';
            }
            if(minutes < 10){
                return hour+':0'+minutes+st;
            }else{
                return hour+':'+minutes+st;
            }
        }
        public JobAlloc(sked__Job_Allocation__c jobAllo) {
            this.allocat = jobAllo;
            if(jobAllo.sked_Start_Time__c != null){
                this.formattedStartTime = this.getFormattedTime(Integer.valueOf(jobAllo.sked_Start_Time__c.hour()),Integer.valueOf(jobAllo.sked_Start_Time__c.minute()));
            }
            else{
                this.formattedStartTime = '';
            }
            system.debug(' this.formattedStartTime:-'+ this.formattedStartTime);
            if(jobAllo.sked_Set_End_Time__c != null){
                this.formattedEndTime = this.getFormattedTime(Integer.valueOf(jobAllo.sked_Set_End_Time__c.hour()),Integer.valueOf(jobAllo.sked_Set_End_Time__c.minute()));
            }
            else{
                this.formattedEndTime = '';
            }
            if(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Start_Time__c != null){
                this.formattedShiftSTime = this.getFormattedTime(Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Start_Time__c.hour()),Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Start_Time__c.minute()));
            }
            else{
                this.formattedShiftSTime = '';
            }
            if(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_End_Time__c != null){
                this.formattedShiftETime = this.getFormattedTime(Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_End_Time__c.hour()),Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_End_Time__c.minute()));
            }
            else{
                this.formattedShiftETime = '';
            }
            if(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c != null){
                this.formattedShiftLunchSTime = this.getFormattedTime(Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c.hour()),Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c.minute()));
            }
            else{
                this.formattedShiftLunchSTime = '';
            }
            if(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c != null){
                this.formattedShiftLunchETime = this.getFormattedTime(Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c.hour()),Integer.valueOf(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c.minute()));
            }
            else{
                this.formattedShiftLunchETime = '';
            }
            /*
            * HRP-12745 changes starts here
            */
            if(jobAllo.sked_Set_End_Time__c != null && jobAllo.sked_Start_Time__c != null){
                long timeDef = (jobAllo.sked_Set_End_Time__c.hour()*60 +jobAllo.sked_Set_End_Time__c.minute()) - (jobAllo.sked_Start_Time__c.hour()*60 +jobAllo.sked_Start_Time__c.minute());
                long hours = timeDef /60;
                long remainingMins = timeDef -(hours*60);
                this.timeDifference = String.valueOf(hours) + '.' + String.valueOf(remainingMins);
            }
            /*
            * HRP-12745 changes ends here
            */
            if(jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c != null && jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c != null && jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Duration__c != null){
                long timeDef = (jobAllo.sked_Set_End_Time__c.hour()*60 +jobAllo.sked_Set_End_Time__c.minute()) - (jobAllo.sked_Start_Time__c.hour()*60 +jobAllo.sked_Start_Time__c.minute());
                long hours = timeDef /60;
                long remainingMins = timeDef -(hours*60);
                //this.timeDifference = String.valueOf(hours) + '.' + String.valueOf(remainingMins); // commented for HRP-12745
                long lunchTimeDiff = (jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c.hour()*60 +jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_End_Time__c.minute()) - (jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c.hour()*60 +jobAllo.sked__Job__r.sked_Drive_Shift__r.sked_Lunch_Break_Start_Time__c.minute());
                long lunchhours = lunchTimeDiff /60;
                long remainingLunchMins = lunchTimeDiff -(lunchhours*60);
                String lunchbrkDiff = String.valueOf(lunchhours) + '.' + String.valueOf(remainingLunchMins);
                Decimal totalHrsCalc = (hours*60 + remainingMins) - (lunchhours*60 + remainingLunchMins);
                this.lunchBreakCalc = ((totalHrsCalc)/60).setScale(2);
            }
        }
    }
    public class ActivityRes{
        public string formattedStartTime{get;set;}
        public String formattedEndTime{get;set;}
        public String timeDifference{get;set;}
        public sked__Activity_Resource__c act{get;set;}
        public String getFormattedTime(Integer hour, Integer minutes){
            String st;
            if(hour == 0){
                hour = 12;
                st = ' AM';
            }else if(hour < 12){
                st = ' AM';
            }else if(hour == 12){
                st = ' PM';
            }else if(hour > 12){
                hour = hour - 12;
                st = ' PM';
            }
            if(minutes < 10){
                return hour+':0'+minutes+st;
            }else{
                return hour+':'+minutes+st;
            }
        }
        public ActivityRes(sked__Activity_Resource__c actRes){
            this.act = actRes;
            if(actRes.sked__Activity__r.sked_Start_Time__c != null){
                this.formattedStartTime = this.getFormattedTime(Integer.valueOf(actRes.sked__Activity__r.sked_Start_Time__c.hour()),Integer.valueOf(actRes.sked__Activity__r.sked_Start_Time__c.minute()));  
            }
            else{
                this.formattedStartTime = '';
            }
            if(actRes.sked__Activity__r.sked_End_Time__c != null){
                this.formattedEndTime = this.getFormattedTime(Integer.valueOf(actRes.sked__Activity__r.sked_End_Time__c.hour()),Integer.valueOf(actRes.sked__Activity__r.sked_End_Time__c.minute()));
            }
            else{
                this.formattedEndTime = '';
            }
            if(actRes.sked__Activity__r.sked_End_Time__c != null && actRes.sked__Activity__r.sked_Start_Time__c != null){
                date startDate = actRes.sked__Activity__r.sked_Start_Date__c;
                date dueDate = actRes.sked__Activity__r.sked_End_Date__c;
                integer numberofDays = startDate.daysBetween(dueDate);
                Integer timeinminutes= (numberofDays)*24*60;
                long timeDef = (actRes.sked__Activity__r.sked_End_Time__c.hour()*60 +actRes.sked__Activity__r.sked_End_Time__c.minute()) - (actRes.sked__Activity__r.sked_Start_Time__c.hour()*60 +actRes.sked__Activity__r.sked_Start_Time__c.minute());
                long hours = timeDef /60;
                long remainingMins = timeDef -(hours*60); 
                this.timeDifference = String.valueOf(hours) + '.' + String.valueOf(remainingMins);
                system.debug('test for timedef===>'+this.timeDifference);

                integer timediff;
                if(startDate!=dueDate){
                    timeDef=timeinminutes + timeDef ;
                    hours = timeDef /60;
                    remainingMins = timeDef -(hours*60); 
                    this.timeDifference = String.valueOf(hours) + '.' + String.valueOf(remainingMins);
                    system.debug('test for timedef===>'+this.timeDifference);
                   // this.timeDifference=String.valueOf((timediff-(-hours))) + '.' + String.valueOf(remainingMins);
                }
             
            }
            else{
                this.timeDifference = null;
            }
        }
    }
    public class sObjectWapr{
        public ActivityRes ActivityResource {get;set;}
        public JobAlloc JobAllocation {get;set;}
        public boolean isActivityResource {get;set;}
        public boolean isJobAllocation {get;set;}
        public date recordDate {get;set;}
        public Time recordTime {get;set;}
    }
}