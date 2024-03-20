/*The following test class has covered the following class
 DateTimeConverter*/

@isTest
public class DateTimeConverter_Test {
    
    public static Date myDate = Date.newInstance(2022, 7, 24);
	public static Time myTime = Time.newInstance(1, 2, 3, 4);
    public static DateTime actual = DateTime.newInstance(myDate.year(), myDate.month(), myDate.day(), 
                                                           myTime.hour(), myTime.minute(), 0);
     
 @isTest static void testMethodToConvertDateTimeIntoGMT() {
   		DateTime result = DateTimeConverter.convertDateTimeIntoGMT('America/Los_Angeles', myDate, myTime);
     	system.assertEquals(result, actual.addHours(3));
     
   }
}