#######################################################
# Get 4 lane data pasted from BaseSpace in 4 text files
#######################################################

library("readr")
library("openxlsx")

args <- commandArgs(trailingOnly=TRUE)
#folder <- args[1]
zipfile <- args[1]

# folder <- "~/git_repos/Nucleomics-VIB/genepattern-tools/modules/RePool"

unzip(zipfile, files = NULL, list = FALSE, overwrite = TRUE,
      junkpaths = FALSE, exdir = ".", unzip = "internal",
      setTimes = FALSE)

filelist <- list.files(path = "data", pattern = ".*.txt")

if (!length(filelist)==4){
  sink("stderr.txt")
  cat("ERROR: The archive did not contain 4 laneX.txt files\n")
  quit(save="no",status=1,runLast=FALSE)
}

# get list of text files in folder
datalist = lapply(paste("data", filelist, sep="/"), function(x) read_delim(x, "\t", escape_double = FALSE,
                                                   col_names = FALSE, trim_ws = TRUE,
                                                   col_types = cols()))

# take sample names from first file
info <- as.data.frame(datalist[1])
samples <- info[4:nrow(info),2]
merged <- data.frame(samples=samples)
idx <- 0

# aggreagate all text files
for (l in datalist){
lane <- as.data.frame(l)
idx <- idx+1
dat <- paste0("lane",idx)
pftot <- as.numeric(gsub(",", "",lane[2,2]))
merged[dat] <- as.numeric(lane[4:nrow(lane),6])/100*pftot
}

# add total and percent based on the new read total
merged$counts <- rowSums(merged[,c(2:ncol(merged))]) 
merged$percent <- merged$counts/sum(merged$counts)*100

# temporarily create an Excel file for review
ExcelWorkbook <- createWorkbook()
addWorksheet(ExcelWorkbook,"Lane_Counts",gridLines=FALSE)
writeDataTable(ExcelWorkbook,"Lane_Counts",merged,colNames=TRUE)
setColWidths(ExcelWorkbook,"Lane_Counts",cols=1:ncol(merged),widths="auto")
OutFile <- paste("Repooling-LaneCounts-",format(Sys.time(),format="%Y-%m-%d"),".xlsx",sep="")
saveWorkbook(ExcelWorkbook,OutFile,overwrite=TRUE)
