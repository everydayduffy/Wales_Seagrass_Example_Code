##Creating texture layers from the green orthomosaic band

##Read in data 
in_rast <- "Angle_Ricoh_BNG_PS2_Ortho_Crop.tif" # RGB orthomosaic

r <- raster::stack(paste0("Data/",in_rast))
r <- raster::dropLayer(r, 4) # drop alpha band
r_g <- raster::raster(paste0("Data/",in_rast),band=2) # green band only

##Calculate texture
r_glcm_g <- glcm::glcm(r_g) # takes a long time

##Write out as individual layers
#raster::writeRaster(r_glcm_g, paste0("Data/Angle_Ricoh_BNG_PS2_Ortho_green_", 
#                                     names(r.glcm.g)), bylayer = TRUE, 
#                    format = "GTiff")

##Write out as one stack
#raster::writeRaster(r_glcm_g, "Data/Angle_Ricoh_BNG_PS2_Ortho_green_tex", 
#                    format = "GTiff")

##Write out as one stack (combined RGB + texture bands)
r_combo <- raster::stack(r,r_glcm_g)
raster::writeRaster(r_combo, "Data/Angle_Ricoh_BNG_PS2_Ortho_Tex_All", 
                    format = "GTiff")