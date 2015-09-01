/*
* Parametros mandatorios
*/
var disableRefresh=false;
var nBytes=0;
var nRefresh=-1; //Number of refresh since the first invocation
function startTime()
{
   var today=new Date();
   var h=today.getHours();
   var m=today.getMinutes();
   var s=today.getSeconds();
   // add a zero in front of numbers<10
   m=checkTime(m);
   s=checkTime(s);
   document.getElementById('publishDate').innerHTML=h+":"+m+":"+s;
   t=setTimeout(function(){startTime()},1000);
}

function checkTime(i)
{
if (i<10)
  {
  i="0" + i;
  }
return i;
}
function refreshdiv(){
      // The XMLHttpRequest object
      var seconds = 1; // el tiempo en que se refresca
      var divid = "contenido"; // el div que quieres actualizar!
      var url = "./data/dp_changes.txt"; // el archivo que ira en el div
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

      // The code...

      xmlHttp.onreadystatechange=function(){
         if(xmlHttp.readyState== 4 && xmlHttp.readyState != null){
            
            //newData=xmlHttp.responseText.split("\n");
            if ((disableRefresh == false) &&
               (nBytes != xmlHttp.responseText.length)) {
               if (( nBytes > xmlHttp.responseText.length) || 
                   (getURLParameter(PARAM_RESULTSTATE) == EXECUTION_TRANSITION )
               ){
                  dataLength=0;
                  nBytes=0;
               };
               if (getURLParameter(PARAM_REFRESH) == "false" ){
                  disableRefresh=true;
               }
               newData=xmlHttp.responseText.substring(nBytes).split("\n");
               nBytes=xmlHttp.responseText.length;
               nRefresh++;
               refreshData();
               refreshIndex(PARAM_REFRESH,"Auto Refresh","false","Disable");
               refreshIndex(PARAM_INTERVAL,"Interval Log","1,7,30,122","Last 24h,Last Week,Last Month,Last Quarter");
               refreshIndex(PARAM_STATS,"Stats","true","Enable");
               refreshDataStats();
               refreshIndex(PARAM_PIPELINE,"Pipelines",getPipelineIds(),null);
               refreshIndex(PARAM_PHASE,"Phases",getPhases(),null);
               refreshIndex(PARAM_RESULTSTATE,"Result",EXECUTION_TRANSITION+","+getResultStates(),null);
               refreshIndex(PARAM_ENVIROMENT,"Enviroments",getEnviroments(),null);
               refreshIndex(PARAM_TRIGGER,"Trigger",getTriggers(),null);
               refreshIndex(PARAM_EXECUTOR_PIPELINES,"Executors",getPipelineIds(),null);
               if (location.search.length >1){
                  refreshIndex(PARAM_DISABLEFILTERS,"Disable Filters","true","Disable");
               }
               drawTable();
               sortTable();
               drawChart(dataGraph());  
            }
            setTimeout('refreshdiv()',seconds*1000);
         }
      }
      xmlHttp.open("GET",nocacheurl,true);
      xmlHttp.send(null);
   }

   // Empieza la función de refrescar
   window.onload = function(){
      refreshdiv(); // corremos inmediatamente la funcion
      startTime();
   }
