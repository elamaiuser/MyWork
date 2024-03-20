public class DateTimeConverter {
    
      static Map<String,Integer> mapOfTimeZones=new Map<String,Integer>();
      static  {
        mapOfTimeZones.put('America/New_York',1);
        mapOfTimeZones.put('America/Chicago',2);
        mapOfTimeZones.put('America/Denver',3);
        mapOfTimeZones.put('America/Los_Angeles',4);  
        
     }    
    public static DateTime convertDateTimeIntoGMT(String timeZoneInfo,Date dateInfo,Time timeInfo){  
        DateTime dateTimeInfo=DateTime.newInstance(dateInfo.year(),dateInfo.month(),dateinfo.day(), timeInfo.hour(),timeInfo.minute(),0);
             Integer userTimeZoneValue=mapOfTimeZones.get(UserInfo.getTimeZone().getId());          
             Integer driveSiteTimeZoneValue=mapOfTimeZones.get(timeZoneInfo);
              System.debug('userTimeZoneValue==='+userTimeZoneValue);
              System.debug('driveSiteTimeZoneValue==='+driveSiteTimeZoneValue);
             if(driveSiteTimeZoneValue!=null && userTimeZoneValue!=null && userTimeZoneValue!=driveSiteTimeZoneValue){
               dateTimeInfo=dateTimeInfo.addhours(driveSiteTimeZoneValue-userTimeZoneValue);
              }
          return dateTimeInfo;
    }

}