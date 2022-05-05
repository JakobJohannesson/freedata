## ---- message=FALSE, eval=FALSE-----------------------------------------------
#  devtools::install_github('jakobjohannesson/borsdata', build_vignettes = TRUE)

## ---- message=FALSE, eval=FALSE-----------------------------------------------
#  help(package = "borsdata")

## ---- message=FALSE-----------------------------------------------------------
library(borsdata)

## ---- message=TRUE------------------------------------------------------------
key<- "API" # Ange din API nyckel

## ----eval=FALSE---------------------------------------------------------------
#  
#  # Instruments innehåller alla aktier
#  instruments <- fetch_instruments(key = key)
#  str(instruments)

## ----eval=FALSE---------------------------------------------------------------
#  # Ange ditt id i funktionen, exempelvis 221 för Systemair
#  systemair<-fetch_year(id=221,key=key)
#  str(systemair)
#  

## ----eval=FALSE---------------------------------------------------------------
#  # Rullande 12 månader
#  r12<-fetch_r12(id=221,key=key)
#  str(systemair)
#  
#  # Kvartalsdata
#  kvartal<-fetch_quarter(id=221,key=key)
#  str(systemair)
#  

## ----eval=FALSE---------------------------------------------------------------
#  systemair_kurs <- fetch_stockprice(id = 221, key = key)
#  Sys.sleep(3)
#  jm_kurs <- fetch_stockprice(id = 116, key = key)
#  Sys.sleep(3)
#  balder_kurs <- fetch_stockprice(id = 83, key = key)
#  Sys.sleep(3)
#  # Slår samman aktiekurserna till en och samma data.frame
#  frame <-data.frame(JM=jm_kurs$c, Systemair=systemair_kurs$c, Balder=balder_kurs$c)

## ----eval=FALSE---------------------------------------------------------------
#  library(GGally)
#  
#  
#  ggpairs(frame)
#  
#  ggcorr(frame,
#        method = c("pairwise", "pearson"),
#        label = TRUE,
#        digits = 2)
#  
#  
#  # tar fram yttligare en korrelationsmatris
#  ggpairs(
#    data = frame,
#    mapping = 1:3,
#    axisLabels = "internal",
#    upper = list(continuous = "cor"),
#    title = "Korrelationsmatris mellan bolag"
#  ) +
#    theme_bw() +
#    theme(plot.title = element_text(hjust = 0.5))
#  

## ----eval=FALSE---------------------------------------------------------------
#  # Kalla på branches
#  branches<-fetch_branches(key=key)
#  str(branches)
#  
#  # Kalla på countries
#  countries<-fetch_countries(key=key)
#  str(countries)
#  
#  
#  # Kalla på markets
#  markets<-fetch_markets(key=key)
#  str(markets)
#  
#  # Kalla på updated_instruments
#  updated_instruments<-fetch_updated_instruments(key=key)
#  str(updated_instruments)
#  
#  # Kalla på sectors
#  sectors<-fetch_sectors(key=key)
#  str(sectors)
#  

