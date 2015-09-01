var data;
var sectionData=0;
var sectionStats=1;
var sectionPipeline=2;
var sectionDeploymentTable=3;
var ASC_DIR_TABLE="asc";
var DESC_DIR_TABLE="desc"; // Draw table from the end to the begining.
var dataLength=0;
var interval=null;
function loadData(){
   var rows;
   data= {
      title:      "Pipeline Dashboard",
      description:"All pipeline events in deployment pipeline",
      sections:[
      {
         title:       "Pipeline Events",
         description: "All pipeline events.<a href='./dp_help.html#Pipeline_Events'>Help</a>",
         head:       [  "Date",
                        "PipelineId",
                        "Enviromment",
                        "Trigger",
                        "Event",
                        "Result",
                        "Success(%)"
                     ],//Cabeceras
         dir: DESC_DIR_TABLE,
         data:       []
      },
      {
         title:       "Pipeline stats",
         description: "All pipeline stats.<a href='./dp_help.html#Pipeline_Stats'>Help</a>",
         head:       [  "Stat",
                        "Value"
                     ],//Cabeceras
         data:       []
      },
      {
         title:       "Pipeline Executions",
         description: "Pipelines executions in differents enviroments.<a href='./dp_help.html#Pipeline_Executions'>Help</a>",
         head:       [  "Date",
                        "#Build Id",
                     ],//Cabeceras
         dir: DESC_DIR_TABLE,
         data:       []
      },
      {
         title:       "Deployment Table",
         description: "Deployment table configuration.<a href='./dp_help.html#Deployment_Table'>Help</a>",
         head:       [  "Enviroment",
                        "IP/Host",
                        "Packages",
                        "Current Installation",
                        "Rollback Installation",
                     ],//Cabeceras
         data:       []
      },

   ]}
   refreshData();
}

loadData();
