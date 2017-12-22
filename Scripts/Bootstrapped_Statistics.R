##Script to calculate bootstrapped statistics on the differences in pixel 
##counts to observed coverages across quadrats.

set.seed(25)

#############
##FUNCTIONS##
#############

##Function - can deal with any length of a
#x=raster
#a=values to be replaced
#b=replacement value
replacevals <- function(x, a, b,filename) {
  bs <- blockSize(x)
  out <- writeStart(x, filename, overwrite=TRUE)
  for (i in 1:bs$n) {
    print(paste0("Block ",i," of ",bs$n))
    v <- getValues(x, row=bs$row[i], nrows=bs$nrows[i] )
    for (j in 1:length(a)) {
      v[v==a[j]] <- b
    }
    out <- writeValues(out, v, bs$row[i])
  }
  out <- writeStop(out)
  return(out)
}

##Input data and column locations of observed (a) and classified (b) % cover. 
bootcoverage <- function(data,a,b) {
  ##Define stats functions for bootstrapping
  bs.stats <- function(x, d) {
    return(c(mean(x[d]),sd(x[d])))
  }
  dev <- data[,a]-data[,b]
  ##Remove NAs
  dev <- dev[!is.na(dev)]
  dev.mean <- boot::boot(dev,statistic=bs.stats,1000)
  dev.mean <- as.data.frame(dev.mean$t)
  overall_uncert <- sqrt(dev.mean[,1]^2+dev.mean[,2]^2)
  out <- cbind(dev.mean,overall_uncert)
  colnames(out) <- c("Mean","SD","Uncert")
  return(out)
}

##############
##PROCESSING##
##############

##Read in quadrat data
quadrats <- rgdal::readOGR("Data",layer = "Angle_Quadrats_Poly_Crop")
quad_data <- read.csv("Data/Angle_Quadrat_Data.csv")

##Read in classified raster
in_rast <- raster::raster("Data/Angle_RGB_combo.tif")
##Seagrass class (pixel value)
sg_class <- 1

all_result <- NULL
for (i in 1:length(quadrats$Quad_ID))
{
  shp <- quadrats[quadrats$Quad_ID[i],]
  out <- raster::mask(raster::crop(in_rast,shp),shp)
  ##Get a count of pixels
  result <- as.data.frame(table(as.vector(out)))
  result <- cbind(result,rep(quadrats$Quad_ID[i],nrow(result)))
  ##Turn the counts into %s
  result$Freq<- round(result$Freq/sum(result$Freq),2)*100
  all_result <- rbind(all_result,result)
}

colnames(all_result) <- c("Class","Count","Quad_ID")
##Remove non seagrass classes
all_result <- all_result[all_result$Class==sg_class,]
##Remove missing quadrat data
all_result <- all_result[all_result$Quad_ID!="MISS",]
##Merge existing and new data
master <- full_join(all_result,quad_data)

##Write out collated data
write.table(master,"Data/Angle_2class.txt", row.names=F)

##Bootstrap statistics
boot_res <- bootcoverage(master,2,5)

##Write out bootstrapped statistics
write.table(boot_res, "Data/Angle_Boot_Res_2class.txt", row.names=F)