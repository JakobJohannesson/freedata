#' @import tidyverse jsonlite lubridate httr rvest
fetch_insynshandel<-function(pages=0){
  library(rvest)
  library(tidyverse)
  library(lubridate)
  library(httr)
  library(jsonlite)
  
  url="https://marknadssok.fi.se/publiceringsklient"
  resp=read_html(url)
  table=resp %>% html_table() %>% .[[1]] %>% mutate(sida=1)
  
  n_page=resp %>% html_element(css = ".disabled+ li a") %>% html_text() %>% 
    str_remove(".") %>% as.numeric()
  M=c()
  x=1
  # --- Creating links to crawl ---
  while(x<n_page){
    url=paste0("https://marknadssok.fi.se/publiceringsklient?Page=",x)
    M=c(M,url)
    x=x+1
  }
  
  # Checking how many of the links to use --- 0 = all
  #pages=10
  if(pages==0){
    M=M
  } else {
    M=c(M[1:pages])
  }
  
  failed_url=c()
  readUrl <- function(url) {
    out <- tryCatch(
      {
        resp=read_html(url)
        table_new=resp %>% html_table() %>% .[[1]]
        table_new$Volym=table_new$Volym %>% as.character()
        page=str_extract_all(url,"\\d") %>% unlist() %>% 
          str_flatten() %>% as.numeric()
        table_new=table_new %>% mutate(sida = page)
        print(paste0("Hämtar insynshandel från FI: ",round(((page/length(M))*100),digits=2),"%"))
        #print(nrow(table))
        table_new
      },
      error=function(cond) {
        failed_url <<- c(failed_url,url)
        message(paste("URL does not seem to exist:", url))
        message("Here's the original error message:")
        message(cond)
        return(NA)
      }
    )    
    return(out)
  }
  
  
  df=map(M,readUrl)
  test=df %>% pluck(1) 
  for(i in 2:length(df)){
    test=test %>% bind_rows(df[[i]])
    print(paste0("Processerar datan: ",(i/length(df))*100,"%"))
  }
  df=test
  df$`Person i ledande ställning`=str_squish(df$`Person i ledande ställning`)
  df$`Person i ledande ställning`=str_to_title(df$`Person i ledande ställning`)
  df$Volym=str_replace_all(df$Volym,"\\s","") 
  df$Volym=df$Volym %>% as.numeric()
  df$Pris=str_replace_all(df$Pris,"\\s","") 
  df$Pris = str_replace_all(df$Pris,",",".")
  df$Pris=df$Pris %>% as.numeric()
  df$Publiceringsdatum=lubridate::as_date(df$Publiceringsdatum)
  df$Transaktionsdatum=lubridate::as_date(df$Transaktionsdatum)
  
  
  missing = df %>% filter(is.na(Status))
  df=df %>% filter(Status != "Makulerad", Status != "Reviderad") %>% 
    bind_rows(missing)
  output=list(df,failed_url)
  return(output)
}


#' @importFrom tidyverse jsonlite lubridate httr rvest
fetch_stockprice=function(id){
  
  library(rvest)
  library(tidyverse)
  library(lubridate)
  library(httr)
  library(jsonlite)
  url<-paste0("borsdata.se/api/terminal/instruments/",id,"/stockprices?format=chart")
  getdata=httr::GET(url)
  df=getdata %>% httr::content() %>% unlist() %>% enframe() %>% pivot_wider(names_from = name,values_from = value,values_fn = list)
  df=tibble(time=unlist(df$x),aktiekurs=unlist(df$y))
  df$time=as_datetime(df$time/1000)
  return(df)
}

#df=fetch_stockprice(750)

#' @importFrom tidyverse jsonlite lubridate httr rvest
fetch_company<-function(id){
  #id=520
  library(rvest)
  library(tidyverse)
  library(lubridate)
  library(httr)
  library(jsonlite)
  
  url=paste0("https://borsdata.se/api/terminal/instruments/",id,"/analysis/finances/report/1?periodType=0&years=10&growthCalcType=0")
  resp=httr::GET(url)
  content=httr::content(resp)
  # -- content
  data=content %>% unlist() %>% tibble::enframe()
  # Formaterar namnen - Använder endast namnen
  names=data %>% filter(str_detect(name,"kpisHistories.kpi"))
  names=names %>% pivot_wider(names_from = name,values_from = value,values_fill = NA, values_fn = list) %>% 
    select(-10) %>% unnest(cols = c(kpisHistories.kpi.hasSpecialStyle, kpisHistories.kpi.hasValuesColoring, 
                                    kpisHistories.kpi.description, kpisHistories.kpi.name, kpisHistories.kpi.isPercent, 
                                    kpisHistories.kpi.growthCalcType, kpisHistories.kpi.id, kpisHistories.kpi.priceType, 
                                    kpisHistories.kpi.hasQuarterCalc))
  
  # Formaterar de 10 åren av data
  df=data %>% filter(str_detect(name,"orderedHistoryValues")) %>% 
    tidyr::pivot_wider(names_from = "name",values_from = "value",values_fn = list) %>% 
    unnest(cols = c(kpisHistories.orderedHistoryValues.formattedValue, kpisHistories.orderedHistoryValues.value, 
                    kpisHistories.orderedHistoryValues.period.year, kpisHistories.orderedHistoryValues.period.quarter, 
                    kpisHistories.orderedHistoryValues.period.date, kpisHistories.orderedHistoryValues.period.label))
  n_row=nrow(df)/10
  df=df %>% mutate(beskrivning=rep(names$kpisHistories.kpi.name,each=n_row))
  
  df=df %>% pivot_wider(id_cols = c(kpisHistories.orderedHistoryValues.period.year),names_from = beskrivning,values_from=kpisHistories.orderedHistoryValues.value)
  df=df %>% mutate_if(is.character,as.numeric)
  return(df)
}

#' @importFrom tidyverse jsonlite lubridate httr rvest
fetch_ratios<-function(id){
  
  library(rvest)
  library(tidyverse)
  library(lubridate)
  library(httr)
  library(jsonlite)
  url="borsdata.se/api/terminal/instruments/520/ratios?groupType=1&period=0&years=10"
  getdata=httr::GET(url)
  data=getdata %>% httr::content() %>% unlist() %>% tibble::enframe()
  ratios=data %>% filter(!str_detect(data$name,"CompoundId")) %>% 
    pivot_wider(names_from = name,values_from = value) %>% unnest()
  
  ratios=ratios %>% map_if(str_detect(colnames(ratios),"kpiHistory"), as.numeric)
  ratios2=ratios %>% map(.f = pluck(1)) %>% enframe() #%>% map(.f = pluck(2)) %>% enframe()
  
  for(i in 2:8){
    temp=ratios %>% map(.f = pluck(i)) %>% enframe()
    ratios2=ratios2 %>% left_join(temp,by="name")
  }
  colnames(ratios2)=unlist(ratios2[1,])
  ratios2=ratios2 %>% slice(-1)
  year_now=lubridate::today() %>% lubridate::year()
  kpi=ratios2 %>% slice(5:14) %>% select(-1) %>% mutate_all(.funs = as.numeric) %>% mutate(year=c((year_now-9):year_now))
  ratios=list(ratios2,kpi)
  return(ratios)
}



#' @importFrom tidyverse jsonlite lubridate httr rvest
alla_bolag=function(number_of_companies=16596){
  
  library(rvest)
  library(tidyverse)
  library(lubridate)
  library(httr)
  library(jsonlite)
  url="https://borsdata.se/api/terminal/screener/kpis/data"
  payload=list("page"=0,"rowsInPage"=number_of_companies,"nameFilter"="","kpiFilter"=NA,"watchlistId"=NA,"companyNameOrdering"=0)
  resp=httr::POST(url,body = payload, encode = "json")
  data=content(resp)
  df=data %>% unlist() %>% enframe()
  
  df=df %>% filter(!str_detect(df$name,"kpisValues"))
  df=df %>% filter(!str_detect(df$name,"branchId"))
  df=df %>% filter(!str_detect(df$name,"sectorId"))
  df=df %>% filter(!str_detect(df$name,"companyInsref"))
  df=df %>% filter(str_detect(df$name,"data"))
  
  kek=df %>% pivot_wider(names_from = name,values_from = value, values_fill = NA) %>% 
    unnest()
  return(alla_bolag)
}

#' @importFrom tidyverse jsonlite lubridate httr rvest anomalize
fetch_anomaly=function(id){
  library(rvest)
  library(tidyverse)
  library(lubridate)
  library(httr)
  library(jsonlite)
  library(anomalize)
  df=fetch_stockprice(id)
  p=df %>% 
    tibble() %>% 
    time_decompose(as.integer(aktiekurs), method = "stl", trend = "3 month") %>% # method = STL
    anomalize(remainder, method = "gesd",alpha = 0.05,max_anoms = 0.01) %>%  # method = "IQR"
    time_recompose() %>% 
    plot_anomalies(time_recomposed = TRUE) + 
    labs(title = "Anomaly detection",
         x = "Time", y= "Stock price", )+
    theme(plot.title = element_text(size = 20,hjust =0.5,vjust = 0.5))
  return(p)
}



