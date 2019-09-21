#!/bin/ksh
# hourly job to check for missing MRMS on dcom and notify 
# NCEP.List.IDP_Support@noaa.gov if one is not found.  At present there is
# a 92-97 delay:
#  May 16 16:32 GaugeCorr_QPE_01H_00.00_20170516-150000.grib2.gz
#  May 16 15:32 GaugeCorr_QPE_01H_00.00_20170516-140000.grib2.gz
#  May 16 14:35 GaugeCorr_QPE_01H_00.00_20170516-130000.grib2.gz
#  May 16 13:37 GaugeCorr_QPE_01H_00.00_20170516-120000.grib2.gz
#  May 16 12:36 GaugeCorr_QPE_01H_00.00_20170516-110000.grib2.gz
#
# 2019/07/12: Lag is reduced to ~1hr:
#  Jul 12 18:00 GaugeCorr_QPE_01H_00.00_20190712-170000.grib2.gz
#  Jul 12 17:00 GaugeCorr_QPE_01H_00.00_20190712-160000.grib2.gz
#  Jul 12 15:59 GaugeCorr_QPE_01H_00.00_20190712-150000.grib2.gz
#  Jul 12 14:58 GaugeCorr_QPE_01H_00.00_20190712-140000.grib2.gz
#  Jul 12 13:58 GaugeCorr_QPE_01H_00.00_20190712-130000.grib2.gz
# Run this job at 15 min past the top of the hour to check for the presence# 
# of the previous hour's MRMS.  
#

set -x
if [ $# -eq 0 ]; then
  datem1h=`date +%Y%m%d%H -d "1 hour ago"`
else
  datem1h=$1
fi

DCOMMRMS=/gpfs/dell1/nco/ops/dcom/prod/ldmdata/obs/upperair/mrms/conus/GaugeCorr_QPE

yyyymmdd=${datem1h:0:8}
hh=${datem1h:8:2}
MRMSfile=GaugeCorr_QPE_01H_00.00_${yyyymmdd}-${hh}0000.grib2.gz

wrkdir=/gpfs/dell2/stmp/Ying.Lin/mrms_monitor
if [ -d $wrkdir ]; then
  rm -f $wrkdir/*
else
  mkdir -p $wrkdir
fi
msg=$wrkdir/emailmsg.txt

cd $DCOMMRMS

if [ -s $MRMSfile ]; then 
  ls -l $MRMSfile > $wrkdir/aok
else
  cat > $msg <<EOF
  At `date`
  $MRMSfile not found on 
    `pwd -P`
  This is an automatic message sent by a monitoring job of Ying.Lin@noaa.gov
EOF
  Mail -s "Missing MRMS files for ${yyyymmdd}-${hh}Z" -r Ying.Lin@noaa.gov NCEP.List.IDP_Support@noaa.gov idp-support@noaa.gov Ying.Lin@noaa.gov < $msg
fi

exit
