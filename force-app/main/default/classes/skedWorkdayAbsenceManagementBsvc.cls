public class skedWorkdayAbsenceManagementBsvc {
	private static final String s_ns0 = 'urn:com.workday/bsvc';
	
	public class Adjust_Time_Off_DataType {
		public skedWorkdayAbsenceManagementBsvc.WorkerObjectType Worker_Reference;
		public skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType[] Adjust_Time_Off_Entry_Data;
		public Boolean Run_Time_Off_Validations;
		private transient String[] Run_Time_Off_Validations_type_info = new String[]{'Run_Time_Off_Validations',s_ns0,'boolean','0','1','false'};
		private transient String[] Worker_Reference_type_info = new String[]{'Worker_Reference',s_ns0,'WorkerObjectType','1','1','false'};
		private transient String[] Adjust_Time_Off_Entry_Data_type_info = new String[]{'Adjust_Time_Off_Entry_Data',s_ns0,'Adjust_Time_Off_Entry_DataType','1','-1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Run_Time_Off_Validations','Worker_Reference','Adjust_Time_Off_Entry_Data'};
		public Adjust_Time_Off_DataType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayAbsenceManagementBsvc.WorkerObjectType Worker_ReferenceObj = this.Worker_Reference;
			Dom.XmlNode Worker_ReferenceNode = outerNode.addChildElement('Worker_Reference', 'urn:com.workday/bsvc', 'bsvc');
			if(Worker_ReferenceObj != null){
				Worker_ReferenceObj.populateXmlNode(Worker_ReferenceNode);
			}
			
			skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType[] Adjust_Time_Off_Entry_DataObj = this.Adjust_Time_Off_Entry_Data;
			if(Adjust_Time_Off_Entry_DataObj != null){
				for(skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType element: Adjust_Time_Off_Entry_DataObj){
					Dom.XmlNode Adjust_Time_Off_Entry_DataNode = outerNode.addChildElement('Adjust_Time_Off_Entry_Data', 'urn:com.workday/bsvc', 'bsvc');
					element.populateXmlNode(Adjust_Time_Off_Entry_DataNode);
				}
			}			
		}
	}
	public class Adjust_Time_Off_Entry_DataType {
		public String Time_Off_Entry_ID;
		public skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectType Time_Off_Entry_Reference;
		public Decimal Adjustment_to_Requested;
		public String Comment;
		private transient String[] Time_Off_Entry_ID_type_info = new String[]{'Time_Off_Entry_ID',s_ns0,'string','0','1','false'};
		private transient String[] Time_Off_Entry_Reference_type_info = new String[]{'Time_Off_Entry_Reference',s_ns0,'Time_Off_EntryObjectType','1','1','false'};
		private transient String[] Adjustment_to_Requested_type_info = new String[]{'Adjustment_to_Requested',s_ns0,'','1','1','false'};
		private transient String[] Comment_type_info = new String[]{'Comment',s_ns0,'string','0','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Time_Off_Entry_ID','Time_Off_Entry_Reference','Adjustment_to_Requested','Comment'};
		public Adjust_Time_Off_Entry_DataType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			if (this.Time_Off_Entry_ID != null) {
				Dom.XmlNode Time_Off_Entry_IDNode = outerNode.addChildElement('Time_Off_Entry_ID', 'urn:com.workday/bsvc', 'bsvc');
				Time_Off_Entry_IDNode.addTextNode((this.Time_Off_Entry_ID == null) ? '' : this.Time_Off_Entry_ID);
			}
			
			skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectType Time_Off_Entry_ReferenceObj = this.Time_Off_Entry_Reference;
			if(Time_Off_Entry_ReferenceObj != null){
				Dom.XmlNode Time_Off_Entry_ReferenceNode = outerNode.addChildElement('Time_Off_Entry_Reference', 'urn:com.workday/bsvc', 'bsvc');
				Time_Off_Entry_ReferenceObj.populateXmlNode(Time_Off_Entry_ReferenceNode);
			}
			Dom.XmlNode Adjustment_to_RequestedNode = outerNode.addChildElement('Adjustment_to_Requested', 'urn:com.workday/bsvc', 'bsvc');
			if(this.Adjustment_to_Requested != null){
				Adjustment_to_RequestedNode.addTextNode(String.valueOf(this.Adjustment_to_Requested));
			}
			Dom.XmlNode CommentNode = outerNode.addChildElement('Comment', 'urn:com.workday/bsvc', 'bsvc');
			CommentNode.addTextNode((this.Comment == null) ? '' : this.Comment);
		}
	}
	public class Adjust_Time_Off_RequestType {
		public skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_Parameters;
		public skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_DataType Adjust_Time_Off_Data;
		private transient String[] Business_Process_Parameters_type_info = new String[]{'Business_Process_Parameters',s_ns0,'Business_Process_ParametersType','0','1','false'};
		private transient String[] Adjust_Time_Off_Data_type_info = new String[]{'Adjust_Time_Off_Data',s_ns0,'Adjust_Time_Off_DataType','1','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Business_Process_Parameters','Adjust_Time_Off_Data'};
		public Adjust_Time_Off_RequestType(){
		}
		public Adjust_Time_Off_RequestType(skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_Parameters,skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_DataType Adjust_Time_Off_Data){
			this.Business_Process_Parameters = Business_Process_Parameters;
			this.Adjust_Time_Off_Data = Adjust_Time_Off_Data;
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			//System.assertEquals('Adjust_Time_Off', outerNode.getName());
			
			skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_ParametersObj = this.Business_Process_Parameters;
			Dom.XmlNode Business_Process_ParametersNode = outerNode.addChildElement('Business_Process_Parameters', 'urn:com.workday/bsvc', 'bsvc');
			if(Business_Process_ParametersObj != null){
				Business_Process_ParametersObj.populateXmlNode(Business_Process_ParametersNode);
			}
			
			skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_DataType Adjust_Time_Off_DataObj = this.Adjust_Time_Off_Data;
			Dom.XmlNode Adjust_Time_Off_DataNode = outerNode.addChildElement('Adjust_Time_Off_Data', 'urn:com.workday/bsvc', 'bsvc');
			if(Adjust_Time_Off_DataObj != null){
				Adjust_Time_Off_DataObj.populateXmlNode(Adjust_Time_Off_DataNode);
			}
		}
	}
	public class Business_Process_Comment_DataType {
		public String Comment;
		public skedWorkdayAbsenceManagementBsvc.WorkerObjectType Worker_Reference;
		private transient String[] Comment_type_info = new String[]{'Comment',s_ns0,'string','0','1','false'};
		private transient String[] Worker_Reference_type_info = new String[]{'Worker_Reference',s_ns0,'WorkerObjectType','0','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Comment','Worker_Reference'};
		public Business_Process_Comment_DataType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			Dom.XmlNode CommentNode = outerNode.addChildElement('Comment', 'urn:com.workday/bsvc', 'bsvc');
			CommentNode.addTextNode((this.Comment == null) ? '' : this.Comment);
			
			skedWorkdayAbsenceManagementBsvc.WorkerObjectType Worker_ReferenceObj = this.Worker_Reference;
			Dom.XmlNode Worker_ReferenceNode = outerNode.addChildElement('Worker_Reference', 'urn:com.workday/bsvc', 'bsvc');
			if(Worker_ReferenceObj != null){
				Worker_ReferenceObj.populateXmlNode(Worker_ReferenceNode);
			}
		}
	}
	public class Business_Process_ParametersType {
		public Boolean Auto_Complete;
		public Boolean Run_Now;
		public Boolean Discard_On_Exit_Validation_Error;
		public skedWorkdayAbsenceManagementBsvc.Business_Process_Comment_DataType Comment_Data;
		private transient String[] Auto_Complete_type_info = new String[]{'Auto_Complete',s_ns0,'boolean','0','1','false'};
		private transient String[] Run_Now_type_info = new String[]{'Run_Now',s_ns0,'boolean','0','1','false'};
		private transient String[] Discard_On_Exit_Validation_Error_type_info = new String[]{'Discard_On_Exit_Validation_Error',s_ns0,'boolean','0','1','false'};
		private transient String[] Comment_Data_type_info = new String[]{'Comment_Data',s_ns0,'Business_Process_Comment_DataType','0','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Auto_Complete','Run_Now','Discard_On_Exit_Validation_Error','Comment_Data'};
		public Business_Process_ParametersType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			Dom.XmlNode Auto_CompleteNode = outerNode.addChildElement('Auto_Complete', 'urn:com.workday/bsvc', 'bsvc');
			Auto_CompleteNode.addTextNode((this.Auto_Complete == null) ? '' : String.valueOf(this.Auto_Complete));
			Dom.XmlNode Run_NowNode = outerNode.addChildElement('Run_Now', 'urn:com.workday/bsvc', 'bsvc');
			Run_NowNode.addTextNode((this.Run_Now == null) ? '' : String.valueOf(this.Run_Now));
			
			skedWorkdayAbsenceManagementBsvc.Business_Process_Comment_DataType Comment_DataObj = this.Comment_Data;
			if(Comment_DataObj != null){
				Dom.XmlNode Comment_DataNode = outerNode.addChildElement('Comment_Data', 'urn:com.workday/bsvc', 'bsvc');
				Comment_DataObj.populateXmlNode(Comment_DataNode);
			}		
		}
	}
	public class Enter_Time_Off_DataType {
		public Boolean Turn_Off_Run_Time_Calculations_with_Time_Off_Approval;
		public Boolean Run_Time_Off_Validations;
		public skedWorkdayAbsenceManagementBsvc.WorkerObjectType Worker_Reference;
		public skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType[] Enter_Time_Off_Entry_Data;
		private transient String[] Turn_Off_Run_Time_Calculations_with_Time_Off_Approval_type_info = new String[]{'Turn_Off_Run_Time_Calculations_with_Time_Off_Approval',s_ns0,'boolean','0','1','false'};
		private transient String[] Run_Time_Off_Validations_type_info = new String[]{'Run_Time_Off_Validations',s_ns0,'boolean','0','1','false'};
		private transient String[] Worker_Reference_type_info = new String[]{'Worker_Reference',s_ns0,'WorkerObjectType','1','1','false'};
		private transient String[] Enter_Time_Off_Entry_Data_type_info = new String[]{'Enter_Time_Off_Entry_Data',s_ns0,'Enter_Time_Off_Entry_DataType','1','-1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Turn_Off_Run_Time_Calculations_with_Time_Off_Approval','Run_Time_Off_Validations','Worker_Reference','Enter_Time_Off_Entry_Data'};
		public Enter_Time_Off_DataType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			Dom.XmlNode Turn_Off_Run_Time_Calculations_with_Time_Off_ApprovalNode = outerNode.addChildElement('Turn_Off_Run_Time_Calculations_with_Time_Off_Approval', 'urn:com.workday/bsvc', 'bsvc');
			Turn_Off_Run_Time_Calculations_with_Time_Off_ApprovalNode.addTextNode((this.Turn_Off_Run_Time_Calculations_with_Time_Off_Approval == null) ? '' : String.valueOf(this.Turn_Off_Run_Time_Calculations_with_Time_Off_Approval));

			Dom.XmlNode Run_Time_Off_ValidationsNode = outerNode.addChildElement('Run_Time_Off_Validations', 'urn:com.workday/bsvc', 'bsvc');
			Run_Time_Off_ValidationsNode.addTextNode((this.Run_Time_Off_Validations == null) ? '' : String.valueOf(this.Turn_Off_Run_Time_Calculations_with_Time_Off_Approval));
			
			skedWorkdayAbsenceManagementBsvc.WorkerObjectType Worker_ReferenceObj = this.Worker_Reference;
			Dom.XmlNode Worker_ReferenceNode = outerNode.addChildElement('Worker_Reference', 'urn:com.workday/bsvc', 'bsvc');
			if(Worker_ReferenceObj != null){
				Worker_ReferenceObj.populateXmlNode(Worker_ReferenceNode);
			}
			
			skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType[] Enter_Time_Off_Entry_DataObj = this.Enter_Time_Off_Entry_Data;
			if(Enter_Time_Off_Entry_DataObj != null){
				for(skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType element: Enter_Time_Off_Entry_DataObj){
					Dom.XmlNode Enter_Time_Off_Entry_DataNode = outerNode.addChildElement('Enter_Time_Off_Entry_Data', 'urn:com.workday/bsvc', 'bsvc');
					element.populateXmlNode(Enter_Time_Off_Entry_DataNode);
				}
			}			
		}
	}
	public class Enter_Time_Off_Entry_DataType {
		public String Time_Off_Entry_ID;
		public Date Date_x;
		public Decimal Requested;
		public skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectType Time_Off_Type_Reference;
		public skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectType Time_Off_Reason_Reference;
		public String Comment;
		private transient String[] Time_Off_Entry_ID_type_info = new String[]{'Time_Off_Entry_ID',s_ns0,'string','0','1','false'};
		private transient String[] Date_x_type_info = new String[]{'Date',s_ns0,'date','1','1','false'};
		private transient String[] Requested_type_info = new String[]{'Requested',s_ns0,'','0','1','false'};
		private transient String[] Time_Off_Type_Reference_type_info = new String[]{'Time_Off_Type_Reference',s_ns0,'Time_Off_TypeObjectType','0','1','false'};
		private transient String[] Time_Off_Reason_Reference_type_info = new String[]{'Time_Off_Reason_Reference',s_ns0,'Time_Off_ReasonObjectType','0','1','false'};
		private transient String[] Comment_type_info = new String[]{'Comment',s_ns0,'string','0','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Time_Off_Entry_ID','Date_x','Requested','Time_Off_Type_Reference','Time_Off_Reason_Reference','Comment'};
		public Enter_Time_Off_Entry_DataType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			Dom.XmlNode Time_Off_Entry_IDNode = outerNode.addChildElement('Time_Off_Entry_ID', 'urn:com.workday/bsvc', 'bsvc');
			Time_Off_Entry_IDNode.addTextNode((this.Time_Off_Entry_ID == null) ? '' : this.Time_Off_Entry_ID);
			Dom.XmlNode Date_xNode = outerNode.addChildElement('Date', 'urn:com.workday/bsvc', 'bsvc');
			if(this.Date_x != null){
				Date_xNode.addTextNode(String.valueOf(this.Date_x));
			}

			if (this.Requested != null) {
				Dom.XmlNode RequestedNode = outerNode.addChildElement('Requested', 'urn:com.workday/bsvc', 'bsvc');
				RequestedNode.addTextNode((this.Requested == null) ? '' : String.valueOf(this.Requested));
			}
			
			skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectType Time_Off_Type_ReferenceObj = this.Time_Off_Type_Reference;
			if(Time_Off_Type_ReferenceObj != null){
				Dom.XmlNode Time_Off_Type_ReferenceNode = outerNode.addChildElement('Time_Off_Type_Reference', 'urn:com.workday/bsvc', 'bsvc');
				Time_Off_Type_ReferenceObj.populateXmlNode(Time_Off_Type_ReferenceNode);
			}
			
			skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectType Time_Off_Reason_ReferenceObj = this.Time_Off_Reason_Reference;
			if(Time_Off_Reason_ReferenceObj != null){
				Dom.XmlNode Time_Off_Reason_ReferenceNode = outerNode.addChildElement('Time_Off_Reason_Reference', 'urn:com.workday/bsvc', 'bsvc');
				Time_Off_Reason_ReferenceObj.populateXmlNode(Time_Off_Reason_ReferenceNode);
			}
			Dom.XmlNode CommentNode = outerNode.addChildElement('Comment', 'urn:com.workday/bsvc', 'bsvc');
			CommentNode.addTextNode((this.Comment == null) ? '' : this.Comment);
		}
	}
	public class Enter_Time_Off_RequestType {
		public skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_Parameters;
		public skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_DataType Enter_Time_Off_Data;
		private transient String[] Business_Process_Parameters_type_info = new String[]{'Business_Process_Parameters',s_ns0,'Business_Process_ParametersType','0','1','false'};
		private transient String[] Enter_Time_Off_Data_type_info = new String[]{'Enter_Time_Off_Data',s_ns0,'Enter_Time_Off_DataType','1','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Business_Process_Parameters','Enter_Time_Off_Data'};
		public Enter_Time_Off_RequestType(){
		}
		public Enter_Time_Off_RequestType(skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_Parameters,skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_DataType Enter_Time_Off_Data){
			this.Business_Process_Parameters = Business_Process_Parameters;
			this.Enter_Time_Off_Data = Enter_Time_Off_Data;
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			//System.assertEquals('Enter_Time_Off', outerNode.getName());
			
			skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_ParametersObj = this.Business_Process_Parameters;
			Dom.XmlNode Business_Process_ParametersNode = outerNode.addChildElement('Business_Process_Parameters', 'urn:com.workday/bsvc', 'bsvc');
			if(Business_Process_ParametersObj != null){
				Business_Process_ParametersObj.populateXmlNode(Business_Process_ParametersNode);
			}
			
			skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_DataType Enter_Time_Off_DataObj = this.Enter_Time_Off_Data;
			Dom.XmlNode Enter_Time_Off_DataNode = outerNode.addChildElement('Enter_Time_Off_Data', 'urn:com.workday/bsvc', 'bsvc');
			if(Enter_Time_Off_DataObj != null){
				Enter_Time_Off_DataObj.populateXmlNode(Enter_Time_Off_DataNode);
			}
		}
	}
	
	//Warning: Simple Content Types with Attributes are not supported by WebServiceCallout.invoke
	public class Time_Off_EntryObjectIDType {
		public String input;
		private transient String[] input_type_info = new String[]{'input','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		public String type_x;
		public String[] type_x_att_info = new String[]{'type'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{};
		public Time_Off_EntryObjectIDType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.addTextNode(this.input);
			outerNode.setAttribute('bsvc:type', this.type_x);
		}
	}
	public class Time_Off_EntryObjectType {
		public skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'Time_Off_EntryObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public Time_Off_EntryObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', 'bsvc');
					element.populateXmlNode(IDNode);
				}
			}			

		}
	}
	//Warning: Simple Content Types with Attributes are not supported by WebServiceCallout.invoke
	public class Time_Off_ReasonObjectIDType {
		public String input;
		private transient String[] input_type_info = new String[]{'input','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		public String type_x;
		public String[] type_x_att_info = new String[]{'type'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{};
		public Time_Off_ReasonObjectIDType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.addTextNode(this.input);
			outerNode.setAttribute('bsvc:type', this.type_x);
		}
	}
	public class Time_Off_ReasonObjectType {
		public skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'Time_Off_ReasonObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public Time_Off_ReasonObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', 'bsvc');
					element.populateXmlNode(IDNode);
				}
			}			
			outerNode.setAttribute('bsvc:Descriptor', 'string');
		}
	}
	
	//Warning: Simple Content Types with Attributes are not supported by WebServiceCallout.invoke
	public class Time_Off_TypeObjectIDType {
		public String input;
		private transient String[] input_type_info = new String[]{'input','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		public String type_x;
		public String[] type_x_att_info = new String[]{'type'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{};
		public Time_Off_TypeObjectIDType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.addTextNode(this.input);
			outerNode.setAttribute('bsvc:type', this.type_x);
		}
	}
	public class Time_Off_TypeObjectType {
		public skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'Time_Off_TypeObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public Time_Off_TypeObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.setAttribute('bsvc:Descriptor', 'string');
			skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', 'bsvc');
					element.populateXmlNode(IDNode);
				}
			}	
					
		}
	}
	public class Workday_Common_HeaderType {
		public Boolean Include_Reference_Descriptors_In_Response;
		private transient String[] Include_Reference_Descriptors_In_Response_type_info = new String[]{'Include_Reference_Descriptors_In_Response',s_ns0,'boolean','0','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Include_Reference_Descriptors_In_Response'};
		public Workday_Common_HeaderType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			Dom.XmlNode Include_Reference_Descriptors_In_ResponseNode = outerNode.addChildElement('Include_Reference_Descriptors_In_Response', 'urn:com.workday/bsvc', '');
			Include_Reference_Descriptors_In_ResponseNode.addTextNode((this.Include_Reference_Descriptors_In_Response == null) ? '' : String.valueOf(this.Include_Reference_Descriptors_In_Response));
		}
	}

	//Warning: Simple Content Types with Attributes are not supported by WebServiceCallout.invoke
	public class WorkerObjectIDType {
		public String input;
		private transient String[] input_type_info = new String[]{'input','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		public String type_x;
		public String[] type_x_att_info = new String[]{'type'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{};
		public WorkerObjectIDType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.addTextNode(this.input);
			outerNode.setAttribute('bsvc:type', this.type_x);
		}
	}
	public class WorkerObjectType {
		public skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'WorkerObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public WorkerObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', 'bsvc');
					element.populateXmlNode(IDNode);
				}
			}			
			outerNode.setAttribute('bsvc:Descriptor', 'string');
		}
	}
}