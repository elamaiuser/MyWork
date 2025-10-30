public class TestSFCAFailure {
    public static void myMethod() {
        try {
            Integer i = 1 / 0;
        } catch (Exception e) {
            // This empty catch block will be flagged by the scanner testing one last time.
        }
    }
}