# 1. Download the newest disease2pubtator file: ftp://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator/
# 2. replace MESH: from the newest disease2pubtator file within the script
# 3. Creates a new disease table (using a different name than PubMesh) and filtering the table to include only
#    records with Genes in the database and records that are cancer-related (see attached script called 'loadpubmeshdata.sql').
# 4. Create a new table containing the records that (1) are in the new disease data but not currently in our database.
# 5. (2) are currently in our database but are not in the new disease table. The former are records we need to add; the latter are records to be deleted.

# Side note: It would be great if you could write a script that allows the user to specify whether we are creating a new database from
#             scratch (what my script assumes) or whether we will be adding to an existing database.

library(RMySQL)

# ------------------------------------------------------
# Control Variables 
# ------------------------------------------------------

# If this is a new database, set 'newDatabase' to TRUE and set to FALSE if it is an existing database.
newDatabase <- FALSE

# Need the filepath and file name in 'newDisease2PubFilePath'
newDisease2PubFilePath <- "/home/mz/Desktop/disease2pubtator"

# This for creating NewToInsertPubmesh.txt & DeletedPubmesh.txt at the folder location of 'outputFilePath'
# so we can have an record what was inserted and deleted.
outputFilePath <- "/home/mz/Desktop/rtesting"

# If you want to delete rows from orignal 'PubMesh' table then set deleteRows to TRUE
# This only works when newDatabase is FALSE
deleteRows <- FALSE

# ------------------------------------------------------
# End of Control Variables 
# ------------------------------------------------------

# connect to the database CPP
con = dbConnect(MySQL(), group = "CPP")

if(newDatabase == TRUE){
  tablename <- "pubmesh"
}else{
  tablename <- "newpubmesh"
}


# Note: This is taken from loadpubmeshdata.sql from email "Next Steps" from Wed, Aug 8, 2018 at 10:11 PM
# This steps: 3

# ------------------------------------------------------
#  DDL for Table newpubmesh
# ------------------------------------------------------
qry <- paste0("CREATE TABLE DCAST.",tablename," 
             (PMID INT NOT NULL, 
          	  MeshID VARCHAR(15) NOT NULL, 
          	  MENTIONS VARCHAR(800)); ")
dbGetQuery(con, qry)

# ------------------------------------------------------
#  Load data into newpubmesh 
# ------------------------------------------------------
qry <- paste0("LOAD DATA LOCAL INFILE '",newDisease2PubFilePath,"' INTO TABLE DCAST.",tablename, " IGNORE 1 LINES;")
dbGetQuery(con, qry)

# ------------------------------------------------------
#  Update newpubmesh to include only PMIDs in PubGene table  
#  and remove duplicates using group by  
# ------------------------------------------------------
qry <- paste0("create table t2 as SELECT ",tablename,".PMID, ",tablename,".MeshID 
               FROM ",tablename," INNER JOIN PubGene ON PubGene.PMID = ",tablename,".PMID
               GROUP BY PMID, MeshID;")
dbGetQuery(con, qry)

qry <- paste0("drop table ",tablename,";")
dbGetQuery(con, qry)

qry <- paste0("rename table t2 to ",tablename,";")
dbGetQuery(con, qry)

qry <- paste0("create table t2 as select ",tablename,".PMID, ",tablename,".MeshID 
              from ",tablename," inner join MeshTerms ON ",tablename,".MeshID = MeshTerms.MeshID 
              where MeshTerms.TreeID LIKE 'C04.%';")
dbGetQuery(con, qry)

qry <- paste0("drop table ",tablename,";")
dbGetQuery(con, qry)

qry <- paste0("rename table t2 to ",tablename,";")
dbGetQuery(con, qry)

# ------------------------------------------------------
#  DDL for Index newpubmesh_IX1
# ------------------------------------------------------
qry <- paste0("create INDEX PMIDIndex ON ",tablename," (PMID);")
dbGetQuery(con, qry)

qry <- paste0("create INDEX MeshIndex ON ",tablename," (MeshID);")
dbGetQuery(con, qry)

# ------------------------------------------------------
#  This is step 4 and 5 - comparing old and new tables
#  This will only happen if newDatabase == false
# ------------------------------------------------------

if(newDatabase == FALSE){
  
  # select new PMIDs comparing newpubmesh with original pubmesh
  # also inserting the new PMIDs into the original pubmesh
  qry <- paste0("INSERT INTO pubmesh SELECT DISTINCT *
                FROM ",tablename," WHERE
                NOT EXISTS( SELECT pubmesh.pmid
                FROM pubmesh WHERE
                ",tablename,".pmid = pubmesh.pmid);")
  res <- dbGetQuery(con, qry)
  filepath <- paste0(outputFilePath,"/NewToInsertPubmesh.txt")
  write.table(res, file = filepath , sep = "\t", row.names = FALSE)
  
  
  # select deleted PMIDs comparing newpubmesh with original pubmesh
  qry <- paste0("SELECT DISTINCT pmid
                FROM pubmesh WHERE
                NOT EXISTS( SELECT ",tablename,".pmid
                FROM ",tablename," WHERE
                ",tablename,".pmid = pubmesh.pmid);")
  res <- dbGetQuery(con, qry)
  filepath2 <- paste0(outputFilePath,"/DeletedPubmesh.txt")
  write.table(res, file = filepath2, sep = "\t", row.names = FALSE)
  
  # insert the rows from 'newPubMesh' table to the orignal 'PubMesh' table
  qry <- paste0("INSERT INTO pubmesh 
                SELECT DISTINCT * FROM ",tablename," WHERE 
                NOT EXISTS( SELECT pubmesh.pmid
                FROM pubmesh WHERE
                ",tablename,".pmid = pubmesh.pmid);")
  dbGetQuery(con, qry)
  

  if(deleteRows == TRUE){
  # This SET SQL_SAFE_UPDATES=0 is for avoiding error code: 1175
  qry <- paste0("SET SQL_SAFE_UPDATES=0; ")
  dbGetQuery(con, qry)
  
  qry <- paste0("DELETE FROM pubmesh
                WHERE NOT EXISTS( SELECT ",tablename,".pmid
                FROM ",tablename,"
                WHERE ",tablename,".pmid = pubmesh.pmid);")
  dbGetQuery(con, qry)
  }
}

dbDisconnect(con)  