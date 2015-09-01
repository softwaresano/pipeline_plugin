var md5DeploymentTable="";

function refreshDataDeploymentTable(deploymentTable){
   var newData=deploymentTable.split("\n");
   var enviroments1;
   var enviroments=new Array();
   var nEnviroments=0;
   var nLength=0;
   data.sections[sectionDeploymentTable].data=new Array();
   for (var i=0;i<newData.length;i++){
      var line=trim(newData[i])
      if (line.indexOf("# Enviroments:") == 0){
         enviroments1 = line.substring("# Enviroments:".length).split(" ");
      
         for (var j=0;j<enviroments1.length;j++){
            if (trim(enviroments1[j]).length > 0){
               enviroments[nEnviroments++]=trim(enviroments1[j]);
            }
         }
      } else {
         if ((line.indexOf("#") == -1) && (line.length>0)){
            var columns=line.split(FIELD_SEPARATOR);
            for (var j=0;j<columns.length;j++){
               columns[j]=trim(columns[j]);
            }
            //Add last Enviroment
            if (lastEnviromentInstallations.hasOwnProperty(columns[0])){
               var pipelineStateEntry=lastEnviromentInstallations[columns[0]];
               columns[columns.length]=addBuildIdColumn(pipelineStateEntry.host,
                           pipelineStateEntry.pipelineId+"-ALL-01-"+INSTALL_PHASE,pipelineStateEntry.installId)
            } else{
               columns[columns.length]="N/A";
            }
            //Add rollback
            if (rollbackEnviromentInstallations.hasOwnProperty(columns[0])){
               var pipelineStateEntry=rollbackEnviromentInstallations[columns[0]];
               columns[columns.length]=addRollbackInstallationId(pipelineStateEntry);
            } else{
               columns[columns.length]="N/A";
            }
            data.sections[sectionDeploymentTable].data[nLength++]=columns;
         }
      }
   }
   return enviroments;
}


function refreshDeploymentTable(){
      var executorPipelines=getURLParameter(PARAM_EXECUTOR_PIPELINES);
      var index=executorPipelines.indexOf("(");
      var pipelineId=executorPipelines.substring(0,index);
      var hostPipeline=executorPipelines.substring(index+1,executorPipelines.length-1);
      var deploymentTableSuffix="-ALL-01-install/lastSuccessfulBuild/artifact/target/DEPLOYMENT_PIPELINE/deployment.txt"
      var url="http://"+hostPipeline+"/jenkins/job/"+pipelineId+deploymentTableSuffix;
      var xmlHttp;
      try{
         xmlHttp=new XMLHttpRequest(); // Firefox, Opera 8.0+, Safari
      }
      catch (e){
         try{
            xmlHttp=new ActiveXObject("Msxml2.XMLHTTP"); // Internet Explorer
         }
         catch (e){
            try{
               xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
            }
            catch (e){
               alert("Tu explorador no soporta AJAX.");
               return false;
            }
         }
      }
      
      // Timestamp for preventing IE caching the GET request
      var timestamp = parseInt(new Date().getTime().toString().substring(0, 10));
      var nocacheurl = url+"?t="+timestamp;
      try {
         //Avoid cross-domain problem with ajax (redirect to php)
         xmlHttp.open("GET","redir.php?url="+ encodeURIComponent(nocacheurl),false);
         xmlHttp.send(null);
         if ((xmlHttp.status == 200 ) && (xmlHttp.responseText.length > 0)){
            //Hay al menos una ejecución exitosa y por tanto se ha publicado la deployment Table
               return refreshDataDeploymentTable(xmlHttp.responseText);
            }
         else{
            return null;
         }
      } catch (e){
         window.alert("No se puede recuperar la deployment table. Puede ser que no se haya realizado ninguna instalación exitosa");
      }
};

