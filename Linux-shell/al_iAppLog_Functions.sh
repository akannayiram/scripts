#!/bin/bash
# ****************************************
# Functions to monitor iApp Log Files 
#    - Al Kannayiram, October 2018
# ****************************************

function callUsage () {
  echo "########################################################"
  echo "ERROR!! No arguments supplied"
  echo "Pass Applicant or Retiree as argument"
  echo "Usage:"
#  echo "  $0 Applicant"
#  echo "  $0 Retiree"
  echo "  $0 <Module> <Num of days> <For stats>"
  echo "       Module: Applicant or Retiree"
  echo "  Num of days: 2 or 4 or All"
  echo "    For stats: Outputs one line per transaction"
  echo "ERROR!! Aborting"
  echo "########################################################"
}

function setLogfileList () {
  # Limit the number of log files
  #for i in `ls -tr $LOGDIR/spring*`
  for i in `ls -tr $LOGDIR/spring*.[1234].log`
  do
   LOGFILES="$LOGFILES $i"
  done
  LOGFILES="$LOGFILES $LOGFILE"
  #echo "LOGFILES: $LOGFILES"
  #LOGFILES=$LOGFILE
  #LOGFILES=$LOGDIR/spring*
}

function set4PriorDates () {
  # ******
  # Check the log for the last four days - Al 6/25/2018
  # ******
  currdt=`date '+%m-%d-%Y'`
  priordt1=`date '+%m-%d-%Y' -d"-1day"`
  priordt2=`date '+%m-%d-%Y' -d"-2day"`
  priordt3=`date '+%m-%d-%Y' -d"-3day"`
  egrepdates="^$currdt|^$priordt1|^$priordt2|^$priordt3"
  echo $egrepdates
}

function set2PriorDates () {
  # ******
  # Check the log for the last two days - Al 6/25/2018
  # ******
  currdt=`date '+%m-%d-%Y'`
  priordt1=`date '+%m-%d-%Y' -d"-1day"`
  egrepdates="^$currdt|^$priordt1"
  echo $egrepdates
}

function getScriptName () {
  s1=`basename $0`
  if [[ $s1 =~ bash ]] ; then
     sname=${module}_defaultname
  else
     sname=`echo $s1|awk -F"." '{print $1}'`
  fi
  echo $sname
}

function getApplicantRegistartions () {
  echo "==================================================="
  echo "BEGIN: `date '+%c'`: Searching for ${module} Registration"
  echo "BEGIN: Hostname: ${srvr}"
  echo "BEGIN: Search Dates: $egrepdates"
  echo "==================================================="
  # ***
  PRUNEDLOGFILE=$OUTDIR/${sname}_{$module}_`date '+%Y%m%d_%H%M%S'`_pruneddlog$$.txt
  STAGEFILE=$OUTDIR/${sname}_{$module}_`date '+%Y%m%d_%H%M%S'`_stage$$.txt
  egrep $egrepdates $LOGFILES|egrep "Start.*POST /|End.*POST /|\"AppInput\"|appResponse={\"Status| Start | End |SCIMClientOIM.processHTTPCall|callDcxApplicant|https://api.coned.com/" > $PRUNEDLOGFILE
  
  printline="no"
  let i=0
  while IFS= read -r line
  do
  line=`echo $line|sed 's/\x1b\[[0-9;]*m//g'`
  # POST /applicant
  if [[ $line =~ ${STARTPOST} ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*--- //"`
     printline="yes"
     i=$((i + 1))
     printf -v j "%05d" $i
     echo "##################################################"
     echo " "
     echo "${j}) $line2"
  fi
  
  if [[ $line =~ ${ENDPOST} ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*--- //"`
     printline="no"
     echo "${j}) $line2"
  fi
  
  if [[ $line =~ ${STARTPOSTRET} ]] ; then
     printline="no"
  fi
  
  if [[ $line =~ ${ENDPOSTRET} ]] ; then
     printline="no"
  fi
  
  if [[ $line =~ \"AppInput\" ]] ; then
     line2=`echo $line|awk '{print $1 " " $2 " " $15}'|sed -e "s/^.*log://"|sed -e "s/\"{\"AppInput\"/AppInput/"|sed -e "s/\}\"//"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ appResponse ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[.*null//"|sed -e "s/, app/app/"|sed -e "s/\}\}/}/"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ Start[[:space:]]PeopleSoft[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ Start[[:space:]]OIM[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ Start[[:space:]]callDcxApplicant ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ callDcxApplicant.*Start[[:space:]]Update[[:space:]]User[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ callDcxApplicant.*Start[[:space:]]Add[[:space:]]User.*Group ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ End[[:space:]]PeopleSoft[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- End /End /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ End[[:space:]]Errored[[:space:]]OIM[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- End /End /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ callDcxApplicant.*End[[:space:]]callDcx ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- End /End /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ SCIMClientOIM.processHTTPCall.*Response[[:space:]]code ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*SCIMClientOIM.processHTTPCall - Response code/SCIMClientOIM - Response code/"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ SCIMClientOIM.processHTTPCall.*Response[[:space:]]Body.*IAM-305000 ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*SCIMClientOIM.processHTTPCall - Response Body/SCIMClientOIM - Response Body/"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ handleResponse.*P.*https://api.coned.com/ ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*handleResponse - //"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  done < $PRUNEDLOGFILE > $STAGEFILE
  echo "##################################################"
  echo " "
  echo "==================================================="
  echo "END: `date '+%c'`: Searching for ${module} Registration"
  #echo "END: Hostname: ${srvr} - will wake up in $SLEEPTIME secs"
  echo "END: Hostname: ${srvr} "
  echo "END: Search Dates: $egrepdates"
  echo "==================================================="
  echo "END: Output is at $STAGEFILE"
  echo "==================================================="
}

function getRetireeRegistartions () {
  echo "==================================================="
  echo "BEGIN: `date '+%c'`: Searching for ${module} Registration"
  echo "BEGIN: Hostname: ${srvr}"
  echo "BEGIN: Search Dates: $egrepdates"
  echo "==================================================="
  # ***
  PRUNEDLOGFILE=$OUTDIR/${sname}_{$module}_`date '+%Y%m%d_%H%M%S'`_pruneddlog$$.txt
  STAGEFILE=$OUTDIR/${sname}_{$module}_`date '+%Y%m%d_%H%M%S'`_stage$$.txt
  #egrep "Start.*POST /|End.*POST /|{retResponse={|{\"RetInput| Start | End |SCIMClientOIM.processHTTPCall|callDcxRetiree|https://api.coned.com/" $LOGFILES > $STAGEFILE
  egrep  $egrepdates $LOGFILES|egrep "Start.*POST /|End.*POST /|{retResponse={|{\"RetInput| Start | End |SCIMClientOIM.processHTTPCall|callDcxRetiree|https://api.coned.com/" > $STAGEFILE
  
  printline="no"
  let i=0
  while IFS= read -r line
  do
  line=`echo $line|sed 's/\x1b\[[0-9;]*m//g'`
  # POST /retiree
  if [[ $line =~ ${STARTPOSTRET} ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*--- //"`
     printline="yes"
     i=$((i + 1))
     printf -v j "%05d" $i
     echo "##################################################"
     echo " "
     echo "${j}) $line2"
  fi
  
  if [[ $line =~ ${ENDPOSTRET} ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*--- //"`
     printline="no"
     echo "${j}) $line2"
  fi
  
  if [[ $line =~ ${STARTPOSTAPP} ]] ; then
     printline="no"
  fi
  
  if [[ $line =~ ${ENDPOSTAPP} ]] ; then
     printline="no"
  fi
  
  if [[ $line =~ \{retResponse\= ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*retResponse/retResponse/"|sed -e "s/appResponse.*$//"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ \{\"RetInput ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|awk '{print $1 " " $2 " " $15}'|sed -e "s/PayCheck.*EmployeeID/EmployeeID/"|sed -e "s/\"{\"RetInput\"/RetInput/"|sed -e "s/}\"//"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ Start[[:space:]]PeopleSoft[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ Start[[:space:]]OIM[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ Start[[:space:]]callDcxRetiree ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ callDcxRetiree*Start[[:space:]]Update[[:space:]]User[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ callDcxRetiree*Start[[:space:]]Add[[:space:]]User.*Group ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- Start /Start /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ End[[:space:]]PeopleSoft[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- End /End /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ End[[:space:]]Errored[[:space:]]OIM[[:space:]]Request ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- End /End /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ callDcxRetiree*End[[:space:]]callDcx ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*- End /End /"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ SCIMClientOIM.processHTTPCall.*Response[[:space:]]code ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*SCIMClientOIM.processHTTPCall - Response code/SCIMClientOIM - Response code/"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ SCIMClientOIM.processHTTPCall.*Response[[:space:]]Body.*IAM-305000 ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*SCIMClientOIM.processHTTPCall - Response Body/SCIMClientOIM - Response Body/"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  if [[ $line =~ handleResponse.*P.*https://api.coned.com/ ]] ; then
     line2=`echo $line|sed -e "s/^.*log://"|sed -e "s/\[\[ACTIVE.*handleResponse - //"`
     [[ $printline == "yes" ]] && echo "${j}) $line2"
  fi
  
  done < $PRUNEDLOGFILE > $STAGEFILE
  echo "##################################################"
  echo " "
  echo "==================================================="
  echo "END: `date '+%c'`: Searching for ${module} Registration"
  #echo "END: Hostname: ${srvr} - will wake up in $SLEEPTIME secs"
  echo "END: Hostname: ${srvr} "
  echo "END: Search Dates: $egrepdates"
  echo "==================================================="
  echo "END: Output is at $STAGEFILE"
  echo "==================================================="
}


set +x
. $HOME/iapp.env
srvr=`hostname`
# Start POST 
STARTPOSTRET="Start[[:space:]]POST[[:space:]]/retiree"
STARTPOSTAPP="Start[[:space:]]POST[[:space:]]/applicant"
#End POST
ENDPOSTRET="End.*POST[[:space:]]/retiree"
ENDPOSTAPP="End.*POST[[:space:]]/applicant"
# Output directory
#OUTDIR=/tmp
OUTDIR=/app/stage/al/output
#FINALFILE=$OUTDIR/${sname}_{$module}_`date '+%Y%m%d_%H%M%S'`_regs$$.txt

[ -z "$1" ] && callUsage; exit
arg1=`tr [a-z] [A-Z] $1`
case "$arg1" in
  APLICANT|APP)
    module=Applicant
    STARTPOST=$STARTPOSTAPP
    ENDPOST=$ENDPOSTAPP
    SLEEPTIME=300
    ;;
  RETIREE|RET)
    module=Retiree
    STARTPOST=$STARTPOSTRET
    ENDPOST=$ENDPOSTRET
    SLEEPTIME=1200
    ;;    
  *)
    echo "ERROR!! $1 is not a valid argument."
    callUsage
    echo "ERROR!! Aborting"
    exit    ;;
esac




getScriptName
setLogfileList
set4PriorDates
set2PriorDates

#while true
#do

rm -f $PRUNEDLOGFILE
#sleep $SLEEPTIME
#done

