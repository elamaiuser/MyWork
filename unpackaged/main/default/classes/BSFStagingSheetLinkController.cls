public class BSFStagingSheetLinkController {
    public String jobId;
    public Boolean enableAllLinks {get; set;}
    public Boolean enableMOELinks {get; set;}
    public Boolean enableNonMOELinks {get; set;}
    public BSFStagingSheetLinkController(){
        this.enableAllLinks = true;
        if(Staging_Sheet_Config__mdt.getInstance('Show_MOE_Sheet_Links').String_Value__c.equalsIgnoreCase('true')){
            this.enableMOELinks = true;
        }
        if(Staging_Sheet_Config__mdt.getInstance('Show_Non_MOE_Sheet_Links').String_Value__c.equalsIgnoreCase('true')){
            this.enableNonMOELinks = true;
        }
        List<String> jobIdParams = new List<String>{'jobid','jobId','JobId','JOBID','JobID'};
        for(String param : jobIdParams){
            if(String.isNotBlank(Apexpages.currentPage().getParameters().get(param))){
                this.jobId = Apexpages.currentPage().getParameters().get(param);
                break;
            }
        }
        System.debug('input jobid : '+this.jobId);
        if(String.isNotBlank(this.jobId)){
            this.jobId = String.escapeSingleQuotes(this.jobId);
            this.jobId = this.jobId.escapeHtml4();
        }else{
            enableAllLinks = false;
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'Job Id not found.');
            ApexPages.addMessage(msg);
        }
    }

    public PageReference OpenStagingSheetStandard(){
        PageReference pr = new PageReference('/apex/BSFStagingSheetVF');
        pr.getParameters().put('appeal','No');
        pr.getParameters().put('jobid',this.jobId);
        //pr.getParameters().put('moe','false');
        pr.getParameters().put('renderas','html');
        pr.getParameters().put('backToSearch','false');
        pr.setRedirect(true);
        return pr;
    }
    public PageReference OpenStagingSheetAppeal(){
        PageReference pr = new PageReference('/apex/BSFStagingSheetVF');
        pr.getParameters().put('appeal','Yes');
        pr.getParameters().put('jobid',this.jobId);
        //pr.getParameters().put('moe','false');
        pr.getParameters().put('renderas','html');
        pr.getParameters().put('backToSearch','false');
        pr.setRedirect(true);
        return pr;
    }
    public PageReference OpenStagingSheetMOEStandard(){
        PageReference pr = new PageReference('/apex/BSFStagingSheetVF');
        pr.getParameters().put('appeal','No');
        pr.getParameters().put('jobid',this.jobId);
        pr.getParameters().put('moe','true');
        pr.getParameters().put('renderas','html');
        pr.getParameters().put('backToSearch','false');
        pr.setRedirect(true);
        return pr;
    }
    public PageReference OpenStagingSheetMOEAppeal(){
        PageReference pr = new PageReference('/apex/BSFStagingSheetVF');
        pr.getParameters().put('appeal','Yes');
        pr.getParameters().put('jobid',this.jobId);
        pr.getParameters().put('moe','true');
        pr.getParameters().put('renderas','html');
        pr.getParameters().put('backToSearch','false');
        pr.setRedirect(true);
        return pr;
    }
}