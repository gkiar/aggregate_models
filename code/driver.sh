#!/usr/bin/env bash

bp="/home/gkiar/code/gkiar-aggregate/code/"
cd $bp

if [[ ${1} == 25 ]]
then
  DSET="D25"
  dset="../data/aggregation_connect+demo_dset25x2x2x20.h5"
  jobp="./slurm_scripts_25/"
else
  DSET="D100"
  dset="../data/aggregation_connect+feature+demo_dset100x1x1x20.h5"
  jobp="./slurm_scripts_100/"
fi

resd="../data/results_${DSET}/"
mkdir -p ${resd} ${jobp}

if [[ ${DSET} == "D100" ]]
then
  exps="mca"
  targets="bmi age cholesterol sex rel_vo2max"
  timest="06:00:00"
else
  exps="mca session subsample"
  targets="bmi age sex rel_vo2max"
  timest="00:30:00"
fi

nmca="20 15 10 5 2"
aggs="ref meta mega mean median consensus"
classifs="SVM LR RF"

for t in ${targets}
do
  for c in ${classifs}
  do
    for e in ${exps}
    do
      logf="${jobp}log_${DSET}_${t}_${c}_${e}.txt"
      cat << TMP > ${jobp}exec_${t}_${c}_${e}.sh
#!/bin/bash
#SBATCH --time ${timest}
#SBATCH --mem 16G
#SBATCH --account rpp-aevans-ab


source /home/gkiar/code/env/aggregate/bin/activate
cd ${bp}

exp="${e}"

if [[ \${exp} != "mca" ]]
then
  agg_iter="`echo ${aggs} | cut -d " " -f -4`"
else
  agg_iter="${aggs}"
fi
for a in \${agg_iter}
do
  if [[ \${exp} == "mca" ]]
  then
    for n in ${nmca}
    do
      echo $e $t \$a $c \$n &>> ${logf}
      (time python model_wrapper.py ${resd} ${dset} ${e} ${t} \${a} ${c} --n_mca \${n} --verbose) &>>${logf}
    done
  else
    echo $e $t \$a $c &>> ${logf}
    (time python model_wrapper.py ${resd} ${dset} ${e} ${t} \${a} ${c} --verbose) &>>${logf}
  fi
done
TMP
      chmod +x ${jobp}exec_${t}_${c}_${e}.sh
      sbatch ${jobp}exec_${t}_${c}_${e}.sh
    done
  done
done
