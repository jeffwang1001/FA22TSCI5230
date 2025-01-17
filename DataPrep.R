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
library(tidyr);
library(purrr);
library(table1);
library(reticulate);

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


#patient = subset(patients, select = -c(dod))
#paste0(letters,LETTERS, collapse = '---')

############################Vanc/Zosyn study data
# build list of keywords
kw_abx <- c("vanco", "zosyn", "piperacillin", "tazobactam", "cefepime", "meropenam", "ertapenem", "carbapenem", "levofloxacin")
kw_lab <- c("creatinine")
kw_aki <- c("acute renal failure", "acute kidney injury", "acute kidney failure", "acute kidney", "acute renal insufficiency")
kw_aki_pp <- c("postpartum", "labor and delivery")


# search for those keywords in the tables to find the full label names
# remove post partum from aki in last line here
# may need to remove some of the lab labels as well (pending)
# vertical pipe takes the arguement and uses it as an "or" command for the the list of keywords that is being searched
label_abx <- grep(paste0(kw_abx, collapse = '|'), d_items$label, ignore.case = T, value = T, invert = F)
label_lab <- grep(paste0(kw_lab, collapse = '|'), d_labitems$label, ignore.case = T, value = T, invert = F)
label_aki <- grep(paste0(kw_aki, collapse = '|'), d_icd_diagnoses$long_title, ignore.case = T, value = T, invert = F)
label_aki <- grep(paste0(kw_aki_pp, collapse = '|'), label_aki, ignore.case = T, value = T, invert = T)


# use dplyr filter to make tables with the item_id for the keywords above
item_ids_abx <- d_items %>% filter(label %in% label_abx)
item_ids_lab <- d_labitems %>% filter(label %in% label_lab)
item_ids_aki <- d_icd_diagnoses %>% filter(long_title %in% label_aki)

subset(item_ids_abx, category == 'Antibiotics') #Only selects rows with category of Antibiotics
subset(item_ids_abx, category == 'Antibiotics') %>%
  left_join(inputevents, by = 'itemid') #By using subset first in left_join, starting off
#by only selecting rows with antibiotics, and then pulling inputevents data for those
#patients that received the antibiotics with our specified IDs

Antibiotics <- subset(item_ids_abx, category == 'Antibiotics') %>%
  left_join(inputevents, by = 'itemid')

grep('N17', diagnoses_icd$icd_code, value = T) #ICD codes found within the dataset
grep('^548|^N17', diagnoses_icd$icd_code, value=T) #Either 548... or N17... values
#within the diagnosis_icd$icd_code data set
grepl('^548|^N17', diagnoses_icd$icd_code) #True/False for each row whether it contains value
subset(diagnoses_icd,grepl('^548|^N17',icd_code)) #Pulls only the rows that have ICD code of interest
Akidiagnoses_icd <- subset(diagnoses_icd,grepl('^548|^N17',icd_code))

Cr_labevents <- subset(item_ids_lab, fluid == "Blood") %>%
  left_join(labevents, by = 'itemid') #Filter only blood Cr and match to lab events

grepl(paste(kw_abx, collapse='|'),emar$medication)
subset(emar,grepl(paste(kw_abx, collapse='|'),medication,ignore.case = T))$event_txt%>%
  table()%>%sort() #Filter emar by antibiotic administration with individual event txt

#merge lab events and antibiotic administration

#comparing Vancomycin to Zosyn


Antibiotic_Groupings <- group_by(Antibiotics, hadm_id)%>%
  summarise(Vanc = 'Vancomycin' %in% label, Zosyn = any(grepl('Piperacillin', label)),
            N = n(),
            Other = length(grep('Piperacillin|Vancomycin',
                                label, val = TRUE, invert = TRUE))>0,
            Exposure1 = case_when(!Vanc ~ 'Other',
                                  Vanc&Zosyn ~ 'Vanc & Zosyn',
                                  Other ~ 'Vanc & Other',
                                  !Other ~ 'Vanc',
                                  TRUE ~ 'UNDEFINED'),
            Exposure2 = case_when(Vanc & !Zosyn & !Other ~ 'Vanc',
                                  Vanc & Zosyn & !Other ~ 'Vanc & Zosyn',
                                  Vanc & Zosyn & Other ~ 'Vanc & Zosyn',
                                  !Vanc & !Zosyn ~ 'Other'))
#Vanc & !Zosyn & !Other ~ 'Vanc' example: make another column for exposure 2


Admission_Scaffold <- admissions %>% select(hadm_id, admittime, dischtime) %>%
  transmute(hadm_id = hadm_id,
            ip_date = map2(as.Date(admittime), as.Date(dischtime), seq, by = "1 day"))%>%
  unnest(ip_date)



Antibiotics_dates <- Antibiotics %>%
  transmute(hadm_id = hadm_id,
            group = case_when('Vancomycin' == label ~ "Vanc",
                              grepl('Piperacillin', label) ~ "Zosyn",
                              TRUE ~ "Other"),
            starttime = starttime,
            endtime = endtime)%>%
  unique()%>%
  subset(!is.na(starttime) & !is.na(endtime))%>%
  transmute(hadm_id = hadm_id,
            ip_date = {oo <- try(map2(as.Date(starttime), as.Date(endtime), seq, by = "1 day"));
            if(is(oo, 'try-error')){browser()}
            oo},
            group = group)%>%
  unnest(ip_date)%>%
  unique()

Antibiotics_dates <- split(Antibiotics_dates, Antibiotics_dates$group)

# summary(Antibiotics_dates)
# subset(Antibiotics_dates, group == 'Vanc')%>%
#   left_join(Admission_Scaffold, .)%>%
#   mutate(Vanc = !is.na(group))%>%
#   select(-group)%>%
#   View()


Antibiotics_dates <- sapply(names(Antibiotics_dates), function(xx){names(Antibiotics_dates[[xx]])[3] <- xx
  #browser()
  Antibiotics_dates[[xx]]
  },simplify = FALSE)%>%
  Reduce(left_join, ., Admission_Scaffold)

#mutate(Antibiotics_dates,treatment = if_else(is.na(Other),'',Other))%>%
#  View()

mutate(Antibiotics_dates, across(all_of(c('Other', 'Vanc', 'Zosyn')),~coalesce(.x,'')),
       Exposure = paste(Vanc, Zosyn, Other))%>%
  select(hadm_id, Exposure)%>%
  unique()%>%
  pull(Exposure)%>%
  table()

#class October 5th 2022

Cr_labevents2 <- Antibiotics_dates %>%
  group_by(hadm_id)%>%
  #mutate(Vanc_Zosyn_Date = min(ip_date[!is.na(Vanc) & !is.na(Zosyn)]))%>%
  summarise(Vanc_Zosyn_Date = min(ip_date[!is.na(Vanc) & !is.na(Zosyn)]))%>%
  subset(!is.infinite(Vanc_Zosyn_Date)) %>%
  left_join(Cr_labevents,.)%>%
  group_by(hadm_id)%>%
  subset(!is.na(hadm_id)) %>%
  arrange(hadm_id,charttime)%>%
  mutate(Vanc_Zosyn = !all(is.na(Vanc_Zosyn_Date)))


#combining demographics and creatinine tables
Analysis_Data <- left_join(Cr_labevents2,Demographics1)

ggplot(Analysis_Data, aes(x = Vanc_Zosyn, y = valuenum)) +
  geom_violin()

paireed_analysis <- c('valuenum', 'admits', 'flag', 'Vanc_Zosyn')

Analysis_Data[,paireed_analysis]%>%
  ggpairs(aes(col = Vanc_Zosyn))
#table(Antibiotics_dates$group)%>%
#  View()

table1(~valuenum+admits+flag+anchor_age+gender|Vanc_Zosyn, data = Analysis_Data)


my.render.cont <- function(x) {
  with(stats.default(x),
       sprintf("%0.2f (%0.1f)", MEAN, SD))
}

# subset(Antibiotics, is.na(starttime) & is.na(endtime))
# | is or




group_by(Antibiotic_Groupings, Vanc, Zosyn, Other) %>%
  summarise(N =n())

#debug = {browser();TRUE})



grepl("Zosyn", Antibiotics$label)

export