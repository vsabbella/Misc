public with sharing class ExportPdfController {
	public String fileName { get; set; }
	public List<Object> gridColumns { get; set; }
	public List<List<Object>> gridRows { get; set; }
	public List<Object> headerRows { get; set; }
	public Integer colSpan { get; set; }
	public Boolean isPrintableView { get; set; }
	public String renderAs {get;set;}

    public ExportPdfController()
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
    	
    	colSpan = 1;
    	if (gridColumns != null) {
    		if (gridColumns.size() > 0) {
    			colSpan = gridColumns.size();
    		}	
    	}
    	
    	
    	String printableView = String.isNotBlank(ApexPages.currentPage().getParameters().get('print')) ? ApexPages.currentPage().getParameters().get('print') : '';
    	
    	isPrintableView = (printableView == '1') ? true : false;
    	fileName = fileName + System.now().format().replace(' ', '_');
    	renderAs = (isPrintableView) ? null : 'pdf';
    	
		if (!isPrintableView) {
    		Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=' + fileName + '.pdf');
		}
    }
}