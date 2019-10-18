/**********************************************************************
 * General purpose function created by Macromedia tools
**********************************************************************/
function MM_openBrWindow(theURL,winName,features) { //v2.0
	window.open(theURL,winName,features);
}

function MM_swapImage() { //v3.0
	var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
	if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
}

function MM_swapImgRestore() { //v3.0
	var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
}

function MM_findObj(n, d) { //v4.01
	var p,i,x;
	if(!d) d=document; 
	if((p=n.indexOf("?"))>0&&parent.frames.length) {
	d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
	if(!(x=d[n])&&d.all) 
		x=d.all[n]; 
		
	for (i=0;!x&&i<d.forms.length;i++)
		x=d.forms[i][n];
	
	for(i=0;!x&&d.layers&&i<d.layers.length;i++) 
		x=MM_findObj(n,d.layers[i].document);
	
	if(!x && d.getElementById) x=d.getElementById(n); 
	
	return x;
}

function MM_swapImage() { //v3.0
	var i,j=0,x,a=MM_swapImage.arguments; 
	document.MM_sr=new Array; 
	for(i=0;i<(a.length-2);i+=3)
	if ((x=MM_findObj(a[i]))!=null) {
		document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];
	}
}

/**********************************************************************
 * Functions used exclusively in literature and DSS. 
 *********************************************************************/
function displayDssInstructions() {
	var dssInstruction = document.createElement("span");
	dssInstruction.innerHTML = "You may add a category or select certain documents to your Technical Updates subscription. To add a category, visit the <a href='/subscribe'>Email Management Subscription Center</a>. To add a document with the <img src='/common/action-buttons/subscribe-individual-doc.gif' alt='Subscribe Alert' border='0' />  icon, simply click on the icon. You will be notified if there are any updates to the categories or documents you choose in a weekly email digest.";

	if (document.getElementById("showBlock")) {
		var parent = document.getElementById("showBlock").parentNode;
		parent.insertBefore(dssInstruction, document.getElementById("showBlock"));
	} else if (document.getElementById("theLegacyListing")) {
		var parent = document.getElementById("theLegacyListing").parentNode;
		var targetNodeIndex = -1;
		
		for (var i=0;i<parent.childNodes.length;i++) {
			if (parent.childNodes[i].nodeName=="P" || parent.childNodes[i].nodeName=="A") {
				targetNodeIndex = i;
			} else if (parent.childNodes[i].id=="theLegacyListing") {
				break;
			}
		}
		if (targetNodeIndex>0) {
			parent.insertBefore(dssInstruction, parent.childNodes[targetNodeIndex]);
		} else {
			parent.insertBefore(dssInstruction, document.getElementById("theLegacyListing"));
		}
	}
}

/**********************************************************************
 * Functions used for myAltera
 *********************************************************************/
var displayMyAlteraSignin = false;
function popupSignin() {
	if (document.getElementById("myalteraSignIn")) {
		document.getElementById("myalteraSignIn").style.display = (displayMyAlteraSignin) ? "inline" : "none";
		displayMyAlteraSignin = !displayMyAlteraSignin;
	}
	return false;
}

/**********************************************************************
 * SDC codes deployed in 2008
**********************************************************************/
// --- START OF Advanced SmartSource Data Collector TAG  --------------
// Copyright (c) 1996-2007 WebTrends Inc. All rights reserved.
// V8.0d
// $DateTime: 2007/02/02 09:50:38 $
var gService = false;
var gTimeZone = -8;
// Code section for Enable First-Party Cookie Tracking
function dcsCookie(){
	if (typeof(dcsOther)=="function"){
		dcsOther();
	}
	else if (typeof(dcsPlugin)=="function"){
		dcsPlugin();
	}
	else if (typeof(dcsFPC)=="function"){
		dcsFPC(gTimeZone);
	}
}
function dcsGetCookie(name){
	var pos=document.cookie.indexOf(name+"=");
	if (pos!=-1){
		var start=pos+name.length+1;
		var end=document.cookie.indexOf(";",start);
		if (end==-1){
			end=document.cookie.length;
		}
		return unescape(document.cookie.substring(start,end));
	}
	return null;
}
function dcsGetCrumb(name,crumb){
	var aCookie=dcsGetCookie(name).split(":");
	for (var i=0;i<aCookie.length;i++){
		var aCrumb=aCookie[i].split("=");
		if (crumb==aCrumb[0]){
			return aCrumb[1];
		}
	}
	return null;
}
function dcsGetIdCrumb(name,crumb){
	var cookie=dcsGetCookie(name);
	var id=cookie.substring(0,cookie.indexOf(":lv="));
	var aCrumb=id.split("=");
	for (var i=0;i<aCrumb.length;i++){
		if (crumb==aCrumb[0]){
			return aCrumb[1];
		}
	}
	return null;
}
function dcsFPC(offset){
	if (typeof(offset)=="undefined"){
		return;
	}
	if (document.cookie.indexOf("WTLOPTOUT=")!=-1){
		return;
	}
	var name=gFpc;
	var dCur=new Date();
	var adj=(dCur.getTimezoneOffset()*60000)+(offset*3600000);
	dCur.setTime(dCur.getTime()+adj);
	var dExp=new Date(dCur.getTime()+315360000000);
	var dSes=new Date(dCur.getTime());
	WT.co_f=WT.vt_sid=WT.vt_f=WT.vt_f_a=WT.vt_f_s=WT.vt_f_d=WT.vt_f_tlh=WT.vt_f_tlv="";
	if (document.cookie.indexOf(name+"=")==-1){
		if ((typeof(gWtId)!="undefined")&&(gWtId!="")){
			WT.co_f=gWtId;
		}
		else if ((typeof(gTempWtId)!="undefined")&&(gTempWtId!="")){
			WT.co_f=gTempWtId;
			WT.vt_f="1";
		}
		else{
			WT.co_f="2";
			var cur=dCur.getTime().toString();
			for (var i=2;i<=(32-cur.length);i++){
				WT.co_f+=Math.floor(Math.random()*16.0).toString(16);
			}
			WT.co_f+=cur;
			WT.vt_f="1";
		}
		if (typeof(gWtAccountRollup)=="undefined"){
			WT.vt_f_a="1";
		}
		WT.vt_f_s=WT.vt_f_d="1";
		WT.vt_f_tlh=WT.vt_f_tlv="0";
	}
	else{
		var id=dcsGetIdCrumb(name,"id");
		var lv=parseInt(dcsGetCrumb(name,"lv"));
		var ss=parseInt(dcsGetCrumb(name,"ss"));
		if ((id==null)||(id=="null")||isNaN(lv)||isNaN(ss)){
			return;
		}
		WT.co_f=id;
		var dLst=new Date(lv);
		WT.vt_f_tlh=Math.floor((dLst.getTime()-adj)/1000);
		dSes.setTime(ss);
		if ((dCur.getTime()>(dLst.getTime()+1800000))||(dCur.getTime()>(dSes.getTime()+28800000))){
			WT.vt_f_tlv=Math.floor((dSes.getTime()-adj)/1000);
			dSes.setTime(dCur.getTime());
			WT.vt_f_s="1";
		}
		if ((dCur.getDay()!=dLst.getDay())||(dCur.getMonth()!=dLst.getMonth())||(dCur.getYear()!=dLst.getYear())){
			WT.vt_f_d="1";
		}
	}
	WT.co_f=escape(WT.co_f);
	WT.vt_sid=WT.co_f+"."+(dSes.getTime()-adj);
	var expiry="; expires="+dExp.toGMTString();
	document.cookie=name+"="+"id="+WT.co_f+":lv="+dCur.getTime().toString()+":ss="+dSes.getTime().toString()+expiry+"; path=/"+(((typeof(gFpcDom)!="undefined")&&(gFpcDom!=""))?("; domain="+gFpcDom):(""));
	if (document.cookie.indexOf(name+"=")==-1){
		WT.co_f=WT.vt_sid=WT.vt_f_s=WT.vt_f_d=WT.vt_f_tlh=WT.vt_f_tlv="";
		WT.vt_f=WT.vt_f_a="2";
	}
}

// Add dcsOther() here if using existing first-party cookie, or dcsPlugin() here if using WT Cookie Plugin

// Code section for Set the First-Party Cookie domain
//var gFpcDom=".webtrends.com";

// Code section for Enable Event Tracking
function dcsParseSvl(sv){
	sv=sv.split(" ").join("");
	sv=sv.split("\t").join("");
	sv=sv.split("\n").join("");
	var pos=sv.toUpperCase().indexOf("WT.SVL=");
	if (pos!=-1){
		var start=pos+8;
		var end=sv.indexOf('"',start);
		if (end==-1){
			end=sv.indexOf("'",start);
			if (end==-1){
				end=sv.length;
			}
		}
		return sv.substring(start,end);
	}
	return "";
}
function dcsIsOnsite(host){
	var doms="@@ONSITEDOMAINS@@";
    var aDoms=doms.split(',');
    for (var i=0;i<aDoms.length;i++){
		if (host.indexOf(aDoms[i])!=-1){
		       return 1;
		}
    }
    return 0;
}
function dcsIsHttp(e){
	return (e.href&&e.protocol&&(e.protocol.indexOf("http")!=-1))?true:false;
}
function dcsTypeMatch(path, typelist){
	var type=path.substring(path.lastIndexOf(".")+1,path.length);
	var types=typelist.split(",");
	for (var i=0;i<types.length;i++){
		if (type==types[i]){
			return true;
		}
	}
	return false;
}
function dcsEvt(evt,tag){
	var e=evt.target||evt.srcElement;
	while (e.tagName&&(e.tagName!=tag)){
		e=e.parentElement||e.parentNode;
	}
	return e;
}
function dcsBind(event,func){
	if ((typeof(window[func])=="function")&&document.body){
		if (document.body.addEventListener){
			document.body.addEventListener(event, window[func], true);
		}
		else if(document.body.attachEvent){
			document.body.attachEvent("on"+event, window[func]);
		}
	}
}
function dcsET(){
	var e=(navigator.appVersion.indexOf("MSIE")!=-1)?"click":"mousedown";
	dcsBind(e,"dcsDownload");
	dcsBind(e,"dcsDynamic");
	dcsBind(e,"dcsFormButton");
	dcsBind(e,"dcsOffsite");
	dcsBind(e,"dcsAnchor");
	dcsBind("mousedown","dcsRightClick");
}
	
function dcsMultiTrack(){
	if (arguments.length%2==0){
		for (var i=0;i<arguments.length;i+=2){
			if (arguments[i].indexOf('WT.')==0){
				WT[arguments[i].substring(3)]=arguments[i+1];
			}
			else if (arguments[i].indexOf('DCS.')==0){
				DCS[arguments[i].substring(4)]=arguments[i+1];
			}
			else if (arguments[i].indexOf('DCSext.')==0){
				DCSext[arguments[i].substring(7)]=arguments[i+1];
			}
		}
		var dCurrent=new Date();
		DCS.dcsdat=dCurrent.getTime();
		dcsFunc("dcsCookie");
		dcsTag();
	}
}

// Add event handlers here

function dcsAdv(){
	dcsFunc("dcsET");
	dcsFunc("dcsCookie");
	dcsFunc("dcsAdSearch");
	dcsFunc("dcsTP");
}
// --- END OF Advanced SmartSource Data Collector TAG ---------------------

// --- START OF Basic SmartSource Data Collector TAG ----------------------
// Copyright (c) 1996-2006 WebTrends Inc. All rights reserved.
// V8.0
// $DateTime: 2007/02/02 09:50:38 $
var gImages=new Array;
var gIndex=0;
var DCS=new Object();
var WT=new Object();
var DCSext=new Object();
var gQP=new Array();
var gI18n=true;

var gDomain="sdc.altera.com";
var gDcsId="";
var gFpc="WT_FPC";
var gConvert=false;
if ((typeof(gConvert)!="undefined")&&gConvert&&(document.cookie.indexOf(gFpc+"=")==-1)&&(document.cookie.indexOf("WTLOPTOUT=")==-1)){
	document.write("<SCR"+"IPT TYPE='text/javascript' SRC='"+"http"+(window.location.protocol.indexOf('https:')==0?'s':'')+"://"+gDomain+"/"+gDcsId+"/wtid.js"+"'><\/SCR"+"IPT>");
}
if (window.RegExp){
	var RE={"%09":/\t/g,"%20":/ /g,"%23":/\#/g,"%26":/\&/g,"%2B":/\+/g,"%3F":/\?/g,"%5C":/\\/g,"%22":/\"/g,"%7F":/\x7F/g,"%A0":/\xA0/g};
	var I18NRE={"%25":/\%/g};
}

// Add customizations here

function dcsVar(){
	var dCurrent=new Date();
	WT.tz=dCurrent.getTimezoneOffset()/60*-1;
	if (WT.tz==0){
		WT.tz="0";
	}
	WT.bh=dCurrent.getHours();
	WT.ul=navigator.appName=="Netscape"?navigator.language:navigator.userLanguage;
	if (typeof(screen)=="object"){
		WT.cd=navigator.appName=="Netscape"?screen.pixelDepth:screen.colorDepth;
		WT.sr=screen.width+"x"+screen.height;
	}
	if (typeof(navigator.javaEnabled())=="boolean"){
		WT.jo=navigator.javaEnabled()?"Yes":"No";
	}
	if (document.title){
		WT.ti=gI18n?dcsEscape(dcsEncode(document.title),I18NRE):document.title;
	}
	WT.js="Yes";
	WT.jv=dcsJV();
	if (document.body&&document.body.addBehavior){
		document.body.addBehavior("#default#clientCaps");
		WT.ct=document.body.connectionType||"unknown";
		document.body.addBehavior("#default#homePage");
		WT.hp=document.body.isHomePage(location.href)?"1":"0";
	}
	else{

		WT.ct="unknown";
	}
	if (parseInt(navigator.appVersion)>3){
		if ((navigator.appName=="Microsoft Internet Explorer")&&document.body){
			WT.bs=document.body.offsetWidth+"x"+document.body.offsetHeight;
		}
		else if (navigator.appName=="Netscape"){
			WT.bs=window.innerWidth+"x"+window.innerHeight;
		}
	}
	WT.fi="No";
	if (window.ActiveXObject){
		for(var i=10;i>0;i--){
			try{
				var flash = new ActiveXObject("ShockwaveFlash.ShockwaveFlash."+i);
				WT.fi="Yes";
				WT.fv=i+".0";
				break;
			}
			catch(e){
			}
		}
	}
	else if (navigator.plugins&&navigator.plugins.length){
		for (var i=0;i<navigator.plugins.length;i++){
			if (navigator.plugins[i].name.indexOf('Shockwave Flash')!=-1){
				WT.fi="Yes";
				WT.fv=navigator.plugins[i].description.split(" ")[2];
				break;
			}
		}
	}
	if (gI18n){
		WT.em=(typeof(encodeURIComponent)=="function")?"uri":"esc";
		if (typeof(document.defaultCharset)=="string"){
			WT.le=document.defaultCharset;
		} 
		else if (typeof(document.characterSet)=="string"){
			WT.le=document.characterSet;
		}
	}
	WT.tv="8.0.2";
//	WT.sp="@@SPLITVALUE@@";

	DCS.dcsdat=dCurrent.getTime();
	DCS.dcssip=window.location.hostname;
	DCS.dcsuri=window.location.pathname;
	if (window.location.search){
		DCS.dcsqry=window.location.search;
		if (gQP.length>0){
			for (var i=0;i<gQP.length;i++){
				var pos=DCS.dcsqry.indexOf(gQP[i]);
				if (pos!=-1){
					var front=DCS.dcsqry.substring(0,pos);
					var end=DCS.dcsqry.substring(pos+gQP[i].length,DCS.dcsqry.length);
					DCS.dcsqry=front+end;
				}
			}
		}
	}
	if ((window.document.referrer!="")&&(window.document.referrer!="-")){
		if (!(navigator.appName=="Microsoft Internet Explorer"&&parseInt(navigator.appVersion)<4)){
			DCS.dcsref=gI18n?dcsEscape(window.document.referrer, I18NRE):window.document.referrer;
		}
	}
}

function dcsA(N,V){
	return "&"+N+"="+dcsEscape(V, RE);
}

function dcsEscape(S, REL){
	if (typeof(REL)!="undefined"){
		var retStr = new String(S);
		for (var R in REL){
			retStr = retStr.replace(REL[R],R);

		}
		return retStr;
	}
	else{
		return escape(S);
	}
}

function dcsEncode(S){
	return (typeof(encodeURIComponent)=="function")?encodeURIComponent(S):escape(S);
}

function dcsCreateImage(dcsSrc){
	if (document.images){
		gImages[gIndex]=new Image;
		gImages[gIndex].src=dcsSrc;
		gIndex++;
	}
	else{
		document.write('<IMG ALT="" BORDER="0" NAME="DCSIMG" WIDTH="1" HEIGHT="1" SRC="'+dcsSrc+'">');
	}
}

function dcsMeta(){
	var elems;
	if (document.all){
		elems=document.all.tags("meta");
	}
	else if (document.documentElement){
		elems=document.getElementsByTagName("meta");
	}
	if (typeof(elems)!="undefined"){
		var length=elems.length;
		for (var i=0;i<length;i++){
			var name=elems.item(i).name;
			var content=elems.item(i).content;
			var equiv=elems.item(i).httpEquiv;
			if (name.length>0){
				if (name.indexOf("WT.")==0){
					var encode=false;
					if (gI18n){
						var params=["mc_id","oss","ti"];
						for (var j=0;j<params.length;j++){
							if (name.indexOf("WT."+params[j])==0){
								encode=true;
								break;
							}
						}
					}
					WT[name.substring(3)]=encode?dcsEscape(dcsEncode(content),I18NRE):content;
				}
				else if (name.indexOf("DCSext.")==0){
					DCSext[name.substring(7)]=content;
				}
				else if (name.indexOf("DCS.")==0){
					DCS[name.substring(4)]=(gI18n&&(name.indexOf("DCS.dcsref")==0))?dcsEscape(content,I18NRE):content;
				}
			}
			else if (gI18n&&(equiv=="Content-Type")){
				var pos=content.toLowerCase().indexOf("charset=");
				if (pos!=-1){
					WT.mle=content.substring(pos+8);
				}
			}
		}
	}
}

function dcsTag(){
	if (document.cookie.indexOf("WTLOPTOUT=")!=-1){
		return;
	}
	var P="http"+(window.location.protocol.indexOf('https:')==0?'s':'')+"://"+gDomain+(gDcsId==""?'':'/'+gDcsId)+"/dcs.gif?";
	for (var N in DCS){
		if (DCS[N]) {
			P+=dcsA(N,DCS[N]);
		}
	}
	var keys=["co_f","vt_sid","vt_f_tlv"];
	for (var i=0;i<keys.length;i++){
		var key=keys[i];
		if (WT[key]){
			P+=dcsA("WT."+key,WT[key]);
			delete WT[key];
		}
	}
	for (N in WT){
		if (WT[N]) {
			P+=dcsA("WT."+N,WT[N]);
		}
	}
	for (N in DCSext){
		if (DCSext[N]) {
			P+=dcsA(N,DCSext[N]);
		}
	}
	if (P.length>2048&&navigator.userAgent.indexOf('MSIE')>=0){
		P=P.substring(0,2040)+"&WT.tu=1";
	}
	dcsCreateImage(P);
}

function dcsJV(){
	var agt=navigator.userAgent.toLowerCase();
	var major=parseInt(navigator.appVersion);
	var mac=(agt.indexOf("mac")!=-1);
	var ff=(agt.indexOf("firefox")!=-1);
	var ff0=(agt.indexOf("firefox/0.")!=-1);
	var ff10=(agt.indexOf("firefox/1.0")!=-1);
	var ff15=(agt.indexOf("firefox/1.5")!=-1);
	var ff2up=(ff&&!ff0&&!ff10&!ff15);
	var nn=(!ff&&(agt.indexOf("mozilla")!=-1)&&(agt.indexOf("compatible")==-1));
	var nn4=(nn&&(major==4));
	var nn6up=(nn&&(major>=5));
	var ie=((agt.indexOf("msie")!=-1)&&(agt.indexOf("opera")==-1));
	var ie4=(ie&&(major==4)&&(agt.indexOf("msie 4")!=-1));
	var ie5up=(ie&&!ie4);
	var op=(agt.indexOf("opera")!=-1);
	var op5=(agt.indexOf("opera 5")!=-1||agt.indexOf("opera/5")!=-1);
	var op6=(agt.indexOf("opera 6")!=-1||agt.indexOf("opera/6")!=-1);
	var op7up=(op&&!op5&&!op6);
	var jv="1.1";
	if (ff2up){
		jv="1.7";
	}
	else if (ff15){
		jv="1.6";
	}
	else if (ff0||ff10||nn6up||op7up){
		jv="1.5";
	}
	else if ((mac&&ie5up)||op6){
		jv="1.4";
	}
	else if (ie5up||nn4||op5){
		jv="1.3";
	}
	else if (ie4){
		jv="1.2";
	}
	return jv;
}

function dcsFunc(func){
	if (typeof(window[func])=="function"){
		window[func]();
	}
}

dcsVar();
dcsMeta();
//dcsFunc("dcsAdv");
dcsTag();
// --- END OF Basic SmartSource Data Collector TAG --------------------
/*********************************************************************/

/*********************************************************************
 * JavaScript functions specific to 2008 refresh.
 *********************************************************************/
displaySearchCollection = false;
function toggleSearchCollection() { 
	displaySearchCollection = !displaySearchCollection;
	document.getElementById("collectionMenu").style.display = (displaySearchCollection==true) ? "block" : "none";
}

function toggleObject(name, isDisplay) {
	document.getElementById(name).style.display = (isDisplay==true) ? "block" : "none"; 
}

function toggleFooterLink(number, status) {
	if (status) {
		document.getElementById("footerIcon" + number).style.textDecoration = "underline";
	} else {
		document.getElementById("footerIcon" + number).style.textDecoration = "none";
	}
}

var searchText = "Search";
function resetSearchField(obj) {
	if (obj.value==searchText) {
		obj.value = "";
		obj.style.color = "#000";
	} else if (obj.value=="") {
		obj.value = searchText;
		obj.style.color = "#333";
	}
}

function isSearchFormCompleted(objForm) {
	if ((objForm.q.value=="Search" || objForm.q.value=="") && objForm.pn.value=='1') {
		location.href = "/cgi-bin/devsearch.pl";
		return false;
	} else if ((objForm.q.value=="Search" || objForm.q.value=="")) {
		objForm.q.value = "";
		objForm.pn.value = '0';
	}
	return true;
}

function updateSearchCollection(nodeId, toggleSearchOff) {
	if (!document.theSearchForm) return;
	
	document.theSearchForm.pn.value='0';
	
	var hostname = window.location.hostname.toLowerCase();
	if (hostname.indexOf("cn")>0 || hostname.indexOf("china")==0 || window.location.href.indexOf(".com/cn/")>0) {
		switch (nodeId) {
			case 1: document.theSearchForm.site.value='china'; document.theSearchForm.pn.value='1'; break;
			case 2: document.theSearchForm.site.value='www_spt_kdb'; break;
			case 3: document.theSearchForm.site.value='china_spt_techdocs'; break;
			case 4: document.theSearchForm.site.value='www_forum'; break;
			default: document.theSearchForm.site.value='china';
		}
	} else if (hostname.indexOf("jp")>0 || hostname.indexOf("japan")==0 || window.location.href.indexOf(".com/jp/")>0) {
		switch (nodeId) {
			case 1: document.theSearchForm.site.value='japan'; document.theSearchForm.pn.value='1'; break;
			case 2: document.theSearchForm.site.value='japan_spt_kdb'; break;
			case 3: document.theSearchForm.site.value='japan_spt_techdocs'; break;
			case 4: document.theSearchForm.site.value='www_forum'; break;
			default: document.theSearchForm.site.value='japan';
		}
	} else {
		switch (nodeId) {
			case 1: document.theSearchForm.site.value='www'; document.theSearchForm.pn.value='1'; break;
			case 2: document.theSearchForm.site.value='www_spt_kdb'; break;
			case 3: document.theSearchForm.site.value='www_spt_techdocs'; break;
			case 4: document.theSearchForm.site.value='www_forum'; break;
			default: document.theSearchForm.site.value='www';
		}
	}
	var collectionMenu = document.getElementById("collectionMenu");
	var counter = -1;
	for (var i=0;i<collectionMenu.childNodes.length;i++) {
		if (collectionMenu.childNodes[i].nodeName=="LI") 
			counter++;
		else 
			continue;
		if (nodeId==counter) {
			collectionMenu.childNodes[i].style.color = "#06c";
		} else {
			collectionMenu.childNodes[i].style.color = "#333";
		}
	}
	if (!toggleSearchOff)
		toggleSearchCollection();
}


displayLanguageOptions = false;
function toggleLanguageOptions() { 
	displayLanguageOptions = !displayLanguageOptions;
	document.getElementById("languageMenu").style.display = (displayLanguageOptions==true) ? "block" : "none";
}

/***********************************************************************
 * 2009-04-23: JavaScript variables and function used in the tab in the content area. 
 * This functionality will kick in when the "tab heading" DIV is defined.
 * Reminder: Be sure to call initializeContentTab() from the initalizeTemplateEvents() 
 * TODO: Find a clearner way to define the onlick event. 
 **********************************************************************/
var TAB_NAME_PREFIX = "tab-heading";
var TAB_CONTENT_PREFIX = "tab-content";
var currentTab = 1;

function initializeContentTab() {
	// --- If tab exists, initialize the tab by assigning id attribute and onclick. ---
	if (document.getElementById(TAB_NAME_PREFIX)) {
		document.getElementById(TAB_NAME_PREFIX).style.display = "block";
		var lists = document.getElementById(TAB_NAME_PREFIX).getElementsByTagName("li");
		for (var i=0;i<lists.length;i++) {
			lists[i].id = TAB_NAME_PREFIX + "-" + (i+1);
			switch(i+1) {
				case 1: lists[i].onclick = function() { activateContentTab(1); return false; }; break;
				case 2: lists[i].onclick = function() { activateContentTab(2); return false; }; break;
				case 3: lists[i].onclick = function() { activateContentTab(3); return false; }; break;
				case 4: lists[i].onclick = function() { activateContentTab(4); return false; }; break;
				case 5: lists[i].onclick = function() { activateContentTab(5); return false; }; break;
				case 6: lists[i].onclick = function() { activateContentTab(6); return false; }; break;
				default: lists[i].onclick = function() { activateContentTab(1); return false; } 
			}
			if ((i+1)!=currentTab) { document.getElementById(TAB_CONTENT_PREFIX+"-"+(i+1)).style.display = "none"; }
		}
		activateContentTab(1);
	}
}

function activateContentTab(tabNumber) {
	var oldTab = document.getElementById(TAB_NAME_PREFIX+"-"+currentTab);
	oldTab.style.background = "url(/common/icons/tab/tab-right.gif) no-repeat right top";
	var lists = oldTab.getElementsByTagName("A");
	if (lists) { 
		lists[0].style.background = "url(/common/icons/tab/tab-left.gif) no-repeat left top"; 
		lists[0].style.color = "#fff";
	}
	
	var newTab = document.getElementById(TAB_NAME_PREFIX+"-"+tabNumber);
	newTab.style.background = "url(/common/icons/tab/selected-right.gif) no-repeat right top";
	lists = newTab.getElementsByTagName("A");
	if (lists) { 
		lists[0].style.background = "url(/common/icons/tab/selected-left.gif) no-repeat left top"; 
		lists[0].style.color = "#069";
	}
	
    document.getElementById(TAB_CONTENT_PREFIX+"-"+currentTab).style.display = "none";
    document.getElementById(TAB_CONTENT_PREFIX+"-"+tabNumber).style.display = "block";
    currentTab = tabNumber;
}

/*********************************************************************
 * Main gateway to initialize everything we need for the template. 
 * The intialization involves 
 * + intialize the onclick event for the document, search drop down  
 *   and collection items, language drop down and link items
 * + setting collapsable left navigation
 * + initialize search collection 
 *********************************************************************/
if (document.addEventListener) {
	document.addEventListener("DOMContentLoaded", initalizeTemplateEvents, false);
} else {
	window.onload=initalizeTemplateEventsIE;
}

function initalizeTemplateEventsIE() {
    initalizeTemplateEvents();
	// --- IE specific JavaScript statements ---
}

function initalizeTemplateEvents() {
	document.onclick = function(e) { 
		displaySearchCollection = false;
		displayLanguageOptions = false;
		if (document.getElementById("collectionMenu")) toggleObject("collectionMenu", false);
		if (document.getElementById("languageMenu")) toggleObject("languageMenu", false);
	}
	
	if (document.getElementById("searchDropdown")) {
		document.getElementById("searchDropdown").onclick = function(e) {
			if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; }
			toggleSearchCollection();
		}
	}
	
	if (document.getElementById("languageDropdown")) {
		document.getElementById("languageDropdown").onclick = function(e) {
			if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; }
			toggleLanguageOptions();
		}
	}
	
	if (document.getElementById("collectionMenu")) {
		var collectionItems = document.getElementById("collectionMenu").getElementsByTagName("li");
		for (var itemCount=0;itemCount<collectionItems.length;itemCount++) {
			if (itemCount==1) {
				collectionItems[itemCount].onclick = function(e) { if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; } updateSearchCollection(1); }
			} else if (itemCount==2) {
				collectionItems[itemCount].onclick = function(e) { if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; } updateSearchCollection(2); }
			} else if (itemCount==3) {
				collectionItems[itemCount].onclick = function(e) { if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; } updateSearchCollection(3); }
			} else if (itemCount==4) {
				collectionItems[itemCount].onclick = function(e) { if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; } updateSearchCollection(4); }
			} else {
				collectionItems[itemCount].onclick = function(e) { if (!e) var e = window.event; if (e.stopPropagation) { e.stopPropagation(); } else { e.cancelBubble = true; } updateSearchCollection(0); }
			}
		}
	}
	if (document.getElementById("lang-en")) { document.getElementById("lang-en").onclick = function(e) { document.location = document.getElementById("lang-en").getElementsByTagName("a")[0].href; } }
	if (document.getElementById("lang-zh_CN")) { document.getElementById("lang-zh_CN").onclick = function(e) { document.location = document.getElementById("lang-zh_CN").getElementsByTagName("a")[0].href; } }
	if (document.getElementById("lang-ja")) { document.getElementById("lang-ja").onclick = function(e) { document.location = document.getElementById("lang-ja").getElementsByTagName("a")[0].href; } }
	
	leftnavCollapsableInit();
	updateSearchCollection(0, true);
	
	// --- 2009-09-01: Added to prevent the 404 being captured @ Vtrenz ---
	if (document.domain.indexOf("www")>=0 && document.title!="Page not found" && document.title!="找不到该页") {
		loadExternalFile("http://gw-services.vtrenz.net/WebCookies/iMAWebCookie.js?D26BF81D-E463-4098-B267-1EEFD139D220");
	}
	
	// --- 2009-11-17: Initialize the myAltera tab ---
	popupSignin();
	var contactId = GetCookie("ContactId");
	if (document.getElementById("before-sign-in")) document.getElementById("before-sign-in").style.display = (contactId==null) ? "inline" : "none";
	if (document.getElementById("after-sign-in")) document.getElementById("after-sign-in").style.display = (contactId==null) ? "none" : "inline";
	
	// --- 2010-09-22: Clean up the about: in the img's src and a's href (KDB Solutions only) ---
	if (document.URL.toLowerCase().indexOf("/support/kdb/solutions/")>0) {
		var images = document.getElementsByTagName("img");
		for (var i=0;i<images.length;i++) {
			if (images.item(i).src.toLowerCase().indexOf("about:")==0) {
				images.item(i).src = images.item(i).src.replace(/^about:/i, "");
			}
		}
		var anchors = document.getElementsByTagName("a");
		for (var i=0;i<anchors.length;i++) {
			if (anchors.item(i).href.toLowerCase().indexOf("about:")==0) {
				anchors.item(i).href = anchors.item(i).href.replace(/^about:/i, "");
			}
		}
	}
	
	// --- Initialize the tab in the content page ---
	initializeContentTab();
}

/*********************************************************************
 * JavaScript functions specific to left navigation for 2008 refresh.
 *********************************************************************/
var WEBSITE_HOSTNAME = window.location.hostname.toLowerCase();
var URL_PREFIX = window.location.protocol + "//" + WEBSITE_HOSTNAME;
if (WEBSITE_HOSTNAME.indexOf("www")<0 && WEBSITE_HOSTNAME!=("altera.com")<0 && WEBSITE_HOSTNAME.indexOf("altera.co.jp")<0 && WEBSITE_HOSTNAME.indexOf("altera.com.cn")<0) {
	URL_PREFIX = "http://www.altera.com";
}
var COLLAPSABLE_EXPAND_LEFTNAV_IMG = URL_PREFIX + "/common/template/08/arrow-diag-11pts.gif";   
var COLLAPSABLE_SHRINK_LEFTNAV_IMG = URL_PREFIX + "/common/template/08/arrow-down-11pts.gif"; 
var COLLAPSABLE_START_LEFTNAV_TYPE = "li";
var COLLAPSABLE_PARENT_LEFTNAV_TYPE = "div";
var COLLAPSABLE_PARENT_NAME_LEFTNAV_CATEGORY = "collapsable-leftnav"; 
var COLLAPSABLE_CHILD_LEFTNAV_TYPE = "span"; 

var default_expand_node = "";
var default_expand_node4 = ""; 
var default_expand_node5 = "";
var default_expand_node6 = ""; 
var default_highline_node = ""; 

var flat = 0; 

leftnavCollapsableInit=function(){
	if (document.getElementById && document.createTextNode) { 
        var entries = document.getElementsByTagName(COLLAPSABLE_PARENT_LEFTNAV_TYPE);  
        for(i=0;i<entries.length;i++) {
			if (entries[i].className==COLLAPSABLE_PARENT_NAME_LEFTNAV_CATEGORY) 
				assignLeftnavCollapseImg(entries[i]); // --- Used with image-based icons ---
		}
    } 
	//after set the default expand section, set the default highlight for the page
	setLeftnavHighlight();
}

function setLeftnavHighlight() {
	if (document.getElementById && document.createElement)
	{
		if (default_highline_node!="") {
			document.getElementById(default_highline_node).childNodes[0].style.color='#f93';
			//document.getElementById(default_highline_node).parentNode.style.backgroundColor = "#FFFFFF";
		}
	} else 
		alert('Your browser doesn\'t support the Level 1 DOM');
}

/**
 * Assign collapse/expand image to each block, based on the tag's class name.
 */
function assignLeftnavCollapseImg(div) { 
	var leftnavcollapsableIcon = document.createElement('img');
	leftnavcollapsableIcon.className = 'leftnavtwisty';
	leftnavcollapsableIcon.setAttribute('align', 'bottom');
	leftnavcollapsableIcon.style.color='#0000ff'; 
    leftnavcollapsableIcon.setAttribute('expand', COLLAPSABLE_EXPAND_LEFTNAV_IMG); 
    leftnavcollapsableIcon.setAttribute('shrink', COLLAPSABLE_SHRINK_LEFTNAV_IMG);
	
	if (default_expand_node!="" && div.getElementsByTagName(COLLAPSABLE_START_LEFTNAV_TYPE)[0].id==default_expand_node) {
		leftnavcollapsableIcon.setAttribute('leftnavstate', 1); 
	} else if (default_expand_node4!="" && div.getElementsByTagName(COLLAPSABLE_START_LEFTNAV_TYPE)[0].id==default_expand_node4) {
			leftnavcollapsableIcon.setAttribute('leftnavstate', 1); 
	} else if (default_expand_node5!="" && div.getElementsByTagName(COLLAPSABLE_START_LEFTNAV_TYPE)[0].id==default_expand_node5) {
			leftnavcollapsableIcon.setAttribute('leftnavstate', 1); 
	} else if (default_expand_node6!="" && div.getElementsByTagName(COLLAPSABLE_START_LEFTNAV_TYPE)[0].id==default_expand_node6) {
			leftnavcollapsableIcon.setAttribute('leftnavstate', 1); 
	} else {
		leftnavcollapsableIcon.setAttribute('leftnavstate', -1); 
	}

	div.insertBefore(leftnavcollapsableIcon, div.getElementsByTagName(COLLAPSABLE_START_LEFTNAV_TYPE)[0]);
	if (div.className==COLLAPSABLE_PARENT_NAME_LEFTNAV_CATEGORY) 		        {
		leftnavcollapsableIcon.style.cursor='pointer'; 
		leftnavcollapsableIcon.onclick=function() { twistyLeftnavImages(leftnavcollapsableIcon, 0, div); }               
		leftnavcollapsableIcon.onclick(); 
	} 
}

function twistyLeftnavImages(leftnavcollapsableIcon, flat, div) { 
	var state = "";
	if (flat == 0 )  {
		state = -(1*leftnavcollapsableIcon.getAttribute('leftnavstate')); 
		leftnavcollapsableIcon.setAttribute('leftnavstate', state);
		leftnavcollapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_LEFTNAV_TYPE)[0].style.display=state==1?'none':'block';
		
		if (leftnavcollapsableIcon.getAttribute('leftnavstate')==1)
			leftnavcollapsableIcon.src = COLLAPSABLE_EXPAND_LEFTNAV_IMG;
		else 
			leftnavcollapsableIcon.src = COLLAPSABLE_SHRINK_LEFTNAV_IMG;	
		
	} else if (flat == 1) { // --- expand all ---
		leftnavcollapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_LEFTNAV_TYPE)[0].style.display='block'; 
		leftnavcollapsableIcon.src = COLLAPSABLE_SHRINK_LEFTNAV_IMG;	// --- use image as collapse/expand icon --- 
		leftnavcollapsableIcon.setAttribute('leftnavstate', 1);
		leftnavcollapsableIcon.onclick();		
	} else if (flat == -1) {// --- collaps all --- 
		leftnavcollapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_LEFTNAV_TYPE)[0].style.display='none'; 
		leftnavcollapsableIcon.src = COLLAPSABLE_EXPAND_LEFTNAV_IMG;	// --- use image as collapse/expand icon --- 
		leftnavcollapsableIcon.setAttribute('leftnavstate', -1);
		leftnavcollapsableIcon.onclick();
	}
}

/** 2009-03-26: Merged into other template code *
if (document.addEventListener) {    
	document.addEventListener("DOMContentLoaded", leftnavCollapsableInit, false);
} else {
	window.onload=leftnavCollapsableInit;
}
 */

/*************************************************************************************************************
 * The following functions are used in the tree expand/collapse function. - Erin (2007-01-31)
 * It apply to literature, board design, KDB expand/collapse listing
 * Example: Cyclone III HandBood listing
 * Usage pattern:
 		 <div class='collapsable'>
			  <h4>"Application Notes" or "Volume 1 - Stratix III Device Handbook"</h4>
				  <span>
						text here
				  </span>
		 </div>
 * Implementation note: The tree icon can be text or image based. 
 *                      Overwrite the functions here rin a different .js (JavaScript) file.
***************************************************************************************************************/
var COLLAPSABLE_PARENT_NAME = "collapsable"; 
var COLLAPSABLE_PARENT_TYPE = "div"; 
var COLLAPSABLE_CHILD_TYPE = "span"; // --- all text that can be expand/collaps must put it between <span></span> tag --- 
var COLLAPSABLE_START_TYPE = "h4";   // --- the marker to start put the [+] and [-] symbol ---
var COLLAPSABLE_EXPAND = "[+]"; 
var COLLAPSABLE_SHRINK = "[&ndash;]"; 
var flat = 0;  	// default: flat=0, expand all: flat=1, collaps all: flat=-1 

/**
 * Assign collapsable image to desginated block 
 */ 
function assignCollapse(div) { 
	// --- Creates an instance of the element object with tag name "a"
    var collapsableIcon = document.createElement('a'); 
	collapsableIcon.className = 'twisty';
	// --- DOM Style Object:represents an individual style statement
	// --- cursor: sets the type of cursor to be displayed.
	// --- example: value=pointer -- the cursor indicates a link
	// ---          value=text    -- the cursor indicates text
    collapsableIcon.style.cursor='pointer'; 
	// --- create a e/c attribute, ready to be inserted somewhere in document
    collapsableIcon.setAttribute('expand', COLLAPSABLE_EXPAND); 
    collapsableIcon.setAttribute('shrink', COLLAPSABLE_SHRINK);
	
	// --- Default to collapse all ---
    // collapsableIcon.setAttribute('state', -1); 
	
	// volume section default to expanded and related doc default to collapse
   	collapsableIcon.setAttribute('state', 1); 
	
	// --- Syntax: parentObj.insertBefore(childObj, brotherObj)
	div.insertBefore(collapsableIcon, div.getElementsByTagName(COLLAPSABLE_START_TYPE)[0]);
	collapsableIcon.onclick=function() { twisty(collapsableIcon, 0); }               
    collapsableIcon.onclick(); 
} 

function twisty(collapsableIcon, flat) { 
	var state = "";
	if (flat == 0 )  {
		state = -(1*collapsableIcon.getAttribute('state')); 
		collapsableIcon.setAttribute('state', state);
		collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0].style.display=state==1?'none':'block'; 
		collapsableIcon.innerHTML = collapsableIcon.getAttribute(state==1?'expand':'shrink');
	} else if (flat == 1) { // --- expand all ---
		collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0].style.display='block'; 
		// ---  alert(collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0]);
		collapsableIcon.innerHTML = collapsableIcon.getAttribute('shrink');
		collapsableIcon.setAttribute('state', 1);
		collapsableIcon.onclick();
	} else if (flat == -1) { // --- collaps all ---
		collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0].style.display='none'; 
		collapsableIcon.innerHTML = collapsableIcon.getAttribute('expand');
		collapsableIcon.setAttribute('state', -1);
		collapsableIcon.onclick();
	} 
}

changeLink=function(setting){ 
	var tempstatus = "";
	var alink = "";
	if (document.getElementById && document.createTextNode) { 
        var aentries = document.getElementsByTagName(COLLAPSABLE_PARENT_TYPE);
		for (var i=0; i<aentries.length; i++){
			if (aentries[i].className==COLLAPSABLE_PARENT_NAME)  {
				alink = aentries[i].getElementsByTagName("a")[0];
				if (setting=="expand")
					twisty(alink, 1); 
				else if (setting=="collapse")  
					twisty(alink, -1); 
			}
		}
	}
}

function twistyImages(collapsableIcon, flat) { 
	var state = "";
	if (flat == 0 )  {
		state = -(1*collapsableIcon.getAttribute('state')); 
		collapsableIcon.setAttribute('state', state);
		collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0].style.display=state==1?'none':'block'; 
		if (collapsableIcon.getAttribute('state')==1)
			collapsableIcon.src = COLLAPSABLE_EXPAND_IMG;
		else 
			collapsableIcon.src = COLLAPSABLE_SHRINK_IMG;
	} else if (flat == 1) { // --- expand all ---
		collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0].style.display='block'; 
		collapsableIcon.src = COLLAPSABLE_SHRINK_IMG;	// --- use image as collapse/expand icon --- 
		collapsableIcon.setAttribute('state', 1);
		collapsableIcon.onclick();
		
	} else if (flat == -1) {// --- collaps all --- 
		collapsableIcon.parentNode.getElementsByTagName(COLLAPSABLE_CHILD_TYPE)[0].style.display='none'; 
		collapsableIcon.src = COLLAPSABLE_EXPAND_IMG;	// --- use image as collapse/expand icon --- 
		collapsableIcon.setAttribute('state', -1);
		collapsableIcon.onclick();
	}
}

changeLinkImg=function(setting) { 
	var tempstatus = "";
	var alink = "";
    // --- if there are switch contents defined on the page --- 
	 if(document.getElementById && document.createTextNode) { 
        var aentries = document.getElementsByTagName(COLLAPSABLE_PARENT_TYPE);
		for (var i=0; i<aentries.length; i++){
			if (aentries[i].className==COLLAPSABLE_PARENT_NAME)  {
				alink = aentries[i].getElementsByTagName("img")[0];   // --- if use image as collapse/expand icon ---
				if (setting=="expand") 
					twistyImages(alink, 1);
				else if (setting=="collapse")  
					twistyImages(alink, -1);
			}
		}
	}
}

/****************************************************
 JavaScript for the Home Page
*****************************************************/
function toggleTabContent(number) { 
	for (var i=1;i<=3;i++) {
		document.getElementById("hpTabContent" + i).style.display = "none";
		document.getElementById("tabMenu" + i).style.backgroundImage = "url(/images/tab-color.gif)";
	}
	document.getElementById("hpTabContent" + number).style.display = "block";
	document.getElementById("tabMenu" +  number).style.backgroundImage = "url(/images/tab-white.gif)";
}

function changeLanguage(selectObj) {
	var lang = selectObj.options[selectObj.selectedIndex].value;
	if (lang=="en") {
		document.location = "http://www.altera.com";
	} else if (lang=="zh_CN") {
		document.location = "http://www.altera.com.cn";
	} else if (lang=="ja") {
		document.location = "http://www.altera.co.jp"; 
	}
}

function setTimer(callback, blockId, duration, setTimer) {
	if (blockId=="" || callback=="" || duration<0) return; 
	if (setTimer==true) {
		timerId = setTimeout(callback+"("+blockId+")", duration);
	} else {
		clearTimeout(timerId);
		timerId = -1;	
	}
}

function toggleTab(newBlockId) {
	if (newBlockId<1 || newBlockId>3) return; 
	
	document.getElementById("hp-tab-heading").style.backgroundImage = "url(images/tabs-"+newBlockId+".png)"; 
	for (i=1;i<=3;i++) {
		if (i==newBlockId) {
			document.getElementById("hp-tab-heading-"+i).style.color = "#06c";
			document.getElementById("tab-content-"+i).style.display = "block";
		} else {
			document.getElementById("hp-tab-heading-"+i).style.color = "#fff";
			document.getElementById("tab-content-"+i).style.display = "none";
		}
	}
}

// --- 2008-05-15: Candidate for removal ---
function addEvent(obj,type,fn) {
	if (obj.addEventListener)
		obj.addEventListener(type,fn,false);
	else if (obj.attachEvent)
		obj.attachEvent("on"+type,fn);
}

function go() {
	// --- Reset the CSS for the Search Form if JavaScript is enable ---
	document.getElementById("searchQuery").style.width = "155px";
	document.getElementById("searchDropdown").style.display = "inline";

	// --- For language drop down menu ---
	// --- 2009-03-30: No longer in use ---
	// document.getElementById("language-select").style.width = "172px";

	// --- Initialize tab ---
	timerId = -1;
	toggleTab(1);
	document.getElementById("tab-content").style.height = "172px";
	document.getElementById("tab-gh-container").style.height = "202px";
}

/***************************************************************
 * General purpose JavaScript functions
 **************************************************************/

/**
 * Duplicated from /js.lib/cookie2.js so we do not need to 
 * include additional file for just one fuction only. 
 */
function getCookieVal (offset) {
  var endstr = document.cookie.indexOf (";", offset);
  if (endstr == -1)
    endstr = document.cookie.length;
  return unescape(document.cookie.substring(offset, endstr));
}

function GetCookie (name) {
	var arg = name + "=";
	var alen = arg.length;
	var clen = document.cookie.length;
	var i = 0;
	while (i < clen) {
	var j = i + alen;
	if (document.cookie.substring(i, j) == arg)
		return getCookieVal (j);
		i = document.cookie.indexOf(" ", i) + 1;
		if (i == 0) break; 
	}
	return null;
}

/**
 * To load external file, js or css dynamically.
 */
function loadExternalFile(filename){
	var elementObj;
	if (filename.indexOf(".js")>0) { 
		elementObj=document.createElement('script')
		elementObj.setAttribute("type","text/javascript")
		elementObj.setAttribute("src", filename)
	} else if (filename.indexOf(".css")>0) { 
		elementObj=document.createElement("link")
		elementObj.setAttribute("rel", "stylesheet")
		elementObj.setAttribute("type", "text/css")
		elementObj.setAttribute("href", filename)
	}
	if (typeof elementObj!="elementObj") {
		document.getElementsByTagName("head")[0].appendChild(elementObj);
	}
}
  
/***************************************************************
 * JavaScript for the database-driven listing page
 **************************************************************/
 /*
var index = document.URL.indexOf("/literature/");
if (index>=0 && index<document.URL.indexOf(".jsp")) { 
	loadExternalFile("/js.lib/dhtmlwindow/dhtmlwindow.js");
	loadExternalFile("/js.lib/dhtmlwindow/dhtmlwindow.css");
	/***********************************************
	 * DHTML Window Widget- © Dynamic Drive (www.dynamicdrive.com)
	 * This notice must stay intact for legal use.
	 * Visit http://www.dynamicdrive.com/ for full source code
	 ***********************************************/
/*}*/

var inlinePopup;
function subscribeAlert(dssId) {
	inlinePopup = dhtmlwindow.open(
		"individualDocumentSubscription",
		"iframe", 
		"https://www.altera.com/servlets/subscriptions/alert?dp=pop&id="+dssId,
		"Subscription by Individual Document", 
		"width=350px,height=350px,resize=1,scrolling=1,center=1"
	); 
}