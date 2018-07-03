public with sharing class GLAcctsManageHierarchyExt extends BaseController
{
    public list<GL_Account__c> GLList=new list<GL_Account__c>();
    public list<string> FieldList=new list<string>();
    public list<string> LabelList= new list<string>();

    public string GLListSer{get;set;}
    public string FieldListSer{get;set;}
    public string LabelListSer{get;set;}
    public string parentFieldHier{get;set;}
    public string NamespaceUU { get { return KSE.NamespaceUU; }} 
    
    schemaUtil Util= schemaUtil.getInstance();
    public static schemaUtil Util= schemaUtil.getInstance();
    public class resultObject
    {
        gl_account__c result;
        string message;
    }

    public GLAcctsManageHierarchyExt(apexpages.StandardsetController sc)
    {

               parentFieldHier = NamespaceUU + 'SubAccount_of__c';
               /*string q = util.generateQueryFromFieldSet( 'GL_Account__c',
                                                  new set<string>{'HierarchyView'}, 
                                                  new set<string>{'id','Name', 'Type__c', 'SubAccount_of__c'},null)+ ' limit 10000'; 
               GLList=Database.query(q);*/

               // ----------------------Commenting out based on #KNDY-11058------------------
               // ------------- This code is duplicate , the same db call is made in Remoteaction treeListRead()
            /* String whereClause = 'limit 10000';//KNDY-8796
               String whereClause  = null;
               SOQLUtil soql = new SOQLUtil('GL_Account__c',true);
               soql.addFields(new Set<String>{'id','Name', 'Type__c', 'SubAccount_of__c'});
               soql.addFields('HierarchyView');
               soql.setWhereClause(whereClause);
               soql.setLimit(10000);
               GLList=Database.query(soql.getQuery());-------------------------------*/
  
               List<Schema.FieldSetMember> fsmList = util.getFieldsFromFieldSet(GL_Account__c.getSobjectType(),'HierarchyView');
        
               for(Schema.FieldSetMember fsm:fsmList)
               {
                LabelList.add(fsm.getLabel());                  
               }
               FieldList =  util.getFieldsFromFieldSetString(GL_Account__c.getSobjectType(),'HierarchyView');
        
               //GLListSer = JSON.serialize(GLList);
               FieldListSer = JSON.serialize(fieldList);
               labelListSer = JSON.serialize(LabelList);
               //GLList= [select id,name,type__c,SubAccount_of__c from GL_Account__c where SubAccount_of__c!=null];
    }
    
    public String getFieldInfoList() {
        FieldInfo[] fieldInfoList = FieldInfo.fetchJsonFieldInfos('GL_Account__c', 'HierarchyView');
        
        for (FieldInfo fi: fieldInfoList) {
            if (fi.field != 'Id' && fi.field != 'Name' && fi.field != 'CreatedDate' && fi.field!='LastModifiedDate') {
                fi.field = NamespaceUU + fi.field;
            }
        }
        
        return JSON.serialize(fieldInfoList);
    }
    
    @remoteaction
    public static jsonresult treeListRead()
    {
        /* string q = util.generateQueryFromFieldSet( 'GL_Account__c',
                                                  new set<string>{'HierarchyView'}, 
                                                  new set<string>{'id','Name', 'Type__c', 'SubAccount_of__c'},'Active__c  = true' ); 
         list<sobject>  GLList=Database.query(q);*/
        String whereClause = 'Active__c  = true';//KNDY-8796
        SOQLUtil soql = new SOQLUtil('GL_Account__c',true);
        soql.addFields('HierarchyView');
        soql.addFields(new Set<String>{'id','Name', 'Type__c', 'SubAccount_of__c'});
        soql.setWhereClause(whereClause);
         // ------------------------Adding based on #KNDY-11058------------------------
        soql.setLimit(10000);

        list<sobject>  GLList=Database.query(soql.getQuery());
        
         return new JSONResult(GLList,GLList.size());
    }
    @remoteaction
    public static resultObject treeListCreate(string Glaccount)
    {
        Gl_Account__c newGLAccount;
        resultObject resultObj = new resultObject();
        try
        {
         newGLAccount = (gl_account__c)json.deserialize(Glaccount, gl_account__c.class);
         DML.checkUpsertAsUser(newGLAccount); upsert newGLAccount;  
         resultObj.result=newGLAccount;
         resultObj.message='Success';
        }
        catch(Exception ex)
        {
         resultObj.message='GL Account create failed :'+ex.getMessage();            
        }

        return  resultObj;
    }
}