#!/bin/bash
# Parses the Security.evtx event log from a Windows systems
# and consoidates the results into HTML and CSV reports.
#
USAGE="$0 [file or directory...]"
DESCRIPTION=$(echo -e "\tParses one or more Security.evtx log files from Windows systems\n"\
                      "\tand outputs information to .html and .csv")
[ "$1" == "" ] && echo -e "Usage: $USAGE\n$DESCRIPTION"  && exit
[ ! -f "$1" ] && [ ! -d "$1" ] && echo -e "Usage: $USAGE\n$DESCRIPTION" && exit
echo "" > /tmp/OUTPUT
echo "" > Security.evtx.csv
echo "" > /tmp/Flat.txt
echo "Please wait....."
echo "Flattening Security.evtx file(s)"
[ -f "$1" ] && evtxexport -f xml "$1"|awk '{printf $0}'|sed 's/\s//g'|sed 's/<\/Event>/<\/Event>\n/g'|grep "LogonType" |tee -a /tmp/Flat.txt
[ -d "$1" ] && find "$1" -iname  "*\.evtx" 2>/dev/null | while read line; do evtxexport -f xml "$line"|awk '{printf $0}'|sed 's/\s//g'|sed 's/<\/Event>/<\/Event>\n/g'|grep "LogonType"; done |tee -a /tmp/Flat.txt
echo "Complete!"
Records=$(grep -c . /tmp/Flat.txt)
while read line; do
# shellcheck disable=2129
printf "<TR><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=SystemTime\=\").{3,35}(?=\"\/)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
# shellcheck disable=2129
echo "$line" | grep -Po '(?<=<EventID>)[0-9]*(?=<\/EventID)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
# shellcheck disable=2129
echo "$line" | grep -Po '(?<="LogonType">)[0-9]{1,2}(?=<\/Data>)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
# shellcheck disable=2129
echo "$line" | grep -Po '(?<=\=\"IpAddress\">)([0-9]{1,3}[\.]){3}[0-9]{1,3}(?=<\/Data)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=\=\"AuthenticationPackageName\">).{3,30}(?=<\/Data)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=\=\"SubjectDomainName\">).{3,30}(?=<\/Data)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=\=\"TargetDomainName\">).{3,30}(?=<\/Data)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=\=\"SubjectUserName\">).{3,30}(?=<\/Data)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=\=\"TargetUserName\">).{3,30}(?=<\/Data)' | awk '{printf $0}' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD><TD>">>/tmp/OUTPUT
echo "$line" | grep -Po '(?<=Computer>).{1,30}(?=<\/Computer)' >>/tmp/OUTPUT
# shellcheck disable=2129
printf "</TD></TR>" >>/tmp/OUTPUT
# shellcheck disable=2129
printf "\n" >>/tmp/OUTPUT
counter=$((counter+1))
echo "${counter} of ${Records} event(s) processed."
done < /tmp/Flat.txt
echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>Grabips Output</title>'>/tmp/HTOP
echo '<style>* {margin:0; padding:0; outline:none}body {font:10px Verdana,Arial; margin:25px; background:#fff repeat-x; color:#091f30}.sortable {width:980px; border-left:1px solid #c6d5e1; border-top:1px solid #c6d5e1; border-bottom:none; margin:0 15px}.sortable th {background-color:#999999; text-align:left; color:#cfdce7; border:1px solid #fff; border-right:none}.sortable th h3 {font-size:10px; padding:6px 8px 8px}.sortable td {padding:4px 6px 6px; border-bottom:1px solid #c6d5e1; border-right:1px solid #c6d5e1}.sortable .desc, .sortable .asc {background-color:#666666;}.sortable .head:hover, .sortable .desc:hover, .sortable .asc:hover {color:#fff}.sortable .evenrow td {background:#fff}.sortable .oddrow td {background:#ecf2f6}.sortable td.evenselected {background:#ecf2f6}.sortable td.oddselected {background:#dce6ee}#controls {width:980px; margin:0 auto; height:20px}#perpage {float:left; width:200px}#perpage select {float:left; font-size:11px}#perpage span {float:left; margin:2px 0 0 5px}#navigation {float:left; width:580px; text-align:center}#navigation img {cursor:pointer}#text {float:left; width:200px; text-align:right; margin-top:2px}</style>'>>/tmp/HTOP
# shellcheck disable=2129
# shellcheck disable=2016
echo '<script type="text/javascript"> var TINY={};function T$(i){return document.getElementById(i)}function T$$(e,p){return p.getElementsByTagName(e)}TINY.table=function(){function sorter(n){this.n=n;this.pagesize=10000;this.paginate=0}sorter.prototype.init=function(e,f){var t=ge(e),i=0;this.e=e;this.l=t.r.length;t.a=[];t.h=T$$("thead",T$(e))[0].rows[0];t.w=t.h.cells.length;for(i;i<t.w;i++){var c=t.h.cells[i];if(c.className!="nosort"){c.className=this.head;c.onclick=new Function(this.n+".wk(this.cellIndex)")}}for(i=0;i<this.l;i++){t.a[i]={}}if(f!=null){var a=new Function(this.n+".wk("+f+")");a()}if(this.paginate){this.g=1;this.pages()}};sorter.prototype.wk=function(y){var t=ge(this.e),x=t.h.cells[y],i=0;for(i;i<this.l;i++){t.a[i].o=i;var v=t.r[i].cells[y];t.r[i].style.display="";while(v.hasChildNodes()){v=v.firstChild}t.a[i].v=v.nodeValue?v.nodeValue:""}for(i=0;i<t.w;i++){var c=t.h.cells[i];if(c.className!="nosort"){c.className=this.head}}if(t.p==y){t.a.reverse();x.className=t.d?this.asc:this.desc;t.d=t.d?0:1}else{t.p=y;t.a.sort(cp);t.d=0;x.className=this.asc}var n=document.createElement("tbody");for(i=0;i<this.l;i++){var r=t.r[t.a[i].o].cloneNode(true);n.appendChild(r);r.className=i%2==0?this.even:this.odd;var cells=T$$("td",r);for(var z=0;z<t.w;z++){cells[z].className=y==z?i%2==0?this.evensel:this.oddsel:""}}t.replaceChild(n,t.b);if(this.paginate){this.size(this.pagesize)}};sorter.prototype.page=function(s){var t=ge(this.e),i=0,l=s+parseInt(this.pagesize);if(this.currentid&&this.limitid){T$(this.currentid).innerHTML=this.g}for(i;i<this.l;i++){t.r[i].style.display=i>=s&&i<l?"":"none"}};sorter.prototype.move=function(d,m){var s=d==1?(m?this.d:this.g+1):(m?1:this.g-1);if(s<=this.d&&s>0){this.g=s;this.page((s-1)*this.pagesize)}};sorter.prototype.size=function(s){this.pagesize=s;this.g=1;this.pages();this.page(0);if(this.currentid&&this.limitid){T$(this.limitid).innerHTML=this.d}};sorter.prototype.pages=function(){this.d=Math.ceil(this.l/this.pagesize)};function ge(e){var t=T$(e);t.b=T$$("tbody",t)[0];t.r=t.b.rows;return t};function cp(f,c){var g,h;f=g=f.v.toLowerCase(),c=h=c.v.toLowerCase();var i=parseFloat(f.replace(/(\$|\,)/g,"")),n=parseFloat(c.replace(/(\$|\,)/g,""));if(!isNaN(i)&&!isNaN(n)){g=i,h=n}i=Date.parse(f);n=Date.parse(c);if(!isNaN(i)&&!isNaN(n)){g=i;h=n}return g>h?1:(g<h?-1:0)};return{sorter:sorter}}();</script>'>>/tmp/HTOP
echo '</head><body><table cellpadding="0" cellspacing="0" border="0" id="table" class="sortable"><thead><tr><th><h3>EventTime</h3></th><th><h3>EventID</h3></th><th><h3>LogonType</h3></th><th><h3>IPAddress</h3></th><th><h3>AuthType</h3></th><th><h3>SubjectDomain</h3></th><th><h3>TargetDomain</h3></th><th><h3>SubjectUserName</h3><th><h3>TargetUserName</h3></th><th><h3>Computer</h3></th></tr></thead><tbody>'>>/tmp/HTOP
echo '</tbody></table><script type="text/javascript">  var sorter = new TINY.table.sorter("sorter");sorter.head = "head";sorter.asc = "asc";sorter.desc = "desc";sorter.even = "evenrow";sorter.odd = "oddrow";sorter.evensel = "evenselected";sorter.oddsel = "oddselected";sorter.paginate = true;sorter.currentid = "currentpage";sorter.limitid = "pagelimit";sorter.init("table",1);</script></body></html>' >/tmp/HFOOT
cat /tmp/HTOP /tmp/OUTPUT /tmp/HFOOT > Security.evtx.html
echo ""
echo "File Security.evtx.html created!"
sed -e 's/<[^>]\+>/ /g' -e 's/^ *//; s/ *$//; /^$/d' -e 's/ \+/,/g' /tmp/OUTPUT > Security.evtx.csv
echo "File Security.evtx.csv created!"
echo ""
echo ""
grep ",NTLM," Security.evtx.csv | grep -vc ANONYMOUSLOGON | awk '{printf $0 " Matches found in lateral movement/Pass the Hash search:\n"}'|tee PTH-lateral.csv
echo "PTH/Lateral movement profile:"
echo "EventID: 4624/4625,  NTLM Authentication, Type 3,  Non Anonymous Logon Attempt, Non Domain" | tee -a PTH-Lateral.csv
echo "see https://www.nsa.gov/ia/_files/app/Spotting_the_Adversary_with_Windows_Event_Log_Monitoring.pdf  Section 4.15 for more info"
grep ",NTLM," Security.evtx.csv | grep -v ANONYMOUSLOGON | grep ,4625, | grep ,3, | tee -a PTH-lateral.csv
grep ",NTLM," Security.evtx.csv | grep -vc ANONYMOUSLOGON | grep ,4624, | grep ,3, | tee -a PTH-lateral.csv
echo "File PTH-lateral.csv created!"
echo "Process Complete!"
exit
