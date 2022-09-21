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

library(ggplot2); # visualisation
library(GGally);
#library(rio);# simple command for importing and exporting
library(pander); # format tables
library(printr); # set limit on number of lines printed
library(broom); # allows to give clean dataset
library(dplyr); #add dplyr library

options(max.print=42);
panderOptions('table.split.table',Inf); panderOptions('table.split.cells',Inf);

# load data ----

if(!file.exists("working_script.rdata")){
  system("R -f data.R")
}

load("working_script.rdata")

View(patients)

##plotting using ggplot
ggplot(data = patients, aes(x = anchor_age, fill = gender))+
  geom_histogram() +
  geom_vline(xintercept = 65)

table(patients$gender)
#check for duplicates in the subject_id

#aggregating data: data structures

Demographics <- group_by(admissions, subject_id)%>%
  mutate(los = difftime(dischtime, admittime))%>%
  summarise(admits = n(),
            ethnic = length(unique(ethnicity)),
            ethnicity_combo = paste(sort(unique(ethnicity)), collapse = ":"),
            # language0 <- length(unique(language)),
            # language_combo <- paste(sort(unique(language)), collapse = ":")
            language = tail(language, 1),
            dod = max(deathtime, na.rm = TRUE),
            los = median(los),
            numED = length(na.omit(edregtime)))


 #subset(ethnic > 1)

table(admissions$ethnicity)



ggplot(data = Demographics, aes(x = admits)) +
  geom_histogram()

intersect(names(Demographics), names(patients))

Demographics$subject_id

intersect(Demographics$subject_id, patients$subject_id)

setdiff(Demographics$subject_id, patients$subject_id)

setdiff(Demographics$dod, patients$dod)

Demographics1 <- left_join(Demographics, select(patients, -dod), by = c("subject_id"))



