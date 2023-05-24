#!/bin/bash 

## check that all the runs have exactly 2 archived fastq files associated with them, 
## and re-organise them according to sample_to_run.tsv 

SERIES=$1
if (( $# != 1 ))
then
  >&2 echo "USAGE: ./reorganize_fastq.sh <series_id>"
  >&2 echo
  >&2 echo "(requires non-empty <series_id>.sample.list, <series_id>.run.list, and <series_id>.sample_x_run.list)" 
  exit 1
fi

mkdir fastqs

SAMPLES=`cat $SERIES.sample.list`
RUNS=`cat $SERIES.run.list`

## at this point, all the downloaded or converted fastq.gz files should be in /done_wget
cd done_wget

for i in $RUNS
do
  ## files named _1(2).fastq.gz are proper ENA fastq files, and directory is the output of bam2fastq
  if [[ ! -s ${i}_1.fastq.gz || ! -s ${i}_2.fastq.gz || ! -d $i ]]  
  then 
    >&2 echo "WARNING: Run $i does not seem to have two fastq files (or a bamtofastq output directory) associated with it!"
    ## let's check if there are original submitter's fastq files (AE does that): 
    URL=`grep $i ../$SERIES.parsed.tsv | cut -f3 | tr ';' '\n' | head -n1`
    ORIFQ=`basename $URL`
    if [[ $URL != "" && -s $ORIFQ ]]
    then
      >&2 echo "Original submitter's fastq files ($ORIFQ etc) found for $i.."
    else 
      >&2 echo "WARNING: No ENA/BAM/original submitter's fastq files associated with run $i found - please investigate!"
    fi 
  fi
done 

for i in $SAMPLES
do
  >&2 echo "Moving the files for sample $i:" 
  mkdir $i 
  SMPRUNS=`grep $i ../$SERIES.sample_x_run.tsv | awk '{print $2}' | tr ',' '\n'`
  for j in $SMPRUNS
  do
    >&2 echo "==> Run $j belongs to sample $i, moving to directory $i.." 
    if [[ -s ${j}_1.fastq.gz ]]
    then
      mv ${j}_?.fastq.gz $i
    elif [[ -d $j ]] 
    then
      mv $j $i
    else
      ## special case for original submitter's fastqs: 
      URLS=`grep $j ../$SERIES.parsed.tsv | cut -f3 | tr ';' '\n'`
      for k in $URLS
      do
        ORIFQ=`basename $k`
        mv $ORIFQ $i
      done
    fi
  done 
  mv $i ../fastqs 
  >&2 echo "Moving directory $i to /fastqs.."
done 

echo "REORGANISE FASTQS: ALL DONE!" 

