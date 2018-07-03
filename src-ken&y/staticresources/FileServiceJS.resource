/*ShareType = "I"= Inferred permission. The user’s permission is determined by the related record. For shares with a library, this is defined by the permissions the user has in that library.
            Other Share Types are:
            V Viewer premission. The user can explicitly view but not edit the shared file.
            C Collaborator permission. The user can explicitly view and edit the shared file.
*/
var FileServiceUtil = function(){
    return{
            GetReturnObj: function(fileNameStr, fileIdStr, isFirstVersion){
                var obj = { fileName : fileNameStr, fileId :fileIdStr, firstVersion:isFirstVersion};
                return obj;
            },
            
            UploadContentVersion: function (apiSessionId, fileContent, isBase64Encoded, filename, parentId, fileShareType, reasonForChange,onUploadFileSuccess,onUploadFileFailure){
                FileServiceUtil.CreaeFileWithVersionControl(apiSessionId, fileContent, isBase64Encoded, filename, parentId, fileShareType, reasonForChange,onUploadFileSuccess, onUploadFileFailure);
            },
            
            //Assumption: Files have unique titles within an org
            CreaeFileWithVersionControl: function (apiSessionId, fileContent, isBase64Encoded, filename, parentId, fileShareType, reasonForChange,onUploadFileSuccess, onUploadFileFailure){
                var file = FileServiceUtil.CreateFile(fileContent, filename, isBase64Encoded);
                
                //Success callback for GetContentDocumentId method
                var onGetContentDocumentIdSuccess = function(contentDocumentId, fileId){
                    if (contentDocumentId){                    
                        FileServiceUtil.CreateContentDocumentLink(apiSessionId, fileId, filename, contentDocumentId, parentId, fileShareType, onUploadFileSuccess, onUploadFileFailure);
                    }
                }
                
                FileServiceUtil.InsertFile(apiSessionId, file, parentId, reasonForChange,onGetContentDocumentIdSuccess,onUploadFileSuccess, onUploadFileFailure);
            },
            
            InsertFile: function (apiSessionId,file, parentId,reasonForChange,onGetContentDocumentIdSuccess,onUploadFileSuccess, onUploadFileFailure){
                sforce.connection.sessionId= apiSessionId;
                var existingContentDocumentId;
                
                // Check if file exists
                result = sforce.connection.query("SELECT Id, Title, ContentDocumentId from ContentVersion where Title  = \'" + file.Title + "\'",
                {
                     onSuccess: function ( result , source ) { 
                          console.log('InsertFile query success:' + result);
                          if(result.records){
                              // Create a new version for existing file
                              var contentVersion;
                              if (result.records instanceof Array){
                                 contentVersion = result.records[0];
                              }
                              else{
                                 contentVersion = result.records;
                              }
                              existingContentDocumentId = contentVersion.ContentDocumentId;
                              file.ContentDocumentId = contentVersion.ContentDocumentId;
                              if (reasonForChange){
                                  file.ReasonForChange = reasonForChange;
                              }
                          }
                         
                          // Insert File(ContentVersion)
                          sforce.connection.create([file],
                          { 
                              onSuccess: function ( result , source ) {
                                  console.log('create file success:' + result);
                                  fileId = result[0].get('id');
                                  
                                  if(existingContentDocumentId){
                                      //A new version of the file was successfully created
                                      var returnObj = FileServiceUtil.GetReturnObj(file.Title,fileId, false);
                                      onUploadFileSuccess(returnObj);
                                  }
                                  else if (parentId){
                                      //New file was created,
                                      FileServiceUtil.AttachNewFileToParentObject(apiSessionId, fileId, onGetContentDocumentIdSuccess, onUploadFileFailure);
                                  }
                               },
                               onFailure : function (error , source ) {
                                   console.log('create file failed:' + error);
                                   onUploadFileFailure(error);
                               }
                          });
                     },
                     onFailure:function (error , source ) {
                          console.log('InsertFile query failed:' + error);
                          onUploadFileFailure(error);
                     }
                });
            },
            
            //Queries File to get its ContentDocumentId
            GetContentDocumentId: function(apiSessionId, fileId, onGetContentDocumentIdSuccess, onUploadFileFailure){
                var contentDocumentId;
                sforce.connection.sessionId= apiSessionId;
                result = sforce.connection.query("SELECT ContentDocumentId, Title from ContentVersion where Id  = \'" + fileId+ "\'",
                {
                     onSuccess: function ( result , source ) {
                          console.log('GetContentDocumentId query success:' + result);
                          records = result.records;
                          contentDocumentId = records.ContentDocumentId;
                          onGetContentDocumentIdSuccess(contentDocumentId, fileId);
                     },
                     onFailure:function (error , source ) {
                          console.log('GetContentDocumentId query failed:' + error);
                          onUploadFileFailure(error);
                     }
                });
            },
            
             //New file was created, get contentDocumentId for ContentVersion and insert ContentDocumentLink
            AttachNewFileToParentObject: function(apiSessionId, fileId, onGetContentDocumentIdSuccess, onUploadFileFailure){ 
                FileServiceUtil.GetContentDocumentId(apiSessionId, fileId, onGetContentDocumentIdSuccess, onUploadFileFailure);
            },
            
            CreateContentDocumentLink: function(apiSessionId, fileId, fileName, contentDocumentId, parentId, shareType, onUploadFileSuccess, onUploadFileFailure){
                sforce.connection.sessionId= apiSessionId;
                var documentLink =  new sforce.SObject('ContentDocumentLink');
                documentLink.ContentDocumentId =  contentDocumentId;
                documentLink.LinkedEntityId = parentId;
                documentLink.ShareType = shareType;
                sforce.connection.create([documentLink],
                {
                    onSuccess: function ( result , source ) {
                        console.log('CreateContentDocumentLink set parent id success:' + result);
                        var returnObj = FileServiceUtil.GetReturnObj(fileName,fileId,true);
                        onUploadFileSuccess(returnObj);
                    },
                    onFailure:function (error , source ) {
                        console.log('CreateContentDocumentLink set parent id failed:' + error);
                        onUploadtFileFailure(error);
                    }
                });
            },
            
            CreateFile: function (fileContent, filename, isBase64Encoded){
                var file = new sforce.SObject('ContentVersion');
                var data =  "";
                if(isBase64Encoded) {
                    data = fileContent;
                } else {
                    data = (new sforce.Base64Binary(fileContent)).toString();
                }
                file.VersionData = data;
                file.Title  = filename;
                file.Description = filename;
                file.ContentLocation = "S"; //This is a document located within Salesforce.
                file.isMajorVersion = false; // Major versions cannot be replaced
                file.PathOnClient = "/" + filename;
                return file;
            }
      };
}();