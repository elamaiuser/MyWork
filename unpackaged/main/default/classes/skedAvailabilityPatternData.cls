public class skedAvailabilityPatternData {
    
    public dayModel[] days;
    public integer lengthDays; //when use "custom" type
    public integer repeatWeeks; //when use "weekly" type
    public string type;//weekly; custom
    
    /* Nested Classes */
    public class dayModel {
        public integer day; // when use "custom" type
        public string weekday; // when use "weekly" type
        public intervalModel[] intervals;
    }
    
    public class intervalModel {
        public string startTime; //08:00
        public string endTime; //17:00
    }
    
}