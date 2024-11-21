/********************************************************************************************
@ Component Name : DateTimeFormat 
@ Developed By: Ankit Kundu
@ purpose: It will populate in the Change reason fields on mass update opportunity modal.

**********************************************************************************************
Story               Date                Modified by             Description
==============================================================================================
HRP - 6231       05/12/2023             Ankit Kundu                HRP-6231

**********************************************************************************************/
public class DateTimeFormat
{
    @InvocableMethod(label='Format DateTime')
    public static List<String> formatDateTime(List<DateTime> dateTimeList)
    {
        List<String> formattedDateTimeList = new List<String>();
        
        // Iterate through the input DateTime list
        for (DateTime dt : dateTimeList)
        {
            // Use the format method to format the DateTime object
            String formattedDt = dt.format('MM/dd/yyyy HH:mm:ss');
            
            // Add the formatted DateTime string to the output list
            formattedDateTimeList.add(formattedDt);
        }
        
        // Return the formatted DateTime string list
        return formattedDateTimeList;
    }
}