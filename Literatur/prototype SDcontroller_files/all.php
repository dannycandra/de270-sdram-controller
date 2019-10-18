
 /* AC_RunActiveContent.js */
//v1.7
// Flash Player Version Detection
// Detect Client Browser type
// Copyright 2005-2007 Adobe Systems Incorporated.  All rights reserved.
var isIE  = (navigator.appVersion.indexOf("MSIE") != -1) ? true : false;
var isWin = (navigator.appVersion.toLowerCase().indexOf("win") != -1) ? true : false;
var isOpera = (navigator.userAgent.indexOf("Opera") != -1) ? true : false;

function ControlVersion()
{
	var version;
	var axo;
	var e;

	// NOTE : new ActiveXObject(strFoo) throws an exception if strFoo isn't in the registry

	try {
		// version will be set for 7.X or greater players
		axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7");
		version = axo.GetVariable("$version");
	} catch (e) {
	}

	if (!version)
	{
		try {
			// version will be set for 6.X players only
			axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6");
			
			// installed player is some revision of 6.0
			// GetVariable("$version") crashes for versions 6.0.22 through 6.0.29,
			// so we have to be careful. 
			
			// default to the first public version
			version = "WIN 6,0,21,0";

			// throws if AllowScripAccess does not exist (introduced in 6.0r47)		
			axo.AllowScriptAccess = "always";

			// safe to call for 6.0r47 or greater
			version = axo.GetVariable("$version");

		} catch (e) {
		}
	}

	if (!version)
	{
		try {
			// version will be set for 4.X or 5.X player
			axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.3");
			version = axo.GetVariable("$version");
		} catch (e) {
		}
	}

	if (!version)
	{
		try {
			// version will be set for 3.X player
			axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash.3");
			version = "WIN 3,0,18,0";
		} catch (e) {
		}
	}

	if (!version)
	{
		try {
			// version will be set for 2.X player
			axo = new ActiveXObject("ShockwaveFlash.ShockwaveFlash");
			version = "WIN 2,0,0,11";
		} catch (e) {
			version = -1;
		}
	}
	
	return version;
}

// JavaScript helper required to detect Flash Player PlugIn version information
function GetSwfVer(){
	// NS/Opera version >= 3 check for Flash plugin in plugin array
	var flashVer = -1;
	
	if (navigator.plugins != null && navigator.plugins.length > 0) {
		if (navigator.plugins["Shockwave Flash 2.0"] || navigator.plugins["Shockwave Flash"]) {
			var swVer2 = navigator.plugins["Shockwave Flash 2.0"] ? " 2.0" : "";
			var flashDescription = navigator.plugins["Shockwave Flash" + swVer2].description;
			var descArray = flashDescription.split(" ");
			var tempArrayMajor = descArray[2].split(".");			
			var versionMajor = tempArrayMajor[0];
			var versionMinor = tempArrayMajor[1];
			var versionRevision = descArray[3];
			if (versionRevision == "") {
				versionRevision = descArray[4];
			}
			if (versionRevision[0] == "d") {
				versionRevision = versionRevision.substring(1);
			} else if (versionRevision[0] == "r") {
				versionRevision = versionRevision.substring(1);
				if (versionRevision.indexOf("d") > 0) {
					versionRevision = versionRevision.substring(0, versionRevision.indexOf("d"));
				}
			}
			var flashVer = versionMajor + "." + versionMinor + "." + versionRevision;
		}
	}
	// MSN/WebTV 2.6 supports Flash 4
	else if (navigator.userAgent.toLowerCase().indexOf("webtv/2.6") != -1) flashVer = 4;
	// WebTV 2.5 supports Flash 3
	else if (navigator.userAgent.toLowerCase().indexOf("webtv/2.5") != -1) flashVer = 3;
	// older WebTV supports Flash 2
	else if (navigator.userAgent.toLowerCase().indexOf("webtv") != -1) flashVer = 2;
	else if ( isIE && isWin && !isOpera ) {
		flashVer = ControlVersion();
	}	
	return flashVer;
}

// When called with reqMajorVer, reqMinorVer, reqRevision returns true if that version or greater is available
function DetectFlashVer(reqMajorVer, reqMinorVer, reqRevision)
{
	versionStr = GetSwfVer();
	if (versionStr == -1 ) {
		return false;
	} else if (versionStr != 0) {
		if(isIE && isWin && !isOpera) {
			// Given "WIN 2,0,0,11"
			tempArray         = versionStr.split(" "); 	// ["WIN", "2,0,0,11"]
			tempString        = tempArray[1];			// "2,0,0,11"
			versionArray      = tempString.split(",");	// ['2', '0', '0', '11']
		} else {
			versionArray      = versionStr.split(".");
		}
		var versionMajor      = versionArray[0];
		var versionMinor      = versionArray[1];
		var versionRevision   = versionArray[2];

        	// is the major.revision >= requested major.revision AND the minor version >= requested minor
		if (versionMajor > parseFloat(reqMajorVer)) {
			return true;
		} else if (versionMajor == parseFloat(reqMajorVer)) {
			if (versionMinor > parseFloat(reqMinorVer))
				return true;
			else if (versionMinor == parseFloat(reqMinorVer)) {
				if (versionRevision >= parseFloat(reqRevision))
					return true;
			}
		}
		return false;
	}
}

function AC_AddExtension(src, ext)
{
  if (src.indexOf('?') != -1)
    return src.replace(/\?/, ext+'?'); 
  else
    return src + ext;
}

function AC_Generateobj(objAttrs, params, embedAttrs) 
{ 
  var str = '';
  if (isIE && isWin && !isOpera)
  {
    str += '<object ';
    for (var i in objAttrs)
    {
      str += i + '="' + objAttrs[i] + '" ';
    }
    str += '>';
    for (var i in params)
    {
      str += '<param name="' + i + '" value="' + params[i] + '" /> ';
    }
    str += '</object>';
  }
  else
  {
    str += '<embed ';
    for (var i in embedAttrs)
    {
      str += i + '="' + embedAttrs[i] + '" ';
    }
    str += '> </embed>';
  }

  document.write(str);
}

function AC_FL_RunContent(){
  var ret = 
    AC_GetArgs
    (  arguments, ".swf", "movie", "clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
     , "application/x-shockwave-flash"
    );
  AC_Generateobj(ret.objAttrs, ret.params, ret.embedAttrs);
}

function AC_SW_RunContent(){
  var ret = 
    AC_GetArgs
    (  arguments, ".dcr", "src", "clsid:166B1BCA-3F9C-11CF-8075-444553540000"
     , null
    );
  AC_Generateobj(ret.objAttrs, ret.params, ret.embedAttrs);
}

function AC_GetArgs(args, ext, srcParamName, classid, mimeType){
  var ret = new Object();
  ret.embedAttrs = new Object();
  ret.params = new Object();
  ret.objAttrs = new Object();
  for (var i=0; i < args.length; i=i+2){
    var currArg = args[i].toLowerCase();    

    switch (currArg){	
      case "classid":
        break;
      case "pluginspage":
        ret.embedAttrs[args[i]] = args[i+1];
        break;
      case "src":
      case "movie":	
        args[i+1] = AC_AddExtension(args[i+1], ext);
        ret.embedAttrs["src"] = args[i+1];
        ret.params[srcParamName] = args[i+1];
        break;
      case "onafterupdate":
      case "onbeforeupdate":
      case "onblur":
      case "oncellchange":
      case "onclick":
      case "ondblclick":
      case "ondrag":
      case "ondragend":
      case "ondragenter":
      case "ondragleave":
      case "ondragover":
      case "ondrop":
      case "onfinish":
      case "onfocus":
      case "onhelp":
      case "onmousedown":
      case "onmouseup":
      case "onmouseover":
      case "onmousemove":
      case "onmouseout":
      case "onkeypress":
      case "onkeydown":
      case "onkeyup":
      case "onload":
      case "onlosecapture":
      case "onpropertychange":
      case "onreadystatechange":
      case "onrowsdelete":
      case "onrowenter":
      case "onrowexit":
      case "onrowsinserted":
      case "onstart":
      case "onscroll":
      case "onbeforeeditfocus":
      case "onactivate":
      case "onbeforedeactivate":
      case "ondeactivate":
      case "type":
      case "codebase":
      case "id":
        ret.objAttrs[args[i]] = args[i+1];
        break;
      case "width":
      case "height":
      case "align":
      case "vspace": 
      case "hspace":
      case "class":
      case "title":
      case "accesskey":
      case "name":
      case "tabindex":
        ret.embedAttrs[args[i]] = ret.objAttrs[args[i]] = args[i+1];
        break;
      default:
        ret.embedAttrs[args[i]] = ret.params[args[i]] = args[i+1];
    }
  }
  ret.objAttrs["classid"] = classid;
  if (mimeType) ret.embedAttrs["type"] = mimeType;
  return ret;
}



 /* ajax.js */
/* Ajax functions */

function ajax() {
    var tmp;
    try {
      tmp=new XMLHttpRequest();
    } catch (e1) { try {
            tmp=new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e2) { try {
                tmp=new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e3) {
                alert("Your browser does not support AJAX, Get firefox!");
                window.location="http://getfirefox.com/";
                return false;
            }
        }
    }
    return tmp;
}

function loading() {
    return '<img src="img/loading.gif" alt="loading" title="loading" /> Loading page, please wait...';
}

function load_main(site) {
    var a, b;
    a=ajax()
    b=document.getElementById('dmc');
    a.onreadystatechange=function() {
        if(a.readyState==4) {
            b.innerHTML=a.responseText;
        }
    };
    b.innerHTML=loading();
    a.open("GET","index.php?ajax&do="+site);
    a.send(null);
    scroll(0,0);
}

/* End ajax functions */


 /* forum.js */
/*Forum functions under here! */

var forum_last_a = new Array;
var forum_last_i = -1;

function fedit(id) {
    document.getElementById("f_"+id).style.display="block";
    document.getElementById("t_"+id).style.display="none";
}

function forum(href) {
    return false; //Delete this row to enable ajax in the forums.
    forum_last_i += 1;
    forum_last_a[forum_last_i] = href;
    
    var f,x;
    f=document.getElementById('forum_top');
    x=ajax();
    
    if(x === false) {
        return false;
    }
    
    x.onreadystatechange=function() {
        if(x.readyState==4) {
            f.innerHTML=x.responseText;
        }
    };
    
    f.innerHTML=loading();
    
    x.open("GET",href+"&ajax",true);
    x.send(null);
    scroll(0,0);
    
    return true;
}

function forum_back() {
    if(forum_last_i > 0) {
        forum_last_i -= 2;
        forum(forum_last_a[forum_last_i+1]);
    }
}

/* End forum functions here! */


 /* ie6.js */



 /* menu.js */

function toggle(element) {
    
    i = 0;
    
    do {
        element = element.nextSibling;
        i++;
    } while(i < 24 && element.nodeName && element.nodeName.toLowerCase() != "ul");
    
    if(element.style) {
        
        if(element.style.display == "none") {
            element.style.display = "block";
        } else {
            element.style.display = "none";
        }
        
        return true;
        
    } else {
        
        return false;
        
    }
    
}



 /* pngfix.js */
/*
 
Correctly handle PNG transparency in Win IE 5.5 & 6.
http://homepage.ntlworld.com/bobosola. Updated 18-Jan-2006.

Use in <HEAD> with DEFER keyword wrapped in conditional comments:
<!--[if lt IE 7]>
<script defer type="text/javascript" src="pngfix.js"></script>
<![endif]-->

*/

var arVersion = navigator.appVersion.split("MSIE")
var version = parseFloat(arVersion[1])

if ((version >= 5.5) && (document.body.filters)) 
{
   for(var i=0; i<document.images.length; i++)
   {
      var img = document.images[i]
      var imgName = img.src.toUpperCase()
      if (imgName.substring(imgName.length-3, imgName.length) == "PNG")
      {
         var imgID = (img.id) ? "id='" + img.id + "' " : ""
         var imgClass = (img.className) ? "class='" + img.className + "' " : ""
         var imgTitle = (img.title) ? "title='" + img.title + "' " : "title='" + img.alt + "' "
         var imgStyle = "display:inline-block;" + img.style.cssText 
         if (img.align == "left") imgStyle = "float:left;" + imgStyle
         if (img.align == "right") imgStyle = "float:right;" + imgStyle
         if (img.parentElement.href) imgStyle = "cursor:hand;" + imgStyle
         var strNewHTML = "<span " + imgID + imgClass + imgTitle
         + " style=\"" + "width:" + img.width + "px; height:" + img.height + "px;" + imgStyle + ";"
         + "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
         + "(src=\'" + img.src + "\', sizingMethod='scale');\"></span>" 
         img.outerHTML = strNewHTML
         i = i-1
      }
   }
}



 /* project.js */
/* Project functions */

function pedit(id,l) {
    f=document.getElementById('f_'+id);
    p=document.getElementById('p_'+id);
    
    if(l != -1) {
        f.text.style.width="99%";
        f.text.style.height=16*(l+3)+"px";
    }
    p.style.display="none";
    f.style.display="inline";
}

function pdelete(id,pr,pa) {
    if(!confirm("Sure?")) return false;
    
    var a,b;
    a=document.getElementById("d_"+id);
    b=ajax();
    
    b.onreadystatechange=function() {
        if(b.readyState==4) {
            a.innerHTML=b.responseText;
        }
    };
    
    a.innerHTML='<img src="img/loading.gif" />';
    
    b.open("GET","?ajax&do=pdelete&proj="+pr+"&page="+pa+"&sort=1&titl="+id,true);
    b.send(null);
    
    return true;
}

function addmaint(pr) {
    m=prompt("Please enter the new maintainer's username, firstname or lastname.");
    if(m == null) return false;
    if(m.length < 1) return false;
    window.location.href="project_edit_maintainers," + pr + ",search," + m;
    return true;
}

function psort(dir,id) {
    var a=document.getElementById(id);
    if(dir == "add" || dir == "rem") {
        if(dir == "add") {
            var b = document.createElement('option');
            var c = document.getElementById('addpagename');
            if(c.value == "" || c.value == " ") { return false; }
            b.value=c.value.replace(' ','_').toLowerCase();
            b.text=c.value;
            if(a.selectedIndex == a.length-1) {
                a.add(b,null);
            } else {
                a.add(b,a.options[a.selectedIndex+1]);
            }
            a.selectedIndex += 1;
            a.size += 1;
        } else {
            a.remove(a.selectedIndex);
            a.size -= 1;
        }
    } else {
        if(dir == "upp") {
            if(a.selectedIndex == 0) return false;
        } else {
            if(a.selectedIndex == a.size-1) return false;
        }
        var b = a.options[a.selectedIndex];
        if(dir == "upp") {
            a.selectedIndex-=1;
        } else {
            a.selectedIndex+=1;
        }
        var c = a.options[a.selectedIndex];
        var d = document.createElement('option');
        d.value=b.value;
        d.text=b.text;
        a.remove(b.index);
        if(dir == "upp") {
            a.add(d,c);
            a.selectedIndex = c.index-1;
        } else {
            a.add(d,a.options[c.index+1]);
            a.selectedIndex = c.index+1;
        }
    }
    return true;
}

function psort_done() {
    a=document.getElementById("blocks");
    a.multiple=true;
    for(i=0;i<a.size;i++) {
        //a.options[i].value=a.options[i].innerHTML;
        a.options[i].selected=true;
    }
    return true;
}

/* End project functions */


 /* register.js */
/* Register functions */
/*
function check_register() {
    if(document.getElementById('reg_res').innerHTML.match('plus.png') == null) {
        alert("Username...");
        scroll(0,0);
        return false;
    }
    if(document.getElementById('reg_res2').innerHTML.match('plus.png') == null) {
        alert("Email...");
        scroll(0,0);
        return false;
    }
    var iama, fpga, asic, ip, veri;
    iama=document.getElementsByName('iama')[0];
    fpga=document.getElementById('fpga_dev');
    asic=document.getElementById('asic_dev');
    ip  =document.getElementById('ipco_dev');
    veri=document.getElementById('veri_dev');
    var a, b, c;
    a=document.getElementById("regform");
    b=a.getElementsByTagName("input");
    for(c=0;c<b.length;c++) {
        if(b[c].title == "need") {
            if(b[c].name.substr(0,4) != "org_" || iama.selectedIndex == 2) {
                if(b[c].value == "") {
                    alert("You need to fill in: "+b[c].name+"!");
                    return false;
                }
            }
        }
        if(b[c].title == "need_fpga") {
            if(b[c].value == "" && fpga.selectedIndex != 1) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
        if(b[c].title == "need_asic") {
            if(b[c].value == "" && asic.selectedIndex != 1) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
        if(b[c].title == "need_ip") {
            if(b[c].value == "" && ip.selectedIndex != 1) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
        if(b[c].title == "need_veri") {
            if(b[c].value == "" && veri[0].selectedIndex != 1) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
    }
    if(fpga.selectedIndex == 0) {
        alert("You need to fill in: fpga_dev!");
        return false;
    }
    if(asic.selectedIndex == 0) {
        alert("You need to fill in: asic_dev!");
        return false;
    }
    if(ip.selectedIndex == 0) {
        alert("You need to fill in: ipco_dev!");
        return false;
    }
    if(veri[0].selectedIndex == 0) {
        alert("You need to fill in: veri_dev!");
        return false;
    }
    return true;
}
*/
function check_accedit() {
    var iama, fpga, asic, ip, veri;
    iama=document.getElementsByName('iama')[0];
    fpga=document.getElementsByName('fpga_dev');
    asic=document.getElementsByName('asic_dev');
    ip  =document.getElementsByName('ipco_dev');
    veri=document.getElementsByName('veri_dev');
    var a, b, c;
    a=document.getElementById("acceditform");
    b=a.getElementsByTagName("input");
    for(c=0;c<b.length;c++) {
        if(b[c].title == "need") {
            if(b[c].name.substr(0,4) != "org_" || iama.selectedIndex == 2) {
                if(b[c].value == "") {
                    alert("You need to fill in: "+b[c].name+"!");
                    return false;
                }
            }
        }
        if(b[c].title == "need_fpga") {
            if(b[c].value == "" && fpga[0].selectedIndex != 0) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
        if(b[c].title == "need_asic") {
            if(b[c].value == "" && asic[0].selectedIndex != 0) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
        if(b[c].title == "need_ip") {
            if(b[c].value == "" && ip[0].selectedIndex != 0) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
        if(b[c].title == "need_veri") {
            if(b[c].value == "" && veri[0].selectedIndex != 0) {
                alert("You need to fill in: "+b[c].name+"!");
                return false;
            }
        }
    }
    return true;
}

function cshowhide() {
    var a=document.getElementsByName('iama');
    if(a[0].selectedIndex == 2) {
        cshow();
    } else {
        chide();
    }
}

function chide() {
    document.getElementById('companythings').style.display="none";
    var a, b;
    a=document.getElementById('companythings').getElementsByTagName('input');
    for(b=0;b<a.length;b++) {
        a[b].value='n/a';
    }
}

function cshow() {
    document.getElementById('companythings').style.display="inline";
    var a, b;
    a=document.getElementById('companythings').getElementsByTagName('input');
    for(b=0;b<a.length;b++) {
        a[b].value='';
    }
}

function cun() {
    if(uname_counter != -1) {
        clearTimeout(uname_counter);
    }
    uname_counter=setTimeout('cun_now()',500);
}

function cun_now() {
    var a, b, c;
    a=ajax();
    b=document.getElementById('reg_res');
    c=document.getElementById('my_uname').value
    if(c.length > 0) {
        a.onreadystatechange=function() {
            if(a.readyState==4) {
                b.innerHTML=a.responseText;
            }
        };
        b.innerHTML='Loading';
        a.open("GET","check_username.php?un="+c);
        a.send(null);
    } else {
        b.innerHTML=' ';
    }
}


function cem() {
    if(email_counter != -1) {
        clearTimeout(email_counter);
    }
    email_counter=setTimeout('cem_now()',500);
}

function cem_now() {
    var a, b, c;
    a=ajax();
    b=document.getElementById('reg_res2');
    c=document.getElementById('my_email').value
    if(c.length > 0) {
        a.onreadystatechange=function() {
            if(a.readyState==4) {
                b.innerHTML=a.responseText;
            }
        };
        b.innerHTML='Loading';
        a.open("GET","check_email.php?em="+c);
        a.send(null);
    } else {
        b.innerHTML=' ';
    }
}

/* End register functions */


 /* scripts.js */
var uname_counter = -1;
var email_counter = -1;

function au_filter(id1,id2) {
    sea=document.getElementById(id1).value;
    sel=document.getElementById(id2);
    reg = new RegExp(sea);
    for(i=0;i<sel.length;i=i+1) {
        if(reg.test(sel.options[i].innerHTML)) {
            sel.options[i].style.display="block";
        } else {
            sel.options[i].style.display="none";
        }
    }
}

function au_clear_filter(id1,id2) {
    sea=document.getElementById(id1).value;
    sel=document.getElementById(id2);
    for(i=0;i<sel.length;i=i+1) {
        sel.options[i].style.display="block";
    }
}

function showhide(id) {
    if(document.getElementById(id).style.display != "block")
        document.getElementById(id).style.display = "block";
    else
        document.getElementById(id).style.display = "none";
}

function p_showcat_select(id) {
    a=document.getElementById(id);
    if(a.selectedIndex == 0) {
        p_showallcat();
    } else {
        b=a.options[a.selectedIndex].text.substr(0,3);
        p_showcat(b.toLowerCase());
    }
}


function p_showcat(cat) {
    p_hideallcat();
    document.getElementById('pc_'+cat).style.display="list-item";
}

function p_hideallcat() {
    a= ['ari','pro','com','cop','cry','dsp','ecc','lib','mem','mic','oth','soc','sys','vid'];
    for(b in a) {
        document.getElementById('pc_'+a[b]).style.display="none";
    }
}

function p_showallcat() {
    a= ['ari','pro','com','cop','cry','dsp','ecc','lib','mem','mic','oth','soc','sys','vid'];
    for(b in a) {
        document.getElementById('pc_'+a[b]).style.display="list-item";
    }
}

function printer_switch() {
    if(document.getElementById('dmc')) {
        document.getElementById('main').innerHTML='<img src="img/mid1.png" style="float: left;" class="noprint" onclick="printer_switch()" />' + document.getElementById('dmc').innerHTML;
        document.getElementById('main').style.backgroundColor = "white";
    } else {
        history.go(0);
    }
}

function vote(poll,answer) {
    var a,b;
    a=document.getElementById('poll');
    b=ajax();
    
    b.onreadystatechange=function() {
        if(b.readyState==4) {
            a.innerHTML=b.responseText;
        }
    };
    
    a.innerHTML='<img src="img/loading.gif" />';
    
    b.open("GET","poll.php?poll="+poll+"&ans="+answer,true);
    b.send(null);
}

function bt_add() {
    a=document.getElementById('bt_add_stuff');
    if(a.style.display=="none") {
        a.style.display="block";
        a.innerHTML+='<br />Title:&nbsp;&nbsp;&nbsp;<input type="text" name="title" /><br />';
        a.innerHTML+='Description:<br /><textarea name="desc" rows="10" cols="80"></textarea><br />';
        a.innerHTML+='<input type="submit" />';
    }
}

function svnget(id) {
    var a, b;
    a=document.getElementById(id);
    b=a.options[a.selectedIndex].value;
    window.location.href="svnget/" + b;
}


 /* shop.js */

function shop_delete_item_from_cart(a) {

    item = a.parentElement;
    
    if(item) { item = item.getElementsByTagName('input'); }
    if(item) { item = item[0]; }
    if(item) { item.value = "0"; }
    if(item) { item = item.parentElement; }
    
    while(item) {
        
        if(item.tagName == "FORM") {
            break;
        } else {
            item = item.parentElement;
        }
        
    }
    
    if(item) {
        item.submit();
        return true;
    }
    
    return false;
    
}



 /* stats.js */

function showStat(project) {
    var a = document.getElementById('StatsForm');
    var b = document.getElementById('StatsImg');
    var c = a.getElementsByTagName('select');
    var m = null, y = null;
    for(var i in c) {
        if(c[i].name == "StartDateMonth") {
            m = c[i].options[c[i].selectedIndex].value;
        } else
        if(c[i].name == "StartDateYear") {
            y = c[i].options[c[i].selectedIndex].value;
        }
    }
    b.src = "chart,line," + project + "," + y + "," + m;
    return true;
}


