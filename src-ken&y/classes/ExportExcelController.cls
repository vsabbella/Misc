public with sharing class ExportExcelController {
	public String fileName { get; set; }
	public List<Object> gridColumns { get; set; }
	public List<List<Object>> gridRows { get; set; }
	public List<Object> headerRows { get; set; }

    public ExportExcelController()
    {
    	headerRows =  String.isNotBlank(ApexPages.currentPage().getParameters().get('gridHeader')) ? (List<Object>)JSON.deserializeUnTyped(ApexPages.currentPage().getParameters().get('gridHeader')) : null;
    	fileName = String.isNotBlank(ApexPages.currentPage().getParameters().get('filename')) ? ApexPages.currentPage().getParameters().get('filename') : 'Report';
    	gridColumns = String.isNotBlank(ApexPages.currentPage().getParameters().get('gridColumns')) ? (List<Object>)JSON.deserializeUnTyped(ApexPages.currentPage().getParameters().get('gridColumns')) : null;
		
		List<Object> allGridRows = String.isNotBlank(ApexPages.currentPage().getParameters().get('gridRows')) ? (List<Object>)JSON.deserializeUnTyped(ApexPages.currentPage().getParameters().get('gridRows')) : null;
    	gridRows = new List<List<Object>>();
    	List<Object> chunkOfRows = new List<Object>();
    	//chunk up the rows into a list of lists where each inner list is <= 1000
    	//to break through the VF 1000 row limit
		if (allGridRows != null) {    	
	    	for (Integer i=0; i<allGridRows.size(); i++) {
	    		chunkOfRows.add(allGridRows[i]);
	    		if (chunkOfRows.size() == 1000) {
	    			gridRows.add(chunkOfRows);
	    			chunkOfRows = new List<Object>();	
	    		}
	    	}
	    	//add leftovers
	    	if (chunkOfRows.size() > 0) {
	    		gridRows.add(chunkOfRows);	
	    	}
		}
    	    	
    	//if there is anything in headerRows, add another blank line under it to separate it from the rest of the data
    	if (headerRows != null) {
    		if (!headerRows.isEmpty()) {
    			headerRows.add('');	
    		}	
    	}
    	//KNDY-17782 - added space in case of grid title used as a filename
    	fileName = (fileName +' '+ System.now().format()).replace(' ', '_');
    	//fileName = EncodingUtil.urlEncode(fileName, 'UTF-8');
    }
    
    public String xlsHeader {
		get {
			String strHeader = '';
		 	
		 	strHeader += '<?xml version="1.0"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
		 	
		 	return strHeader;
		}
	}
}