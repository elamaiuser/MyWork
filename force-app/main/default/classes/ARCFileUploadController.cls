public inherited sharing class ARCFileUploadController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableFileTypes(String recordid){ 
        try {
            List<String> typeList = new List<String>();
            Id currentrecordid = recordid;     
            String objectname = currentrecordid.getSobjectType().getDescribe().getName();
            objectname = objectname.toLowerCase();   
            List<ARCFileContentTypeMatrix__mdt> filecontentmdt = [ SELECT                                                               
                                                                  ObjectName__c,
                                                                  Type__c
                                                                  FROM ARCFileContentTypeMatrix__mdt
                                                                  WHERE 
                                                                  ObjectName__c =: objectname AND
                                                                  IsValid__c = true 
                                                                 ];
            
            
            if( !filecontentmdt.isEmpty() ){
                for( ARCFileContentTypeMatrix__mdt fc : filecontentmdt ){
                    if( fc.Type__c !=null ){
                        typeList.add( fc.Type__c );
                    }
                }
            }
            
            return typeList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableFileFormats(){
        try {
            List<String> formatList = new List<String>();  
            List<ARCFileContentTypeMatrix__mdt> filecontentmdt = [ SELECT                                                               
                                                                  SupportedFileFormat__c
                                                                  FROM ARCFileContentTypeMatrix__mdt
                                                                  WHERE 
                                                                  DeveloperName = 'FileFormats' AND
                                                                  SupportedFileFormat__c != null 
                                                                 ];
            
            
            if( !filecontentmdt.isEmpty() ){
                String[] typeformatarray;
                for( ARCFileContentTypeMatrix__mdt fc : filecontentmdt ){
                    String typeformat = fc.SupportedFileFormat__c.trim().toLowerCase();
                    typeformatarray = typeformat.split( ',' );
                    //formatList.add( fc.SupportedFileFormat__c );
                }
                
                for( String tf : typeformatarray ){
                    formatList.add( tf );
                }
            }
            
            return formatList;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled(cacheable=false)
    public static List<String> getFileTypeAndInsert(String fileName,Date expiryDate,List<String> uploadedFileIds){
        System.debug('File Name:: ' + fileName);
        System.debug('uploadedFileIds: '+uploadedFileIds);
        List<String> fileTitleListToReturnList = new List<String>();
        
        Set<Id> fileIdSet = new Set<Id>();
        
        for(String fileIds:uploadedFileIds){
            fileIdSet.add(fileIds);
        }
        
        List<ContentVersion> filesUploaded = new List<ContentVersion>();
        filesUploaded = [SELECT Id,
                         Title,
                         ContentDocumentId,
                         FileExtension,
                         FileType,
                         Description,
                         Expiry_Date__c 
                         FROM ContentVersion 
                         WHERE ContentDocumentId IN :fileIdSet ];
        
        
        if(!filesUploaded.isEmpty()){                          
            for(ContentVersion file:filesUploaded) {
                file.Description = fileName;
                file.Expiry_Date__c = expiryDate;                
                String fileTitleAndExtension = file.Title+'.'+file.FileExtension;
                fileTitleListToReturnList.add(fileTitleAndExtension);
            } 
        } 
        System.debug('Files would be updating: '+filesUploaded);
		//Schema.DescribeSObjectResult ds = ContentVersion.sObjectType.getDescribe();if(ds.isUpdateable()){}
		 Database.update(filesUploaded);
        
        return fileTitleListToReturnList;
    }
    
    @AuraEnabled(cacheable=false)
    public static List<String> getContentDocumentId( String recordid){
        List<String> condoclist = new List<String>();
        List<ContentDocumentLink> cdlink = [SELECT ContentDocumentId  FROM ContentDocumentLink where LinkedEntityId =: recordid   ];
        if( !cdlink.isEmpty() ){
            for( ContentDocumentLink cd : cdlink ){
                condoclist.add(cd.ContentDocumentId);
            }
        }
        
        return condoclist; 
    }
    
    @AuraEnabled(cacheable=false)
    public static void getFilesAndDelete( List<String> fileIds ){
        
        List<ContentDocument> cdlink = [SELECT Id  FROM ContentDocument where Id IN: fileIds   ];
		//Schema.DescribeSObjectResult ds = ContentDocument.sObjectType.getDescribe();if(ds.isDeletable()){}
        
			if( !cdlink.isEmpty() ){
				delete cdlink;
        }
				
        
        
        
    }
    
    // @AuraEnabled(cacheable=false)
    // public static List<String> getOpportunityIds( String recordid){
    // List<String> oppidlist = new List<String>();
    // List<Opportunity> opplist = [SELECT Id FROM Opportunity where AccountId =: recordid   ];
    // if( !opplist.isEmpty() ){
    // for( Opportunity cd : opplist ){
    // oppidlist.add(cd.id);
    // }
    // }
    
    // return oppidlist;
    // }
    
    
    
}