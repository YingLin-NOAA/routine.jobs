#!/bin/ksh
set -x
# run this script for Alaska in winter season.
# schedule it at 21:00Z (see Arleen note)
# Alaska winter 2017-2018 schedule:
#  run the check each day on 21:00Z
# Sat/Sun: check on Monday, along with the Monday QPEs
# Federal holidays: 
# 11/12: check on Tue 11/13
# 11/22: check on Fri 11/23
# 12/24
# 12/25: check on Wed 12/26
# 1/1: check on Wed 1/2
# 1/21: check on Tue 1/22
# 2/18: check on Tue 2/19
#
# From Arleen, 2017/9/28:
# 
# Our winter schedule begins in November this year, so QPE will be created 
# every day through 11/3.  That weekend (11/4-5) will be the first weekend 
# that QPE are created the following Monday instead of daily.  As for timing, 
# generally 20:15 will be OK, but doing 3 days of QPE on Monday (4 on Tuesday 
# in the case of a Monday holiday) means that sometimes a day will not be 
# completed until a little later (perhaps by 21Z).
#
# As for holidays, your list should be correct with the exception of 11/23-24, 
# which you can check for on 11/24 (I usually come in for at least part of 
# that Friday).  Or you can check on Monday.
#
# Also, I will probably take a day or two off the week between Christmas and 
# New Years, but that schedule is not up yet, so I will have to let you know 
# later if there will be any additional delayed days that week.
#
# We usually go back on our "summer" schedule in late April or early May, 
# but the schedule is not out yet.  So I will have to give you that exact 
# date later.

if [ $# -eq 0 ]; then
  today=`date -u +%Y%m%d`
else
  today=$1
fi

#mailmode=yl
mailmode=live

# Load module prod_util to get UTILROOT for finddate.sh: 
. /usrx/local/prod/lmod/lmod/init/ksh
# only load the grep'd module below to avoid loading too many irrelevant modules
# and produce a lot of output message:
`grep prod_util ~/dots/dot.bashrc`
FINDDATE=$UTILROOT/ush/finddate.sh

# find day of week: ('6' for Saturday, '7' for Sunday)
dow=`date +%w -d$today`

if [ $dow -eq 6 -o $dow -eq 0 -o $today -eq 20191128 \
         -o $today -eq 20191225 -o $today -eq 20200101 -o $today -eq 20200120 \
         -o $today -eq 20200217 ]
then
  echo weekend/holiday.  Skip checking
  Mail -s "Weekend/Holiday/off day for AK, no QPE check" Ying.Lin@noaa.gov <<EOF
No checking AKQPE for $today 
EOF
  exit
fi


if [ $mailmode = live ]; then
  address='nws.ar.aprfc@noaa.gov'
elif [ $mailmode = yl ]; then
  address='Ying.Lin+Alaska@noaa.gov malvivant+Alaska@gmail.com'
else
  echo mail mode needs to be either 'live' or 'yl'!  
  Mail -s "chk_akqpe_winter job run with incorrect mailmode" Ying.Lin@noaa.gov <<EOF
mailmode is ${mailmode}.  Should have been either 'live' or 'yl'
EOF
  exit
fi # mailmode = live/yl
daym8=`$FINDDATE $today d-8`
day=$daym8

DCOMROOT=/gpfs/dell1/nco/ops/dcom/prod

wrkdir=/gpfs/dell2/stmp/Ying.Lin/qpe_monitor_ak
if [ -d $wrkdir ]; then
  rm -f $wrkdir/*
else
  mkdir -p $wrkdir
fi

cd $wrkdir

# Create a check list that contains the AK 6h/24h QPEs from ${daym5)18 to
# ${day}12:

while [ $day -le $today ]
do 
  prevday=`$FINDDATE $day d-1`

  DCOM=$DCOMROOT/$day/wgrbbul/qpe
  DCOMprev=$DCOMROOT/$prevday/wgrbbul/qpe
  
  cat >> chklist.ak <<EOF
$DCOMprev/QPE.151.${prevday}18.06h
$DCOM/QPE.151.${day}00.06h
$DCOM/QPE.151.${day}06.06h
$DCOM/QPE.151.${day}12.06h
$DCOM/QPE.151.${day}12.24h 
EOF

  day=`$FINDDATE $day d+1`
done # put the past four days' 6h/24 QPF files on check list

errfile=ak_missing_qpe.txt

aok=YES

for file in `cat chklist.ak`
do
  if [ ! -s $file ]; then
    echo $file missing >> $errfile
    aok=NO
  fi
done

if [ $aok = NO ]; then
  cat >> $errfile <<EOF

This is an automatic email sent by a monitoring job of Ying.Lin@noaa.gov
NCEP has not received the above QPE file(s) from $rfcname by `date`
yyyymmddhh.xxh: xx hour accumulation ending at yyyymmddhh

Missing or corrected QPE files need to be received within 7 days of validation 
time to be included in the final run for Stage IV/URMA and for 
water.weather.gov/precip.  

If problem involves AWIPS, you may need to open a ticket with the NCF.

EOF
  Mail -s "Missing QPE files from Alaska - ACTION REQUIRED" \
    -r "Ying.Lin@noaa.gov" \
    ${address[rid]} Ying.Lin@noaa.gov < $errfile
  else
    echo All files for Alaska are present.
  fi

if [ ! -s $errfile ]; then
  Mail -s "QPE check AOK for Alaska" Ying.Lin@noaa.gov <<EOF
No missing QPE files found for the 120h period ending 12Z $today.
EOF
fi
exit
