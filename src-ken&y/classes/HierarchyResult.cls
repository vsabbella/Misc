public with sharing class HierarchyResult {
	
	public map<Id, Id> rootNodes;
	public map<Id, Node> mNodes;
	public map <Id, Id> mChildParent;
	
	public List<Node> getChildNodes(Id parentId){
		system.debug(logginglevel.info,'mNodes:'+mNodes);
		return HierarchyService.getChildren(parentId, mNodes);
		
	}
	
	public boolean checkParent(Id childId, Id parentId){
		
		return HierarchyService.isMyParent(childId, parentId, mChildParent);
		
	}
	
}