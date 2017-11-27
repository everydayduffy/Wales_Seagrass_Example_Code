##Performing unsupervised classifications of multiple combinations of layers

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

in_rast <- "Angle_Ricoh_BNG_PS2_Ortho_Tex_All.tif"
in_vect_mask <- "Angle_Ricoh_Mask"
in_vect_quad <- "Angle_Quadrats_Poly_Crop"

##Stack of RGB and texture layers
r_all <- raster::stack(paste0("Data/",in_rast))

##Mask polygon of orthomosaic
site_mask <- rgdal::readOGR("Data", layer = in_vect_mask)

##Quadrat polygons
quadrats <- rgdal::readOGR("Data", layer = in_vect_quad)

##All combinations of texture layers (8 in total)
combos <-  lapply(1:(dim(r_all)[3]-3), 
                  function(i) do.call(rbind, combn((dim(r_all)[3]-3), 
                                                   i, simplify=FALSE)))

##Classifications on multiple combinations of bands with 2-5 classes

##For each set of combinations
for(i in 1:length(combos))
{
  print(paste0("i is ",i))
  ##Subset the group of combinations
  sub_combos <- combos[[i]]
  ##For each combination in a set
  for (j in 1:nrow(sub_combos))
  {
    print(paste0("j is ",j))
    ##Subset the individual combination of numbers
    sub_combos_2 <- sub_combos[j,]
    ##Create initial stack (RGB layers)
    stk <- raster::subset(r_all,c(1,2,3))
    ##Loop through each value in the combination and add to stack
    for (k in 1:length(sub_combos_2))
    {
      ##Add to stack
      stk <- raster::stack(stk,raster::subset(r_all,sub_combos_2[k]+3))
    }
    ##Choosing the number of classes in the classification
    for (l in 2:5)
    {
      ##Perform the classification
      out <- RStoolbox::unsuperClass(stk, nClasses = l)$map
      ##Pull out data relevant to quadrats
      out_result <- crop_and_store(out, quadrats,"Quad_ID")
      ##Write out results
      write.table(out_result,paste0("Data/Classified_RGBTex/",i,"_",j,"_",l,"classes.txt"), 
                  row.names=F)
    }
    raster::removeTmpFiles(h=2)
  }
}