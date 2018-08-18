# 1. Learn how to load mulitiple text files
#    (Have to worry about the size of the columns, dont wanna take too much memeory)
# 2. Learn how to do full text search
#    (I should be able to search and retrieve the PMIDs whose text contains a particular terms such as mutat or genertic alteration.)
#    (full range text search?)
# 3. Learn about searching text with like?

library(RMySQL)

# connect to the database CPP
con = dbConnect(MySQL(), group = "CPP")

# Path to data files
path = "/home/mz/Desktop/stem_cancer_extracted"
file.names <- dir(path, pattern = ".txt")

# Create table PubArticleText if it does not exist
if (!dbExistsTable(con,"pubarticletext")){
  qry <- paste0("CREATE TABLE pubArticleText (
                PMID INT UNSIGNED NOT NULL,
                articleText text,
                FULLTEXT (articleText));")
  dbGetQuery(con, qry)
}  

# Loop through the files in folder to load data into table PubArticleText
for (i in 1:length(file.names)) {
  print(file.names[i])

  qry <- paste0("LOAD DATA LOCAL INFILE '",path, "/" ,file.names[i],"' INTO TABLE pubarticletext 
                 Fields enclosed by '''' LINES TERMINATED BY '\r\n'")
  dbGetQuery(con, qry)
}

dbDisconnect(con)  