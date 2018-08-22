# ECSU-Independent-Study-Summer-2018
For this independent study, I worked with Dr. Dancik on a tool called Cancer Publication Portal (CPP). This tool will help researchers find biomedical journals related to human cancer. The tool will break down the journals by genes, cancer types, drugs, and mutations. The researcher will be able to filter the journals by these categories. This project had three components to work on: web interface, data scraping, and the database. I worked on the database that stored all the data for CPP.

	CompareGeneSummaries.R – Compare two different versions of a query that summarize the 
		Mesh Diseases associated with gene.
		Email related to this assignment – “R assignment” Jun 13, 2018
				 
	RMySQL_Premade_Temp_Vector.R – Continuing from “CompareGeneSummaries.R”, evaluating 
		whether using temporary or permanent table will improve query times.
		Email related to this assignment – “R assignment” Jun 21, 2018
				       
	Upload_ArticleText_to_table.R – Create table ‘PubArticleText’ and load all the article’s 
		title and abstract to database.
		Email related to this assignment – “Article data for DCAST / CPP" July 4, 2018
					
	CancerTermArticleQuery.R – Takes the 15 cancer terms and their patterns and do full-text 
		search in Boolean mode against the article title and abstract.
		Email related to this assignment – “Cancer keyword list” Aug 3, 2018
	
	UpdatingTableAssignment.R - Update old PubMesh table with new data from disease2pubtator
		Email related to this assignment – “Next steps” Aug 3, 2018
