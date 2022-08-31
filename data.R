#'---
#' title: "TSCI 5230: Introduction to Data Science"
#' author: 'Jeff Wang'
#' abstract: |
#'  | Provide a summary of objectives, study design, setting, participants,
#'  | sample size, predictors, outcome, statistical analysis, results,
#'  | and conclusions.
#' documentclass: article
#' description: 'Manuscript'
#' clean: false
#' self_contained: true
#' number_sections: false
#' keep_md: true
#' fig_caption: true
#' output:
#'  html_document:
#'    toc: true
#'    toc_float: true
#'    code_folding: show
#' ---
#'
#+ init, echo=FALSE, message=FALSE, warning=FALSE
# init ----
# This part does not show up in your rendered report, only in the script,
# because we are using regular comments instead of #' comments
debug <- 0;
knitr::opts_chunk$set(echo=debug>-1, warning=debug>0, message=debug>0);


# install.packages('R.utils')

library(R.utils)
library(ggplot2); # visualisation
library(GGally);
library(rio);# simple command for importing and exporting
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr); #add dplyr library
library(fs)

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf);
whatisthis <- function(xx){
  list(class=class(xx),info=c(mode=mode(xx),storage.mode=storage.mode(xx)
                              ,typeof=typeof(xx)))};
#Import Data

Input_data <- "https://physionet.org/static/published-projects/mimic-iv-demo/mimic-iv-clinical-database-demo-1.0.zip"
dir.create('data', showWarnings = F)
zipped_data <- file.path('data', 'tempdata.zip')

if(!file.exists(zipped_data)){
  download.file(Input_data, destfile = zipped_data)}


Unzipped_data <- unzip(zipped_data, exdir = "data")%>%
  grep('gz', ., value = TRUE)

Table_Names <- unzip(zipped_data, exdir = "data")%>%
  grep('gz', ., value = TRUE)%>%
  basename()%>%
  fs::path_ext_remove()%>%
  fs::path_ext_remove()

#assign(Table_Names[3], import(Unzipped_data[3], fread = FALSE))

# for(ii in seq_along(Table_Names)){
#   assign(Table_Names[ii], import(Unzipped_data[ii], format = 'csv'), inherits = TRUE)}

Junk <- mapply(function(xx,yy){
  #browser()
  assign(xx, import(yy, format = 'csv'), inherits = TRUE)}, Table_Names, Unzipped_data)


#Saving the data

save(list = Table_Names, file = "working_script.rdata")




# Transfers <- import(Unzipped_data[3], fread = FALSE)
#
# assign("Transfers0", import(Unzipped_data[3], fread = FALSE))

#the period is a placeholder for the left most variable of the pipe operation


#grep("gz", Unzipped_data, value = TRUE)
#value = TRUE returns the actual file names





