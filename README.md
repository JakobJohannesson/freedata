# Hämta data från bland annat Finansinspektionen

Tanka ner data från insynshandeln på FI

## Installera från GitHub:

För att installera behöver du R och Rstudio. Installera devtools om du
inte redan har det. kör sedan install\_github kommandot nedan.

    # install.packages("devtools")
    devtools::install_github('jakobjohannesson/freedata')

### Testar paketet

    library(freedata)
    df=fetch_insynshandel(10) # Hämtar senaste 10 sidorna från finansinspektionen

    # ---- Ftg data ----
    company=fetch_company(520) # Hämtar ett bolag
    stockprice=freedata::fetch_stockprice(520) # Hämtar ett bolag
    ratios=freedata::fetch_ratios(520)
