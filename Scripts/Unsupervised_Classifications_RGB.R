##Performing unsupervised classifications of multiple combinations of layers

##RGB Only

##Functions

##Uses a set of polygons to mask the raster and crop out relevant areas. 
crop_and_store <- function(r,shp,shp_id) {
  all_result <- NULL
  ##For the number of quadrats in shapefile
  for (i in 1:length(eval(parse(text=paste0("shp$",eval(shp_id))))))
  {
    ##Subset shp
    sub_shp <- shp[eval(parse(text=paste0("shp$",eval(shp_id))))[i],]
    ##Crop raster to individual quadrat
    out <- raster::mask(raster::crop(r,sub_shp),sub_shp)
    ##Get a count of pixels
    result <- as.data.frame(table(as.vector(out)))
    result <- cbind(result,rep(eval(parse(text=paste0("shp$",
                                                      eval(shp_id))))[i],
                               nrow(result)))
    ##Turn the counts into %s
    #result$Freq<- round(result$Freq/sum(result$Freq),2)*100
    all_result <- rbind(all_result,result)
  }
  colnames(all_result) <- c("Class","Count","Quad_ID")
  return(all_result)
}

##Read in Data

in_rast <- "Angle_Ricoh_BNG_PS2_Ortho_Crop.tif"
in_vect_mask <- "Angle_Ricoh_Mask"
in_vect_quad <- "Angle_Quadrats_Poly_Crop"

##Stack of RGB and texture layers
r_all <- raster::stack(paste0("Data/",in_rast))

##Drop alpha layer
r_all <- raster::dropLayer(r_all,4)

##Mask polygon of orthomosaic
site_mask <- rgdal::readOGR("Data", layer = in_vect_mask)

##Quadrat polygons
quadrats <- rgdal::readOGR("Data", layer = in_vect_quad)

##Classifications on RGB with 2-5 classes

##Choosing the number of classes in the classification
for (l in 2:5)
  {
  ##Perform the classification
  out <- RStoolbox::unsuperClass(r_all, nClasses = l)$map
  ##Pull out data relevant to quadrats
  out_result <- crop_and_store(out, quadrats,"Quad_ID")
  ##Write out results
  write.table(out_result,paste0("Data/Classified_RGB/",l,"classes.txt"), 
                  row.names=F)
}

raster::removeTmpFiles(h=2)