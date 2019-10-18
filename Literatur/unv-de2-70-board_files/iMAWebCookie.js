(function(){
  var version=2.02,page={},cookiespace='com.vtrenz.iMA',metaspace='com.vtrenz.',sessionTTL=8/*hrs*/,websyncTTL=1000/*days*/,
   api={path:'/WebCookies/RegisterWebPageVisit.cfm'},d=document,l=location,n=navigator,w=window,onloadcallstack=[];

  w.eb2b=w.eb2b||{
    track : function(){
      http(api.endpoint + $tx({
          session : session(),
          eventName:arguments[0].name||'n/a'
        },arguments[0].type)
      );
      top.location = top.location + '#';
      return false;
    }
  };

  function pageview(){
    websyncBridge();
    page.args = pageargs();
    page.metas = metatags();
    page.contact = contact();
    page.websync = websync();
    page.pageName = pagename();
    api.endpoint = endpoint();
    http(api.endpoint + $tx({
      session : session(),
      webSyncId : page.websync.uid
    },'pageview'));
  }

  function endpoint(){
    return port()+host()+api.path+'?accesskey='+pagekey()+'&v='+version;
  }

  function port(){
    return (l.protocol&&l.protocol.toString().toLowerCase()=='https:')?'https://':'http://';
  }

  function host(){
    return w.eb2b_gws_host||'gw-services.vtrenz.net';
  }

  function $tx(tx,_type){
    var _tx={}, query = tx.session.isNew ? '&isNewSession=1&type='+_type : '&isNewSession=0&type='+_type;
    _tx.customReferrerName=page.args['customreferrer']||'';
    _tx.eventName = tx.eventName||'';
    _tx.sessionGUID = tx.session.uid;
    _tx.webSyncID = page.websync.uid;
    _tx.url = d.URL;
    _tx.referringURL = d.referrer; //(d.referrer!='') ? d.referrer : 'n/a';
    _tx.cid = page.contact.uid;
    _tx.gclid = page.args['gclid']||'';
    _tx.hostname = l.hostname;
    _tx.pathname = l.pathname;
    _tx.pagename = page.pageName;
    _tx.gwkey = page.args['gwkey']||'';
    query += querystring(_tx);
    return query;
  }

  function querystring(obj,prefix){
    var q='', _prefix=prefix?prefix.toString()+'.':'';
    for(var key in obj){
      //q += (typeof obj[key]=="string" && obj[key]!='') ? '&'+_prefix+key+'='+encodeURIComponent(obj[key]) : /*recurse over non-strings*/querystring(obj[key],key);//removed for stackoverflow\too much recursion problem for js libraries that would extend the 'obj' argument
      if(typeof obj[key]=='string' && obj[key]!='') q+='&'+_prefix+key+'='+encodeURIComponent(obj[key]);
    }
    return q;
  }

  function createCookie(c){
    if(n&&n.cookieEnabled){
      var batter = c.name+"="+c.uid + _ttl(c.ttl) + "; path=/";
      d.cookie = batter;
    }
  }

  function updateCookie(_name,_value,_expiry){
    if(n&&n.cookieEnabled){
      var batter = cookiespace+_name+'='+_value + _ttl(_expiry) + '; path=/';
      d.cookie = batter;
    }
  }

  function readCookie(_name){
    var cookies = d.cookie ? d.cookie.split('; ') : [];
    var cookiename = cookiespace+_name;
    for(var i=0; i<cookies.length; i++) {
      if (cookies[i].indexOf(cookiename) == 0) return cookies[i].split('=')[1];
    }
    return '';
  }

  function deleteCookie(_name){
    var batter={name:_name,uid:'',ttl:-1};
    createCookie(batter);
  }

  function _guid(){
    var g = '';//this.isNew=1;
    for (var i=0; i<32; i++) {
      g += Math.floor(Math.random() * 0xF).toString(0xF) + (i == 7 || i == 11 || i == 15 || i == 19 ? "-" : "")
    }
    return g;
  }

  function _ttl(ttl){
    if(ttl){
      var date = new Date();
      date.setTime(date.getTime()+(ttl*24*60*60*1000));
      return "; expires="+date.toGMTString();
    }
    else {
      return '';
    }
  }

  function http(uri){
    var b=d.createElement('img');
    b.style.display='none';d.body.appendChild(b);b.src=uri;
  }

  function pagekey(){
    var js = d.getElementsByTagName('script');
    for(var i=0;i<js.length;i++){
      if((js[i].src) && js[i].src.match(/iMAWebCookie\.js(\?.*)$/i)) return js[i].src.split('?')[1];
    }
    return 'no-key';
  }

  function pageargs(){
    var h, args={}, q=location.search.substring(1).split('&');
    for(var i=0;i<q.length;i++){
      h=q[i].split("="); args[h[0].toLowerCase()]=unescape(h[1]);
    }
    return args;
  }

  function pagename(){
    return page.args['vpagename'] || w.eb2b_pagename || page.metas[metaspace+'pagename'] || '';
  }

  function metatags(){
    var tags={}, m=d.getElementsByTagName('meta');
    for(var i=0;i<m.length;i++){
      tags[m[i].name.toLowerCase()]=m[i].content;
    }
    return tags;
  }

  function contact(){
    var c = {
      uid : readCookie('.imaCID'),
      ttl : 1000,
      name : cookiespace+'.imaCID',
      isNew:false
    };

    if (c.uid=='' && typeof(page.args['contactid']) != 'undefined'){ // no cookie OR cookie!=url.contactid
      //deleteCookie('.imaCID');
      c.uid = page.args['contactid'];
      createCookie(c);
      c.isNew = true;
    }
    else if(c.uid != page.args['contactid'] && typeof(page.args['contactid']) != 'undefined' && c.cid != ''){
      deleteCookie(cookiespace+'.imaCID');
      deleteCookie(cookiespace+'.session');
      deleteCookie(cookiespace+'WebCookie');
      c.uid = page.args['contactid'];
      createCookie(c);
      c.isNew = true;
    }
    else if(c.uid == page.args['contactid']) {
      updateCookie('.imaCID',c.uid,c.ttl);
    }
    return c;
  }

  function websync(){
    var w = {
      uid:readCookie('WebCookie'),
      ttl:websyncTTL,
      name:cookiespace+'WebCookie'
    };
    if (w.uid==''){// || page.contact.isNew) {
      //create websync guid & cookie:
      w.uid = _guid(); createCookie(w);
    }
    else {
      //[just] extend cookie expiry:
      updateCookie('WebCookie',w.uid,w.ttl);
    }
    return w;
  }

  function websyncBridge(){
    var oVal=readCookie('WebCookie'), nVal=readCookie('.webSyncID');

    if(oVal!='' && nVal!='')//both exist, delete new
      deleteCookie(cookiespace+'.webSyncID');

    if(oVal=='' && nVal!='') {//only new exists, so rename (via create/delete)
      createCookie({uid:nVal,ttl:websyncTTL,name:cookiespace+'WebCookie'});
      deleteCookie(cookiespace+'.webSyncID');
    }
  }

  function session(){
    var s = {
      uid:readCookie('.session'),
      ttl:(w.eb2b_session_ttl||sessionTTL)/24,//input in hrs, convert to days
      name:cookiespace+'.session',
      //eventName: pagename(),
      isNew:false
    };
    if (s.uid=='' ){//|| page.contact.isNew) {
      //create session guid & cookie:
      s.uid = _guid(); createCookie(s);
      s.isNew=true;
    }
    else {
      //[just] extend cookie expiry:
      updateCookie('.session',s.uid,s.ttl);
    }
    return s;
  }

  if(typeof w.onload=='function') onloadcallstack.push(w.onload); onloadcallstack.push(pageview);
  w.onload=function(){for(var i=0;i<onloadcallstack.length;i++){onloadcallstack[i]();}};
})();