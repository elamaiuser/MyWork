public class skedWorkdayEnterTimeOffRequest extends skedWorkdayApiRequest {
    public List<skedWorkdayTimeOffEntry> timeOffEntries;

    public skedWorkdayEnterTimeOffRequest() {
        super();
        this.timeOffEntries = new List<skedWorkdayTimeOffEntry>();
    }

    public class skedWorkdayTimeOffEntry {
        public String ptoEntryId;
        public Date ptoDate;
        public Decimal hoursRequested;
        public String timeOffType;
        public String ptoReason;
        public String comment;
    }
}