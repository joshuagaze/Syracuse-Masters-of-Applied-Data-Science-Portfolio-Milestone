# Author: Joshua A. Gaze
# Class: IST-719 Information Visualization
# Purpose: Netflix Project
# Term: Spring 2022

# import of packages
library(tidyverse)
library(ggplot2)
library(tidyverse)
library(wordcloud)
library(RColorBrewer)
library(tidytext)
library(rworldmap)
library(wordcloud)
library(wordcloud2)

# import of data and initial data cleaning
df_original <- read.csv("netflix_titles.csv")

df <- df_original %>% drop_na()

# creation of general_rating, in order to standardize the ratings systems that exist amongst movies and tv shows
df$general_rating[df$rating == "G" | df$rating == "TV-Y" | df$rating == "TV-Y7" | df$rating == "TV-Y7-FV" | df$rating == "TV-G"] <- "Child"
df$general_rating[df$rating == "PG" | df$rating == "TV-PG"] <- "Teenager"
df$general_rating[df$rating == "PG-13" | df$rating == "TV-14"] <- "Young Adult"
df$general_rating[df$rating == "R" | df$rating == "NR" | df$rating == "UR" | df$rating == "NC-17" | df$rating == "TV-MA" | df$rating == "66 min" | df$rating == "74 min" | df$rating == "84 min"] <- "Adult"

df$general_rating[df$show_id == "s5990"] <- "Teenager"
df$general_rating[df$show_id == "s6828"] <- "Young Adult"
df$general_rating[df$show_id == "s7313"] <- "Child"
df$general_rating[df$show_id == "s7538"] <- "Adult"

### creation of barplot showing the distributions of projects across the newly standardized ratings
tab_general_rating <- table(df$general_rating)
bp <- barplot(tab_general_rating, col = c('#221f1f', '#b20710', '#e50914','#C0C2C9')
              , ylim = c(0,5000)
              , ylab = "Number of Titles"
              , main = "Audience Netflix Markets Towards")
text(x = bp, 0, round(tab_general_rating, 1), cex=2, pos=3, col = c('#F0EAD6'))
###############################################################################################################################


### data cleaning on df$country, to prep before creating a world map distribution of the frequency of projects across countries
country_df <- df$country
cntry_vec <- unlist(strsplit(country_df, split = ", "))
length(cntry_vec)
cntry_df <- data.frame(cntry_vec)
colnames(cntry_df) <- "country"


cntry_df %>%
  group_by(country) %>%
  count() %>%
  arrange(desc(n)) %>%
  head(20) %>%
  ggplot() + geom_col(aes(y = reorder(country,n), x = n)) +
  geom_label(aes(y = reorder(country,n), x = n, label = n)) +
  labs(title = 'Approx. Number of Titles of each Country',
       subtitle = 'Top 20 Countries') 
# issue with cntry_df as I was more needed one column for country, and another column for frequency 

# attempt 2
gsub(',', '', country_df)

country_df <- df$country
cntry_vec <- unlist(strsplit(country_df, split = ", "))
country_vec <- gsub(',','',cntry_vec)
country_tab <- table(country_vec)
country_df_final <- data.frame(country_tab)
country_df_final <- country_df_final %>% 
  drop_na()
country_df <- country_df_final
colnames(country_df) <- c("country","freq")

# getting iso3 codes to associate country_name to the standardized format needed for creating the map density visual
iso3.codes <- tapply(country_df$country
                     , 1:length(country_df$country)
                     , rwmGetISO3)


df_2map <- data.frame(country = iso3.codes, labels = country_df$country
                      , freq = country_df$freq)

df.map <- joinCountryData2Map(df_2map, joinCode = "ISO3"
                              , nameJoinColumn = "country")

par(mar = c(0,0,1,0))

mapCountryData(df.map
               , nameColumnToPlot = "freq"
               , numCats = 5
               , catMethod = "categorical" 
               , colourPalette = c('#f8f9f9','gray47','#b20710')
               , borderCol = 'peachpuff4'
               , oceanCol = 'gray88'
               , missingCountryCol = 'white'
               , lwd = 1.5
               , addLegend = FALSE
)
#################################################################################################


### creation of time-series trending of number of titles by release_year in the Netflix catalogue
df %>% 
  group_by(type) %>% 
  ggplot() +
  geom_histogram(aes(x=release_year, fill = type), binwidth = 1) +
  scale_fill_manual(values=c('#b20710', '#221f1f')) +
  labs(x = 'Year Released', y = 'Frequency', title = 'Frequency of Media Type by Release Year', fill = 'Media Type') +
  scale_y_continuous(expand=c(0,0), breaks = seq(0,1200, by=100), limits=c(0,1200)) +
  scale_x_continuous(expand=c(0,0), breaks = round(seq(1940, 2022, by=5),1), limits = c(1940, 2022))

###########################################################################################################


# The following was run in Python
# the reason for this was due to the wordcloud2 package not properly outputting plots to be able to produce the wordcloud in a specified form, in this case to incorporate within the word "NETFLIX"

from os import path
from PIL import Image
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
from wordcloud import WordCloud, STOPWORDS

d = os.getcwd()
# Read the whole text.
text = open(path.join(d, 'words1.txt')).read()

# read the mask image
mask = np.array(Image.open(path.join(d, "Netflix-logo1.jpg")))
stopwords = set(STOPWORDS)

wc = WordCloud(background_color="white", max_words=500, mask=mask, colormap='RdGy'
               , collocations = False,
               stopwords=stopwords, contour_width=3, contour_color='#f5f5f1')

# show Netflix wordcloud
plt.imshow(wc, interpolation="bilinear")
plt.axis("off")
plt.figure(figsize=(35, 35))
plt.show()

# store to file
wc.to_file(path.join(d, "Netflix_Description_Wordcloud.png"))