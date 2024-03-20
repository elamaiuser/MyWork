public class skedWorkdayPTOReportMock implements HttpCalloutMock {

     public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<env:Body>' +
                '<wd:Report_Data xmlns:wd="urn:com.workday.report/Web_Services_-_EE_Time_Off_Report_Skedulo">' +
                '<wd:Report_Entry>' +
                    '<wd:Time_Off_Completed_Details_group>' +
                    '<wd:Time_Off_Type_for_Time_Off_Entry wd:Descriptor="PTO">' +
                        '<wd:ID wd:type="WID">8a81de01e08310a69be25d4796f0b1d3</wd:ID>' +
                        '<wd:ID wd:type="Time_Off_Type_ID">PTO</wd:ID>' +
                    '</wd:Time_Off_Type_for_Time_Off_Entry>' +
                    '<wd:date>2022-01-01-08:00</wd:date>' +
                    '<wd:Amount>10</wd:Amount>' +
                    '<wd:Reference_ID_Value>TIME_OFF_ENTRY-3-3700575</wd:Reference_ID_Value>' +
                    '</wd:Time_Off_Completed_Details_group>' +
                    '<wd:Time_Off_Completed_Details_group>' +
                    '<wd:Time_Off_Type_for_Time_Off_Entry wd:Descriptor="PTO">' +
                        '<wd:ID wd:type="WID">8a81de01e08310a69be25d4796f0b1d3</wd:ID>' +
                        '<wd:ID wd:type="Time_Off_Type_ID">PTO</wd:ID>' +
                    '</wd:Time_Off_Type_for_Time_Off_Entry>' +
                    '<wd:date>2022-02-01-08:00</wd:date>' +
                    '<wd:Amount>10</wd:Amount>' +
                    '<wd:Reference_ID_Value>TIME_OFF_ENTRY-3-3761979</wd:Reference_ID_Value>' +
                    '</wd:Time_Off_Completed_Details_group>' +
                '</wd:Report_Entry>' +
                '</wd:Report_Data>' +
            '</env:Body>' +
            '</env:Envelope>'
        );
        res.setStatusCode(200);
        return res;
    }
}