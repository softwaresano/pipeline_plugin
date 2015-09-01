var deploymentPipelineEnviroments="";
var newData=null;
function getState(value){
   var state=new Object();
   var fieldValues=value.split("-");
   state.result=fieldValues[fieldValues.length-1];
   state.pipelineId=fieldValues[0];
   state.phase=fieldValues[fieldValues.length-2];
   state.id=value;
   if (fieldValues[fieldValues.length-1] == EXPORT_PHASE){
      state.order=fieldValues[2];
      state.module=fieldValues[1];
   } else {
      state.order="00";
      state.module="ALL";
   }
   return state;
}

function getPipelineStateEntry(columns){
   var pipelineStateEntry=new Object();
   pipelineStateEntry.date=columns[2];
   pipelineStateEntry.pipelineId=columns[0];
   pipelineStateEntry.enviroment=columns[3];
   pipelineStateEntry.state=getState(columns[4]);
   pipelineStateEntry.trigger=columns[5];
   pipelineStateEntry.buildId=columns[6];
   pipelineStateEntry.installId=columns[7];
   pipelineStateEntry.host=columns[1];
   pipelineStateEntry.job=columns[4].substring(0,columns[4].lastIndexOf("-"));
   return pipelineStateEntry;

}

function processData(type, value){
   if (type == TYPE_PIPELINEID){
      var returnValue=new String(value.pipelineId+"("+value.host+")");
      return "<a href=\"http://"+value.host+"/jenkins/view/"+value.state.pipelineId+"\" >"+returnValue+"</a>";
   } else
      if (type == PARAM_ENVIROMENT){
         return value.enviroment;
      } else 
         if (type == TYPE_DATE){
            return addConsoleColumn(value.host,value.job,value.buildId,value.date);
         } else
            if (type == TYPE_STATE){
               return "<a href=\"http://"+value.host+"/jenkins/job/"+value.job+"/"+value.buildId+"\" >"+value.state.id+"</a>";
            } else
            if (type == TYPE_RESULT ){
               return "<a href=\"http://"+value.host+"/jenkins/job/"+value.job+"/"+value.buildId+"\" >"+value.state.result+"<img src=\"./img/"+value.state.result+".png\" alt=\""+value.state.result+"\" tooltip=\""+value.state.result+"\"></a>";
            } else 
               if (type == TYPE_SUCCESS ){
                  return getSuccessfullState(value);
               } else
                    if (type == TYPE_TRIGGER){
                  return value.trigger;
               }
}

function isCorrectRow(columns){
   if (columns.length != data.sections[sectionData].head.length+2){
      return false;
   }
   return true;
}
function isInExecution(index,pipelineStateEntry){
   for (var i=index+1;i<newData.length;i++){
      var columns=newData[i].split(FIELD_SEPARATOR);
      if (isCorrectRow(columns)){
         var nextPipelineStateEntry=getPipelineStateEntry(columns);
         if ((nextPipelineStateEntry.buildId == pipelineStateEntry.buildId) &&
             (nextPipelineStateEntry.pipelineId == pipelineStateEntry.pipelineId) &&
             (nextPipelineStateEntry.host == pipelineStateEntry.host) &&
             (nextPipelineStateEntry.job == pipelineStateEntry.job) &&
             (nextPipelineStateEntry.state.result != stateExecuting) &&
             (nextPipelineStateEntry.enviroment == pipelineStateEntry.enviroment)
         ){
            return false;
         }
      }
   }
   return true;
}

function getValidData(i,columns){
   if (isCorrectRow(columns) == false){
      return null;
   }
   var pipelineStateEntry=getPipelineStateEntry(columns);
   var executorPipelines=getURLParameter(PARAM_EXECUTOR_PIPELINES);
   if ( executorPipelines != "null" ){
      pipelineStateEntry=getValidDataPipeline(pipelineStateEntry);
   } else{
      pipelineStateEntry=getValidDataLog(i,pipelineStateEntry);
   }

   if ( pipelineStateEntry != null){
      dataLength++;
   }
   return pipelineStateEntry
}

function playLastState(lastResultState){
   if (nRefresh < 1){
      return;
   }
   var e;
   try{
      var snd = new Audio("sounds/"+lastResultState+".wav");
      snd.play();
   } catch (e){
      return;
   }
}

function processPipelineStateEntry(pipelineStateEntry,isExecutor){
   var nColumnsReport=data.sections[sectionData].head.length-1;
   var k=data.sections[sectionData].data.length;
   data.sections[sectionData].data[k]=new Array();
   for (var j=0;j<nColumnsReport;j++){
      switch (j){
         case 0:
            //Fecha
            data.sections[sectionData].data[k][j]=processData(TYPE_DATE,pipelineStateEntry);
            break;
         case 1:
            //pipelineId
            data.sections[sectionData].data[k][j]=processData(TYPE_PIPELINEID,pipelineStateEntry);
            break;
         case 2:
            //Entorno
            data.sections[sectionData].data[k][j]=processData(PARAM_ENVIROMENT,pipelineStateEntry);
            break;
         case 3:
            data.sections[sectionData].data[k][j]=processData(TYPE_TRIGGER,pipelineStateEntry);
            //Cause
            break;
          case 4:
            //Estado
            data.sections[sectionData].data[k][j]=processData(TYPE_STATE,pipelineStateEntry);
            break;
           case 5:
            //Estado
            data.sections[sectionData].data[k][j]=processData(TYPE_RESULT,pipelineStateEntry);
            break;
         }
      }
      if (isExecutor){
         addExecution(pipelineStateEntry);
      }
      processStat(pipelineStateEntry);
      data.sections[sectionData].data[k][nColumnsReport]=processData(TYPE_SUCCESS,pipelineStateEntry);
      return pipelineStateEntry.state.result;
}

function refreshData(){
   if (newData == null){
      return;
   }
   var pipelineStateEntry;
   if (dataLength == 0){
      data.sections[sectionData].data=new Array();
      clearStats();
      statesStats=new Object();
   }
   var lastResultState=""
   var executorPipelines=getURLParameter(PARAM_EXECUTOR_PIPELINES);
   for (var i=0;i<newData.length;i++){
      var columns=newData[i].split(FIELD_SEPARATOR);
      pipelineStateEntry=getValidData(i,columns);
      if (pipelineStateEntry != null){
         if ( executorPipelines != "null" ){
            lastResultState=processPipelineStateEntry(pipelineStateEntry,true);
         } else {
            lastResultState=processPipelineStateEntry(pipelineStateEntry,false);
         }
       }
   }
   if (executorPipelines !=  "null" ){
      deploymentPipelineEnviroments=refreshDeploymentTable();
      if (deploymentPipelineEnviroments != null){
         createDeploymentTable();
      };
   } else {
      playLastState(lastResultState);
   }
}
