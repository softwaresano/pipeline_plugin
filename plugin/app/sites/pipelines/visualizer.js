/*
 *
 * Visualizador tablas a partir de datos JSON
 * author: Carlos Gómez (carlosg@tid.es)
 */
var nNormalTables=0;
var nSumarizeTables=0;

function getURLParameter(name){
   return decodeURI((RegExp(name + "=" + "(.+?)(&|$)").exec(location.search)||[,null])[1]);
}

function getURLParameters() {
  var url=location.search;
  if (url.length==0){
   return null;
  }
  var request = {};
  var pairs = url.substring(url.indexOf('?') + 1).split('&');
  for (var i = 0; i < pairs.length; i++) {
    var pair = pairs[i].split('=');
    if (pair.length==2){
      request[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1]);
    }
  }
  return request;
}


function addParameter(parameterName){
   var parameter=getURLParameter(parameterName);
   if (parameter != "null"){
      return "&"+parameterName+"="+parameter;
   }
   return "";
}

function addParameters(type){
   var httpRequestParameters=getURLParameters();
   var parameters="";
   if (httpRequestParameters == null){
      return parameters;
   }
   for (var i in httpRequestParameters) {
      if (i != type){
         parameters=parameters+"&"+i+"="+httpRequestParameters[i];
       }
   }
   return parameters;
}

function refreshIndex(type,title,items,textItems){
   if (data.sections[sectionData].data.length == 0){
      document.getElementById(type+"Index").innerHTML="";
      return;
   }
   if ((getURLParameter(PARAM_EXECUTOR_PIPELINES) != "null") &&
      ((type == PARAM_INTERVAL) ||
       (type == PARAM_STATS) ||
       (type == PARAM_PIPELINE) ||
       (type == PARAM_PHASE) ||
       (type == PARAM_RESULTSTATE) ||
       (type == PARAM_ENVIROMENT) ||
       (type == PARAM_TRIGGER) ||
       (type == PARAM_EXECUTOR_PIPELINES) 
      )
   ){
      document.getElementById(type+"Index").innerHTML="";
   return;
   }

   var docHTML="";
   docHTML+=addHTMLElement("h5",title);
   var itemsIds;
   if ((items!=null) && (items!=",")){
      itemsIds=items.split(",");
      }
   else{
      document.getElementById(type+"Index").innerHTML="";
      return;
   }
   var itemsHTML="";
   var parameters="";
   if  (type != PARAM_EXECUTOR_PIPELINES){
      parameters=addParameters(type);
   }    
   if (getURLParameter(type) != "null"){
      if (getURLParameter(PARAM_REFRESH) == "false"){
         itemsHTML+="<li class=\"none\"><a href=\"./index.html?"+parameters+"\" title=\"Enable\">Enable</a></li>";
      } else{
         itemsHTML+="<li class=\"none\"><a href=\"./index.html?"+parameters+"\" title=\"Disable "+type+" filter\">Disable "+type+" filter</a></li>";
      }
   }
   if (type == PARAM_DISABLEFILTERS) {
      itemsHTML="<li class=\"none\"><a href=\"./index.html\" title=\"Disable\">Disable</a></li>";
   } else{
      if ((itemsIds.length > 1) ||
            ((itemsIds.length == 1) && (type == PARAM_DISABLEFILTERS ) && 
            (getURLParameter(PARAM_DISABLEFILTERS) == "null"))||
            ((itemsIds.length == 1) && (type == PARAM_STATS) && 
            (getURLParameter(PARAM_STATS) == "null"))||
            ((itemsIds.length == 1) && (type == PARAM_REFRESH ) && 
            (getURLParameter(PARAM_REFRESH) == "null"))||
            ((itemsIds.length == 1) && (type == PARAM_EXECUTOR_PIPELINES ) && 
            (getURLParameter(PARAM_EXECUTOR_PIPELINES) == "null"))
            ){
         if (textItems != null){
               textItems=textItems.split(",");
         }
         for (var i=0;i<itemsIds.length;i++){
            var text=null;
            if (textItems != null){
               text=textItems[i];
            } else {
               text=itemsIds[i];
            }
            itemsHTML+="<li class=\"none\"><a href=\"./index.html?"+parameters+"&"+type+"="+itemsIds[i]+"\" title=\""+text+"\">"+text+"</a></li>";
         }
      }
   }
   docHTML+=addHTMLElement("ul",itemsHTML);
   document.getElementById(type+"Index").innerHTML=docHTML;
}

function drawTable(){
   var json=data;
   var docHTML=""
   docHTML+=addHTMLElement("h2",json.title);
   docHTML+=addHTMLElement("h3",json.description);
   var listView=[sectionData, sectionStats];
   var firstStats=getURLParameter("stats");
   var executorPipelines=getURLParameter(PARAM_EXECUTOR_PIPELINES);
   if ( executorPipelines != "null" ){
      listView=[sectionDeploymentTable,sectionPipeline,sectionStats,sectionData];
   } else{
         if (firstStats == "true"){
            listView=[sectionStats,sectionData];
         }
   }
   for (var indexTable in listView){
      if ((json.sections[listView[indexTable]].data.length != null ) && 
         (json.sections[listView[indexTable]].data.length > 0)){
         docHTML+=addHTMLElement("h2",json.sections[listView[indexTable]].title);
         docHTML+=addHTMLElement("p",json.sections[listView[indexTable]].description);
         // Cabecera de la tabla
         var head=json.sections[listView[indexTable]].head;
         var tableHeader ="";
         if (head.length > 0){
            tableHeader=addHTMLElement("thead",addRow("head",head));
         }
         var dades=json.sections[listView[indexTable]].data;
         var tableBody=null;
         var dir=null;
         if (json.sections[listView[indexTable]].hasOwnProperty("dir")){
            dir=DESC_DIR_TABLE;
         }
         tableBody=drawTableBody(dades,dir);
         if (tableHeader != ""){
            docHTML+=addHTMLElement("table id=\"styling-custom-striping"+(nNormalTables++)+"\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\"",tableHeader+tableBody);
         }
         var sumarize=json.sections[listView[indexTable]].sumarize;
         if (sumarize != null){
            tableBody=drawTableBody(sumarize);
            if ((tableBody!="")){
               docHTML+=addHTMLElement("table id=\"styling-resume-striping"+(nSumarizeTables++)+"\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\"",tableBody);
            }
         }
      }
   }
   document.getElementById("contenido").innerHTML=docHTML;
}

function sortTable(){
  for (var i=0;i<nNormalTables;i++){
        $("#styling-custom-striping"+i).tableSorter({
            //sortDir: "0", //0-->Ascending 1-->Descending
            sortColumn: 'name',              // Integer or String of the name of the column to sort by.
            sortClassAsc: 'headerSortUp',    // class name for ascending sorting action to header
            sortClassDesc: 'headerSortDown', // class name for descending sorting action to header
            headerClass: 'header',           // class name for headers (th's)
            stripingRowClass: ['even','odd'],// class names for striping supplyed as a array.
            stripeRowsOnStartUp: true,
            dateFormat : "dd/mm/yyyy"
        });
    }
    for (var i=0;i<nSumarizeTables;i++){
        $("#styling-resume -striping"+i).tableSorter({
            //sortDir: "0", //0-->Ascending 1-->Descending
            sortColumn: 'name',              // Integer or String of the name of the column to sort by.
            sortClassAsc: 'headerSortUp',    // class name for ascending sorting action to header
            sortClassDesc: 'headerSortDown', // class name for descending sorting action to header
            headerClass: 'header',           // class name for headers (th's)
            stripingRowClass: ['even','odd'],// class names for striping supplyed as a array.
            stripeRowsOnStartUp: true,
            dateFormat : "dd/mm/yyyy"
        });
    }
}

