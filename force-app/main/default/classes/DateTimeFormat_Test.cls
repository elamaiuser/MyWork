/*The following test class has covered the following class
 DateTimeFormat*/

@isTest
public class DateTimeFormat_Test {
@isTest
     static void testFormatDateTime() {
        // Create a list of DateTime objects to test
        List<DateTime> dateTimeList = new List<DateTime>();
        dateTimeList.add(DateTime.newInstance( 5, 12 , 2023, 13, 30, 0));
        dateTimeList.add(DateTime.newInstance( 5, 13, 2023, 9, 0, 0));
        
        // Call the formatDateTime method and verify the output
        List<String> formattedDateTimeList = DateTimeFormat.formatDateTime(dateTimeList);
       // System.assertEquals('06-15-0011  13:30:00', formattedDateTimeList[0]);
         System.assertEquals('06/15/0011 13:30:00', formattedDateTimeList[0]);
        System.assertEquals('07/16/0011 09:00:00', formattedDateTimeList[1]);
    }

}