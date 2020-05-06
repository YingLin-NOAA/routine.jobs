#!/bin/ksh
set -x
set -A rfc
set -A address

if [ $# -eq 0 ]; then
  day0=`date -u +%Y%m%d`
else
  day0=$1
fi

# check for missing QPEs for "western" RFCs, i.e. all except the following 
# five regions.  In the winter Alaska is only checked during 
# weekdays/non-holidays, so dayakwinbeg needs to be reset.
# 
#   105: PR
#   155: MARFC
#   158: NERFC
#   160: OHRFC
#   161: SERFC
# 
# days to go back on: 
ndback=4

dayakwinbeg=20201101
#dayakwinend=20180TBD

#mailmode=yl
mailmode=live

# Load module prod_util to get UTILROOT for finddate.sh: 
. /usrx/local/prod/lmod/lmod/init/ksh
# only load the grep'd module below to avoid loading too many irrelevant modules
# and produce a lot of output message:
`grep prod_util ~/dots/dot.bashrc`
FINDDATE=$UTILROOT/ush/finddate.sh

echo Actual output starts here:

# define RFCs and contact addresses using RFC IDs:
rfc[105]='Puerto Rico'
rfc[150]=ABRFC
rfc[151]=Alaska
rfc[152]=CBRFC
rfc[153]=CNRFC
rfc[155]=MARFC
rfc[156]=MBRFC
rfc[157]=NCRFC
rfc[158]=NERFC
rfc[159]=NWRFC
rfc[160]=OHRFC
rfc[161]=SERFC

if [ $mailmode = live ]; then
address[150]='harold.crowley@noaa.gov larry.lowe@noaa.gov mason.rowell@noaa.gov bill.lawrence@noaa.gov james.paul@noaa.gov paul.mckee@noaa.gov'
address[151]='nws.ar.aprfc@noaa.gov'
address[152]='cbrfc.webmasters@noaa.gov katherine.rowden@noaa.gov'
address[153]='cnrfc.webmaster@noaa.gov cnrfc@noaa.gov katherine.rowden@noaa.gov'
address[154]='sr-orn.all@noaa.gov paul.mckee@noaa.gov'
address[155]='jason.nolan@noaa.gov seann.reed@noaa.gov laurie.hogan@noaa.gov robert.shedd@noaa.gov theodore.rodgers@noaa.gov david.ondrejik@noaa.gov'
address[156]='john.lague@noaa.gov marian.baker@noaa.gov daniel.virgillito@noaa.gov briona.saltman@noaa.gov'
address[157]='cr.msr@noaa.gov marian.baker@noaa.gov'
address[158]='nerfc.data@noaa.gov jeffrey.ouellet@noaa.gov ronald.horwood@noaa.gov alison.macneil@noaa.gov laurie.hogan@noaa.gov'
address[159]='nwrfc.all.hands@noaa.gov katherine.rowden@noaa.gov'
address[160]='ohrfc.ops@noaa.gov James.Noel@noaa.gov Brian.Astifan@noaa.gov laurie.hogan@noaa.gov'
address[161]='sr-alr.rivers@noaa.gov Christopher.Schaffer@noaa.gov john.schmidt@noaa.gov paul.mckee@noaa.gov'
address[162]='sr-fwr.all@noaa.gov paul.mckee@noaa.gov'
address[105]=${address[161]}

elif [ $mailmode = yl ]; then

address[150]='Ying.Lin+ABRFC@noaa.gov malvivant+ABRFC@gmail.com'
address[151]='Ying.Lin+Alaska@noaa.gov malvivant+Alaska@gmail.com'
address[152]='Ying.Lin+CBRFC@noaa.gov malvivant+CBRFC@gmail.com'
address[153]='Ying.Lin+CNRFC@noaa.gov malvivant+CNRFC@gmail.com'
address[154]='Ying.Lin+LMRFC@noaa.gov malvivant+LMRFC@gmail.com'
address[155]='Ying.Lin+MARFC@noaa.gov malvivant+MARFC@gmail.com'
address[156]='Ying.Lin+MBRFC@noaa.gov malvivant+MBRFC@gmail.com'
address[157]='Ying.Lin+NCRFC@noaa.gov malvivant+NCRFC@gmail.com'
address[158]='Ying.Lin+NERFC@noaa.gov malvivant+NERFC@gmail.com'
address[159]='Ying.Lin+NWRFC@noaa.gov malvivant+NWRFC@gmail.com'
address[160]='Ying.Lin+OHRFC@noaa.gov malvivant+OHRFC@gmail.com'
address[161]='Ying.Lin+SERFC@noaa.gov malvivant+SERFC@gmail.com'
address[162]='Ying.Lin+WGRFC@noaa.gov malvivant+WGRFC@gmail.com'
address[105]=${address[161]}

else
  echo mail mode needs to be either 'live' or 'yl'!  
  Mail -s "chk_qpe job run with incorrect mailmode" Ying.Lin@noaa.gov <<EOF
mailmode is ${mailmode}.  Should have been either 'live' or 'yl'
EOF
  exit
fi # mailmode = live/yl

DCOMROOT=/gpfs/dell1/nco/ops/dcom/prod

wrkdir=/gpfs/dell2/stmp/Ying.Lin/qpe_monitor_west
if [ -d $wrkdir ]; then
  rm -f $wrkdir/*
else
  mkdir -p $wrkdir
fi

cd $wrkdir

# Exclude Alaska in winter:
if [ $day0 -lt $dayakwinbeg ]; then
  rids="150 151 152 153 156 157 159"
else
  rids="150 152 153 156 157 159"
fi

for rid in $rids
do 
  aok=YES
  errfile=rfc_${rid}_missing_qpe.txt

  # Create a check list for each RFC:
  
  day=`$FINDDATE $day0 d-$ndback`
  while [ $day -le $day0 ];
  do 
    daym1=`$FINDDATE $day d-1`
    DCOM=$DCOMROOT/$day/wgrbbul/qpe
    DCOMm1=$DCOMROOT/$daym1/wgrbbul/qpe
    # All RFCs except AK/CN/NW have hourlies:
    if [ $rid -ne 151 -a $rid -ne 153 -a $rid -ne 159 ]; then
      cat >> chklist.$rid <<EOF
$DCOMm1/QPE.$rid.${daym1}13.01h
$DCOMm1/QPE.$rid.${daym1}14.01h
$DCOMm1/QPE.$rid.${daym1}15.01h
$DCOMm1/QPE.$rid.${daym1}16.01h
$DCOMm1/QPE.$rid.${daym1}17.01h
$DCOMm1/QPE.$rid.${daym1}18.01h
$DCOMm1/QPE.$rid.${daym1}19.01h
$DCOMm1/QPE.$rid.${daym1}20.01h
$DCOMm1/QPE.$rid.${daym1}21.01h
$DCOMm1/QPE.$rid.${daym1}22.01h
$DCOMm1/QPE.$rid.${daym1}23.01h
$DCOM/QPE.$rid.${day}00.01h
$DCOM/QPE.$rid.${day}01.01h
$DCOM/QPE.$rid.${day}02.01h
$DCOM/QPE.$rid.${day}03.01h
$DCOM/QPE.$rid.${day}04.01h
$DCOM/QPE.$rid.${day}05.01h
$DCOM/QPE.$rid.${day}06.01h
$DCOM/QPE.$rid.${day}07.01h
$DCOM/QPE.$rid.${day}08.01h
$DCOM/QPE.$rid.${day}09.01h
$DCOM/QPE.$rid.${day}10.01h
$DCOM/QPE.$rid.${day}11.01h
$DCOM/QPE.$rid.${day}12.01h
EOF
    fi

    # 2019/07/12: check for 6 hourlies only for AK/CB/CN/MB/NW RFCs:
    if [ $rid -eq 151 -o $rid -eq 152 -o $rid -eq 153 -o $rid -eq 156 -o $rid -eq 159 ]; then
    cat >> chklist.$rid <<EOF
$DCOMm1/QPE.$rid.${daym1}18.06h
$DCOM/QPE.$rid.${day}00.06h
$DCOM/QPE.$rid.${day}06.06h
$DCOM/QPE.$rid.${day}12.06h
EOF
    fi

    # AK/MB have 24h:
    if [ $rid -eq 151 -o $rid -eq 156 ]; then
      echo $DCOM/QPE.$rid.${day}12.24h >> chklist.$rid
    fi

    day=`$FINDDATE $day d+1`
  done # finsihed making a list of files to check for one RFC

  for file in `cat chklist.$rid`
  do
    if [ ! -s $file ]; then
      echo $file missing >> $errfile
      aok=NO
    fi
  done

  if [ $aok = NO ]; then
    cat $errfile >> missing.all
    rfcname=${rfc[rid]}
    cat >> $errfile <<EOF

This is an automatic email sent by a monitoring job of Ying.Lin@noaa.gov
NCEP has not received the above QPE file(s) from $rfcname by `date`
yyyymmddhh.xxh: xx hour accumulation ending at yyyymmddhh

Missing or corrected QPE files need to be received within 7 days of validation 
time to be included in the final run for Stage IV/URMA and for 
water.weather.gov/precip.  

If problem involves AWIPS, you may need to open a ticket with the NCF.

EOF
    Mail -s "Missing QPE files from $rfcname - ACTION REQUIRED" \
      -r "Ying.Lin@noaa.gov" \
      ${address[rid]} Ying.Lin@noaa.gov < $errfile
  else
    echo All files for RFC $rid are present.
  fi
done # going through each RFC ID

if [ $day -le $dayakwinbeg ]; then
  msubj="Western QPE check AOK for $day0"
else
  msubj="Western ConUS QPE check AOK for $day0"
fi

if [ ! -s missing.all ]; then
  Mail -s "$msubj" Ying.Lin@noaa.gov <<EOF
No missing QPE files found for $ndback+1 days ending 12Z $day0.
EOF
fi
exit
