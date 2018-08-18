library(RMySQL)

# Comparing the performace of two different queries.
# First query has the PMIDs already written in the Select statement.
# Second query will instead use a select statement to get PMIDs that the first query already have.

timeQuery <- function(con, str) {
  t1 <- Sys.time()
  res <- dbGetQuery(con, str)
  t2 <- Sys.time()
  t2-t1
}

# connect to the database
con = dbConnect(MySQL(), group = "CPP")

# query 1: summarize Mesh Disease terms (PMID list is based on GeneID of 178)
str1 <- paste0("SELECT 
                    COUNT(TT.MeshID) AS Frequency, TT.MeshID, TT.Term
                FROM
                    (SELECT 
                        PubMesh.PMID, MeshTerms.MeshID, MeshTerms.Term
                    FROM
                        PubMesh
                    INNER JOIN MeshTerms ON MeshTerms.MeshID = PubMesh.MeshID
                    WHERE
                        PubMesh.PMID IN ('282662' , '287551', '6982575', '7775401', '9249084', '15833157', '16574319', '17198352', 
                        '18360695', '18593365', '20301788', '23430490', '23525979', '24100167', '24700805', '24837458', '26032551', 
                        '26490312', '26553625', '26924264', '26975021', '27106217', '27595989', '28584628')
                    GROUP BY PubMesh.PMID , MeshTerms.MeshID , MeshTerms.Term) AS TT
                GROUP BY TT.MeshID , TT.Term
                ORDER BY COUNT(TT.MeshID) DESC;  ")

# query 2: Single Query
str2 <- paste0("SELECT 
                    COUNT(TT.MeshID) AS Frequency, TT.MeshID, TT.Term
                FROM
                    (SELECT 
                        PubMesh.PMID, MeshTerms.MeshID, MeshTerms.Term
                    FROM
                        PubMesh
                    INNER JOIN MeshTerms ON MeshTerms.MeshID = PubMesh.MeshID
                    WHERE
                        PubMesh.PMID IN (SELECT DISTINCT
                                PubGene.PMID
                            FROM
                                PubGene
                            INNER JOIN PubMesh ON PubMesh.PMID = PubGene.PMID
                            INNER JOIN MeshTerms ON PubMesh.MeshID = MeshTerms.MeshID
                            WHERE
                                GeneID = '178'
                                    AND MeshTerms.TreeID LIKE 'C04.%')
                    GROUP BY PubMesh.PMID , MeshTerms.MeshID , MeshTerms.Term) AS TT
                GROUP BY TT.MeshID , TT.Term
                ORDER BY COUNT(TT.MeshID) DESC; ")  
  


# launch each query 500 times
t1 <- replicate(500, timeQuery(con, str1))
t2 <- replicate(500, timeQuery(con, str2))

# generate boxplot of the results, ignoring the first query in each set
boxplot(list("hardline PMID" = t1[-1], "SingleQuery" = t2[-1]),
        col = c("lightblue", "lightyellow"),
        main = "MySQL Gene Filter query comparison")


dbDisconnect(con)  



