#!/bin/ksh
set -x

if [ $# -eq 0 ]; then
  echo 'script needs the RFC number as an argument'
  exit
else
  rid=$1
  if [ $# -gt 1 ]; then
    day0=$2
  else
    day0=`date -u +%Y%m%d`
  fi
fi

# Load module prod_util to get UTILROOT for finddate.sh: 
. /usrx/local/prod/lmod/lmod/init/ksh
# only load the grep'd module below to avoid loading too many irrelevant modules
# and produce a lot of output message:
`grep prod_util ~/dots/dot.bashrc`
FINDDATE=$UTILROOT/ush/finddate.sh

ndback=7
day=`$FINDDATE $day0 d-$ndback`

DCOMROOT=/gpfs/dell1/nco/ops/dcom/prod
DCOM=$DCOMROOT/$day/wgrbbul/qpe
DCOMm1=$DCOMROOT/$daym1/wgrbbul/qpe

wrkdir=/gpfs/dell2/stmp/Ying.Lin/qpe_monitor
if [ -d $wrkdir ]; then
  rm -f $wrkdir/*
else
  mkdir -p $wrkdir
fi

cd $wrkdir

while [ $day -le $day0 ];
do 
  daym1=`$FINDDATE $day d-1`
  DCOM=$DCOMROOT/$day/wgrbbul/qpe
  DCOMm1=$DCOMROOT/$daym1/wgrbbul/qpe
  aok=YES
  errfile=rfc_${rid}_missing_qpe.txt

  # Create a check list for this RFC:
  
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

  # AK/NW/MB have 24h:
  if [ $rid -eq 151 -o $rid -eq 159 -o $rid -eq 156 ]; then
    echo $DCOM/QPE.$rid.${day}12.24h >> chklist.$rid
  fi

  day=`$FINDDATE $day d+1`
done

for file in `cat chklist.$rid`
do
  if [ ! -s $file ]; then
    echo $file missing >> $errfile
    aok=NO
  fi
done

# show $err file to screen so I won't need to go to the wrkdir to find out if
# any file is missing:

echo '  '

if [ -s $errfile ]; then 
  cat $errfile 
else
  echo 'no missing files'
fi

exit
