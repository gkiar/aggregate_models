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
  timest="02:00:00"
else
  exps="mca session subsample"
  timest="00:30:00"
fi

clfs="svc rfc lrc knn ada"
nmca="20 18 16 14 12 10 7 5 2"
aggs="ref meta mega mean median consensus truncate"
graphs="graph rankgraph loggraph zgraph"
dimred="pca fa"

for c in ${clfs}
do
  for n in ${nmca}
  do
    for d in ${dimred}
    do
      for e in ${exps}
      do
        logf="${jobp}log_${DSET}_${c}_${n}_${e}_${d}.txt"
        cat << TMP > ${jobp}exec_${c}_${n}_${e}_${d}.sh
#!/bin/bash
#SBATCH --time ${timest}
#SBATCH --mem 16G
#SBATCH --account rpp-aevans-ab


source /home/gkiar/code/env/aggregate/bin/activate
cd ${bp}

exp="${e}"
graphs="${graphs}"

if [[ \${exp} != "mca" ]]
then
  agg_iter="`echo ${aggs} | cut -d " " -f -4`"
else
  agg_iter="${aggs}"
fi
for g in \${graphs}
do
  for a in \${agg_iter}
  do
    if [[ \${exp} == "mca" ]]
    then
      echo $e $c $d \$a \${g} $n &>> ${logf}
      (time python model_wrapper.py ${resd} ${dset} ${e} ${d} ${c} \${a} \${g} --n_mca ${n} --verbose) &>>${logf}
    else
      echo $e $c $d \$a \${g} &>> ${logf}
      (time python model_wrapper.py ${resd} ${dset} ${e} ${d} ${c} \${a} \${g} --verbose) &>>${logf}
    fi
  done
done
TMP
        chmod +x ${jobp}exec_${c}_${n}_${e}_${d}.sh
        sbatch ${jobp}exec_${c}_${n}_${e}_${d}.sh
      done
    done
  done
done

