function addRow(type,values){
    if (values.length>0){
        var tag="td";
        var docHTML="";
        if ( type == "head" ){
            tag="th";
        }
        for (var i=0;i<values.length;i++){
            docHTML+=addHTMLElement(tag,values[i]);
        }
        return addHTMLElement("tr",docHTML);
    }
    return "";
}

function addHTMLElement(anElement,aContent){
    var docHTML="";
    var element;
    if (anElement != null){
        element=trim(anElement);
        docHTML="<"+element+">"+aContent+"</"+ element.split(" ")[0]+">";
    }
    return docHTML;
}

function addImgElement(src,alt,tooltip){
   var element;
   if (src != null){
      element="<img src=\""+trim(src)+"\"";
      if (alt != null){
         element+=" alt=\""+trim(alt)+"\"";
      }
      if (tooltip != null){
         element+=" tooltip=\""+trim(tooltip)+"\"";
      }
      return element+"/>";
   }
   return "";
}

function drawTableBody(data){
   return drawTableBody(data,ASC_DIR_TABLE);
}

function drawTableBody(data,dir){
    var tableBody ="";
    if ((data !=null) && (data.length > 0)){
        for (var i=0;i<data.length;i++){
            if (dir == DESC_DIR_TABLE){
               tableBody+=addRow("body",data[data.length-i-1]);
            } else{
               tableBody+=addRow("body",data[i]);
            }
        }
        tableBody=addHTMLElement("tbody",tableBody);
    }
    return tableBody
}
