# Coinbase filtering
source("Functions.R")
check.packages(c("curl","jsonlite","magrittr","mailR"))

library(curl)
library(jsonlite)
library(magrittr)
library(mailR)

# Downloading the list for the top 100 coins from the Coinmarketcap API, then formatting
raw_result <- fromJSON('https://api.coinmarketcap.com/v2/ticker/')

my_data <- do.call("rbind", raw_result$data) %>% as.data.frame()            # Dataframe
list_currencies_coinmarketcap <- as.character(my_data$symbol)                             # Selecting symbols
list_urls_currencies <- paste0('https://api.coinbase.com/v2/exchange-rates?currency=',list_currencies_coinmarketcap)
list_urls_buy <- paste0("https://api.coinbase.com/v2/prices/",list_currencies_coinmarketcap,"-USD/buy")
list_urls_spot <- paste0("https://api.coinbase.com/v2/prices/",list_currencies_coinmarketcap,"-USD/spot")

# Downloading the pairs from Coinbasepro API
raw_result <- fromJSON("https://api.pro.coinbase.com/products")
coinbasepro_currencies <- raw_result$base_currency %>% unique

# Checking responses
cb <- function(req){
     content <- rawToChar(req$content)           # Grabbing the content
     if (grepl("error", content) == FALSE) {     # If there is no error and the coin is listed, print it
          cat(req$url, "\n")
     }
}

check_call_api <- function(list_urls) {
     pool <- new_pool()
     data <- list()
     
     # All scheduled requests are performed concurrently
     sapply(list_urls, curl_fetch_multi, done = cb, pool = pool) 
     
     # This actually performs requests
     out <- multi_run(pool = pool)
     
     #cb <- function(req){cat("done:", req$url, ": HTTP:", req$status, "\n", "content:", rawToChar(req$content), "\n")}
}

# Examining the results
print(list_currencies_coinmarketcap)
print(coinbasepro_currencies)
check_call_api(list_urls_currencies)
check_call_api(list_urls_buy)


# Sending notification ----------------------------------------------------
list_coins_alerted <- paste(coinbasepro_currencies, collapse = ",")

sender <- "dummy.corporate.mail@gmail.com"
pass <- "222Dummygmail222###$$$"
recipients <- c("frank1392@gmail.com")
send.mail(from = sender,
          to = recipients,
          subject = "Alert notification for Coinbase listing",
          body = paste("Hi Frank. The following coins have had positive response from the API. Please check:",
                       list_coins),
          smtp = list(host.name = "smtp.gmail.com", port = 465, 
                      user.name = sender,            
                      passwd = pass, ssl = TRUE),
          authenticate = TRUE,
          send = TRUE)






