public virtual class skedDateRangeBase implements Comparable {

    public String recordId;
    public Date startDate;
    public Date endDate;

    public skedDateRangeBase(String recordId, Date startDate, Date endDate) {
        this.recordId = recordId;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public Integer compareTo(Object dateRangeObj) {
        skedDateRangeBase dateRange = (skedDateRangeBase) dateRangeObj;

        if (endDate == null || dateRange.startDate == null || dateRange.endDate < startDate) {
            return 1;
        } else if (startDate == null || dateRange.endDate == null || dateRange.startDate > endDate) {
            return -1;
        }
        
        return dateRange.endDate.daysBetween(endDate);
    }
}