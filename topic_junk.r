library(jsonlite)
library(tm)
library(topicmodels)
library(ggplot2)
library(wordcloud)

#read JSON file to R
comments<-fromJSON("A50_Commons_DailyMail_comments.JSON")
firstnames<-read.csv(file = "CSV_Database_of_First_Names.csv")
lastnames<-read.csv(file = "CSV_Database_of_Last_Names.csv")
somestopwords<-as.data.frame(names(read.csv(file= "stop-word-list.csv")))

firstnames
lastnames
somestopwords

class(somestopwords)
my_stop_words<-c(firstnames, lastnames, somestopwords)



names

#rearrange columns very elegantly!
comments_ordered <-comments[,c("message",  "id", "created_time", "from","comment_count", "like_count", "parent_id",    
                               "type", "likes")]

comments_ordered$message
#get this into a corpus
messy_corpus<- Corpus(VectorSource(comments_ordered$message))
writeLines(strwrap(messy_corpus[[3]]$content, 60))

messy_corpus[[1]]$content
messy_corpus[[1]]$meta

#########functions for use throughout the code
#########
# couple of functions for Corpus editing
remove_URL<- function(x) gsub("http[^[:space:]]*", "", x)
remove_num_punct<- function(x) gsub("[^[:alpha:][:space:]]*", "", x)

#count frequency of a word in a corpus
word_freq <- function(corpus, word) {
  results <- lapply(corpus,
                    function(x){grep(as.character(x), pattern = paste0("\\<", word))
                    })
  sum(unlist(results))
}

#function to replace words in the corpus with an alternative if needed
replaceWord <- function(corpus, oldword, newword){
  tm_map(corpus, content_transformer(gsub),
         pattern = oldword, replacement = newword)
}

#we can complete the stemming
stemCompletion2 <- function(x, dictionary) {
  x <- unlist(strsplit(as.character(x), " "))
  x <- x[x != ""]
  x <- stemCompletion(x, dictionary = dictionary)
  x <- paste(x, sep="", collapse = " ")
  PlainTextDocument(stripWhitespace(x))
}

somestopwords<-VectorSource(read.csv(file= "stop-word-list.csv"))
ONS_stopwords <- c(setdiff(stopwords('english'), c("r", "big")), "use", "see", 
                   "used", "via", "amp", "thats","t") 

#lets clean up this corpus by
#removing urls, punctuation, numbers, stopwords,whitespaces
messy_corpus <- tm_map(messy_corpus, content_transformer(remove_URL)) 
messy_corpus <- tm_map(messy_corpus, content_transformer(remove_num_punct)) 
messy_corpus <- tm_map(messy_corpus, content_transformer(tolower)) 
messy_corpus <- tm_map(messy_corpus, removeWords, ONS_stopwords)
messy_corpus <- tm_map(messy_corpus, removeNumbers)
cleaned_corpus <- tm_map(messy_corpus, stripWhitespace)

#take a copy of the corpus here to complete the stemming
cleaned_corpus_copy <- cleaned_corpus

stemmed_corpus <- tm_map(cleaned_corpus, stemDocument)

#We can use the copy of the clean corpus we took earlier as a dictionary to complete the stems

stem_complete_corpus <- lapply(stemmed_corpus, stemCompletion2, dictionary = cleaned_corpus_copy)
stem_complete_corpus <- Corpus(VectorSource(stem_complete_corpus))

writeLines(strwrap(cleaned_corpus[[30]]$content, 60))
#writeLines(strwrap(stem_complete_corpus[[30]]$content, 60))


#create tdm for this data
tdm <- TermDocumentMatrix(cleaned_corpus,
                          control = list(wordLengths = c(1,Inf),
                                         removeNumbers = TRUE))
tdm
plot(tdm)

tdm$dimnames$Terms

# we can look up specific terms if we want
#idx <- which(dimnames(tdm)$Terms %in% c("article"))
#as.matrix(tdm[idx, 1:80])


#inspect frequent words and plot
freq.terms <- findFreqTerms(tdm, lowfreq = 0)
freq.terms

term.freq <- rowSums(as.matrix(tdm))
term.freq <- subset(term.freq, term.freq >=5 & term.freq<2750)

df <- data.frame(term = names(term.freq), freq = term.freq)

ggplot(df, aes(x = term, y = freq)) + geom_bar(stat =  "identity") + 
  xlab("Terms") + ylab("Count") + coord_flip() +
  theme(axis.text = element_text(size = 4))


#we can plot this chart as a word cloud
#as a wordcloud
m <- as.matrix(tdm)
word.freq <- sort(rowSums(m), decreasing = TRUE)
word.freq <- subset(word.freq, word.freq >=10 )
wordcloud(words = names(word.freq), freq = word.freq, min.freq = 2, 
          random.order = FALSE)

dtm

#which words are associated with "r"
findAssocs(tdm, c("remoaners"), 0.3)
