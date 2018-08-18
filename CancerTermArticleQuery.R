library(RMySQL)

# Connect to the database 'CPP'
con = dbConnect(MySQL(), group = "CPP")


# Create table 'CancerTermPMID'. This table will have two columns:'PMID' and 'termID'.
if (!dbExistsTable(con,"cancertermpmid")){
  qry <- paste0("CREATE TABLE cancertermPMID (
                PMID INT UNSIGNED NOT NULL,
                termID INT UNSIGNED NOT NULL,
                INDEX index_PMID (PMID),
                INDEX index_termID(termID) );")
  dbGetQuery(con, qry)
}  

# Start time to complete this script
t1 <- Sys.time()

# Find number of rows in table 'CancerTerm'.
qry <- paste0("SELECT COUNT(*) FROM cancerterm")
res <- dbGetQuery(con, qry)
tablecount <- res$`COUNT(*)`


# This will loop through the rows from the table 'CancerTerm' and extract the words under the 'pattern' column.
for (i in 1:tablecount){
  qry <- paste0("SELECT pattern FROM cancerterm WHERE termid = ",i,";")
  dbGetQuery(con, qry)
  
  # Stores the query results into 'patterns'
  patterns <- res$pattern
  print(patterns)
  
  # This will split each word by the symbol | and stored into a vector 'searchwords'.
  searchwords <- strsplit(patterns, "[|]")[[1]]
  

  # For BOOLEAN MODE, words encapsulated in " " will be searched as one phrase exactly.
  # Find rows that contain the exact phrase “some words” (for example, rows that 
  # contain “some words of wisdom” but not “some noise words”).
  
  # This will loop through the vector 'searchwords' to find a 'pattern' with 2 or more words 
  # to encapsulate in quotation mark.
  for (y in 1:length(searchwords)) {
    if (sapply(strsplit(searchwords[y], " "), length) > 1){
      searchwords[y] <- paste0('"' ,searchwords[y], '"')
    }
  }
  
  # This will concatenate the vector into one string to put in the full text search.
  finalstring <- paste(searchwords, collapse=" ")
  cat(finalstring)  
  
  # Inserting the PMIDs of the Articles that contain words or phrase that matches
  # the 'finalstring' and the related 'termID' from table 'CancerTerm'.
  qry <- paste0("INSERT INTO cancertermPMID(PMID, termID)
                SELECT pubarticletext.PMID, cancerterm.TermID 
                FROM pubarticletext, cancerterm 
                WHERE MATCH (articleText) AGAINST ('",finalstring,"' IN BOOLEAN MODE) 
                AND cancerterm.TermID=",i,"; ")
  
  dbGetQuery(con, qry)
  
}

t2 <- Sys.time()
res <- t2-t1

print(res)

dbDisconnect(con)  