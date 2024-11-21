public with sharing class UpdateCollectionOpWebScheduling {
    
    @InvocableMethod(label='getWebScheduleStartDateEndDate')
    public static List<WrapperClass> getWebDates(List<getValues> listOfValues) {
        List<WrapperClass> listOfWrapperClass=new List<WrapperClass>();
        if(listOfValues!=null && !listOfValues.isEmpty()) {          
            GlobalWebSchedulingSettings__mdt globalWebScMetaData=[SELECT Id, Web_Scheduling_End_Date_Offset__c, Web_Scheduling_End_Time_Offset__c,
                                                             Web_Scheduling_Start_Date_Offset__c,Web_Scheduling_Start_Time__c
                                                             FROM GlobalWebSchedulingSettings__mdt   limit 1];
            if(globalWebScMetaData == null){
                return null;
            }
            Date driveDate=listOfValues[0].driveDate;            
            //WebSchedule StartDate Calc
            Date driveDateAddStartDateOffSet=driveDate.addDays(Integer.valueOf(globalWebScMetaData.Web_Scheduling_Start_Date_Offset__c));
            DateTime driveDateAddStartDateOffSetTime=driveDateAddStartDateOffSet;
            String webStartTime=String.valueOf(globalWebScMetaData.Web_Scheduling_Start_Time__c);    
            DateTime webSchStartDate=driveDateAddStartDateOffSetTime.addHours(Integer.valueOf(webStartTime.left(2))).addMinutes(Integer.valueOf(webStartTime.right(2)));
            System.debug('webSchStartDate==='+webSchStartDate);
            
            //WebSchedule EndDate Calc          
            Date driveDateAddEndDateOffSet=driveDate.addDays(Integer.valueOf(globalWebScMetaData.Web_Scheduling_End_Date_Offset__c));
            String[] strTimeSplit = listOfValues[0].endTimeInfo.split(':');
            Time endTime = Time.newInstance( Integer.valueOf(strTimeSplit[0]),Integer.valueOf(strTimeSplit[1]),0,0);			
            Time calculatedEndTime= endTime.addHours(Integer.valueOf(globalWebScMetaData.Web_Scheduling_End_Time_Offset__c));
            DateTime driveDateAddEndDateOffSetTime=driveDateAddEndDateOffSet;
            DateTime webSchEndDate=driveDateAddStartDateOffSetTime.addHours(driveDateAddEndDateOffSetTime.hour()).addMinutes(driveDateAddEndDateOffSetTime.minute());
            System.debug('webSchEndDate==='+webSchEndDate);                       
            
            WrapperClass wp=new WrapperClass();
            wp.webStartDate=webSchStartDate;
            wp.webEndDate=webSchEndDate;
            listOfWrapperClass.add(wp);
        }
        
        return listOfWrapperClass;
    }
    
    public  class getValues {       
        
        @InvocableVariable
        public String endTimeInfo;
        
        @InvocableVariable
        public  Date driveDate;
    } 
    public class WrapperClass {
        @InvocableVariable public DateTime webStartDate;
        @InvocableVariable public DateTime webEndDate;
        
    }
    
    
    
}