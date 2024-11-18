public class skedWorkdayAdjustTimeOffRequest extends skedWorkdayApiRequest {
    public List<skedWorkdayAdjustTimeOffEntry> adjustTimeOffEntries;

    public skedWorkdayAdjustTimeOffRequest() {
        this.adjustTimeOffEntries = new List<skedWorkdayAdjustTimeOffEntry>();
    }
    
    public class skedWorkdayAdjustTimeOffEntry {
        public String ptoEntryId;
        public Decimal adjustment;
        public String comment;
    }
}