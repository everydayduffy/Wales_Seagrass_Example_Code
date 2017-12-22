##OBIA in GRASS using RGB and texture bands

#version=7.0.4
#date=2016
#revision=00000
#build_date=2016-05-10
#build_platform=x86_64-pc-linux-gnu
#libgis_revision=67364
#libgis_date="2015-12-24 16:07:44 +0100 (Thu, 24 Dec 2015) "
#proj4=4.9.2
#gdal=2.1.0
#geos=3.5.0
#sqlite=3.11.0

##Establish GRASS databases for each site
##Projection used is British National Grid (EPSG:2770)

##Setup file structure
mkdir ~/Wales_Seagrass
cd ~/Wales_Seagrass

##Copy orthomosaic to home folder
cp Angle_Ricoh_BNG_PS2_Ortho_Tex_All.tif ~/Wales_Seagrass

##Load GRASS
grass --text

##Install required extensions
g.extension --verbose extension=i.segment.uspo operation=add
g.extension --verbose extension=i.segment.stats operation=add
g.extension --verbose extension=r.object.geometry operation=add
g.extension --verbose extension=v.class.mlR operation=add
g.extension --verbose extension=r.neighborhoodmatrix operation=add

#############
##Angle Bay##
#############

##Setup location and mapset
grass -e -c EPSG:27700 ~/Wales_Seagrass/Angle
grass -c ~/Wales_Seagrass/Angle/angle1

##Read in raster with RGB+TEX
r.in.gdal --verbose input=~/Wales_Seagrass/Angle_Ricoh_BNG_PS2_Ortho_Tex_All.tif \
output=angle_ortho

##Change names to remove dots
g.rename raster=angle_ortho.1,angle_ortho_1,angle_ortho.2,angle_ortho_2,\
angle_ortho.3,angle_ortho_3,angle_ortho.4,angle_ortho_4,\
angle_ortho.5,angle_ortho_5,angle_ortho.6,angle_ortho_6

##Group bands together
i.group --verbose group=angle_combo input=angle_ortho_1@angle1,angle_ortho_2@angle1,\
angle_ortho_3@angle1,angle_ortho_4@angle1,angle_ortho_5@angle1,\
angle_ortho_6@angle1,angle_ortho_7@angle1,angle_ortho_8@angle1,\
angle_ortho_9@angle1,angle_ortho_10@angle1,,angle_ortho_11@angle1

##Set sample regions for i.segment.uspo tool
##These are subsets of the mosaic that contain 'representitive areas'
g.region -au n=202380 s=202370 w=189710 e=189720 res=0.00436449 \
save=angle_region_1
g.region -au n=202371 s=202361 w=189736 e=189746 res=0.00436449 \
save=angle_region_2

##Optional:output regions as shapefiles to check
#g.region  angle_region_1
#v.in.region output=angle_region_1_poly
#v.out.ogr input=angle_region_1_poly  output=angle_region_1_poly.shp
#g.region angle_region_2
#v.in.region output=angle_region_2_poly
#v.out.ogr input=angle_region_2_poly output=angle_region_2_poly.shp

##Run i.segment.uspo
i.segment.uspo --verbose group=angle_combo@angle1 \
regions=angle_region_1,angle_region_2 \
output=/home/jpd205/Wales_GRASS/Angle/angle_uspo.txt \
segment_map=angle_seg_uspo segmentation_method=region_growing \
threshold_start=0.05 threshold_stop=0.25 threshold_step=0.05 \
minsizes=5,10,15 number_best=5 memory=12000 processes=8

##Optimum parameter results
###threshold=0.1 / minsize=10

##Run i.segment
g.region raster=angle_ortho_1@angle1
i.segment -d --overwrite --verbose group=angle_combo@angle1 \
output=angle_seg_optimum threshold=0.1 minsize=10 memory=12000

##Reclass the raster clumps to ensure more efficient processing
r.clump -d --verbose input=angle_seg_optimum@angle1 \ output=angle_seg_optimum_clump

##Run i.segment.stats outputting csv and vectormap
g.region raster=angle_seg_optimum_clump@angle1

i.segment.stats --verbose map=angle_seg_optimum_clump@angle1 \
rasters=angle_ortho_1@angle1,angle_ortho_2@angle1,angle_ortho_3@angle1,\
angle_ortho_4@angle1,angle_ortho_5@angle1,angle_ortho_6@angle1,\
angle_ortho_7@angle1,angle_ortho_8@angle1,angle_ortho_9@angle1,\
angle_ortho_10@angle1,,angle_ortho_11@angle1 \
raster_statistics=min,max,range,mean,stddev,variance,sum \
csvfile=~/Wales_Seagrass/Angle/angle_seg_stats separator=comma \
vectormap=angle_seg_stats_vec

##Some column names were too long to fit into a shapefile, so were shortened
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=compact_circle,com_circ
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_min,ango1min
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_max,ango1max
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_range,ango1range
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_mean,ango1mean
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_stddev,ango1stdev
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_variance,ango1var
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_1_sum,ango1sum
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_min,ango2min
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_max,ango2max
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_range,ango2range
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_mean,ango2mean
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_stddev,ango2stdev
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_variance,ango2var
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_2_sum,ango1sum
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_min,ango3min
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_max,ango3max
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_range,ango3range
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_mean,ango3mean
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_stddev,ango3stdev
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_variance,ango3var
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_3_sum,ango3sum
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_min,ango4min
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_max,ango4max
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_range,ango4range
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_mean,ango4mean
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_stddev,ango4stdev
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_variance,ango4var
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_4_sum,ango4sum
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_min,ango5min
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_max,ango5max
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_range,ango5range
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_mean,ango5mean
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_stddev,ango5stdev
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_variance,ango5var
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_5_sum,ango5sum
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_min,ango6min
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_max,ango6max
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_range,ango6range
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_mean,ango6mean
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_stddev,ango6stdev
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_variance,ango6var
v.db.renamecolumn map=angle_seg_stats_vec@angle1 column=angle_ortho_6_sum,ango6sum

##It was too big to fit into one shapefile, so split into three
v.extract input=angle_seg_stats_vec where="(cat < 500000)" \
output=angle_seg_stats_vec_p1
v.extract input=angle_seg_stats_vec@angle1 \
where="(cat>=500000) and (cat<1000000)" output=angle_seg_stats_vec_p2
v.extract input=angle_seg_stats_vec@angle1 \
where="(cat>=1000000)" output=angle_seg_stats_vec_p3

##These shapefiles were then opened in QGIS
##Using it as a transparent layer on top of an orthomosaic, select segments
##from each desired class e.g. seagrass/sediment/macroalgae were exported to
##a new shapefile and a column named 'class' added.

##This training class shapefile was then imported into the GRASS database
v.in.ogr --o --verbose \ input=~/Wales_Seagrass/Angle/Classified_shapes/angle_train_class.shp \
key=cat output=angle_train_class

##Run the classification tool
v.class.mlR --overwrite --verbose segments_map=angle_seg_stats_vec@angle1 \
training_map=angle_train_class@angle1 raster_segments_map=angle_seg_optimum_clump@angle1 \
classified_map=angle_seg_out train_class_column=Class output_class_column=vote \
output_prob_column=prob folds=5 partitions=10 tunelength=10 weighting_metric=accuracy \
bw_plot_file=~/Wales_Seagrass/angle_seg_bplot processes=10

##Write out classified map
r.out.gdal input=angle_seg_out output=angle_obia_classified.tif
