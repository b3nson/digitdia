#!/bin/bash 

#TODO:
#process one single img
#output referenceimg with cropboxes?

DRYRUN=0
MOVESRCIMG=1

MAXBRIGHTNESS=180
MINBRIGHTNESS=2

#Session01
#CROPLANDSCAPE=3282x2188+936+577
#CROPPORTRAIT=2188x3282+1485+42

#Session02
CROPLANDSCAPE=3282x2188+912+635
CROPPORTRAIT=2188x3282+1429+72

COUNTFILES=0
COUNTPERDIR=0
STATCOUNTLSIMG=0
STATCOUNTPTIMG=0
STATCOUNTEMPTYIMG=0
LOGFILE=_log.txt


if [ $# -ne 1 ]; then
  echo "You need to specify a sourcepath."
  exit 1;
else
  if !(test -d "$1"); then 
    echo "Please specify a directory, not a file!"
    exit 1;
  fi
fi

SRCPATH=$1
STARTTIME=$(date +%s)


#-----------------------------------------------------------------------------------------------

function recurse() {

  cd -- "$1"

  echo ""                                                                 | tee -a $LOGFILE
  echo $CURDIRNAME                                                        | tee -a $LOGFILE
  echo "----------------------------------------------------------------" | tee -a $LOGFILE

  for i in `ls`; do
    if [ -d "$i" ]; then                                     #if directory
      CURDIRNAME=$i
      COUNTPERDIR=0
      if [ $CURDIRNAME != "_src" ]; then
        recurse "$i"
        cd ..
      fi
    else                                                      #else file
      if [ ${i##*.} == JPG ]; then
        processImage "$i"
        ((COUNTFILES++));
      fi
    fi
  done

  rm -f tmp.tif
}

#-----------------------------------------------------------------------------------------------

function processImage {
  IMG=$1
  TOOBRIGHT=$( tooBright "$IMG" )             # check for empty slides

  if [ $TOOBRIGHT == False ]; then            
#    oiiotool $IMG --cut 290x2185+1170+580 -o tmp.tif #tmpimg to check orientation  #session01
    oiiotool $IMG --cut 290x2185+1080+590 -o tmp.tif #tmpimg to check orientation  #session02

    TOODARK=$( tooDark "tmp.tif" )            # check for orientation
    ((COUNTPERDIR++));
    	if [ $TOODARK == False ]; then			    
    	  ORIENT="LS"
        CROP=$CROPLANDSCAPE
        ((STATCOUNTLSIMG++))
      else
      	ORIENT="PT"
        CROP=$CROPPORTRAIT
        ((STATCOUNTPTIMG++))
      fi

      NEWNAME=$CURDIRNAME"_"$(printf "%03d" $COUNTPERDIR)
      echo "$IMG       > $ORIENT > $NEWNAME.jpg"                           | tee -a $LOGFILE
      if [ $DRYRUN == 0 ]; then
         oiiotool $IMG --cut $CROP --flip --compression "jpeg:96" -o $PWD/$NEWNAME.jpg
         if [ $MOVESRCIMG == 1 ]; then mkdir -p _src; mv $IMG _src/; fi
      fi

  else								            # empty slide
    echo "$IMG       > empty slide "
    ((STATCOUNTEMPTYIMG++))
    if [ $DRYRUN == 0 ]; then
      if [ $MOVESRCIMG == 1 ]; then mkdir -p _src; mv $IMG _src/_$IMG;
      else mv $IMG _$IMG; fi
    fi
  fi
}

#-----------------------------------------------------------------------------------------------

function tooBright {
  AVGBRIGHT=`oiiotool --stats $1 | grep "Stats Avg" | sed 's/Stats Avg: //' | sed 's/ (of 255)//'`

  R=`echo $AVGBRIGHT | cut -d " " -f 1`
  G=`echo $AVGBRIGHT | cut -d " " -f 2`
  B=`echo $AVGBRIGHT | cut -d " " -f 3`

  RETVAL=`python -c "print (($R+$G+$B)/3) > $MAXBRIGHTNESS"`
  echo "$RETVAL"
}

#-----------------------------------------------------------------------------------------------

function tooDark {
  AVGBRIGHT=`oiiotool --stats $1 | grep "Stats Avg" | sed 's/Stats Avg: //' | sed 's/ (of 255)//'`

  R=`echo $AVGBRIGHT | cut -d " " -f 1`
  G=`echo $AVGBRIGHT | cut -d " " -f 2`
  B=`echo $AVGBRIGHT | cut -d " " -f 3`

  RETVAL=`python -c "print (($R+$G+$B)/3) < $MINBRIGHTNESS"`
  echo "$RETVAL"
}

#-----------------------------------------------------------------------------------------------


DIR="${SRCPATH%"${SRCPATH##*[!/]}"}"                        #get starting dirname
CURDIRNAME=${DIR##*/}

if [ $DRYRUN == 1 ]; then
  echo ""
  echo "****************************************** "
  echo "***************** DRYRUN ***************** "
  echo "****************************************** "
fi

#-----------------------------------------------------------------------------------------------

recurse "$SRCPATH"                                          #start traversing

#-----------------------------------------------------------------------------------------------

ENDTIME=$(date +%s)
DIFFTIME=$(( $ENDTIME - $STARTTIME ))
TIMEPERIMG=`python -c "print ( round(($DIFFTIME+0.0)/($COUNTFILES+0.0), 2) )"`

echo ""
echo "===================================================="
echo "Processed $COUNTFILES images in $DIFFTIME seconds. ($TIMEPERIMG s/img)"
echo "- $STATCOUNTLSIMG landscape"
echo "- $STATCOUNTPTIMG portrait"
echo "- $STATCOUNTEMPTYIMG empty slides"
echo "===================================================="
echo ""
exit 0;









