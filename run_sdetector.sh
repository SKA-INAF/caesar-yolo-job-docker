#!/bin/bash -e

# NB: -e makes script to fail if internal script fails (for example when --run is enabled)

#######################################
##         CHECK ARGS
#######################################
NARGS="$#"
echo "INFO: NARGS= $NARGS"


# - DATA OPTIONS
	parser.add_argument('--image', required=False, metavar="Input image", type=str, help='Input image in FITS format to apply the model (used in detect task)')
	parser.add_argument('--datalist', required=False, metavar="/path/to/dataset", help='Train/test data filelist containing a list of json files')
	parser.add_argument('--maxnimgs', required=False, metavar="", type=int, default=-1, help="Max number of images to consider in dataset (-1=all) (default=-1)")

	# - MODEL OPTIONS
	parser.add_argument('--weights', required=True, metavar="/path/to/weights.h5", help="Path to weights .h5 file")
	
	# - DATA PRE-PROCESSING OPTIONS
	parser.add_argument('--imgsize', dest='imgsize', required=False, type=int, default=640, help='Size in pixel used to resize input image (default=640)')
	
	parser.add_argument('--preprocessing', dest='preprocessing', action='store_true',help='Apply pre-processing to input image ')	
	parser.set_defaults(preprocessing=False)
	
	parser.add_argument('--normalize_minmax', dest='normalize_minmax', action='store_true',help='Normalize each channel in range. Default: [0,1]')	
	parser.set_defaults(normalize_minmax=False)
	parser.add_argument('-norm_min', '--norm_min', dest='norm_min', required=False, type=float, default=0., action='store',help='Normalization min value (default=0)')
	parser.add_argument('-norm_max', '--norm_max', dest='norm_max', required=False, type=float, default=1., action='store',help='Normalization max value (default=1)')
	
	parser.add_argument('--subtract_bkg', dest='subtract_bkg', action='store_true',help='Subtract bkg from ref channel image')	
	parser.set_defaults(subtract_bkg=False)
	parser.add_argument('-sigma_bkg', '--sigma_bkg', dest='sigma_bkg', required=False, type=float, default=3, action='store',help='Sigma clip to be used in bkg calculation (default=3)')
	parser.add_argument('--use_box_mask_in_bkg', dest='use_box_mask_in_bkg', action='store_true',help='Compute bkg value in borders left from box mask')	
	parser.set_defaults(use_box_mask_in_bkg=False)	
	parser.add_argument('-bkg_box_mask_fract', '--bkg_box_mask_fract', dest='bkg_box_mask_fract', required=False, type=float, default=0.7, action='store',help='Size of mask box dimensions with respect to image size used in bkg calculation (default=0.7)')
	parser.add_argument('-bkg_chid', '--bkg_chid', dest='bkg_chid', required=False, type=int, default=-1, action='store',help='Channel to subtract background (-1=all) (default=-1)')

	parser.add_argument('--clip_shift_data', dest='clip_shift_data', action='store_true',help='Do sigma clipp shifting')	
	parser.set_defaults(clip_shift_data=False)
	parser.add_argument('-sigma_clip', '--sigma_clip', dest='sigma_clip', required=False, type=float, default=1, action='store',help='Sigma threshold to be used for clip & shifting pixels (default=1)')
	parser.add_argument('--clip_data', dest='clip_data', action='store_true',help='Do sigma clipping')	
	parser.set_defaults(clip_data=False)
	parser.add_argument('-sigma_clip_low', '--sigma_clip_low', dest='sigma_clip_low', required=False, type=float, default=10, action='store',help='Lower sigma threshold to be used for clipping pixels below (mean-sigma_low*stddev) (default=10)')
	parser.add_argument('-sigma_clip_up', '--sigma_clip_up', dest='sigma_clip_up', required=False, type=float, default=10, action='store',help='Upper sigma threshold to be used for clipping pixels above (mean+sigma_up*stddev) (default=10)')	
	parser.add_argument('-clip_chid', '--clip_chid', dest='clip_chid', required=False, type=int, default=-1, action='store',help='Channel to clip data (-1=all) (default=-1)')
	
	parser.add_argument('--zscale_stretch', dest='zscale_stretch', action='store_true',help='Do zscale transform')	
	parser.set_defaults(zscale_stretch=False)
	parser.add_argument('--zscale_contrasts', dest='zscale_contrasts', required=False, type=str, default='0.25,0.25,0.25',help='zscale contrasts applied to all channels') 
	
	parser.add_argument('--chan3_preproc', dest='chan3_preproc', action='store_true',help='Use the 3 channel pre-processor')	
	parser.set_defaults(chan3_preproc=False)
	parser.add_argument('-sigma_clip_baseline', '--sigma_clip_baseline', dest='sigma_clip_baseline', required=False, type=float, default=0, action='store',help='Lower sigma threshold to be used for clipping pixels below (mean-sigma_low*stddev) in first channel of 3-channel preprocessing (default=0)')
	parser.add_argument('-nchannels', '--nchannels', dest='nchannels', required=False, type=int, default=1, action='store',help='Number of channels (1=default). If you modify channels in preprocessing you must set this accordingly')
	
	# - DETECT OPTIONS
	parser.add_argument('--scoreThr', required=False, default=0.7, type=float, metavar="Object detection score threshold to be used during test",help="Object detection score threshold to be used during test")
	parser.add_argument('--iouThr', required=False, default=0.5, type=float, metavar="Intersection Over Union (IoU) threshold for Non-Maximum Suppression (NMS).",help="Intersection Over Union (IoU) threshold for Non-Maximum Suppression (NMS)")
	parser.add_argument('--merge_overlap_iou_thr_soft', required=False, default=0.3, type=float, metavar="IOU threshold used to merge overlapping detected objects with same class",help="IOU threshold used to merge overlapping detected objects with same class")
	parser.add_argument('--merge_overlap_iou_thr_hard', required=False, default=0.8, type=float, metavar="IOU threshold used to merge overlapping detected objects, even those with same class",help="IOU threshold used to merge overlapping detected objects")
	
	parser.add_argument('--xmin', dest='xmin', required=False, type=int, default=-1, help='Image min x to be read (read all if -1)') 
	parser.add_argument('--xmax', dest='xmax', required=False, type=int, default=-1, help='Image max x to be read (read all if -1)') 
	parser.add_argument('--ymin', dest='ymin', required=False, type=int, default=-1, help='Image min y to be read (read all if -1)') 
	parser.add_argument('--ymax', dest='ymax', required=False, type=int, default=-1, help='Image max y to be read (read all if -1)') 
	
	# - PARALLEL PROCESSING OPTIONS
	parser.add_argument('--split_img_in_tiles', dest='split_img_in_tiles', action='store_true')	
	parser.set_defaults(split_img_in_tiles=False)
	parser.add_argument('--tile_xsize', dest='tile_xsize', required=False, type=int, default=512, help='Sub image size in pixel along x') 
	parser.add_argument('--tile_ysize', dest='tile_ysize', required=False, type=int, default=512, help='Sub image size in pixel along y') 
	parser.add_argument('--tile_xstep', dest='tile_xstep', required=False, type=float, default=1.0, help='Sub image step fraction along x (=1 means no overlap)') 
	parser.add_argument('--tile_ystep', dest='tile_ystep', required=False, type=float, default=1.0, help='Sub image step fraction along y (=1 means no overlap)') 
	parser.add_argument('--max_ntasks_per_worker', dest='max_ntasks_per_worker', required=False, type=int, default=100, help='Max number of tasks assigned to a MPI processor worker') 

	# - RUN OPTIONS
	parser.add_argument('--devices', required=False, type=str, default="cpu", metavar="Specifies the device for inference (e.g., cpu, cuda:0).", help="Specifies the device for inference (e.g., cpu, cuda:0 or 0).")
	parser.add_argument('--multigpu', dest='multigpu', action='store_true')	
	parser.set_defaults(multigpu=False)

	# - DRAW OPTIONS
	parser.add_argument('--draw_plots', dest='draw_plots', action='store_true')	
	parser.set_defaults(draw_plots=False)
	parser.add_argument('--draw_class_label_in_caption', dest='draw_class_label_in_caption', action='store_true')	
	parser.set_defaults(draw_class_label_in_caption=False)
	
	# - SAVE OPTIONS
	parser.add_argument('--save_plots', dest='save_plots', action='store_true')	
	parser.set_defaults(save_plots=False)
	parser.add_argument('--save_tile_catalog', dest='save_tile_catalog', action='store_true')	
	parser.set_defaults(save_tile_catalog=False)
	parser.add_argument('--save_tile_region', dest='save_tile_region', action='store_true')	
	parser.set_defaults(save_tile_region=False)
	parser.add_argument('--save_tile_img', dest='save_tile_img', action='store_true')	
	parser.set_defaults(save_tile_img=False)
	parser.add_argument('--detect_outfile', required=False, metavar="Output plot filename", type=str, default="", help='Output plot PNG filename (internally generated if left empty)')
	parser.add_argument('--detect_outfile_json', required=False, metavar="Output json filename with detected objects", type=str, default="", help='Output json filename with detected objects (internally generated if left empty)')





if [ "$NARGS" -lt 1 ]; then
	echo "ERROR: Invalid number of arguments...see script usage!"
  echo ""
	echo "**************************"
  echo "***     USAGE          ***"
	echo "**************************"
 	echo "$0 [ARGS]"
	echo ""
	echo "=========================="
	echo "==    ARGUMENT LIST     =="
	echo "=========================="
	echo "*** MANDATORY ARGS ***"
	echo "--image=[FILENAME] - Input image to apply the model (.fits/.png/.jpg). Takes precedence over --inputfile option."
	echo "--inputfile=[FILENAME] - Input filelist (.json) containing the list of images to be processed."
	
	echo ""

	echo "*** OPTIONAL ARGS ***"
	echo "=== MODEL OPTIONS ==="
	echo "--model=[MODEL] - Pretrained model to be used in prediction. Options are {yolov11l_imgsize128,yolov11l_imgsize256,yolov11l_imgsize512,yolov11l_imgsize640}. Default: yolov11l_imgsize640 "
	echo ""
	
	echo "=== PRE-PROCESSING OPTIONS ==="
	echo "--xmin=[VALUE] - Image min x to be read (read all if -1) (default=-1)"
	echo "--xmax=[VALUE] - Image max x to be read (read all if -1) (default=-1)"
	echo "--ymin=[VALUE] - Image min y to be read (read all if -1) (default=-1)"
	echo "--ymin=[VALUE] - Image max y to be read (read all if -1) (default=-1)"
	echo "--imgsize=[IMGSIZE] - Size in pixels used for image resize (default=640)"
	echo "--preprocessing - Apply pre-processing to input image (default=disabled)"
	echo "--normalize - Apply minmax normalization to images (default=disabled)"
	echo "--normmin=[NORM_MIN] - Normalization min value (default=0)"
	echo "--normmax=[NORM_MAX] - Normalization max value (default=1)"
	echo "--subtract_bkg - Subtract bkg from ref channel image"
	echo "--sigma-bkg=[SIGMA_BKG] - Sigma clip to be used in bkg calculation (default=3)."
	echo "--use-box-mask-in-bkg - Compute bkg value in borders left from box mask"
	echo "--bkg-box-mask-fract=[BKG_BBOX_MASK_FRAC] - Size of mask box dimensions with respect to image size used in bkg calculation (default=0.7)"
	echo "--bkg-chid=[BKG_CHID] - Channel to subtract background (-1=all) (default=-1)"
	echo "--clipshiftdata - Do sigma clipp shifting"
	echo "--sigmaclip=[SIGMA_CLIP] - Sigma threshold to be used for clip & shifting pixels (default=1)"
	echo "--clipdata - Apply sigma clipping to each image channel"
	echo "--sigmaclip-low=[SIGMA_CLIP_LOW] - Min sigma clipping value (default=10)"
	echo "--sigmaclip-up=[SIGMA_CLIP_UP] - Max sigma clipping value (default=10)"
	echo "--sigmaclip-chid=[SIGMA_CHID] - Channel used to apply clipping (-1=all channels) (default=-1)"
	echo "--zscale - Apply zscale transform to each image channel"
	echo "--zscale-contrasts=[CONTRASTS] - zscale transform contrast parameters (separated by commas) (default=0.25,0.25,0.25)"
	echo "--chan3-preproc - Use the 3 channel pre-processor"
	echo "--sigmaclip-baseline=[SIGMA_CLIP_LOW] - Lower sigma threshold to be used for clipping pixels below (mean-sigma_low*stddev) in first channel of 3-channel preprocessing (default=0)"
	echo "--nchans=[NCHANS] - Number of channels. If you modify channels in preprocessing you must set this accordingly (default=1)"
			
	echo ""
	
	echo "=== DETECT OPTIONS ==="
	echo "--score-thr=[THR] - Object detection score threshold to be used during test (default=0.7)"
	echo "--iou-thr=[THR] - Intersection Over Union (IoU) threshold for Non-Maximum Suppression (NMS) (default=0.5)"
	echo "--merge-overlap-iou-thr-soft=[THR] - IOU threshold used to merge overlapping detected objects with same class (default=0.3)"
	echo "--merge_overlap-iou-thr-hard=[THR] - IOU threshold used to merge overlapping detected objects, even those with same class (default=0.8)"
	
	echo ""
	
	echo "=== PARALLEL RUN OPTIONS ==="
	echo "--split-img-in-tiles - Split input image in multiple sub tiles (default=disabled)"
	echo "--tile-xsize=[VALUE] - Sub image size in pixel along x (default=512)"
	echo "--tile-ysize=[VALUE] - Sub image size in pixel along y (default=512)"
	echo "--tile-xstep=[VALUE] - Sub image step fraction along x (=1 means no overlap) (default=1.0)"
	echo "--tile-ystep=[VALUE] - Sub image step fraction along y (=1 means no overlap) (default=1.0)"
	echo "--max-ntasks-per-worker - Max number of tasks assigned to a MPI processor worker (default=100)"
	
	echo ""
	
	echo "=== RUN OPTIONS ==="
	echo "--devices=[DEVICES] - Specifies the device for inference (e.g., cpu, cuda:0) (default=cpu)"
	echo "--multigpu - Enable multi-gpu run (default=disabled)"	
	echo "--run - Run the generated run script on the local shell. If disabled only run script will be generated for later run."	
	echo "--scriptdir=[SCRIPT_DIR] - Job directory where to find scripts (default=/usr/bin)"
	echo "--modeldir=[MODEL_DIR] - Job directory where to find model & weight files (default=/opt/models)"
	echo "--jobdir=[JOB_DIR] - Job directory where to run (default=pwd)"
	echo "--outdir=[OUTPUT_DIR] - Output directory where to put run output file (default=pwd)"
	echo "--waitcopy - Wait a bit after copying output files to output dir (default=no)"
	echo "--copywaittime=[COPY_WAIT_TIME] - Time to wait after copying output files (default=30)"
	echo "--no-logredir - Do not redirect logs to output file in script "	
	
	echo ""
	
	echo "=== DRAW OPTIONS ==="
	echo "--draw-plots - Enable plot making (default=disabled)"
	echo "--draw-class-label-in-caption - Enable drawing of class label in plots (default=disabled)"
	
	echo ""
	
	echo "=== SAVE OPTIONS ==="
	echo "--save-plots - Enable plot saving (default=disabled)"
	echo "--save-tile-catalog - Enable saving of subtile catalog files (default=disabled)"
	echo "--save-tile-region - Enable saving of subtile DS9 region files (default=disabled)"
	echo "--save-tile-img - Enable saving of subtile image files (default=disabled)"
	echo "--outfile=[FILENAME] - Output plot PNG filename (internally generated if left empty) (default=empty)"
	echo "--outfile-catalog=[FILENAME] - Output json filename with detected objects (internally generated if left empty for --image option) (default=empty)"
	
	echo ""
	
	echo "=========================="
  exit 1
fi


#######################################
##         PARSE ARGS
#######################################
JOB_DIR=""
JOB_OUTDIR=""
SCRIPT_DIR="/usr/bin"
MODEL_DIR="/opt/models"

IMAGE=""
IMAGE_GIVEN=false
DATALIST=""
DATALIST_GIVEN=false

RUN_SCRIPT=false
WAIT_COPY=false
COPY_WAIT_TIME=30
REDIRECT_LOGS=true

MODEL="smorphclass"

XMIN=-1
XMAX=-1
YMIN=-1
YMAX=-1
IMGSIZE=640
PREPROCESSING=""
NORMALIZE_MINMAX=""
NORM_MIN=0
NORM_MAX=1
SUBTRACT_BKG=""
SIGMA_BKG=3
USE_BOX_MASK_IN_BKG=""
BKG_BOX_MASK_FRACT=0.7
BKG_CHID=-1

CLIP_SHIFT_DATA=""
SIGMA_CLIP=1
CLIP_DATA=""
SIGMA_CLIP_LOW=10
SIGMA_CLIP_UP=10
CLIP_CHID=-1
ZSCALE_STRETCH=""
ZSCALE_CONTRASTS="0.25,0.25,0.25"
CHAN3_PREPROC=""
SIGMA_CLIP_BASELINE=0
NCHANS=1

SCORE_THR=0.7
IOU_THR=0.5
MERGE_OVERLAP_IOU_THR_SOFT=0.3
MERGE_OVERLAP_IOU_THR_HARD=0.8

SPLIT_IMG_IN_TILES=""
TILE_XSIZE=512
TILE_YSIZE=512
TILE_XSTEP=1
TILE_YSTEP=1
MAX_NTASKS_PER_WORKER=100

DEVICES="cpu"
MULTIGPU=""
DRAW_PLOTS=""
DRAW_CLASS_LABEL_IN_CAPTION=""
SAVE_PLOTS=""
SAVE_TILE_CATALOG=""
SAVE_TILE_REGION=""
SAVE_TILE_IMG=""
OUTFILE=""
OUTFILE_CATALOG=""

for item in "$@"
do
	case $item in 
		## MANDATORY ##
		--image=*)
    	IMAGE=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`		
			if [ "$IMAGE" != "" ]; then
				IMAGE_GIVEN=true
			fi
    ;;
    --inputfile=*)
    	DATALIST=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`		
			if [ "$DATALIST" != "" ]; then
				DATALIST_GIVEN=true
			fi
    ;;
    
    ## OPTIONAL (RUN OPTIONS) ##
    --devices=*)
    	DEVICES=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --multigpu*)
    	MULTIGPU="--multigpu"
    ;;
    --run*)
    	RUN_SCRIPT=true
    ;;
    --scriptdir=*)
    	SCRIPT_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --modeldir=*)
    	MODEL_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --outdir=*)
    	JOB_OUTDIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--waitcopy*)
    	WAIT_COPY=true
    ;;
		--copywaittime=*)
    	COPY_WAIT_TIME=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --jobdir=*)
    	JOB_DIR=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --no-logredir*)
			REDIRECT_LOGS=false
		;;
    
    ## OPTIONAL (MODEL OPTIONS) ##
    --model=*)
    	MODEL=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    
    ## OPTIONAL (PRE-PROCESSING OPTIONS) ##
    --xmin=*)
    	XMIN=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --xmax=*)
    	XMAX=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --ymin=*)
    	YMIN=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --ymax=*)
    	YMAX=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --imgsize=*)
    	IMGSIZE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --preprocessing*)
    	PREPROCESSING="--preprocessing"
    ;;
		--normalize*)
    	NORMALIZE_MINMAX="--normalize_minmax"
    ;;
    --normmin=*)
    	NORM_MIN=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --normmax=*)
    	NORM_MAX=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--subtract-bkg*)
    	SUBTRACT_BKG="--subtract_bkg"
    ;;
		--sigma-bkg=*)
    	SIGMA_BKG=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--use-box-mask-in-bkg*)
    	USE_BOX_MASK_IN_BKG="--use_box_mask_in_bkg"
    ;;
		--bkg-box-mask-fract=*)
    	BKG_BOX_MASK_FRACT=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --bkg-chid=*)
    	BKG_CHID=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--clipshiftdata*)
    	CLIP_SHIFT_DATA="--clip_shift_data"
    ;;
		--sigmaclip=*)
    	SIGMA_CLIP=`echo $item | /bin/sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--sigmaclip*)
    	CLIP_DATA="--clip_data"
    ;;
		--sigmaclip-low*)
    	SIGMA_CLIP_LOW=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;	
    --sigmaclip-up*)
    	SIGMA_CLIP_UP=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--sigmaclip-chid*)
    	CLIP_CHID=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --zscale*)
    	ZSCALE_STRETCH="--zscale_stretch"
    ;;
		--zscale-contrasts*)
    	ZSCALE_CONTRASTS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--chan3-preproc*)
    	CHAN3_PREPROC="--chan3_preproc"
    ;;
		--sigmaclip-baseline*)
    	SIGMA_CLIP_BASELINE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;  
    --nchans=*)
    	NCHANS=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    
    ## OPTIONAL (DETECT OPTIONS)
    --score-thr=*)
    	SCORE_THR=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --iou-thr=*)
    	IOU_THR=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --merge-overlap-iou-thr-soft=*)
    	MERGE_OVERLAP_IOU_THR_SOFT=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --merge-overlap-iou-thr-hard=*)
    	MERGE_OVERLAP_IOU_THR_HARD=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
	
		## OPTIONAL (PARALLEL RUN OPTIONS)
    --split-img-in-tiles*)
    	SPLIT_IMG_IN_TILES="--split_img_in_tiles"
    ;;
		--tile-xsize=*)
    	TILE_XSIZE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --tile-ysize=*)
    	TILE_YSIZE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --tile-xstep=*)
    	TILE_XSTEP=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --tile-ystep=*)
    	TILE_YSTEP=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
		--max-ntasks-per-worker=*)
    	MAX_NTASKS_PER_WORKER=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    
		## OPTIONAL (DRAW OPTIONS)
    --draw-plots*)
    	DRAW_PLOTS="--draw_plots"
    ;;
    --draw-class-label-in-caption*)
    	DRAW_CLASS_LABEL_IN_CAPTION="--draw_class_label_in_caption"
    ;;
    
		## OPTIONAL (SAVE OPTIONS)
		--save-plots*)
    	SAVE_PLOTS="--save_plots"
    ;;
    --save-tile-catalog*)
    	SAVE_TILE_CATALOG="--save_tile_catalog"
    ;;
    --save-tile-region*)
    	SAVE_TILE_REGION="--save_tile_region"
    ;;
    --save-tile-img*)
    	SAVE_TILE_IMG="--save_tile_img"
    ;;
    --outfile=*)
    	OUTFILE=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    --outfile-catalog=*)
    	OUTFILE_CATALOG=`echo $item | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
	
    *)
    # Unknown option
    echo "ERROR: Unknown option ($item)...exit!"
    exit 1
    ;;
	esac
done


## Check arguments parsed
if [ [ "$DATALIST_GIVEN" = false ] && [ "$IMAGE_GIVEN" = false ] ]; then
  echo "ERROR: Missing or empty IMAGE/DATALIST args (hint: you must specify at least one)!"
  exit 1
fi

if [ "$JOB_DIR" = "" ]; then
  echo "WARN: Empty JOB_DIR given, setting it to pwd ($PWD) ..."
	JOB_DIR="$PWD"
fi

if [ "$JOB_OUTDIR" = "" ]; then
  echo "WARN: Empty JOB_OUTDIR given, setting it to pwd ($PWD) ..."
	JOB_OUTDIR="$PWD"
fi



#######################################
##   SET CLASSIFIER OPTIONS
#######################################
PREPROC_OPTS="--xmin=$XMIN --xmax=$XMAX --ymin=$YMIN --ymax=$YMAX --imgsize=$IMGSIZE $PREPROCESSING $NORMALIZE_MINMAX --norm_min=$NORM_MIN --norm_max=$NORM_MAX $SUBTRACT_BKG --sigma_bkg=$SIGMA_BKG $USE_BOX_MASK_IN_BKG --bkg_box_mask_fract=$BKG_BOX_MASK_FRACT --bkg_chid=$BKG_CHID $CLIP_SHIFT_DATA --sigma_clip=$SIGMA_CLIP $CLIP_DATA --sigma_clip_low=$SIGMA_CLIP_LOW --sigma_clip_up=$SIGMA_CLIP_UP --clip_chid=$CLIP_CHID $ZSCALE_STRETCH --zscale_contrasts=$ZSCALE_CONTRASTS $CHAN3_PREPROC --sigma_clip_baseline=$SIGMA_CLIP_BASELINE --nchannels=$NCHANS "

if [ "$MODEL" = "yolov11l_imgsize128" ]; then
	WEIGHTFILE="$MODEL_DIR/weights-yolov11l_scratch_imgsize128_nepochs300.pt"

elif [ "$MODEL" = "yolov11l_imgsize256" ]; then
	WEIGHTFILE="$MODEL_DIR/weights-yolov11l_scratch_imgsize256_nepochs300.pt"
	
elif [ "$MODEL" = "yolov11l_imgsize512" ]; then
	WEIGHTFILE="$MODEL_DIR/weights-yolov11l_scratch_imgsize512_nepochs300.pt"

elif [ "$MODEL" = "yolov11l_imgsize640" ]; then
	WEIGHTFILE="$MODEL_DIR/weights-yolov11l_scratch_imgsize640_nepochs300.pt"
	
else 
	echo "ERROR: Unknown/not supported MODEL argument $MODEL given!"
  exit 1
fi

DETECT_OPTS="--scoreThr=$SCORE_THR --iouThr=$IOU_THR --merge_overlap_iou_thr_soft=$MERGE_OVERLAP_IOU_THR_SOFT --merge_overlap_iou_thr_hard=$MERGE_OVERLAP_IOU_THR_HARD "
RUN_OPTS="--devices=$DEVICES $MULTIGPU "
PARALLEL_RUN_OPTS="$SPLIT_IMG_IN_TILES --tile_xsize=$TILE_XSIZE --tile_ysize=$TILE_YSIZE --tile_xstep=$TILE_XSTEP --tile_ystep=$TILE_YSTEP --max_ntasks_per_worker=$MAX_NTASKS_PER_WORKER "
DRAW_OPTS="$DRAW_PLOTS $DRAW_CLASS_LABEL_IN_CAPTION "
SAVE_OPTS="$SAVE_PLOTS $SAVE_TILE_CATALOG $SAVE_TILE_REGION $SAVE_TILE_IMG --detect_outfile=$OUTFILE --detect_outfile_json=$OUTFILE_CATALOG "


#######################################
##   DEFINE GENERATE EXE SCRIPT FCN
#######################################
# - Set shfile
shfile="run_predict.sh"

generate_exec_script(){

	local shfile=$1
	
	
	echo "INFO: Creating sh file $shfile ..."
	( 
			echo "#!/bin/bash -e"
			
      echo " "
      echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         PREPARE JOB                     ****"'
      echo 'echo "*************************************************"'

      echo " "
       
      echo "echo \"INFO: Entering job dir $JOB_DIR ...\""
      echo "cd $JOB_DIR"

			echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         RUN CLASSIFIER                  ****"'
      echo 'echo "*************************************************"'
				
			EXE="python $SCRIPT_DIR/run.py" 
			ARGS="--image=$IMAGE --datalist=$DATALIST --weights=$WEIGHTFILE $PREPROC_OPTS $DETECT_OPTS $RUN_OPTS $PARALLEL_RUN_OPTS $DRAW_OPTS $SAVE_OPTS "
			CMD="$EXE $ARGS"

			echo "date"
			echo ""
		
			echo "echo \"INFO: Running source detection ...\""
			
			if [ $REDIRECT_LOGS = true ]; then			
      	echo "$CMD >> $logfile 2>&1"
			else
				echo "$CMD"
      fi
      
			echo " "

			echo 'JOB_STATUS=$?'
			echo 'echo "Classifier terminated with status=$JOB_STATUS"'

			echo "date"

			echo " "

      echo 'echo "*************************************************"'
      echo 'echo "****         COPY DATA TO OUTDIR             ****"'
      echo 'echo "*************************************************"'
      echo 'echo ""'
			
			if [ "$JOB_DIR" != "$JOB_OUTDIR" ]; then
				echo "echo \"INFO: Copying job outputs in $JOB_OUTDIR ...\""
				echo "ls -ltr $JOB_DIR"
				echo " "

				echo "# - Copy output json data"
				echo 'tab_count=`ls -1 *.json 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output table file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.json $JOB_OUTDIR"
				echo "fi"

				echo " "
				
				echo "# - Copy output DS9 region data"
				echo 'tab_count=`ls -1 *.reg 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output table file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.reg $JOB_OUTDIR"
				echo "fi"
				
				echo " "
				
				echo "# - Copy output PNG data"
				echo 'tab_count=`ls -1 *.png 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output table file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.png $JOB_OUTDIR"
				echo "fi"
				
				echo " "
				
				echo "# - Copy output FITS data"
				echo 'tab_count=`ls -1 *.fits 2>/dev/null | wc -l`'
				echo 'if [ $tab_count != 0 ] ; then'
				echo "  echo \"INFO: Copying output table file(s) to $JOB_OUTDIR ...\""
				echo "  cp *.fits $JOB_OUTDIR"
				echo "fi"
				
				echo " "
		
				echo "# - Show output directory"
				echo "echo \"INFO: Show files in $JOB_OUTDIR ...\""
				echo "ls -ltr $JOB_OUTDIR"

				echo " "

				echo "# - Wait a bit after copying data"
				echo "#   NB: Needed if using rclone inside a container, otherwise nothing is copied"
				if [ $WAIT_COPY = true ]; then
           echo "sleep $COPY_WAIT_TIME"
        fi
	
			fi

      echo " "
      echo " "
      
      echo 'echo "*** END RUN ***"'

			echo 'exit $JOB_STATUS'

 	) > $shfile

	chmod +x $shfile
}
## close function generate_exec_script()

###############################
##    RUN SOURCE DETECTOR
###############################
# - Check if job directory exists
if [ ! -d "$JOB_DIR" ] ; then 
  echo "INFO: Job dir $JOB_DIR not existing, creating it now ..."
	mkdir -p "$JOB_DIR" 
fi

# - Moving to job directory
echo "INFO: Moving to job directory $JOB_DIR ..."
cd $JOB_DIR

# - Generate run script
echo "INFO: Creating run script file $shfile ..."
generate_exec_script "$shfile"

# - Launch run script
if [ "$RUN_SCRIPT" = true ] ; then
	echo "INFO: Running script $shfile to local shell system ..."
	$JOB_DIR/$shfile
fi


echo "*** END SUBMISSION ***"

