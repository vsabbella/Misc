public with sharing class gridTileCon {
	
	private Schema.DescribeSObjectResult GETdescribe(string token) { 
    	return SchemaUtil.getInstance().getGlobalDescribe( token ).getDescribe(); 
	} 
	
	public string token {  get; set; }
	public string titleSTR {  get; set; } 
	public string urlSTR {  get; set; } 
	
	// token == 'a0u'  or something, need to look this up
	
	public string hrefURL { get { 
		return (urlSTR != null ? urlSTR : '/'+GETdescribe(token).keyPrefix); 
	} }
	public string labelPlural { get { 
		return ( titleSTR != null ? titleSTR : GETdescribe(token).labelPlural );   
	} }
	public string className { get { return token; } }

}