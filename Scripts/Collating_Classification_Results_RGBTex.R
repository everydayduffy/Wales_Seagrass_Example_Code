##Converting raw pixel countrs from classification into meaningful values
##and comparing with ground based data

library(dplyr) # has to be loaded to allow %>% to work properly

##Functions

##Root mean squared error of difference (between observed and classified)
RMSD_calc <- function(a,b)
{
  c <- sqrt(mean((a-b)^2,na.rm=TRUE))
  return(c)
}

##Read in ground data

in_ground_data <- "Angle_Quadrat_Data.csv"
ground_data <- read.csv(paste0("Data/",in_ground_data))
ground_data <- dplyr::select(ground_data, Quad_ID, X..Cover) %>%
  data.frame()

##List result files from classifications
files <- tools::file_path_sans_ext(list.files("Data/Classified_RGBTex", pattern = ".*.txt"))

results <- NULL

for(h in 1:length(files))
{
  data <- read.table(paste0("Data/Classified_RGBTex/",files[h],".txt"),h=T)
  nclass <- unique(data$Class)
  ##All possible combinations of layers 
  ## -1 used on nclass as combination of all layers e.g. 1+2+3+4+5 is not possible
  combos <-  lapply(1:max(nclass-1), 
                    function(x) do.call(rbind, combn(max(nclass), x,
                                                     simplify=FALSE)))
  for(i in 1:length(combos))
  {
    sub_combos <- combos[[i]]
    for (j in 1:nrow(sub_combos))
    {
      sub_combos2 <- sub_combos[j,]
      
      ##Calculate proportion of 'seagrass' class of all pixels in quadrat
      ##Simplify output
      ##Combine classes to 'new' and count, then create proportion
      out <- dplyr::mutate(data, Class = ifelse(Class %in% sub_combos2, 'new', Class)) %>%
        dplyr::group_by(., Quad_ID, Class) %>%
        dplyr::summarise(., Count = sum(Count)) %>%
        dplyr::ungroup(.) %>%
        dplyr::group_by(., Quad_ID) %>%
        dplyr::mutate(., Prop = round((Count/sum(Count)),2)*100) %>%
        dplyr::filter(., Class == 'new') %>%
        dplyr::select(., Quad_ID, Prop) %>%
        dplyr::full_join(.,ground_data) %>%
        data.frame()
      
      ##Calculate RMSD
      results <- rbind(results,c(paste0(files[h],"_com_",i,"_",j),RMSD_calc(out$X..Cover,out$Prop)))
      ##Write out formatted results
      write.table(out,paste0("Data/Classified_RGBTex_Combn/",files[h],"_com_",i,"_",j,".txt"),row.names=F)
    }
  }
}

##Reformat results to find lowest RMSD
results <- as.data.frame(results)
colnames(results) <- c("ID","RMSD")
results$RMSD <- as.numeric(as.character(results$RMSD))
results <- arrange(results,RMSD)

##Show the lowest RMSD scores
head(results)