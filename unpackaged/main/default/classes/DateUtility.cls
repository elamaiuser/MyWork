public class DateUtility {

    public class ReturnValue {
        @AuraEnabled
        public List<Date> returnValue;
        @AuraEnabled
        public boolean operationStatus = true;
        @AuraEnabled 
        public string errorMessage;
    }

    @AuraEnabled(cacheable=true)
    public static ReturnValue getRecurrenceDate(string startDate, string endDate, string recurrenceType, string weeklyRecurrence, string daysOfWeek, string occurance, string monthlyRecurrence, string dayOfMonth){
        if (String.isBlank(recurrenceType) || recurrenceType == 'weekly') {
            system.System.debug('DateUtility.getRecurrenceDate() - Calling getWeeklyRecurrenceDate(startDate: '+ startDate +' , endDate: '+ endDate +' , weeklyRecurrence: '+ weeklyRecurrence +' , daysOfWeek: '+ daysOfWeek +' )');
            return DateUtility.getWeeklyRecurrenceDate(startDate, endDate, weeklyRecurrence, daysOfWeek);
        } else {
            system.System.debug('DateUtility.getRecurrenceDate() - Calling getMonthlyRecurrenceDate(startDate: '+ startDate +' , endDate: '+ endDate +' , occurance: '+ occurance +' , monthlyRecurrence: '+ monthlyRecurrence +' , dayOfMonth: '+ dayOfMonth +' )');
            return DateUtility.getMonthlyRecurrenceDate(startDate, endDate, occurance, monthlyRecurrence, dayOfMonth);
        }
    }

    @AuraEnabled(cacheable=true)
    public static ReturnValue getWeeklyRecurrenceDate(string startDate, string endDate, string weeklyRecurrence, string daysOfWeek){
        
        ReturnValue finalResults = new ReturnValue();
        List<Date> returnValue = new List<Date>();

        try{
            Date dtStartDate = Date.valueOf(startDate);
            DateTime dtStartDateTime = DateTime.newInstanceGmt(dtStartDate, Time.newInstance(0,0,0,0));

            Date dtEndDate = Date.valueOf(endDate);
            DateTime dtEndDateTime = DateTime.newInstanceGmt(dtEndDate, Time.newInstance(0,0,0,0));

            Integer noOfDays= dtStartDate.daysBetween(dtEndDate);

            Integer intWeekRecur = Integer.valueOf(weeklyRecurrence);
            Integer incrementBy = 7 * intWeekRecur;

            List<DateTime> startDateList = new List<DateTime>();

            Datetime nextDateTime;
            string dayofNextDate;

            for(Integer i=0; i<=6; i++) {
                system.System.debug('DateUtility.getWeeklyRecurrenceDate() - Preparing startDateList');
                nextDateTime = dtStartDateTime.addDays(i);
                dayofNextDate = nextDateTime.formatGMT('u');
                if(nextDateTime <= dtEndDateTime && 
                    ((dayofNextDate == '1' && daysOfWeek.indexOfIgnoreCase('MON') != -1)
                    || (dayofNextDate == '2' && daysOfWeek.indexOfIgnoreCase('TUE') != -1)
                    || (dayofNextDate == '3' && daysOfWeek.indexOfIgnoreCase('WED') != -1)
                    || (dayofNextDate == '4' && daysOfWeek.indexOfIgnoreCase('THU') != -1)
                    || (dayofNextDate == '5' && daysOfWeek.indexOfIgnoreCase('FRI') != -1)
                    || (dayofNextDate == '6' && daysOfWeek.indexOfIgnoreCase('SAT') != -1)
                    || (dayofNextDate == '7' && daysOfWeek.indexOfIgnoreCase('SUN') != -1))
                ){
                    system.System.debug('DateUtility.getWeeklyRecurrenceDate() - Preparing dayofNextDate : ' + dayofNextDate);
                    system.System.debug('DateUtility.getWeeklyRecurrenceDate() - Preparing nextDateTime : ' + nextDateTime);
                    startDateList.add(nextDateTime);
                    returnValue.add(nextDateTime.dateGMT());
                }
            }
            system.System.debug('DateUtility.getWeeklyRecurrenceDate() - startDateList : ' + startDateList.tostring());

            Integer i = 1;
            while (nextDateTime <= dtEndDateTime) {

                for (Datetime dt : startDateList){
                    nextDateTime = dt.addDays(i*incrementBy);
                    system.System.debug('DateUtility.getWeeklyRecurrenceDate() - Incrementing startDateList : ' + i*incrementBy);
                    system.System.debug('DateUtility.getWeeklyRecurrenceDate() - nextDateTime : ' + nextDateTime);
                    if(nextDateTime <= dtEndDateTime){
                        returnValue.add(nextDateTime.dateGMT());
                    }else{
                        system.System.debug('DateUtility.getWeeklyRecurrenceDate() - Exiting ForLoop');
                        break;
                    }
                }
                i++;
            }

            finalResults.operationStatus = true;
            finalResults.returnValue = returnValue;
            system.System.debug('DateUtility.getWeeklyRecurrenceDate() - returnValue : ' + returnValue.tostring());
            system.System.debug('DateUtility.getWeeklyRecurrenceDate() - finalResults : ' + finalResults.tostring());               

        } catch (Exception e) {
            finalResults.operationStatus = false;
            finalResults.returnValue = null;
            finalResults.errorMessage = e.getMessage();
            system.System.debug('DateUtility.getWeeklyRecurrenceDate() - finalResults.errorMessage : ' + finalResults.errorMessage);  
            //throw new AuraHandledException(e.getMessage());
        }

        return finalResults;
    }


    @AuraEnabled(cacheable=true)
    public static ReturnValue getMonthlyRecurrenceDate(string startDate, string endDate, string occurance, string monthlyRecurrence, string dayOfMonth){
        ReturnValue finalResults = new ReturnValue();
        List<Date> returnValue = new List<Date>();
        DateTime monthDayValue;

        try{

            Date dtStartDate = Date.valueOf(startDate);
            DateTime dtStartDateTime = DateTime.newInstanceGmt(dtStartDate, Time.newInstance(0,0,0,0));            

            Date dtEndDate = Date.valueOf(endDate);
            DateTime dtEndDateTime = DateTime.newInstanceGmt(dtEndDate, Time.newInstance(0,0,0,0));

            Integer noOfDays= dtStartDate.daysBetween(dtEndDate);

            Integer intMonthlyRecur = Integer.valueOf(monthlyRecurrence);

            Integer intOccurance = Integer.valueOf(occurance);
            
            DateTime dtCurrentDateTime = dtStartDateTime;
            
            while (getMonthLastDay(dtCurrentDateTime) <= getMonthLastDay(dtEndDateTime)) {

                if(dayOfMonth.equalsIgnoreCase('DAY') || dayOfMonth.equalsIgnoreCase('WEEKDAY') || dayOfMonth.equalsIgnoreCase('WEEKEND')){
                    // for out-layer patterns
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - calling getSpecificMonthDays() : ' + dayOfMonth);
                    monthDayValue = getSpecificMonthDays(dtCurrentDateTime, dayOfMonth, intOccurance);
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - getSpecificMonthDays() monthDayValue : ' + monthDayValue);
                } else {
                    // for day of week month patterns
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - calling getDayOccuranceInMonth() : ' + dayOfMonth);
                    monthDayValue = getDayOccuranceInMonth(dtCurrentDateTime, dayOfMonth, intOccurance);
                    
                }

                if(monthDayValue >= dtStartDateTime && monthDayValue <= dtEndDateTime){
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - monthDayValue added to output : ' + monthDayValue);
                    returnValue.add(monthDayValue.dateGMT());
                } else {
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - monthDayValue out of range : ' + monthDayValue);
                }

                if(getMonthLastDay(dtCurrentDateTime) != null && getMonthLastDay(dtCurrentDateTime) >= getMonthLastDay(dtEndDateTime)){
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - monthDayValue exceeded end date : ' + monthDayValue);
                    break;
                }

                dtCurrentDateTime = dtCurrentDateTime.addMonths(intMonthlyRecur);
            }


            finalResults.operationStatus = true;
            finalResults.returnValue = returnValue;
            system.System.debug('DateUtility.getMonthlyRecurrenceDate() - returnValue : ' + returnValue.tostring());
            system.System.debug('DateUtility.getMonthlyRecurrenceDate() - finalResults : ' + finalResults.tostring());               

        } catch (Exception e) {
            finalResults.operationStatus = false;
            finalResults.returnValue = null;
            finalResults.errorMessage = e.getMessage();
            system.System.debug('DateUtility.getMonthlyRecurrenceDate() - finalResults.errorMessage : ' + finalResults.errorMessage + ' | LINE NUM : '+ e.getLineNumber() + ' | STACK TRACE : ' + e.getStackTraceString());  
            //throw new AuraHandledException(e.getMessage());
        }

        return finalResults;
    }


    private static DateTime getDayOccuranceInMonth(DateTime dateValue, string dayOfMonth, Integer intOccurance){

        system.System.debug('DateUtility.getDayOccuranceInMonth() - Start');
        DateTime monthFirstDay = datetime.newInstanceGmt(dateValue.date().year(), dateValue.date().month(), 1);
        DateTime monthLastDay = getMonthLastDay(dateValue);
        DateTime weekStart;
        DateTime weekEnd;

        string dayofNextDate;
        DateTime nextDateTime;
        Integer weekStartOffset = 1;
        Integer weekEndOffset = 7;

        if(intOccurance > 0){
            weekEndOffset = weekEndOffset * intOccurance;
        } else {
            weekEndOffset = Date.daysInMonth(dateValue.date().year(), dateValue.date().month());
        }
        system.System.debug('DateUtility.getDayOccuranceInMonth() - weekEndOffset : ' + weekEndOffset);

        weekStartOffset = weekEndOffset - 6;
        system.System.debug('DateUtility.getDayOccuranceInMonth() - weekStartOffset : ' + weekStartOffset);        

        weekStart = datetime.newInstanceGmt(dateValue.date().year(), dateValue.date().month(), weekStartOffset);
        system.System.debug('DateUtility.getDayOccuranceInMonth() - weekStart : ' + weekStart);

        weekEnd = datetime.newInstanceGmt(dateValue.date().year(), dateValue.date().month(), weekEndOffset);        
        system.System.debug('DateUtility.getDayOccuranceInMonth() - weekEnd : ' + weekEnd);

        for(Integer i=0; i<=6; i++) {
            
            nextDateTime = weekStart.addDays(i);
            system.System.debug('DateUtility.getDayOccuranceInMonth() - nextDateTime : ' + nextDateTime);

            dayofNextDate = nextDateTime.formatGMT('u');
            system.System.debug('DateUtility.getDayOccuranceInMonth() - dayofNextDate : ' + dayofNextDate);
            system.System.debug('DateUtility.getDayOccuranceInMonth() - dayOfMonth : ' + dayOfMonth);

            if ((dayofNextDate == '1' && dayOfMonth.indexOfIgnoreCase('MON') != -1)
                    || (dayofNextDate == '2' && dayOfMonth.indexOfIgnoreCase('TUE') != -1)
                    || (dayofNextDate == '3' && dayOfMonth.indexOfIgnoreCase('WED') != -1)
                    || (dayofNextDate == '4' && dayOfMonth.indexOfIgnoreCase('THU') != -1)
                    || (dayofNextDate == '5' && dayOfMonth.indexOfIgnoreCase('FRI') != -1)
                    || (dayofNextDate == '6' && dayOfMonth.indexOfIgnoreCase('SAT') != -1)
                    || (dayofNextDate == '7' && dayOfMonth.indexOfIgnoreCase('SUN') != -1)
            ) {
                system.System.debug('DateUtility.getDayOccuranceInMonth() - Hit found for : ' + nextDateTime);
                break;
            }
        }

        return nextDateTime;

    }



    private static DateTime getSpecificMonthDays(DateTime dateValue, string dayOfMonth, Integer intWeelklyOccurane){
        system.System.debug('DateUtility.getSpecificMonthDays() - Start');

        DateTime monthFirstDay = datetime.newInstanceGmt(dateValue.date().year(), dateValue.date().month(), 1);
        DateTime monthLastDay = getMonthLastDay(dateValue);

        DateTime endDate;
        DateTime currentDate;
        Integer incrementFactor = 1;

        if(intWeelklyOccurane < 0){
            //For 'last' series value of Occurance
            currentDate = monthLastDay;
            endDate = monthFirstDay;
            incrementFactor = -1;
        } else {
            currentDate = monthFirstDay;
            endDate = monthLastDay;
            incrementFactor = 1;
        }

        Integer dayCtr = 0;
        Integer weekDayCtr = 0;
        Integer weekEndDayCtr = 0;

        while (endDate != currentDate) {
            system.System.debug('DateUtility.getSpecificMonthDays() - currentDate : ' + currentDate);
            Integer dayOfWeek = Integer.valueOf(currentDate.formatGMT('u'));
            system.System.debug('DateUtility.getSpecificMonthDays() - dayOfWeek : ' + dayOfWeek);

            if(dayOfWeek == 6 || dayOfWeek == 7){
                weekEndDayCtr = weekEndDayCtr + 1;
                dayCtr = dayCtr + 1;
            }else {
                weekDayCtr = weekDayCtr + 1;
                dayCtr = dayCtr + 1;
            }

            if(dayOfMonth.indexOfIgnoreCase('WEEKDAY') == -1 && dayOfMonth.indexOfIgnoreCase('DAY') != -1 && dayCtr == Math.ABS(intWeelklyOccurane)){
                system.System.debug('DateUtility.getSpecificMonthDays() - Match Found on ['+ currentDate +'] for Day : ' + dayCtr);
                break;
            }else if(dayOfMonth.indexOfIgnoreCase('WEEKDAY') != -1 && weekDayCtr == Math.ABS(intWeelklyOccurane)){
                system.System.debug('DateUtility.getSpecificMonthDays() - Match Found on ['+ currentDate +'] for Weekday : ' + weekDayCtr);
                break;
            }else if(dayOfMonth.indexOfIgnoreCase('WEEKEND') != -1 && weekEndDayCtr == Math.ABS(intWeelklyOccurane)){
                system.System.debug('DateUtility.getSpecificMonthDays() - Match Found on ['+ currentDate +'] for Weekend : ' + weekEndDayCtr);
                break;
            }
            currentDate = currentDate.addDays(1*incrementFactor);
        }

        return currentDate;

    }

    private static DateTime getMonthLastDay(DateTime dateValue){

        Integer numberOfDays = Date.daysInMonth(dateValue.date().year(), dateValue.date().month());
        return datetime.newInstanceGmt(dateValue.date().year(), dateValue.date().month(), numberOfDays);

    }

    
    /*
    @AuraEnabled(cacheable=true)
    public static List<Date> getMonthlyRecurrenceDate(string startDate, string endDate, string occurance, string monthlyRecurrence, string dayOfMonth){
        
        ReturnValue finalResults = new ReturnValue();
        List<Date> returnValue = new List<Date>();

        try{

            Date dtStartDate = Date.valueOf(startDate);
            DateTime dtStartDateTime = DateTime.newInstanceGmt(dtStartDate, Time.newInstance(0,0,0,0));

            Date dtEndDate = Date.valueOf(endDate);
            DateTime dtEndDateTime = DateTime.newInstanceGmt(dtEndDate, Time.newInstance(0,0,0,0));

            Integer noOfDays= dtStartDate.daysBetween(dtEndDate);

            Integer intMonthlyRecur = Integer.valueOf(monthlyRecurrence);

            Integer intOccurance = Integer.valueOf(occurance);
            Integer incrementBy = 7;

            List<DateTime> startDateList = new List<DateTime>();

            Datetime nextDateTime;
            string dayofNextDate;

            for(Integer i=0; i<=6; i++) {
                system.System.debug('DateUtility.getMonthlyRecurrenceDate() - Preparing startDateList');
                nextDateTime = dtStartDateTime.addDays(i);
                dayofNextDate = nextDateTime.formatGMT('u');
                if(nextDateTime <= dtEndDateTime && 
                    ((dayofNextDate == '1' && dayOfMonth.indexOfIgnoreCase('MON') != -1)
                    || (dayofNextDate == '2' && dayOfMonth.indexOfIgnoreCase('TUE') != -1)
                    || (dayofNextDate == '3' && dayOfMonth.indexOfIgnoreCase('WED') != -1)
                    || (dayofNextDate == '4' && dayOfMonth.indexOfIgnoreCase('THU') != -1)
                    || (dayofNextDate == '5' && dayOfMonth.indexOfIgnoreCase('FRI') != -1)
                    || (dayofNextDate == '6' && dayOfMonth.indexOfIgnoreCase('SAT') != -1)
                    || (dayofNextDate == '7' && dayOfMonth.indexOfIgnoreCase('SUN') != -1))
                ){
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - Preparing dayofNextDate : ' + dayofNextDate);
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - Preparing nextDateTime : ' + nextDateTime);
                    startDateList.add(nextDateTime);
                    returnValue.add(nextDateTime.dateGMT());
                }
                system.System.debug('DateUtility.getMonthlyRecurrenceDate() - startDateList : ' + startDateList.tostring());
            }
            Integer i = 1;
            month = 1;
            while (nextDateTime <= dtEndDateTime) {

                for (Datetime dt : startDateList){
                    nextDateTime = dt.addDays(i*incrementBy);
                    let nextWeekDateTime = dt.addDays((i+1)*incrementBy);
                    let lastWeekOfMonth = false;
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - Incrementing startDateList : ' + i*incrementBy);
                    system.System.debug('DateUtility.getMonthlyRecurrenceDate() - nextDateTime : ' + nextDateTime);
                    //Last Week Of Month Check. IF true, month varible is incremented.
                    if(Integer.valueOf(nextDateTime.format('W')) > Integer.valueOf(nextWeekDateTime.format('W'))){
                        month = month + 1;
                        lastWeekOfMonth = true;
                    }
                    if(nextDateTime <= dtEndDateTime && ((nextDateTime.format('W') == string.valueOf(intOccurance)) || (intOccurance == -1 && lastWeekOfMonth)) ){
                        returnValue.add(nextDateTime.dateGMT());
                    }else{
                        system.System.debug('DateUtility.getMonthlyRecurrenceDate() - Exiting ForLoop');
                        break;
                    }
                }
                i++;
            }   

            system.System.debug('DateUtility.getWeeklyRecurrenceDate() - returnValue : ' + returnValue.tostring()); 

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return returnValue;
    }*/

    
}