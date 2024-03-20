public class skedWorkdayPTOBalanceMock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<wd:Report_Data xmlns:wd="urn:com.workday.report/Web_Services_Time_Off_Balances_Skedulo">' +
                '<wd:Report_Entry>' +
                    '<wd:Eligible_Time_Off_Plans_for_Worker_group>' +
                        '<wd:time_off_plan wd:Descriptor="Floating Holiday - CA">' +
                            '<wd:ID wd:type="Absence_Plan_ID">Floating Holiday - CA</wd:ID>' +
                        '</wd:time_off_plan>' +
                        '<wd:accrual_ytd>40</wd:accrual_ytd>' +
                        '<wd:time_off_ytd>0</wd:time_off_ytd>' +
                        '<wd:beg_period_bal>28</wd:beg_period_bal>' +
                        '<wd:accural_in_per>0</wd:accural_in_per>' +
                        '<wd:time_paid_period>0</wd:time_paid_period>' +
                        '<wd:balance>28</wd:balance>' +
                        '<wd:visible_bal>1</wd:visible_bal>' +
                    '</wd:Eligible_Time_Off_Plans_for_Worker_group>' +
                    '<wd:Eligible_Time_Off_Plans_for_Worker_group>' +
                    '<wd:time_off_plan wd:Descriptor="PTO - 7 Day Lag">' +
                        '<wd:ID wd:type="WID">8a81de01e08310a6d89d396076d2dfa9</wd:ID>' +
                        '<wd:ID wd:type="Absence_Plan_ID">PTO - 7 Day Lag</wd:ID>' +
                    '</wd:time_off_plan>' +
                    '<wd:accrual_ytd>9.23</wd:accrual_ytd>' +
                    '<wd:time_off_ytd>0</wd:time_off_ytd>' +
                    '<wd:beg_period_bal>290.88</wd:beg_period_bal>' +
                    '<wd:accural_in_per>9.23</wd:accural_in_per>' +
                    '<wd:time_paid_period>0</wd:time_paid_period>' +
                    '<wd:balance>300.11</wd:balance>' +
                    '<wd:visible_bal>1</wd:visible_bal>' +
                    '</wd:Eligible_Time_Off_Plans_for_Worker_group>' +
                    '<wd:as_of_date>2022-12-31-08:00</wd:as_of_date>' +
                '</wd:Report_Entry>' +
            '</wd:Report_Data>'
        );
        res.setStatusCode(200);
        return res;
    }
}