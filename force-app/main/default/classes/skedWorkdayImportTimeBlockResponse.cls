public class skedWorkdayImportTimeBlockResponse extends skedWorkdayApiResponse {
    // Workday Import Process WID (from Put_Import_Process_Response.Import_Process_Reference.ID)
    public String importProcessId;
    /** Full SOAP XML for BSF direct Import path */
    public String fullSoapRequestXml;

    public skedWorkdayImportTimeBlockResponse(String request) {
        super(request);
    }
}