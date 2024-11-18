public class skedWorkdayTimeTrackingBsvc {
	private static final String s_ns0 = 'urn:com.workday/bsvc';

	public class Import_Reported_Time_Blocks_RequestType {
		public skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType[] Reported_Time_Block_Data;
		private transient String[] Reported_Time_Block_Data_type_info = new String[]{'Reported_Time_Block_Data',s_ns0,'Reported_Time_Block_DataType','0','-1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Reported_Time_Block_Data'};
		public Import_Reported_Time_Blocks_RequestType(){
		}
		public Import_Reported_Time_Blocks_RequestType(skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType[] Reported_Time_Block_Data){
			this.Reported_Time_Block_Data = Reported_Time_Block_Data;
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			//System.assertEquals('Import_Reported_Time_Blocks', outerNode.getName());
			
			skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType[] Reported_Time_Block_DataObj = this.Reported_Time_Block_Data;
			if(Reported_Time_Block_DataObj != null){
				for(skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType element: Reported_Time_Block_DataObj){
					Dom.XmlNode Reported_Time_Block_DataNode = outerNode.addChildElement('Reported_Time_Block_Data', 'urn:com.workday/bsvc', '');
					element.populateXmlNode(Reported_Time_Block_DataNode);
				}
			}			
		}
	}
	
	public class Reported_Time_Block_DataType {
		public skedWorkdayTimeTrackingBsvc.WorkerObjectType Worker_Reference;
		// public skedWorkdayTimeTrackingBsvc.Worker_Time_BlockObjectType Worker_Time_Block_Reference;
		public Boolean Delete_Time_Block;
		public skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType Time_Entry_Code_Reference;
		public Date Date_x;
		public Decimal Quantity;
		public DateTime In_Date_Time;
		public DateTime Out_Date_Time;
		// public skedWorkdayTimeTrackingBsvc.Time_Punch_TypeObjectType Out_Reason_Reference;
		public Boolean Do_Not_Bill;
		public Decimal Override_Rate;
		public String Comment;
		private transient String[] Worker_Reference_type_info = new String[]{'Worker_Reference',s_ns0,'WorkerObjectType','1','1','false'};
		// private transient String[] Worker_Time_Block_Reference_type_info = new String[]{'Worker_Time_Block_Reference',s_ns0,'Worker_Time_BlockObjectType','0','1','false'};
		private transient String[] Delete_Time_Block_type_info = new String[]{'Delete_Time_Block',s_ns0,'boolean','0','1','false'};
		private transient String[] Time_Entry_Code_Reference_type_info = new String[]{'Time_Entry_Code_Reference',s_ns0,'Time_Entry_CodeObjectType','0','1','false'};
		private transient String[] Date_x_type_info = new String[]{'Date',s_ns0,'date','0','1','false'};
		private transient String[] Quantity_type_info = new String[]{'Quantity',s_ns0,'','0','1','false'};
		private transient String[] In_Date_Time_type_info = new String[]{'In_Date_Time',s_ns0,'dateTime','0','1','false'};
		private transient String[] Out_Date_Time_type_info = new String[]{'Out_Date_Time',s_ns0,'dateTime','0','1','false'};
		// private transient String[] Out_Reason_Reference_type_info = new String[]{'Out_Reason_Reference',s_ns0,'Time_Punch_TypeObjectType','0','1','false'};
		private transient String[] Do_Not_Bill_type_info = new String[]{'Do_Not_Bill',s_ns0,'boolean','0','1','false'};
		private transient String[] Override_Rate_type_info = new String[]{'Override_Rate',s_ns0,'','0','1','false'};
		private transient String[] Comment_type_info = new String[]{'Comment',s_ns0,'string','0','1','false'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'Worker_Reference',/*'Worker_Time_Block_Reference',*/'Delete_Time_Block','Time_Entry_Code_Reference','Date_x','Quantity','In_Date_Time','Out_Date_Time'/*,'Out_Reason_Reference'*/,'Do_Not_Bill','Override_Rate','Comment'};
		public Reported_Time_Block_DataType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			skedWorkdayTimeTrackingBsvc.WorkerObjectType Worker_ReferenceObj = this.Worker_Reference;
			if(Worker_ReferenceObj != null){
				Dom.XmlNode Worker_ReferenceNode = outerNode.addChildElement('Worker_Reference', 'urn:com.workday/bsvc', '');
				Worker_ReferenceObj.populateXmlNode(Worker_ReferenceNode);
			}
			
			/*skedWorkdayTimeTrackingBsvc.Worker_Time_BlockObjectType Worker_Time_Block_ReferenceObj = this.Worker_Time_Block_Reference;
			if(Worker_Time_Block_ReferenceObj != null){
				Dom.XmlNode Worker_Time_Block_ReferenceNode = outerNode.addChildElement('Worker_Time_Block_Reference', 'urn:com.workday/bsvc', '');
				Worker_Time_Block_ReferenceObj.populateXmlNode(Worker_Time_Block_ReferenceNode);
			}*/
			if (this.Delete_Time_Block != null) {
				Dom.XmlNode Delete_Time_BlockNode = outerNode.addChildElement('Delete_Time_Block', 'urn:com.workday/bsvc', '');
				Delete_Time_BlockNode.addTextNode((this.Delete_Time_Block == null) ? '' : String.valueOf(this.Delete_Time_Block));
			}
			
			skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType Time_Entry_Code_ReferenceObj = this.Time_Entry_Code_Reference;
			if(Time_Entry_Code_ReferenceObj != null){
				Dom.XmlNode Time_Entry_Code_ReferenceNode = outerNode.addChildElement('Time_Entry_Code_Reference', 'urn:com.workday/bsvc', '');
				Time_Entry_Code_ReferenceObj.populateXmlNode(Time_Entry_Code_ReferenceNode);
			}
			
			if (this.Date_x != null) {
				Dom.XmlNode Date_xNode = outerNode.addChildElement('Date', 'urn:com.workday/bsvc', '');
				Date_xNode.addTextNode((this.Date_x == null) ? '' : String.valueOf(this.Date_x));
			}
			if (this.Quantity != null) {
				Dom.XmlNode QuantityNode = outerNode.addChildElement('Quantity', 'urn:com.workday/bsvc', '');
				QuantityNode.addTextNode((this.Quantity == null) ? '' : String.valueOf(this.Quantity));
			}
			if (this.In_Date_Time != null) {
				Dom.XmlNode In_Date_TimeNode = outerNode.addChildElement('In_Date_Time', 'urn:com.workday/bsvc', '');
				In_Date_TimeNode.addTextNode((this.In_Date_Time == null) ? '' : String.valueOf(this.In_Date_Time));
			}
			if (this.Out_Date_Time != null) {
				Dom.XmlNode Out_Date_TimeNode = outerNode.addChildElement('Out_Date_Time', 'urn:com.workday/bsvc', '');
				Out_Date_TimeNode.addTextNode((this.Out_Date_Time == null) ? '' : String.valueOf(this.Out_Date_Time));
			}
			
			/*skedWorkdayTimeTrackingBsvc.Time_Punch_TypeObjectType Out_Reason_ReferenceObj = this.Out_Reason_Reference;
			if(Out_Reason_ReferenceObj != null){
				Dom.XmlNode Out_Reason_ReferenceNode = outerNode.addChildElement('Out_Reason_Reference', 'urn:com.workday/bsvc', '');
				Out_Reason_ReferenceObj.populateXmlNode(Out_Reason_ReferenceNode);
			}*/
			
			if (this.Do_Not_Bill != null) {
				Dom.XmlNode Do_Not_BillNode = outerNode.addChildElement('Do_Not_Bill', 'urn:com.workday/bsvc', '');
				Do_Not_BillNode.addTextNode((this.Do_Not_Bill == null) ? '' : String.valueOf(this.Do_Not_Bill));
			}			
			
			if (this.Override_Rate != null) {
				Dom.XmlNode Override_RateNode = outerNode.addChildElement('Override_Rate', 'urn:com.workday/bsvc', '');
				Override_RateNode.addTextNode((this.Override_Rate == null) ? '' : String.valueOf(this.Override_Rate));
			}

			if (this.Comment != null) {
				Dom.XmlNode CommentNode = outerNode.addChildElement('Comment', 'urn:com.workday/bsvc', '');
				CommentNode.addTextNode((this.Comment == null) ? '' : this.Comment);
			}
		}
	}
	
	//Warning: Simple Content Types with Attributes are not supported by WebServiceCallout.invoke
	public class Time_Entry_CodeObjectIDType {
		public String input;
		private transient String[] input_type_info = new String[]{'input','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		public String type_x;
		public String[] type_x_att_info = new String[]{'type'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{};
		public Time_Entry_CodeObjectIDType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.addTextNode(this.input);
			outerNode.setAttribute('bsvc:type', this.type_x);
		}
	}
	public class Time_Entry_CodeObjectType {
		public skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'Time_Entry_CodeObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public Time_Entry_CodeObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', '');
					element.populateXmlNode(IDNode);
				}
			}			
			outerNode.setAttribute('bsvc:Descriptor', 'string');
		}
	}
	
	/* Start of TimePunch CommentBlock for potential future use
	//Warning: Simple Content Types with Attributes are not supported by WebServiceCallout.invoke
	public class Time_Punch_TypeObjectIDType {
		public String input;
		private transient String[] input_type_info = new String[]{'input','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		public String type_x;
		public String[] type_x_att_info = new String[]{'type'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{};
		public Time_Punch_TypeObjectIDType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			outerNode.addTextNode(this.input);
			outerNode.setAttribute('bsvc:type', this.type_x);
		}
	}
	public class Time_Punch_TypeObjectType {
		public skedWorkdayTimeTrackingBsvc.Time_Punch_TypeObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'Time_Punch_TypeObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public Time_Punch_TypeObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayTimeTrackingBsvc.Time_Punch_TypeObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayTimeTrackingBsvc.Time_Punch_TypeObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', '');
					element.populateXmlNode(IDNode);
				}
			}			
			Dom.XmlNode DescriptorNode = outerNode.addChildElement('Descriptor', 'urn:com.workday/bsvc', '');
			DescriptorNode.addTextNode((this.Descriptor == null) ? '' : this.Descriptor);
		}
	}
	End of TimePunch Comment */

	public class Workday_Common_HeaderType {
		public Boolean Include_Reference_Descriptors_In_Response;
		private transient String[] Include_Reference_Descriptors_In_Response_type_info = new String[]{'Include_Reference_Descriptors_In_Response',s_ns0,'boolean','0','1','false'};

		private transient String[] field_order_type_info = new String[]{'Include_Reference_Descriptors_In_Response'};
		public Workday_Common_HeaderType(){
		}
		public Workday_Common_HeaderType(DOM.XmlNode responseNode){
			Set<DOM.XmlNode> nodesParsed = new Set<DOM.XmlNode>();
			DOM.XmlNode Include_Reference_Descriptors_In_ResponseNode = responseNode.getChildElement('Include_Reference_Descriptors_In_Response', 'urn:com.workday/bsvc');
			this.Include_Reference_Descriptors_In_Response = (Include_Reference_Descriptors_In_ResponseNode == null) ? null : Boolean.valueOf(Include_Reference_Descriptors_In_ResponseNode.getText());
			nodesParsed.add(Include_Reference_Descriptors_In_ResponseNode);
			//System.debug(this.Include_Reference_Descriptors_In_Response);			
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
		public skedWorkdayTimeTrackingBsvc.WorkerObjectIDType[] ID;
		private transient String[] ID_type_info = new String[]{'ID',s_ns0,'WorkerObjectIDType','0','-1','false'};
		public String Descriptor;
		public String[] Descriptor_att_info = new String[]{'Descriptor'};
		private transient String[] apex_schema_type_info = new String[]{s_ns0,'true','false'};
		private transient String[] field_order_type_info = new String[]{'ID'};
		public WorkerObjectType(){
		}
		public void populateXmlNode(Dom.XmlNode outerNode){
			
			skedWorkdayTimeTrackingBsvc.WorkerObjectIDType[] IDObj = this.ID;
			if(IDObj != null){
				for(skedWorkdayTimeTrackingBsvc.WorkerObjectIDType element: IDObj){
					Dom.XmlNode IDNode = outerNode.addChildElement('ID', 'urn:com.workday/bsvc', '');
					element.populateXmlNode(IDNode);
				}
			}			
			outerNode.setAttribute('bsvc:Descriptor', 'string');
		}
	}
}