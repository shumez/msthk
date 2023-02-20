#!/bin/bash
# Filename:	pipeline_demo.sh
# Project: 	/Volumes/BA46/ws/msthk/code
# Authors: 	shumez <https://github.com/shumez>
# Created: 	2023-02-16 21:16:00
# Modified:	2023-02-19 15:33:12
# Hosted:  	shuBookPro.local
# -----
# Copyright (c) 2023 shumez

# preferences: to be modified
DISK=BA46
PROJ=msthk
INST=2
ID=9999
N=1



# preferences: directry
ROOTDIR=/Volumes/$DISK
WSDIR=$ROOTDIR/ws

SSDIR=$WSDIR/$PROJ
SRCDIR=$WSDIR/$PROJ/sourcedata
DCMDIR=$SRCDIR/dcm
DERDIR=$WSDIR/$PROJ/derivatives

D2NVER=v1.0.20210317
D2NDIR=$SRCDIR/dcm2niix/$D2NVER
NIIDIR=$SRCDIR/nii
LIST=$SSDIR/participants.tsv

# MS pipeline
MS_PIPELINE_VER=1.0.0
MPDIR=$DERDIR/ms_pipeline/$MS_THK_PIPELINE_VER
mkdir -p $MPDIR/$SID



# padding
INST="00${INST}"
INST="${INST: -2}"
ID="00000000${ID}"
ID="${ID: -8}"
SID=sub-${INST}${ID}
N="00${N}"
NRUN="${N: -2}"





# ws/msthk
# ├── CHANGES
# ├── README
# ├── code
# │   └── pipeline_demo.sh
# ├── dataset_description.json
# ├── derivatives
# ├── participants.json
# ├── participants.tsv
# └── sourcedata

# $HOME/freesurfer
# ├── 6.0.0
# │   └── freesurfer
# ├── 7.2.0
# │   └── freesurfer
# └── 7.3.2
#     └── freesurfer

# setup: freesurfer
FS_VER=7.3.2

# tar -zxvpf freesurfer-darwin-macOS-7.2.0.tar.gz
# cd ~/freesurfer
export FREESURFER_HOME=$HOME/freesurfer/${FS_VER}/freesurfer
# export FREESURFER_HOME=/Volumes/BA46/bin/freesurfer/7.2.0/freesurfer
export SUBJECTS_DIR=${WSDIR}/${PROJ}/derivatives/freesurfer/${FS_VER}
source $FREESURFER_HOME/SetUpFreeSurfer.sh

which freeview

# print log: setup
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tfreesurfer\tsetup done\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${SID}\t${timestamp}\t${MS_THK_PIPELINE_VER}\t" >> $SSDIR/msthk_pipeline_log.txt

# copy disk
mkdir -p $DCMDIR/$SID/$NRUN
cp -R /Volumes/AOC_MINI/* $DCMDIR/$SID/$NRUN

# print log: copy disk
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tcopy disk\tdone\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t${D2NVER}\t${DCMDIR}/${SID}/${NRUN}\t" >> $SSDIR/msthk_pipeline_log.txt

# dicom import
mkdir -p ${D2NDIR}/${SID}/${NRUN}
dcm2niix -z y -f %p -o ${D2NDIR}/${SID}/${NRUN} ${DCMDIR}/${SID}/${NRUN}

# print log: dicom import
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tdcm2niix\tdone\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t${D2NVER}\t${D2NDIR}/${SID}/${NRUN}\t" >> $SSDIR/msthk_pipeline_log.txt

# copy to bids folder

cp ${D2NDIR}/${SID}/${NRUN}/t1_mprage_sag_*.json ${SSDIR}/${SID}/anat/${SID}-${NRUN}_T1w.json
cp ${D2NDIR}/${SID}/${NRUN}/t1_mprage_sag_*.nii.gz ${SSDIR}/${SID}/anat/${SID}-${NRUN}_T1w.gz

cp ${D2NDIR}/${SID}/${NRUN}/flair_space_sag_*.json ${SSDIR}/${SID}/anat/${SID}-${NRUN}_FLAIR.json
cp ${D2NDIR}/${SID}/${NRUN}/flair_space_sag_*.nii.gz ${SSDIR}/${SID}/anat/${SID}-${NRUN}_FLAIR.nii.gz

# print log: dicom import
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tcopy nii\tdone\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t\t${SSDIR}/${SID}/anat/\t" >> $SSDIR/msthk_pipeline_log.txt


# freesurfer reconstruction all
recon-all \
    -i ${SSDIR}/${SID}/anat/${SID}-${NRUN}_T1w.nii.gz \
    -FLAIR ${SSDIR}/${SID}/anat/${SID}-${NRUN}_FLAIR.nii.gz \
    -s ${SID} \
    -sd ${SUBJECTS_DIR} \
    -all

# print log
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tfreesurfer\trecon-all done\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t${FS_VER}\t${SUBJECTS_DIR}/${SID}\t" >> $SSDIR/msthk_pipeline_log.txt



# freesurfer segmentation extra
${FREESURFER_HOME}/bin/segmentBS.sh $SID $SUBJECTS_DIR
# print log
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tfreesurfer\tsegmentBS done\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t${FS_VER}\t${SUBJECTS_DIR}/${SID}\t" >> $SSDIR/msthk_pipeline_log.txt

${FREESURFER_HOME}/bin/segmentHA_T1.sh $SID $SUBJECTS_DIR

# print log
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tfreesurfer\tsegmentHA done\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t${FS_VER}\t" >> $SSDIR/msthk_pipeline_log.txt

${FREESURFER_HOME}/bin/segmentThalamicNuclei.sh $SID $SUBJECTS_DIR

# print log
timestamp=`date +"%Y-%m-%d %T"`
echo -e "${timestamp}\tfreesurfer\tsegmentThalamicNuclei done\n" > $MPDIR/$SID/msthk_pipeline_log.txt
echo -e "${timestamp}\t${FS_VER}\t" >> $SSDIR/msthk_pipeline_log.txt


# make table
# asegstats2table --subjects --meas volume -- tablefile .tsv

for HEMI in rh lh
do
  for PARC in aparc aparc.a2009s aparc.DKTatlas aparc.pial
  do
    for MEAS in area volume thickness thicknessstd meancurv gauscurv foldind curvind
    do
      aparcstats2table \
        --subjects $SID \
        --hemi $HEMI \
        --parc $PARC \
        --meas $MEAS \
        --tablefile ${SUBJECTS_DIR}/${SID}/stats/${HEMI}.${PARC}.stats_${MEAS}.tsv
    done
  done
done

for MEAS in volume mean
do
  asegstats2table \
    --subjects $SUBJECTS \
    --meas $MEAS \
    --tablefile ${SUBJECTS_DIR}/${SID}/stats//aseg.stats_${MEAS}.tsv
done

for tab in amygdalar-nuclei.lh.T1.v22.stats \
  amygdalar-nuclei.rh.T1.v22.stats \
  brainstem.v13.stats \
  hipposubfields.lh.T1.v22.stats \
  hipposubfields.rh.T1.v22.stats \
  thalamic-nuclei.lh.v13.T1.stats \
  thalamic-nuclei.rh.v13.T1.stats
do
  asegstats2table \
    --subjects $SUBJECTS \
    --statsfile=$tab \
    --tablefile=${SUBJECTS_DIR}/${SID}/stats/${tab}.tsv
done




# sed 1d $LIST | while read id age sex group
# do
#   sid=sub-${id}
  
#   mkdir -p ${SRCDIR}/nii/dcm2niix_2021/${sid}
  
#   dcm2niix -z y -f %p_%t_%s -o ${srcdir}/nii/dcm2niix_2021/${sid} ${srcdir}/dcm/${id}

#   echo $sid
# done


# echo "\n" >> $SSDIR/msthk_pipeline_log.txt
# echo "\n" >> $SSDIR/msthk_pipeline_log.txt