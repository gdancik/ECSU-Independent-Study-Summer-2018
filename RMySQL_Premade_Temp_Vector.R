library(RMySQL)
# Comparing queries from three different methods.
#------------------------------------------------------------------------------------
# Two genes we are comparing are AGL (GeneID = 178) and TP53 (GeneID = 7157)
# There will be three queries for each gene:
#     1. Get cancer PMIDs for AGL
#     2. Summarize the Mesh Disease Terms
#     3. Summarize Genes
# Then I will be timing these queries using three different method for the same queries
#     1. Using a premade table in DCast to store values of the PMIDs list
#     2. Using a temp table to store the values of the PMIDs list
#     3. Using vector to store the values of the PMIDs list
#------------------------------------------------------------------------------------

# a function that uses the PREMADE tables in DCAST
timeQueryPremadeTable <- function(con, gene){
  t1 <- Sys.time()
  
  qry <- paste0("SELECT 
                  COUNT(TT.MeshID) AS Frequency, TT.MeshID, TT.Term
                      FROM
                  (SELECT 
                      PubMesh.PMID, MeshTerms.MeshID, MeshTerms.Term
                  FROM
                      ((PubMesh
                  INNER JOIN MeshTerms ON MeshTerms.MeshID = PubMesh.MeshID)
                  INNER JOIN cancerpmids_",gene," ON cancerpmids_",gene,".PMID = PubMesh.PMID)
                  GROUP BY PubMesh.PMID , MeshTerms.MeshID , MeshTerms.Term) AS TT
                GROUP BY TT.MeshID , TT.Term
                ORDER BY COUNT(TT.MeshID) DESC;")
  dbGetQuery(con, qry)
  
  qry <- paste0("SELECT 
                    COUNT(TT.GeneID) AS Frequency, TT.SYMBOL AS Symbol
                FROM
                    (SELECT 
                        PubGene.PMID, Genes.GeneID, Genes.SYMBOL
                    FROM
                        ((Genes
                    INNER JOIN PubGene ON PubGene.GeneID = Genes.GeneID)
                    INNER JOIN cancerpmids_",gene," ON cancerpmids_",gene,".PMID = PubGene.PMID)
                    GROUP BY PubGene.PMID , Genes.GeneID , Genes.SYMBOL) AS TT
                GROUP BY TT.GeneID , TT.SYMBOL
                ORDER BY COUNT(TT.GeneID) DESC; ")
  res <- dbGetQuery(con, qry)
  
  #print(head(res, n = 5))
  #print(res)
  
  t2 <- Sys.time()
  t2-t1
}


# a function that create a TEMP TABLE to do the query
timeQueryTempTable <- function(con, gene) {
  t1 <- Sys.time()
  
  qry <- paste0( "CREATE TEMPORARY TABLE TempPMIDTable 
                  SELECT DISTINCT PubGene.PMID FROM PubGene
                  INNER JOIN PubMesh ON PubMesh.PMID = PubGene.PMID
                  INNER JOIN MeshTerms ON PubMesh.MeshID = MeshTerms.MeshID
                  WHERE GeneID = ", gene, " AND MeshTerms.TreeID LIKE 'C04.%'; ")
  dbGetQuery(con,qry)
  
  # Create index
  qry <- paste0("CREATE INDEX PMID_IX1 ON DCAST.TempPMIDTable (PMID); ")
  dbGetQuery(con,qry)
  
  qry <- paste0("SELECT 
                    COUNT(TT.MeshID) AS Frequency, TT.MeshID, TT.Term
                FROM
                    (SELECT 
                        PubMesh.PMID, MeshTerms.MeshID, MeshTerms.Term
                    FROM
                        ((PubMesh
                    INNER JOIN MeshTerms ON MeshTerms.MeshID = PubMesh.MeshID)
                    INNER JOIN TempPMIDTable ON TempPMIDTable.PMID = PubMesh.PMID)
                    GROUP BY PubMesh.PMID , MeshTerms.MeshID , MeshTerms.Term) AS TT
                GROUP BY TT.MeshID , TT.Term
                ORDER BY COUNT(TT.MeshID) DESC; ")
  dbGetQuery(con,qry)
  
  qry <- paste0("SELECT 
                    COUNT(TT.GeneID) AS Frequency, TT.SYMBOL AS Symbol
                FROM
                    (SELECT 
                        PubGene.PMID, Genes.GeneID, Genes.SYMBOL
                    FROM
                        ((Genes
                    INNER JOIN PubGene ON PubGene.GeneID = Genes.GeneID)
                    INNER JOIN TempPMIDTable ON TempPMIDTable.PMID = PubGene.PMID)
                    GROUP BY PubGene.PMID , Genes.GeneID , Genes.SYMBOL) AS TT
                GROUP BY TT.GeneID , TT.SYMBOL
                ORDER BY COUNT(TT.GeneID) DESC; ")
  res <- dbGetQuery(con, qry)
  
  #print(head(res, n = 5))
  dbGetQuery(con,"DROP TEMPORARY TABLE TempPMIDTable; ")
  
  t2 <- Sys.time()
  t2-t1
}

# a function to use VECTOR (copied the functions from sql_functions.R)
getCancerPMIDs <- function(con, GeneID) {
  
  str <- paste0("select distinct PubGene.PMID from PubGene\n",
                "inner join PubMesh ON PubMesh.PMID = PubGene.PMID\n",
                "inner join MeshTerms ON PubMesh.MeshID = MeshTerms.MeshID\n",
                "where GeneID = ", GeneID, " and MeshTerms.TreeID LIKE 'C04.%'");
  
  #cat("original query\n", str, "\n")
  dbGetQuery(con, str)
}
getMeshSummaryByPMIDs <- function(pmids, con) {
  
  pmids <- paste0("'",pmids,"'", collapse = ",")
  
  str <- paste0("select count(TT.MeshID) as Frequency, TT.MeshID, TT.Term from\n",
                "(select PubMesh.PMID, MeshTerms.MeshID, MeshTerms.Term from PubMesh\n",
                "inner join MeshTerms ON MeshTerms.MeshID = PubMesh.MeshID\n",
                "where PubMesh.PMID IN ", paste0("(", pmids, ")\n"),
                "group by PubMesh.PMID, MeshTerms.MeshID, MeshTerms.Term) as TT\n",
                "group by TT.MeshID, TT.Term ORDER BY count(TT.MeshID) desc;")
  
  dbGetQuery(con, str)
  
}
getGeneSummaryByPMIDs <- function(pmids, con) {
  
  pmids <- paste0("'",pmids,"'", collapse = ",")
  
  str <- paste0("select count(TT.GeneID) as Frequency, TT.SYMBOL as Symbol FROM\n",
                "(select PubGene.PMID, Genes.GeneID, Genes.SYMBOL from Genes\n",
                "inner join PubGene ON PubGene.GeneID = Genes.GeneID\n",
                "where PubGene.PMID IN ", paste0("(", pmids, ")\n"),
                "group by PubGene.PMID, Genes.GeneID, Genes.SYMBOL) as TT\n",
                "group by TT.GeneID, TT.SYMBOL order by count(TT.GeneID) desc;")
  
  dbGetQuery(con, str)
  
}

timeQueryVector<- function(con, gene){
  t1 <- Sys.time()
  
  pmids_initial = getCancerPMIDs(con, gene)
  pmids <- pmids_initial$PMID
  
  getMeshSummaryByPMIDs(pmids, con)
  
  res <- getGeneSummaryByPMIDs(pmids, con)
  
  t2 <- Sys.time()
  t2-t1
}

# connect to the database
con = dbConnect(MySQL(), group = "CPP")

# control variables for the query
gene1 <- 178  # AGL
gene2 <- 7157  # TP53
runtime <- 4

# launch each query 11 times (took me about 5 mins to run 11 times each)
t1 <- Sys.time()

timePremadeGene1 <- replicate(runtime, timeQueryPremadeTable(con, gene1))
timeTempGene1 <- replicate(runtime, timeQueryTempTable(con, gene1))
timeVectorGene1 <- replicate(runtime, timeQueryVector(con, gene1))

timePremadeGene2 <- replicate(runtime, timeQueryPremadeTable(con, gene2))
timeTempGene2 <- replicate(runtime, timeQueryTempTable(con, gene2))
timeVectorGene2 <- replicate(runtime, timeQueryVector(con, gene2))

t2 <- Sys.time()



launchQueryTime <- t2-t1
print(launchQueryTime)

print(mean(timePremadeGene1[-1]))
print(mean(timeTempGene1[-1]))
print(mean(timeVectorGene1[-1]))

print(mean(timePremadeGene2[-1]))
print(mean(timeTempGene2[-1]))
print(mean(timeVectorGene2[-1]))

dbDisconnect(con)  

