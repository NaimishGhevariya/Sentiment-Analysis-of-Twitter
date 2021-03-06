library(ROAuth)
library(twitteR)

consumer_key <-"xxx"
consumer_secret <- "xxx"
access_token<-"xxx"
access_secret <- "xxx"

setup_twitter_oauth(consumer_key ,consumer_secret, access_token,  access_secret )
 
cred <- OAuthFactory$new(consumerKey="xxx", consumerSecret="xxx",requestURL="https://api.twitter.com/oauth/request_token",accessURL="https://api.twitter.com/oauth/access_token",authURL="https://api.twitter.com/oauth/authorize")

cred$handshake(cainfo="cacert.pem")
searchString<-readline(prompt="Enter tweet search String : ")

obj.tweets = searchTwitter(searchString,lang='en', n=100, resultType='recent')


#Reading the words from file
positivewords=readLines("positive_words.txt")
negativewords=readLines("negative_words.txt")

pos.words <-c(positivewords)
neg.words <-c(negativewords)

#Extracting textual part of the tweets

sample=NULL  #Initialising  #We can get the text from df$text, which are the cleand tweets
for (tweet in obj.tweets)
sample = c(sample,tweet$getText())

#Removing emoticons

s <- searchTwitter("#emoticons")
df <- do.call("rbind", lapply(obj.tweets, as.data.frame))
df$text <- sapply(df$text,function(row) iconv(row, "latin1", "ASCII", sub=""))##

#score.sentiment function
score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  require(plyr)
  require(stringr)
  list=lapply(sentences, function(sentence, pos.words, neg.words)
  {
    sentence = gsub('[[:punct:]]',' ',sentence)
    sentence = gsub('[[:cntrl:]]','',sentence)
    sentence = gsub('\\d+','',sentence)
    sentence = gsub('\n','',sentence)
    
    sentence = tolower(sentence)
    word.list = str_split(sentence, '\\s+')
    words = unlist(word.list)
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    pp=sum(pos.matches)
    nn = sum(neg.matches)
    score = sum(pos.matches) - sum(neg.matches)
    list1=c(score, pp, nn)
    return (list1)
  }, pos.words, neg.words)
  score_new=lapply(list, `[[`, 1)
  pp1=score=lapply(list, `[[`, 2)##
  nn1=score=lapply(list, `[[`, 3)
  
  scores.df = data.frame(score=score_new, text=sentences)##
  positive.df = data.frame(Positive=pp1, text=sentences)
  negative.df = data.frame(Negative=nn1, text=sentences)
  
  list_df=list(scores.df, positive.df, negative.df)
  return(list_df)
}

# Clean the tweets
result = score.sentiment(df$text, pos.words, neg.words)

library(reshape)
#Creating a copy of result data frame
test1=result[[1]]
test2=result[[2]]
test3=result[[3]]

#Creating three different data frames for Score, Positive and Negative
#Removing text column from data frame
test1$text=NULL
test2$text=NULL
test3$text=NULL
#Storing the first row(Containing the sentiment scores) in variable q
osc=test1[1,]
psc=test2[1,]
nsc=test3[1,]
oosc=melt(osc, var="Score")
ppsc=melt(psc, var="Positive")
nnsc=melt(nsc, var="Negative") 
oosc["Score"] = NULL
ppsc["Positive"] = NULL
nnsc["Negative"] = NULL

#Creating data frame
table1 = data.frame(Text=result[[1]]$text, Score=oosc)
table2 = data.frame(Text=result[[2]]$text, Score=ppsc)
table3 = data.frame(Text=result[[3]]$text, Score=nnsc)

#Merging three data frames into one
 final_table=data.frame(Text=table1$Text, Score=table1$value, Positive=table2$value, Negative=table3$value)

#Making percentage columns

p=final_table$Positive/(final_table$Positive+final_table$Negative)
p[ is.nan(p) ] <- 0
final_table$Postive_percentage=p
n=final_table$Negative/(final_table$Positive+final_table$Negative)
n[ is.nan(n) ] <- 0
final_table$Neg_percent=n


#Creating Histogram

hist(final_table$Score, xlab = "Score" , main = paste("Histogram of Overall Score of Sentiment of tweets"), col =rainbow(7))
hist(final_table$Positive, xlab = "Positive Score" , main = paste("Histogram of Positive Score of Sentiment of tweets"), col =rainbow(7))
hist(final_table$Negative, xlab = "Negative Score" , main = paste("Histogram of Negative Score of Sentiment of tweets"), col =rainbow(7))

#Creating Pie Chart

library(plotrix)

slices <- c(sum(final_table$Positive), sum(final_table$Negative))
lbls<-c('Positive','Negative')
pct <- round(slices/sum(slices)*100)
lbls <- paste(lbls, pct) # add percents to labels 
lbls <- paste(lbls,"%",sep="") # ad % to labels 
pie(slices, labels = lbls, col=rainbow(length(lbls)), main='Pie chart of Sentiment Analysis of tweets')
pie3D(slices, labels = lbls, explode=0.0, col=rainbow(length(lbls)), main='3D- Pie chart of Sentiment Analysis tweets')

#Creating Pie chart with percentages for degree of emotions

Sc= final_table$Score
good<- sapply(final_table$Score, function(Sc) Sc > 0 && Sc <= 3)
pos1=final_table$Score[good]
pos1_len=length(pos1)

vgood<- sapply(final_table$Score, function(Sc) Sc > 3 && Sc < 5)
pos2=final_table$Score[vgood]
pos2_len=length(pos2)

vvgood<- sapply(final_table$Score, function(Sc) Sc >= 6)
pos3=final_table$Score[vvgood]
pos3_len=length(pos3)

Sc= final_table$Score
bad<- sapply(final_table$Score, function(Sc) Sc < 0 && Sc >= -3)
neg1=final_table$Score[bad]
neg1_len=length(neg1)

vbad<- sapply(final_table$Score, function(Sc) Sc < -3 && Sc >= -5)
neg2=final_table$Score[vbad]
neg2_len=length(neg2)

vvbad<- sapply(final_table$Score, function(Sc) Sc <= -6)
neg3=final_table$Score[vvbad]
neg3_len=length(neg3)

neutral= sapply(final_table$Score, function(Sc) Sc == 0)
neu=final_table$Score[neutral]
neu_len=length(neu)

slices1 <- c(pos1_len,neg3_len, neg1_len, pos2_len,  neg2_len, neu_len, pos3_len)
lbls1 <- c( 'Good','Awful','Unsatisfactory', 'Great', 'Poor', 'Neutral', 'Outstanding')##
pct=round(slices1/sum(slices1)*100)
lbls1 <- paste(lbls1, pct) # add percents to labels 
lbls1 <- paste(lbls1,'%',sep='') # ad % to labels 
pie(slices1,labels = lbls1, col=rainbow(length(lbls1)),
  	main='Percentage of tweets with particular sentiment')

library(wordcloud)

library(tm)

obj1.tweets=searchTwitter(searchString, lang='en', n=100, resultType='recent')
df <- do.call('rbind', lapply(obj1.tweets, as.data.frame))
obj1_text <- sapply(df$text,function(row) iconv(row, 'latin1', 'ASCII', sub = ''))

jk = data.frame(df$text,df$created,df$screenName,df$favoriteCount,df$retweetCount ,df$location)
jk$df.text = sapply(df$text,function(row) iconv(row, "latin1", "ASCII", sub=""))##
colnames(jk) = c("Tweets", "Date", "Username", "Fav Count", "RT Count", "Location")
#str(obj1_text) -> gives character vector
obj1_corpus = Corpus(VectorSource(obj1_text))

#clean text

obj1_clean = tm_map(obj1_corpus, removePunctuation)
obj1_clean = tm_map(obj1_clean, content_transformer(tolower))
obj1_clean = tm_map(obj1_clean, removeWords, stopwords('english'))
obj1_clean = tm_map(obj1_clean, removeNumbers)
obj1_clean = tm_map(obj1_clean, stripWhitespace)

#cleaning most frequent words
wordcloud(obj1_clean, random.order=F,max.words=1000, col=rainbow(5), scale=c(3.2,0.2))
