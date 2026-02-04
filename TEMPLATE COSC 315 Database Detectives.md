# COSC 315 Database Detectives
Name: Sarah Rae Pritchard
Date: 01/28/26

## Task Results

### Task 2 - Inventory the Database
Link to Finalized DrawSQL ERD: https://drawsql.app/teams/sweetcomputer/diagrams/database-detectives
Enter your report here.
There is 11 tables.
Core Entities: Recording, Release, Creator, Sale, SaleItem, Client, Staff
Because the database can not function without the tables listed above.
Supporting: Style, Format, Collection
These tables describe the data in more detail, they support but are not essential.
Join: CollectionItem
Only exist to connect Collection to Recording.


```sql
SHOW TABLES;
```

### Task 3 - Hypothesize and Test Relationships
Enter your report here.
Hypothesis: The schema uses foreign key columns such as REleaseID, CreatorID, etc.. to link tables together. I expect this is used to form one to many relationships, the parent row will connect to multiple childern. The all coulmns in the CollectionItem table is connected to another so this will be a many to many relationship. 

Which columns appear to function as foreign keys?
CollectionItem.CollectionID -> Collection.CollectionId
CollectionItem. Recording -> Recording.RecordingID
Recording.ReleaseId -> Release.ReleaseID
Recording.FormatId -> Format.FormatID
Release.CreatorId -> Creator.CreatorId
Recording.StyleId -> Style.StyleId
SaleItem.SaleId -> Sale.SaleId
SaleItem.RecordingId -> Recording.RecordingId
Sale.ClientId -> Client.ClientId
Client.AccountRepId -> Staff.StaffId
Staff.StaffId -> ManagerId

What cardinality do you suspect (one-to-many, many-to-many)?
one-to-many:
Creator -> Release
Release -> Recording
Format -> Recording
Style -> Recording
Client -> Sale
Sale -> SaleItem
Staff.ManngerID -> Staff.StaffId
Staff.AccountRepId -> Staff.StaffId

many-to-many:
Collection <-> Recording
Sale <-> Recording

What evidence supports or contradicts each hypothesis?
Support:
Any of the one-to-many examples above work. For example creator -> release works. Because we see that the Creator table is has multiple Releases and in the schema Release.CreatorId can not be NULL so every release must have a Creator.

Contradicts:
There is no contradictions for my hypothesis, but there is one that indicates optionality.  This is because all foriegn keys are valid, the parent tables define the primay keys, bridge tables work properly, and there arre no circles as seen on the diagram.  

Do joins behave as expected?
For each 1:M join, the rows_after_join should be ≤ the child’s baseline count.
For each M:N bridge join, rows_joined should equal the bridge row count.
Yes, the joins are behaving as expected.

Are there orphaned records?
Child table
LEFT JOIN parent table
WHERE parent is NULL AND child FK is not NULL
All queries returned back 0 meaning there is no orphaned records.

Do joins unexpectedly multiply rows?
No, the joins did not unexpectedly multiply rows. Every relationship join row counts matched the child as expected, but Staff self‑join where the INNER JOIN returned fewer rows due to top‑level employees with NULL ManagerId (an expected drop, not a fan‑out).


### Task 4 - Aggregation & Uniqueness Analysis
What do aggregates reveal that simple inspection did not?
Aggregates reveal scale, domain cardinality, and skewed multiplicity.
how many rows exists?
```sql
SELECT COUNT(*) FROM `Recording`;
How many unique attributes are there?
SELECT COUNT(DISTINCT `FormatId`) FROM `Recording`;
```
How many childern exist for each parent?
```sql
SELECT `CreatorId`, COUNT(*)
FROM `Release`
GROUP BY `CreatorId`
ORDER BY COUNT(*) DESC
LIMIT 5;
```
Where do assumptions break down?
Not everyone has a manager, self joined shows that there is 8 total staff, but only 7 appear in the inner join. So one of the staff has null in ManagerId. 
There is only 5 distinct FormatId so we have a heavyly used domain with little variety.
Creators donot contribute evenly, for example Creator 90 has 21 release while others have fewer, this breaks dwon because the aggregates show skewed multiplicity.
There is possible dupliactes with in SaleId and RecordingId so sale can have multiple line for tghe same recording. This can cause a mismatch betweeen assumption and design.

### Task 5 - Anomalies & Design Issues
What design issues might exist?
1. Writer Column break normalization, thus cx=an be from storing multiple values in one column.
2. Heavy skew in formats shows over reuse, the lack of variety can make the data either to broad leaving vague information.
3. Null ManagerId for top level staff but there is no heirachy table.

What evidence supports your claim?
1. Design shows that there is free text field for the Writer column, information is not static or standardized. 
2. 5 formats for 3503 recordings is not a good ratio, the format is oversimplified. 
3. One staff has no manager so the hierarchy is incomplete.

What redesign would you propose?
1. Create a Writer Table and RecodringWriter bridge.
2. Add unique contraint to SaleItem
3. Expand Format table if the more detail is needed. 

### Task 6 - Explore the Data
Across all 3503 recordings, only 5 formats are used. Surprisingly 86.61% of all the recordings are only one format,  MPEG audio file with 3034 recodings. This is a small, heavilied skew in format will causes filters and segmenting to be uneven and misleading balance in this caetgory.
```sql
-- Share of each format across all recordings
SELECT
  r.`FormatId`,
  f.`Name` AS `FormatName`,
  COUNT(*) AS `recordings`,
  ROUND(100 * COUNT(*) / t.`total_recordings`, 2) AS `pct_of_all_recordings`
FROM `Recording` r
JOIN `Format` f ON f.`FormatId` = r.`FormatId`
JOIN (SELECT COUNT(*) AS `total_recordings` FROM `Recording`) t
GROUP BY r.`FormatId`, f.`Name`, t.`total_recordings`
ORDER BY `recordings` DESC;

-- Quick domain size (how many formats total?)
SELECT COUNT(DISTINCT `FormatId`) AS `distinct_formats`,
       COUNT(*) AS `total_recordings`
FROM `Recording`;
```
The top Collection.Name is Music. Which makes sense, but what is suprising is that 3290 recording are without descriptive genres in this schema. For example some genres are Grunge and Brazilian Music. It should also be noted that there are duplicates within this table.
```sql
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection`
FROM `CollectionItem` ci
JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId`
GROUP BY ci.`CollectionId`, c.`Name`
ORDER BY `items_per_collection` DESC;
```
There is not a single recording that brings more than 0.17% of total revenue, even the top recordings individually contribute to less than that. This indicates that revenue is spread widely and not contrated to a single recording. This is interesting since companies typically have a few items that drive the revenue. Not a single recording dominates revenue so promotion most look different for this company than as expected. 
```sql
SELECT
  r.`RecordingId`,
  r.`Name` AS `RecordingName`,
  SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,
  ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue`
FROM `SaleItem` si
JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`
JOIN (SELECT SUM(si2.`Quantity` * si2.`ItemPrice`) AS `total_revenue` FROM `SaleItem` si2) t
GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue`
ORDER BY `revenue` DESC
LIMIT 10;
```
## Appendices

### AI Traceability Log

AI Used: Copilot

Prompt: What evidence supports or contradicts "The schema uses foreign key columns such as REleaseID, CreatorID, etc.. to link tables together. I expect this is used to form one to many relationships, the parent row will connect to multiple childern. The all coulmns in the CollectionItem table is connected to another so this will be a many to many relationship."

AI Response:
Creator → Release (1-to-many)
Evidence supporting:
(a) Schema evidence
Release.CreatorId is a NOT NULL foreign key referencing Creator.CreatorId.
This forces every Release to belong to exactly one Creator.
(b) Data Evidence - If you see Creators with multiple Releases, that supports 1:M.
SELECT CreatorId, COUNT(*) AS releases_per_creator
FROM Release
GROUP BY CreatorId
ORDER BY releases_per_creator DESC;
(c) Join Evidence - Row count equals number of Releases → expected for 1:M parent join.
SELECT COUNT(*) 
FROM `Release` r
JOIN Creator c ON c.CreatorId = r.CreatorId;

Evidence Contradicting:
(a) Duplicate line-items in SaleItem - This does not violate schema, but may violate business rules.
SELECT SaleId, RecordingId, COUNT(*) 
FROM SaleItem
GROUP BY SaleId, RecordingId
HAVING COUNT(*) > 1;
(b) Optional relationships - These being NULL does not contradict the cardinality—just indicates optionality.
Recording.ReleaseId
Recording.StyleId
Client.AccountRepId
Staff.ManagerId
(c)No orphans possible - Because foreign key constraints exist, contradictions like “orphaned child rows” are impossible unless FK checks were disabled during inserts.
SELECT RecordingId FROM `Recording`
WHERE ReleaseId IS NOT NULL
AND ReleaseId NOT IN (SELECT ReleaseId FROM `Release`);

Prompt: i want to make a select statement that will check to see if there are null values in these: Recording.ReleaseId
Recording.StyleId
Client.AccountRepId
Staff.ManagerId

AI Response: 
Option 1: One query that shows NULL counts for all four columns
This is the easiest and most report‑friendly method:
SELECT
  (SELECT COUNT(*) FROM Recording WHERE ReleaseId IS NULL) AS Recording_ReleaseId_NULLs,
  (SELECT COUNT(*) FROM Recording WHERE StyleId IS NULL)   AS Recording_StyleId_NULLs,
  (SELECT COUNT(*) FROM Client    WHERE AccountRepId IS NULL) AS Client_AccountRepId_NULLs,
  (SELECT COUNT(*) FROM Staff     WHERE ManagerId IS NULL) AS Staff_ManagerId_NULLs;

Prompt: what is this question ask of us "Do joins behave as expected?" how can we solve it and what are the implecations

Ai Response:
What the question is really asking
“Do joins behave as expected?” means:

When you join tables using the foreign keys you identified,
do the results match the cardinality you predicted,
or do the joins produce unexpected behavior?

In other words, once you've guessed that two tables are one‑to‑many or many‑to‑many, the question is asking:
Does the data actually behave that way when you join it?

What “expected join behavior” looks like
1) For a One‑to‑Many relationship:
Example: Release → Recording
Expectation:
Joining child → parent should NOT multiply rows.
The number of rows after the join should be ≤ the number of child rows.
If rows multiply:
That means the relationship isn’t truly one‑to‑many—maybe the parent table contains duplicates or there is another hidden relationship.

2) For a Many‑to‑Many relationship
Example: Collection ↔ Recording via CollectionItem
Expectation:
A 3‑table join (Parent A → Bridge → Parent B) should produce exactly the number of rows in the bridge table.
No duplicates unless data violates rules.

3) For Optional Relationships
Example: Recording.StyleId is sometimes NULL
Expectation:
INNER JOIN will drop some rows.
LEFT JOIN will preserve all rows.
Both behaviors are “expected,” depending on join type.
How to “solve” this question
To answer it properly, you simply:

Step 1 — State the relationship you expect
Example:
Hypothesis: Release → Recording is a one‑to‑many relationship.

Step 2 — Perform the join
You already ran (or can run):
SQLSELECT COUNT(*) FROM Recording;SELECT COUNT(*)FROM Recording rJOIN Release rel ON rel.ReleaseId = r.ReleaseId;Show more lines

Step 3 — Compare the counts
If results are the same or smaller:
Join behaves as expected Confirms 1‑to‑many cardinality
If results are larger:
Join does NOT behave as expected Indicates:
Duplicate parent PKs
Hidden many‑to‑many
Data integrity issues

Step 4 — Report findings
For your schema, the results will almost always show:
1:M joins do NOT multiply rows
M:N joins match the bridge table row count
Optional relationships drop rows in INNER JOIN (as expected)

So you conclude:
Yes, joins behave as expected for the hypothesized cardinalities.

Implications (why this question matters)
These are the points you’ll want to include in your written report:

1. Confirms whether your schema understanding is correct
If joins behave as expected, your FK hypotheses are correct.
If not, your schema interpretation or data assumptions may need revising.

2. Detects data quality issues
Unexpected join multiplication can reveal:
Duplicate primary keys
Bridge-table errors
Mis-modeled relationships
Orphaned child rows (if FKs were turned off during import)

3. Shows whether your schema supports reliable reporting
If joins behave unpredictably:
Summaries inflate
Totals look wrong
Dashboards produce misleading aggregations
Your database reports become untrustworthy.

4. Validates cardinality and normalization
Expected joins confirm that:
Foreign keys are modeled correctly
Bridge tables are functioning
The schema follows proper normalization (1NF–3NF)
Relationships match real-world entities (Release → Track, Sale → Line Items, etc.)

Final Answer (ready for your assignment)
The question “Do joins behave as expected?” asks whether the actual SQL join results match the cardinality hypotheses we formed earlier. To answer it, we perform joins between parent and child tables and compare the number of rows before and after joining. For one‑to‑many relationships, the join should not multiply rows; for many‑to‑many relationships, the number of rows after the join should match the number of bridge‑table rows. Optional foreign keys should cause INNER JOINs to drop rows and LEFT JOINs to keep them.
Based on the schema and the counts returned by our join tests, the joins behave exactly as expected: one‑to‑many joins do not inflate row counts, many‑to‑many joins match the bridge table size, and optional relationships drop rows under INNER JOIN. This confirms that our earlier relationship hypotheses are correct and that the database enforces referential integrity as designed.

Prompt: can u make a sql query that does all the joins that u have done on step 2

AI Response:
1) Baseline row counts (for comparison)
SELECT
  (SELECT COUNT(*) FROM Creator)        AS n_creator,
  (SELECT COUNT(*) FROM Release)        AS n_release,
  (SELECT COUNT(*) FROM Recording)      AS n_recording,
  (SELECT COUNT(*) FROM Format)         AS n_format,
  (SELECT COUNT(*) FROM Style)          AS n_style,
  (SELECT COUNT(*) FROM Collection)     AS n_collection,
  (SELECT COUNT(*) FROM CollectionItem) AS n_collectionitem,
  (SELECT COUNT(*) FROM Client)         AS n_client,
  (SELECT COUNT(*) FROM Sale)           AS n_sale,
  (SELECT COUNT(*) FROM SaleItem)       AS n_saleitem,
  (SELECT COUNT(*) FROM Staff)          AS n_staff;

2) One‑to‑Many joins (child → parent)
-- === 1:M JOINS: Recording -> Release, Format, Style ===
-- 2.1 Recording -> Release (optional)
SELECT 'rec_join_release_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM Recording r
JOIN Release rel ON rel.ReleaseId = r.ReleaseId;

SELECT 'rec_join_release_left' AS test_name,
       COUNT(*) AS rows_after_join
FROM Recording r
LEFT JOIN Release rel ON rel.ReleaseId = r.ReleaseId;

-- 2.2 Recording -> Format (mandatory)
SELECT 'rec_join_format_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM Recording r
JOIN Format f ON f.FormatId = r.FormatId;

-- 2.3 Recording -> Style (optional)
SELECT 'rec_join_style_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM Recording r
JOIN Style s ON s.StyleId = r.StyleId;

SELECT 'rec_join_style_left' AS test_name,
       COUNT(*) AS rows_after_join
FROM Recording r
LEFT JOIN Style s ON s.StyleId = r.StyleId;

-- 2.4 Release -> Creator
SELECT 'rel_join_creator_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM Release rel
JOIN Creator c ON c.CreatorId = rel.CreatorId;

-- 2.5 SaleItem -> Sale
SELECT 'saleitem_join_sale_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM SaleItem si
JOIN Sale s ON s.SaleId = si.SaleId;

-- 2.6 SaleItem -> Recording
SELECT 'saleitem_join_recording_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM SaleItem si
JOIN Recording r ON r.RecordingId = si.RecordingId;

-- 2.7 Client -> Staff (AccountRep, optional)
SELECT 'client_join_staffrep_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM Client c
JOIN Staff st ON st.StaffId = c.AccountRepId;

SELECT 'client_join_staffrep_left' AS test_name,
       COUNT(*) AS rows_after_join
FROM Client c
LEFT JOIN Staff st ON st.StaffId = c.AccountRepId;

-- 2.8 Staff (child) -> Staff (manager, optional)
SELECT 'staff_join_manager_inner' AS test_name,
       COUNT(*) AS rows_after_join
FROM Staff s
JOIN Staff m ON m.StaffId = s.ManagerId;

SELECT 'staff_join_manager_left' AS test_name,
       COUNT(*) AS rows_after_join
FROM Staff s
LEFT JOIN Staff m ON m.StaffId = s.ManagerId;

3) Many‑to‑Many joins through bridge tables
-- === M:N JOINS ===

-- 3.1 Collection <-> Recording via CollectionItem
SELECT 'collectionitem_bridge_rows' AS test_name,
       COUNT(*) AS n_bridge
FROM CollectionItem;

SELECT 'collectionitem_full_join' AS test_name,
       COUNT(*) AS rows_joined
FROM CollectionItem ci
JOIN Collection c ON c.CollectionId = ci.CollectionId
JOIN Recording  r ON r.RecordingId  = ci.RecordingId;

-- 3.2 Sale <-> Recording via SaleItem
SELECT 'saleitem_bridge_rows' AS test_name,
       COUNT(*) AS n_bridge
FROM SaleItem;

SELECT 'saleitem_full_join' AS test_name,
       COUNT(*) AS rows_joined
FROM SaleItem si
JOIN Sale s ON s.SaleId = si.SaleId
JOIN Recording r ON r.RecordingId = si.RecordingId;
`` 

Prompt: explain what the question "Are there orphaned records" is asking and how do i check to make sure if there is any 

Ai Response:
1. What the question is asking
The question:

“Are there orphaned records?”

means:
Do you have child rows that reference a parent that does NOT exist?
In other words: A foreign key column points to a value that is not present in the parent table.
Example: A Recording with a ReleaseId = 12, but there is no row in Release where ReleaseId = 12.
That child row is called an orphaned record

Why orphaned records matter
Orphaned records cause real problems:
Joins break (INNER JOIN loses the row)
Reports become inaccurate
Summaries lose data (because the parent lookup fails)
UI or apps crash because they expect a parent that isn’t there
They reveal bad data quality or missing foreign key constraints

In your schema, MySQL has foreign key constraints, so normally orphans cannot exist unless foreign keys were temporarily disabled (e.g., SET FOREIGN_KEY_CHECKS=0), which is common during imports.
So it is still important to check.

How to check for orphaned records (MySQL)
Format:
Child table
LEFT JOIN parent table
WHERE parent is NULL AND child FK is not NULL
This will show you any orphans.
Below are all the checks relevant to your schema.

4. How to interpret results
0 rows returned → No orphaned records for that relationship.
Rows returned → Child rows exist that point to missing parents.
You then decide:

Delete them?
Fix the FK values?
Insert missing parent rows?
Keep them, if the relationship is meant to be optional? (Only if FK is NULL.)

Prompt: Exaplin what the question "Do joins unexpectedly multiply rows?" is asking and walk me step by step to answer it.

Ai Response:
1. What the question is asking (plain English)
When you join tables together in SQL, the number of resulting rows should follow the cardinality you predicted earlier:

In a one‑to‑many (1:M), joining a child to its parent should not create more rows than the child has.
In a many‑to‑many (M:N), the number of joined rows should match the number of rows in the bridge table.
In an optional FK, an INNER JOIN will drop rows, but it should never multiply them.

The question is asking:
When we actually run the JOINs, do we get the number of rows we would expect based on the relationships, or do we suddenly get MORE rows than we should (a “fan‑out”)?

An “unexpected row multiplication” means your understanding of the relationship is wrong OR your data is messy.

Why this matters
Unexpected row multiplication indicates a serious schema problem, such as:

Duplicate parent keys
A hidden many‑to‑many relationship
A mistake in your JOIN conditions
Dirty data (uncontrolled duplicates)
A bridge table not properly constrained

This leads directly to:
Incorrect totals
Duplicated report rows
Inflated sums and averages
Broken analytics

2. How to answer it (step‑by‑step)
Here’s the exact process you follow:

Step 1 — Start with the child table row count
Example (Recording):
SQLSELECT COUNT(*) AS n_recording FROM `Recording`;Show more lines
This number is your baseline.

Step 2 — Join the child to the parent
Example: Recording → Release (1:M expected)
SQLSELECT COUNT(*) AS rows_after_joinFROM `Recording` AS rJOIN `Release`  AS rel ON rel.`ReleaseId` = r.`ReleaseId`;Show more lines

Step 3 — Compare the two numbers
Expected behavior (correct):
rows_after_join ≤ n_recording
Since each Recording should belong to ONE Release.

Unexpected behavior (problem):
rows_after_join > n_recording
Means one Recording joined to MORE THAN ONE Release → impossible in a correct schema.
That indicates:
duplicate parent keys or
incorrect JOIN or
hidden many‑to‑many path

3. Step‑by‑step checks for your schema
Below are the joins you should test.

1:M joins—should NOT multiply rows
Recording → Release
SQLSELECT COUNT(*) FROM `Recording`;SELECT COUNT(*) FROM `Recording` r JOIN `Release` rel ON rel.`ReleaseId` = r.`ReleaseId`;Show more lines
Recording → Format
SQLSELECT COUNT(*) FROM `Recording`;SELECT COUNT(*) FROM `Recording` r JOIN `Format` f ON f.`FormatId` = r.`FormatId`;Show more lines
Recording → Style
SQLSELECT COUNT(*) FROM `Recording`;SELECT COUNT(*) FROM `Recording` r JOIN `Style` s ON s.`StyleId` = r.`StyleId`;Show more lines
SaleItem → Sale
SQLSELECT COUNT(*) FROM `SaleItem`;SELECT COUNT(*) FROM `SaleItem` si JOIN `Sale` s ON s.`SaleId` = si.`SaleId`;Show more lines
SaleItem → Recording
SQLSELECT COUNT(*) FROM `SaleItem`;SELECT COUNT(*) FROM `SaleItem` si JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`;Show more lines

M:N joins — row count should equal the bridge table count
CollectionItem (bridge)
SQLSELECT COUNT(*) FROM `CollectionItem`;SELECT COUNT(*) FROM `CollectionItem` ciJOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId`JOIN `Recording` r ON r.`RecordingId` = ci.`RecordingId`;Show more lines
SaleItem (bridge)
SQLSELECT COUNT(*) FROM `SaleItem`;SELECT COUNT(*) FROM `SaleItem` siJOIN `Sale` s ON s.`SaleId` = si.`SaleId`JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`;Show more lines

4. How to interpret the results
If the join row count is the same as the child’s count GREAT — join behaves as expected.
If the join row count is less than the child’s count This happens with optional foreign keys (NULL fk values). Not a problem.
If the join row count is greater than the child’s count Unexpected row multiplication
This signals:
Duplicate parent keys
Hidden many‑to‑many
Bad data
Incorrect join key
Incorrect relationship assumption
This is EXACTLY what the question wants you to detect.

Evalutaion:
Ai did great during this assignment. It was extremely helpful when giving code because typing eveything in would have been terrible. On the later task it took a long time to get the bare bone answer and no fluff. The ai was like a student that has way too much knowledge and wants to show off. This was ok when understanding the key points of this assignment, but when it got to the code it did it in a way that was un-neccessarily long. 

### SQL Log
sed "s/\\\040/ /g" < ~/.mysql_history
_HiStOrY_V2_
USE COSC315DD;
show tables
;
DESC Client;
SHOW CREATE TABLE Collection\134G;
SHOW CREATE TABLE Creator\134G;
SHOW CREATE TABLE CollectionItem\134G;
CREATE TABLE `CollectionItem` (
  `CollectionId` int NOT NULL,
  `RecordingId` int NOT NULL,
  PRIMARY KEY (`CollectionId`,`RecordingId`),
  KEY `IFK_PlaylistTrackPlaylistId` (`CollectionId`),
  KEY `IFK_PlaylistTrackTrackId` (`RecordingId`),
  CONSTRAINT `FK_PlaylistTrackPlaylistId` FOREIGN KEY (`CollectionId`) REFERENCES `Collection` (`CollectionId`),
  CONSTRAINT `FK_PlaylistTrackTrackId` FOREIGN KEY (`RecordingId`) REFERENCES `Recording` (`RecordingId`)
;
CREATE TABLE `CollectionItem` (   `CollectionId` int NOT NULL,   `RecordingId` int NOT NULL,   PRIMARY KEY (`CollectionId`,`RecordingId`),   KEY `IFK_PlaylistTrackPlaylistId` (`CollectionId`),   KEY `IFK_PlaylistTrackTrackId` (`RecordingId`),   CONSTRAINT `FK_PlaylistTrackPlaylistId` FOREIGN KEY (`CollectionId`) REFERENCES `Collection` (`CollectionId`),   CONSTRAINT `FK_PlaylistTrackTrackId` FOREIGN KEY (`RecordingId`) REFERENCES `Recording` (`RecordingId`);
SHOW CREATE TABLE Format\134G;
SHOW CREATE TABLE Recording\134G;
SHOW CREATE TABLE Release\134G;
SHOW CREATE TABLE 'Release'\134G;
SHOW TABLE `Release`\134G;
 SHOW CREATE TABLE `Release`\134G;
SHOW CREATE TABLE `Sale`\134G;
SHOW CREATE TABLE `SaleItem`\134G;
SHOW CREATE TABLE `Staff`\134G;
SHOW CREATE TABLE `Style`\134G;
SHOW CREATE TABLE `Client`\134G;
USE COSC315DD;
SELECT CreatorId, COUNT(*) AS releases_per_creator
FROM Release
GROUP BY CreatorId
ORDER BY releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator FROM Release GROUP BY CreatorId ORDER BY releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator
FROM Release
GROUP BY CreatorId
ORDER BY releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator FROM Release GROUP BY CreatorId ORDER BY releases_per_creator DESC;
select CreatorId, Count(*) from Release group by CreatorId order by releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator
FROM Release
GROUP BY CreatorId
ORDER BY releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator FROM Release GROUP BY CreatorId ORDER BY releases_per_creator DESC;
select CreatorId, Count(*) from `Release` group by CreatorId order by releases_per_creator DESC;
show tables;
SELECT COUNT(*)
FROM `Release` r
JOIN `Creator` c on c.CreatorId = r.CreatorId;
SELECT COUNT(*) FROM `Release` r JOIN `Creator` c on c.CreatorId = r.CreatorId;
SELECT  `CreatorId`, COUNT(*)
FROM `Release`
GROUP BY  CreatorID
Order By releases_per_creator DESC;
SELECT  `CreatorId`, COUNT(*) FROM `Release` GROUP BY  CreatorID Order By releases_per_creator DESC;
SELECT  `CreatorId`, COUNT(*) as releases_per_creator
 FROM `Release`
    -> GROUP BY  CreatorID
SELECT COUNT(*) FROM `Release` r JOIN `Creator` c on c.CreatorId = r.CreatorId;
SELECT  `CreatorId`, COUNT(*) as releases_per_creator  FROM `Release`     -> GROUP BY  CreatorID SELECT COUNT(*) FROM `Release` r JOIN `Creator` c on c.CreatorId = r.CreatorId;
SELECT CreatorId, COUNT(*) AS releases_per_creator
FROM Release
GROUP BY CreatorId
ORDER BY releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator FROM Release GROUP BY CreatorId ORDER BY releases_per_creator DESC;
ELECT CreatorId, COUNT(*) AS releases_per_creator
From `Release`
GROUP BY CreatorId
;
ELECT CreatorId, COUNT(*) AS releases_per_creator From `Release` GROUP BY CreatorId;
SELECT CreatorId, COUNT(*) AS releases_per_creator
From `Release
;
'
SELECT COUNT(*)
USE COSC315DD;
SELECT CreatorId, COUNT(*) AS releases_per_creator
FROM `Release` GROUP BY CreatorID
ORDER BY releases_per_creator DESC;
SELECT CreatorId, COUNT(*) AS releases_per_creator FROM `Release` GROUP BY CreatorID ORDER BY releases_per_creator DESC;
SELECT COUNT(*) 
FROM `Release` r
JOIN Creator c ON c.CreatorId = r.CreatorId;
SELECT COUNT(*)  FROM `Release` r JOIN Creator c ON c.CreatorId = r.CreatorId;
SELECT SaleId, RecordingId, COUNT(*) 
FROM SaleItem
GROUP BY SaleId, RecordingId
HAVING COUNT(*) > 1;
SELECT SaleId, RecordingId, COUNT(*)  FROM SaleItem GROUP BY SaleId, RecordingId HAVING COUNT(*) > 1;
SELECT RecordingId FROM `Recording`
WHERE ReleaseId IS NOT NULL
AND ReleaseId NOT IN (SELECT ReleaseId FROM `Release`);
SELECT RecordingId FROM `Recording` WHERE ReleaseId IS NOT NULL AND ReleaseId NOT IN (SELECT ReleaseId FROM `Release`);
select ReleaseeId from `Recording`;
select ReleaseId from `Recording`;
SELECT
  (SELECT COUNT(*) FROM Recording WHERE ReleaseId IS NULL) AS Recording_ReleaseId_NULLs,
  (SELECT COUNT(*) FROM Recording WHERE StyleId IS NULL)   AS Recording_StyleId_NULLs,
  (SELECT COUNT(*) FROM Client    WHERE AccountRepId IS NULL) AS Client_AccountRepId_NULLs,
  (SELECT COUNT(*) FROM Staff     WHERE ManagerId IS NULL) AS Staff_ManagerId_NULLs;
SELECT   (SELECT COUNT(*) FROM Recording WHERE ReleaseId IS NULL) AS Recording_ReleaseId_NULLs,   (SELECT COUNT(*) FROM Recording WHERE StyleId IS NULL)   AS Recording_StyleId_NULLs,   (SELECT COUNT(*) FROM Client    WHERE AccountRepId IS NULL) AS Client_AccountRepId_NULLs,   (SELECT COUNT(*) FROM Staff     WHERE ManagerId IS NULL) AS Staff_ManagerId_NULLs;
Select * Staff where ManagerId IS NULL;
SELECT *
FROM Staff
WHERE ManagerId IS NULL;
SELECT * FROM Staff WHERE ManagerId IS NULL;
SELECT SaleId, RecordingId, COUNT(*) 
FROM SaleItem
GROUP BY SaleId, RecordingId
HAVING COUNT(*) > 1;
SELECT SaleId, RecordingId, COUNT(*)  FROM SaleItem GROUP BY SaleId, RecordingId HAVING COUNT(*) > 1;
SELECT RecordingId FROM Recording
WHERE ReleaseId IS NOT NULL
AND ReleaseId NOT IN (SELECT ReleaseId FROM Release);
SELECT RecordingId FROM Recording WHERE ReleaseId IS NOT NULL AND ReleaseId NOT IN (SELECT ReleaseId FROM Release);
USE COSC315DD;
SELECT
  (SELECT COUNT(*) FROM `Creator`)        AS `n_creator`,
  (SELECT COUNT(*) FROM `Release`)        AS `n_release`,
  (SELECT COUNT(*) FROM `Recording`)      AS `n_recording`,
  (SELECT COUNT(*) FROM `Format`)         AS `n_format`,
  (SELECT COUNT(*) FROM `Style`)          AS `n_style`,
  (SELECT COUNT(*) FROM `Collection`)     AS `n_collection`,
  (SELECT COUNT(*) FROM `CollectionItem`) AS `n_collectionitem`,
  (SELECT COUNT(*) FROM `Client`)         AS `n_client`,
  (SELECT COUNT(*) FROM `Sale`)           AS `n_sale`,
  (SELECT COUNT(*) FROM `SaleItem`)       AS `n_saleitem`,
  (SELECT COUNT(*) FROM `Staff`)          AS `n_staff`;
SELECT   (SELECT COUNT(*) FROM `Creator`)        AS `n_creator`,   (SELECT COUNT(*) FROM `Release`)        AS `n_release`,   (SELECT COUNT(*) FROM `Recording`)      AS `n_recording`,   (SELECT COUNT(*) FROM `Format`)         AS `n_format`,   (SELECT COUNT(*) FROM `Style`)          AS `n_style`,   (SELECT COUNT(*) FROM `Collection`)     AS `n_collection`,   (SELECT COUNT(*) FROM `CollectionItem`) AS `n_collectionitem`,   (SELECT COUNT(*) FROM `Client`)         AS `n_client`,   (SELECT COUNT(*) FROM `Sale`)           AS `n_sale`,   (SELECT COUNT(*) FROM `SaleItem`)       AS `n_saleitem`,   (SELECT COUNT(*) FROM `Staff`)          AS `n_staff`;
SELECT 'rec_join_format_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `Recording` AS `r`
JOIN `Format`    AS `f` ON `f`.`FormatId` = `r`.`FormatId`;
SELECT 'rec_join_format_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `Recording` AS `r` JOIN `Format`    AS `f` ON `f`.`FormatId` = `r`.`FormatId`;
SELECT 'rec_join_format_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `Recording` AS `r`
JOIN `Format`    AS `f` ON `f`.`FormatId` = `r`.`FormatId`;
SELECT 'rec_join_format_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `Recording` AS `r` JOIN `Format`    AS `f` ON `f`.`FormatId` = `r`.`FormatId`;
SELECT 'rec_join_release_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `Recording` AS `r`
JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT 'rec_join_release_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `Recording` AS `r` JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT 'rec_join_style_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `Recording` AS `r`
JOIN `Style`     AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT 'rec_join_style_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `Recording` AS `r` JOIN `Style`     AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT 'rel_join_creator_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `Release` AS `rel`
JOIN `Creator` AS `c` ON `c`.`CreatorId` = `rel`.`CreatorId`;
SELECT 'rel_join_creator_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `Release` AS `rel` JOIN `Creator` AS `c` ON `c`.`CreatorId` = `rel`.`CreatorId`;
SELECT 'saleitem_join_sale_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `SaleItem` AS `si`
JOIN `Sale`     AS `s` ON `s`.`SaleId` = `si`.`SaleId`;
SELECT 'saleitem_join_sale_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `SaleItem` AS `si` JOIN `Sale`     AS `s` ON `s`.`SaleId` = `si`.`SaleId`;
SELECT 'saleitem_join_recording_inner' AS `test_name`,
       COUNT(*) AS `rows_after_join`
FROM `SaleItem` AS `si`
JOIN `Recording` AS `r` ON `r`.`RecordingId` = `si`.`RecordingId`;
SELECT 'saleitem_join_recording_inner' AS `test_name`,        COUNT(*) AS `rows_after_join` FROM `SaleItem` AS `si` JOIN `Recording` AS `r` ON `r`.`RecordingId` = `si`.`RecordingId`;
SELECT 'collectionitem_bridge_rows' AS `test_name`,
       COUNT(*) AS `n_bridge`
FROM `CollectionItem`;
SELECT 'collectionitem_bridge_rows' AS `test_name`,        COUNT(*) AS `n_bridge` FROM `CollectionItem`;
SELECT 'collectionitem_full_join' AS `test_name`,
       COUNT(*) AS `rows_joined`
FROM `CollectionItem` AS `ci`
JOIN `Collection`    AS `c`  ON `c`.`CollectionId`   = `ci`.`CollectionId`
JOIN `Recording`     AS `r`  ON `r`.`RecordingId`    = `ci`.`RecordingId`;
SELECT 'collectionitem_full_join' AS `test_name`,        COUNT(*) AS `rows_joined` FROM `CollectionItem` AS `ci` JOIN `Collection`    AS `c`  ON `c`.`CollectionId`   = `ci`.`CollectionId` JOIN `Recording`     AS `r`  ON `r`.`RecordingId`    = `ci`.`RecordingId`;
SELECT 'saleitem_bridge_rows' AS `test_name`,
       COUNT(*) AS `n_bridge`
FROM `SaleItem`;
SELECT 'saleitem_bridge_rows' AS `test_name`,        COUNT(*) AS `n_bridge` FROM `SaleItem`;
SELECT 'saleitem_full_join' AS `test_name`,
       COUNT(*) AS `rows_joined`
FROM `SaleItem`  AS `si`
JOIN `Sale`      AS `s`  ON `s`.`SaleId`       = `si`.`SaleId`
JOIN `Recording` AS `r`  ON `r`.`RecordingId`  = `si`.`RecordingId`;
SELECT 'saleitem_full_join' AS `test_name`,        COUNT(*) AS `rows_joined` FROM `SaleItem`  AS `si` JOIN `Sale`      AS `s`  ON `s`.`SaleId`       = `si`.`SaleId` JOIN `Recording` AS `r`  ON `r`.`RecordingId`  = `si`.`RecordingId`;
SELECT *
FROM `Recording` AS r
LEFT JOIN `Release` AS rel ON rel.`ReleaseId` = r.`ReleaseId`
WHERE r.`ReleaseId` IS NOT NULL
  AND rel.`ReleaseId` IS NULL;
SELECT * FROM `Recording` AS r LEFT JOIN `Release` AS rel ON rel.`ReleaseId` = r.`ReleaseId` WHERE r.`ReleaseId` IS NOT NULL   AND rel.`ReleaseId` IS NULL;
SELECT *
FROM `Recording` AS r
LEFT JOIN `Style` AS s ON s.`StyleId` = r.`StyleId`
WHERE r.`StyleId` IS NOT NULL
  AND s.`StyleId` IS NULL;
SELECT * FROM `Recording` AS r LEFT JOIN `Style` AS s ON s.`StyleId` = r.`StyleId` WHERE r.`StyleId` IS NOT NULL   AND s.`StyleId` IS NULL;
SELECT *
FROM `Recording` AS r
LEFT JOIN `Format` AS f ON f.`FormatId` = r.`FormatId`
WHERE f.`FormatId` IS NULL;
SELECT * FROM `Recording` AS r LEFT JOIN `Format` AS f ON f.`FormatId` = r.`FormatId` WHERE f.`FormatId` IS NULL;
SELECT *
FROM `Release` AS rel
LEFT JOIN `Creator` AS c ON c.`CreatorId` = rel.`CreatorId`
WHERE c.`CreatorId` IS NULL;
SELECT * FROM `Release` AS rel LEFT JOIN `Creator` AS c ON c.`CreatorId` = rel.`CreatorId` WHERE c.`CreatorId` IS NULL;
SELECT *
FROM `CollectionItem` AS ci
LEFT JOIN `Collection` AS c ON c.`CollectionId` = ci.`CollectionId`
WHERE c.`CollectionId` IS NULL;
SELECT * FROM `CollectionItem` AS ci LEFT JOIN `Collection` AS c ON c.`CollectionId` = ci.`CollectionId` WHERE c.`CollectionId` IS NULL;
SELECT *
FROM `CollectionItem` AS ci
LEFT JOIN `Recording` AS r ON r.`RecordingId` = ci.`RecordingId`
WHERE r.`RecordingId` IS NULL;
SELECT * FROM `CollectionItem` AS ci LEFT JOIN `Recording` AS r ON r.`RecordingId` = ci.`RecordingId` WHERE r.`RecordingId` IS NULL;
SELECT *
FROM `SaleItem` AS si
LEFT JOIN `Sale` AS s ON s.`SaleId` = si.`SaleId`
WHERE s.`SaleId` IS NULL;
SELECT * FROM `SaleItem` AS si LEFT JOIN `Sale` AS s ON s.`SaleId` = si.`SaleId` WHERE s.`SaleId` IS NULL;
SELECT *
FROM `SaleItem` AS si
LEFT JOIN `Recording` AS r ON r.`RecordingId` = si.`RecordingId`
WHERE r.`RecordingId` IS NULL;
SELECT * FROM `SaleItem` AS si LEFT JOIN `Recording` AS r ON r.`RecordingId` = si.`RecordingId` WHERE r.`RecordingId` IS NULL;
SELECT *
FROM `Sale` AS s
LEFT JOIN `Client` AS c ON c.`ClientId` = s.`ClientId`
WHERE c.`ClientId` IS NULL;
SELECT * FROM `Sale` AS s LEFT JOIN `Client` AS c ON c.`ClientId` = s.`ClientId` WHERE c.`ClientId` IS NULL;
SELECT *
FROM `Client` AS c
LEFT JOIN `Staff` AS st ON st.`StaffId` = c.`AccountRepId`
WHERE c.`AccountRepId` IS NOT NULL
  AND st.`StaffId` IS NULL;
SELECT * FROM `Client` AS c LEFT JOIN `Staff` AS st ON st.`StaffId` = c.`AccountRepId` WHERE c.`AccountRepId` IS NOT NULL   AND st.`StaffId` IS NULL;
SELECT *
FROM `Staff` AS s
LEFT JOIN `Staff` AS mgr ON mgr.`StaffId` = s.`ManagerId`
WHERE s.`ManagerId` IS NOT NULL
  AND mgr.`StaffId` IS NULL;
SELECT * FROM `Staff` AS s LEFT JOIN `Staff` AS mgr ON mgr.`StaffId` = s.`ManagerId` WHERE s.`ManagerId` IS NOT NULL   AND mgr.`StaffId` IS NULL;
SELECT `CreatorId`, COUNT(*) AS `releases_per_creator`
FROM `Release`
GROUP BY `CreatorId`
ORDER BY `releases_per_creator` DESC
LIMIT 10;
SELECT `CreatorId`, COUNT(*) AS `releases_per_creator` FROM `Release` GROUP BY `CreatorId` ORDER BY `releases_per_creator` DESC LIMIT 10;
-- Baseline (child)
SELECT COUNT(*) AS `n_release` FROM `Release`;
-- Join count
SELECT COUNT(*) AS `rows_after_join`
FROM `Release` AS `rel`
JOIN `Creator` AS `c` ON `c`.`CreatorId` = `rel`.`CreatorId`;
SELECT COUNT(*) AS `rows_after_join` FROM `Release` AS `rel` JOIN `Creator` AS `c` ON `c`.`CreatorId` = `rel`.`CreatorId`;
-- Distinct child ids after join (should equal rows_after_join)
SELECT COUNT(DISTINCT `rel`.`ReleaseId`) AS `distinct_release_after_join`
FROM `Release` AS `rel`
JOIN `Creator` AS `c` ON `c`.`CreatorId` = `rel`.`CreatorId`;
SELECT COUNT(DISTINCT `rel`.`ReleaseId`) AS `distinct_release_after_join` FROM `Release` AS `rel` JOIN `Creator` AS `c` ON `c`.`CreatorId` = `rel`.`CreatorId`;
-- Baseline (child)
SELECT COUNT(*) AS `n_recording` FROM `Recording`;
-- Join count (INNER drops rows where Recording.ReleaseId IS NULL)
SELECT COUNT(*) AS `rows_after_inner_join`
FROM `Recording` AS `r`
JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(*) AS `rows_after_inner_join` FROM `Recording` AS `r` JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
-- Distinct child ids after join
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_inner`
FROM `Recording` AS `r`
JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_inner` FROM `Recording` AS `r` JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
-- Left join fan-out check (should equal n_recording and not duplicate child ids)
SELECT COUNT(*) AS `rows_after_left_join`
FROM `Recording` AS `r`
LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(*) AS `rows_after_left_join` FROM `Recording` AS `r` LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_left`
FROM `Recording` AS `r`
LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_left` FROM `Recording` AS `r` LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
-- Baseline (child)
SELECT COUNT(*) AS `n_recording` FROM `Recording`;
-- Join count (INNER drops rows where Recording.ReleaseId IS NULL)
SELECT COUNT(*) AS `rows_after_inner_join`
FROM `Recording` AS `r`
JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(*) AS `rows_after_inner_join` FROM `Recording` AS `r` JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
-- Distinct child ids after join
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_inner`
FROM `Recording` AS `r`
JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_inner` FROM `Recording` AS `r` JOIN `Release`  AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
-- Left join fan-out check (should equal n_recording and not duplicate child ids)
SELECT COUNT(*) AS `rows_after_left_join`
FROM `Recording` AS `r`
LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(*) AS `rows_after_left_join` FROM `Recording` AS `r` LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_left`
FROM `Recording` AS `r`
LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_left` FROM `Recording` AS `r` LEFT JOIN `Release` AS `rel` ON `rel`.`ReleaseId` = `r`.`ReleaseId`;
SELECT COUNT(*) AS `n_recording` FROM `Recording`;
SELECT COUNT(*) AS `rows_after_inner_join`
FROM `Recording` AS `r`
JOIN `Style`    AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(*) AS `rows_after_inner_join` FROM `Recording` AS `r` JOIN `Style`    AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_inner`
FROM `Recording` AS `r`
JOIN `Style`    AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_inner` FROM `Recording` AS `r` JOIN `Style`    AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(*) AS `rows_after_left_join`
FROM `Recording` AS `r`
LEFT JOIN `Style` AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(*) AS `rows_after_left_join` FROM `Recording` AS `r` LEFT JOIN `Style` AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_left`
FROM `Recording` AS `r`
LEFT JOIN `Style` AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(DISTINCT `r`.`RecordingId`) AS `distinct_recording_after_left` FROM `Recording` AS `r` LEFT JOIN `Style` AS `s` ON `s`.`StyleId` = `r`.`StyleId`;
SELECT COUNT(*) AS `n_sale` FROM `Sale`;
SELECT COUNT(*) AS `rows_after_join`
FROM `Sale` AS `s`
JOIN `Client` AS `c` ON `c`.`ClientId` = `s`.`ClientId`;
SELECT COUNT(*) AS `rows_after_join` FROM `Sale` AS `s` JOIN `Client` AS `c` ON `c`.`ClientId` = `s`.`ClientId`;
SELECT COUNT(DISTINCT `s`.`SaleId`) AS `distinct_sale_after_join`
FROM `Sale` AS `s`
JOIN `Client` AS `c` ON `c`.`ClientId` = `s`.`ClientId`;
SELECT COUNT(DISTINCT `s`.`SaleId`) AS `distinct_sale_after_join` FROM `Sale` AS `s` JOIN `Client` AS `c` ON `c`.`ClientId` = `s`.`ClientId`;
SELECT COUNT(*) AS `n_saleitem` FROM `SaleItem`;
SELECT COUNT(*) AS `rows_after_join`
FROM `SaleItem` AS `si`
JOIN `Sale`     AS `s` ON `s`.`SaleId` = `si`.`SaleId`;
SELECT COUNT(*) AS `rows_after_join` FROM `SaleItem` AS `si` JOIN `Sale`     AS `s` ON `s`.`SaleId` = `si`.`SaleId`;
SELECT COUNT(DISTINCT `si`.`SaleItemId`) AS `distinct_saleitem_after_join`
FROM `SaleItem` AS `si`
JOIN `Sale`     AS `s` ON `s`.`SaleId` = `si`.`SaleId`;
SELECT COUNT(DISTINCT `si`.`SaleItemId`) AS `distinct_saleitem_after_join` FROM `SaleItem` AS `si` JOIN `Sale`     AS `s` ON `s`.`SaleId` = `si`.`SaleId`;
SELECT COUNT(*) AS `n_staff` FROM `Staff`;
SELECT COUNT(*) AS `rows_after_inner_join`
FROM `Staff` AS `s`
JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(*) AS `rows_after_inner_join` FROM `Staff` AS `s` JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(DISTINCT `s`.`StaffId`) AS `distinct_staff_after_inner`
FROM `Staff` AS `s`
JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(DISTINCT `s`.`StaffId`) AS `distinct_staff_after_inner` FROM `Staff` AS `s` JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(*) AS `rows_after_left_join`
FROM `Staff` AS `s`
LEFT JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(*) AS `rows_after_left_join` FROM `Staff` AS `s` LEFT JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(DISTINCT `s`.`StaffId`) AS `distinct_staff_after_left`
FROM `Staff` AS `s`
LEFT JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(DISTINCT `s`.`StaffId`) AS `distinct_staff_after_left` FROM `Staff` AS `s` LEFT JOIN `Staff` AS `m` ON `m`.`StaffId` = `s`.`ManagerId`;
SELECT COUNT(*) AS `n_client` FROM `Client`;
SELECT COUNT(*) AS `rows_after_inner_join`
FROM `Client` AS `c`
JOIN `Staff`  AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(*) AS `rows_after_inner_join` FROM `Client` AS `c` JOIN `Staff`  AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(DISTINCT `c`.`ClientId`) AS `distinct_client_after_inner`
FROM `Client` AS `c`
JOIN `Staff`  AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(DISTINCT `c`.`ClientId`) AS `distinct_client_after_inner` FROM `Client` AS `c` JOIN `Staff`  AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(*) AS `rows_after_left_join`
FROM `Client` AS `c`
LEFT JOIN `Staff` AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(*) AS `rows_after_left_join` FROM `Client` AS `c` LEFT JOIN `Staff` AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(DISTINCT `c`.`ClientId`) AS `distinct_client_after_left`
FROM `Client` AS `c`
LEFT JOIN `Staff` AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
SELECT COUNT(DISTINCT `c`.`ClientId`) AS `distinct_client_after_left` FROM `Client` AS `c` LEFT JOIN `Staff` AS `st` ON `st`.`StaffId` = `c`.`AccountRepId`;
-- Baseline bridge size
SELECT COUNT(*) AS `n_collectionitem` FROM `CollectionItem`;
-- Full join across bridge
SELECT COUNT(*) AS `rows_joined`
FROM `CollectionItem` AS `ci`
JOIN `Collection`    AS `c` ON `c`.`CollectionId` = `ci`.`CollectionId`
JOIN `Recording`     AS `r` ON `r`.`RecordingId`  = `ci`.`RecordingId`;
SELECT COUNT(*) AS `rows_joined` FROM `CollectionItem` AS `ci` JOIN `Collection`    AS `c` ON `c`.`CollectionId` = `ci`.`CollectionId` JOIN `Recording`     AS `r` ON `r`.`RecordingId`  = `ci`.`RecordingId`;
-- Sanity: distinct pairs should equal bridge rows (composite PK ensures it)
SELECT COUNT(*) AS `pairs_in_bridge`
FROM `CollectionItem`;
SELECT COUNT(*) AS `pairs_in_bridge` FROM `CollectionItem`;
SELECT COUNT(*) AS `pairs_after_join`
FROM (
  SELECT `ci`.`CollectionId`, `ci`.`RecordingId`
  FROM `CollectionItem` AS `ci`
  JOIN `Collection`    AS `c` ON `c`.`CollectionId` = `ci`.`CollectionId`
  JOIN `Recording`     AS `r` ON `r`.`RecordingId`  = `ci`.`RecordingId`
) x;
SELECT COUNT(*) AS `pairs_after_join` FROM (   SELECT `ci`.`CollectionId`, `ci`.`RecordingId`   FROM `CollectionItem` AS `ci`   JOIN `Collection`    AS `c` ON `c`.`CollectionId` = `ci`.`CollectionId`   JOIN `Recording`     AS `r` ON `r`.`RecordingId`  = `ci`.`RecordingId` ) x;
-- Baseline bridge size
SELECT COUNT(*) AS `n_saleitem` FROM `SaleItem`;
-- Full join across bridge
SELECT COUNT(*) AS `rows_joined`
FROM `SaleItem`  AS `si`
JOIN `Sale`      AS `s` ON `s`.`SaleId`      = `si`.`SaleId`
JOIN `Recording` AS `r` ON `r`.`RecordingId` = `si`.`RecordingId`;
SELECT COUNT(*) AS `rows_joined` FROM `SaleItem`  AS `si` JOIN `Sale`      AS `s` ON `s`.`SaleId`      = `si`.`SaleId` JOIN `Recording` AS `r` ON `r`.`RecordingId` = `si`.`RecordingId`;
-- Distinct pairs vs bridge size (schema allows duplicates unless constrained)
SELECT COUNT(*) AS `pairs_in_bridge`
FROM (
  SELECT `SaleId`, `RecordingId`
  FROM `SaleItem`
  GROUP BY `SaleId`, `RecordingId`
) t;
SELECT COUNT(*) AS `pairs_in_bridge` FROM (   SELECT `SaleId`, `RecordingId`   FROM `SaleItem`   GROUP BY `SaleId`, `RecordingId` ) t;
SELECT COUNT(*) AS `pairs_after_join`
FROM (
  SELECT `si`.`SaleId`, `si`.`RecordingId`
  FROM `SaleItem`  AS `si`
  JOIN `Sale`      AS `s` ON `s`.`SaleId`      = `si`.`SaleId`
  JOIN `Recording` AS `r` ON `r`.`RecordingId` = `si`.`RecordingId`
  GROUP BY `si`.`SaleId`, `si`.`RecordingId`
) t;
SELECT COUNT(*) AS `pairs_after_join` FROM (   SELECT `si`.`SaleId`, `si`.`RecordingId`   FROM `SaleItem`  AS `si`   JOIN `Sale`      AS `s` ON `s`.`SaleId`      = `si`.`SaleId`   JOIN `Recording` AS `r` ON `r`.`RecordingId` = `si`.`RecordingId`   GROUP BY `si`.`SaleId`, `si`.`RecordingId` ) t;
USE COSC315DD;
SELECT COUNT(*) FROM `Recording`;
SELECT COUNT(DISTINCT `FormatId`) FROM `Recording`;
SELECT `CreatorId`, COUNT(*)
FROM `Release`
GROUP BY `CreatorId`
ORDER BY COUNT(*) DESC
LIMIT 5;
SELECT `CreatorId`, COUNT(*) FROM `Release` GROUP BY `CreatorId` ORDER BY COUNT(*) DESC LIMIT 5;
-- List the concrete rows that are duplicates for each duplicated pair
SELECT
  si.`SaleItemId`,
  si.`SaleId`,
  si.`RecordingId`,
  si.`Quantity`,
  si.`ItemPrice`
FROM `SaleItem` AS si
JOIN (
  SELECT `SaleId`, `RecordingId`
  FROM `SaleItem`
  GROUP BY `SaleId`, `RecordingId`
  HAVING COUNT(*) > 1
) d
  ON d.`SaleId` = si.`SaleId`
 AND d.`RecordingId` = si.`RecordingId`
ORDER BY si.`SaleId`, si.`RecordingId`, si.`SaleItemId`;
SELECT   si.`SaleItemId`,   si.`SaleId`,   si.`RecordingId`,   si.`Quantity`,   si.`ItemPrice` FROM `SaleItem` AS si JOIN (   SELECT `SaleId`, `RecordingId`   FROM `SaleItem`   GROUP BY `SaleId`, `RecordingId`   HAVING COUNT(*) > 1 ) d   ON d.`SaleId` = si.`SaleId`  AND d.`RecordingId` = si.`RecordingId` ORDER BY si.`SaleId`, si.`RecordingId`, si.`SaleItemId`;
-- Compare total SaleItem rows vs distinct (SaleId, RecordingId) pairs
SELECT
  (SELECT COUNT(*) FROM `SaleItem`) AS `rows_total`,
  (SELECT COUNT(*) FROM (
      SELECT `SaleId`, `RecordingId`
      FROM `SaleItem`
      GROUP BY `SaleId`, `RecordingId`
  ) t) AS `distinct_pairs`,
  (SELECT COUNT(*) FROM `SaleItem`) -
  (SELECT COUNT(*) FROM (
      SELECT `SaleId`, `RecordingId`
      FROM `SaleItem`
      GROUP BY `SaleId`, `RecordingId`
  ) t) AS `extra_rows_due_to_duplicates`;
SELECT   (SELECT COUNT(*) FROM `SaleItem`) AS `rows_total`,   (SELECT COUNT(*) FROM (       SELECT `SaleId`, `RecordingId`       FROM `SaleItem`       GROUP BY `SaleId`, `RecordingId`   ) t) AS `distinct_pairs`,   (SELECT COUNT(*) FROM `SaleItem`) -   (SELECT COUNT(*) FROM (       SELECT `SaleId`, `RecordingId`       FROM `SaleItem`       GROUP BY `SaleId`, `RecordingId`   ) t) AS `extra_rows_due_to_duplicates`;
USE COSC315DD;
-- Top creators by release count + share of all releases
SELECT
  rel.`CreatorId`,
  c.`Name`,
  COUNT(*) AS `releases`,
  ROUND(100 * COUNT(*) / t.`total_releases`, 2) AS `pct_of_all_releases`
FROM `Release` rel
JOIN `Creator` c ON c.`CreatorId` = rel.`CreatorId`
JOIN (SELECT COUNT(*) AS `total_releases` FROM `Release`) t
GROUP BY rel.`CreatorId`, c.`Name`, t.`total_releases`
ORDER BY `releases` DESC
LIMIT 10;
SELECT   rel.`CreatorId`,   c.`Name`,   COUNT(*) AS `releases`,   ROUND(100 * COUNT(*) / t.`total_releases`, 2) AS `pct_of_all_releases` FROM `Release` rel JOIN `Creator` c ON c.`CreatorId` = rel.`CreatorId` JOIN (SELECT COUNT(*) AS `total_releases` FROM `Release`) t GROUP BY rel.`CreatorId`, c.`Name`, t.`total_releases` ORDER BY `releases` DESC LIMIT 10;
-- Share of each format across all recordings
SELECT
  r.`FormatId`,
  f.`Name` AS `FormatName`,
  COUNT(*) AS `recordings`,
  ROUND(100 * COUNT(*) / t.`total_recordings`, 2) AS `pct_of_all_recordings`
FROM `Recording` r
JOIN `Format` f ON f.`FormatId` = r.`FormatId`
JOIN (SELECT COUNT(*) AS `total_recordings` FROM `Recording`) t
GROUP BY r.`FormatId`, f.`Name`, t.`total_recordings`
ORDER BY `recordings` DESC;
SELECT   r.`FormatId`,   f.`Name` AS `FormatName`,   COUNT(*) AS `recordings`,   ROUND(100 * COUNT(*) / t.`total_recordings`, 2) AS `pct_of_all_recordings` FROM `Recording` r JOIN `Format` f ON f.`FormatId` = r.`FormatId` JOIN (SELECT COUNT(*) AS `total_recordings` FROM `Recording`) t GROUP BY r.`FormatId`, f.`Name`, t.`total_recordings` ORDER BY `recordings` DESC;
-- Quick domain size (how many formats total?)
SELECT COUNT(DISTINCT `FormatId`) AS `distinct_formats`,
       COUNT(*) AS `total_recordings`
FROM `Recording`;
SELECT COUNT(DISTINCT `FormatId`) AS `distinct_formats`,        COUNT(*) AS `total_recordings` FROM `Recording`;
-- Top recordings by revenue and their % of total
SELECT
  r.`RecordingId`,
  r.`Name` AS `RecordingName`,
  SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,
  ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue`
FROM `SaleItem` si
JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`
JOIN (SELECT SUM(si2.`Quantity` * si2.`ItemPrice`) AS `total_revenue` FROM `SaleItem` si2) t
GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue`
ORDER BY `revenue` DESC
LIMIT 10;
SELECT   r.`RecordingId`,   r.`Name` AS `RecordingName`,   SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,   ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue` FROM `SaleItem` si JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId` JOIN (SELECT SUM(si2.`Quantity` * si2.`ItemPrice`) AS `total_revenue` FROM `SaleItem` si2) t GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue` ORDER BY `revenue` DESC LIMIT 10;
-- (Optional) cumulative share of revenue across ranked recordings (MySQL 8+)
WITH rec_rev AS (
  SELECT r.`RecordingId`, r.`Name` AS `RecordingName`,
         SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`
  FROM `SaleItem` si
  JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`
  GROUP BY r.`RecordingId`, r.`Name`
),
tot AS (SELECT SUM(`revenue`) AS `total_revenue` FROM rec_rev)
SELECT
  rr.`RecordingId`, rr.`RecordingName`, rr.`revenue`,
  ROUND(100 * rr.`revenue` / tot.`total_revenue`, 2) AS `pct_of_total`,
  ROUND(100 * SUM(rr.`revenue`) OVER (ORDER BY rr.`revenue` DESC) / tot.`total_revenue`, 2) AS `cum_pct`
FROM rec_rev rr
CROSS JOIN tot
ORDER BY rr.`revenue` DESC
LIMIT 20;
WITH rec_rev AS (   SELECT r.`RecordingId`, r.`Name` AS `RecordingName`,          SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`   FROM `SaleItem` si   JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`   GROUP BY r.`RecordingId`, r.`Name` ), tot AS (SELECT SUM(`revenue`) AS `total_revenue` FROM rec_rev) SELECT   rr.`RecordingId`, rr.`RecordingName`, rr.`revenue`,   ROUND(100 * rr.`revenue` / tot.`total_revenue`, 2) AS `pct_of_total`,   ROUND(100 * SUM(rr.`revenue`) OVER (ORDER BY rr.`revenue` DESC) / tot.`total_revenue`, 2) AS `cum_pct` FROM rec_rev rr CROSS JOIN tot ORDER BY rr.`revenue` DESC LIMIT 20;
-- Distribution summary
SELECT
  AVG(cnt) AS `avg_recordings_per_release`,
  MIN(cnt) AS `min_recordings_per_release`,
  MAX(cnt) AS `max_recordings_per_release`
FROM (
  SELECT `ReleaseId`, COUNT(*) AS cnt
  FROM `Recording`
  GROUP BY `ReleaseId`
) x;
SELECT   AVG(cnt) AS `avg_recordings_per_release`,   MIN(cnt) AS `min_recordings_per_release`,   MAX(cnt) AS `max_recordings_per_release` FROM (   SELECT `ReleaseId`, COUNT(*) AS cnt   FROM `Recording`   GROUP BY `ReleaseId` ) x;
-- Top 10 largest releases
SELECT `ReleaseId`, COUNT(*) AS `recordings_per_release`
FROM `Recording`
GROUP BY `ReleaseId`
ORDER BY `recordings_per_release` DESC
LIMIT 10;
SELECT `ReleaseId`, COUNT(*) AS `recordings_per_release` FROM `Recording` GROUP BY `ReleaseId` ORDER BY `recordings_per_release` DESC LIMIT 10;
SELECT
  COUNT(*) AS `n_recording`,
  SUM(`StyleId` IS NULL) AS `no_style`,
  ROUND(100 * SUM(`StyleId` IS NULL) / COUNT(*), 2) AS `pct_no_style`,
  SUM(`ReleaseId` IS NULL) AS `no_release`,
  ROUND(100 * SUM(`ReleaseId` IS NULL) / COUNT(*), 2) AS `pct_no_release`
FROM `Recording`;
SELECT   COUNT(*) AS `n_recording`,   SUM(`StyleId` IS NULL) AS `no_style`,   ROUND(100 * SUM(`StyleId` IS NULL) / COUNT(*), 2) AS `pct_no_style`,   SUM(`ReleaseId` IS NULL) AS `no_release`,   ROUND(100 * SUM(`ReleaseId` IS NULL) / COUNT(*), 2) AS `pct_no_release` FROM `Recording`;
-- Top 10 collections by size
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection`
FROM `CollectionItem` ci
JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId`
GROUP BY ci.`CollectionId`, c.`Name`
ORDER BY `items_per_collection` DESC
LIMIT 10;
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection` FROM `CollectionItem` ci JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId` GROUP BY ci.`CollectionId`, c.`Name` ORDER BY `items_per_collection` DESC LIMIT 10;
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection`
FROM `CollectionItem` ci
JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId`
GROUP BY ci.`CollectionId`, c.`Name`
ORDER BY `items_per_collection` DESC
;
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection` FROM `CollectionItem` ci JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId` GROUP BY ci.`CollectionId`, c.`Name` ORDER BY `items_per_collection` DESC;
SELECT
  COUNT(*) AS `n_client`,
  SUM(`AccountRepId` IS NULL) AS `no_rep`,
  ROUND(100 * SUM(`AccountRepId` IS NULL) / COUNT(*), 2) AS `pct_no_rep`
FROM `Client`;
SELECT   COUNT(*) AS `n_client`,   SUM(`AccountRepId` IS NULL) AS `no_rep`,   ROUND(100 * SUM(`AccountRepId` IS NULL) / COUNT(*), 2) AS `pct_no_rep` FROM `Client`;
SELECT
  COUNT(*) AS `n_recording`,
  SUM(`StyleId`   IS NULL) AS `no_style`,
  ROUND(100 * SUM(`StyleId`   IS NULL) / COUNT(*), 2) AS `pct_no_style`,
  SUM(`ReleaseId` IS NULL) AS `no_release`,
  ROUND(100 * SUM(`ReleaseId` IS NULL) / COUNT(*), 2) AS `pct_no_release`
FROM `Recording`;
SELECT   COUNT(*) AS `n_recording`,   SUM(`StyleId`   IS NULL) AS `no_style`,   ROUND(100 * SUM(`StyleId`   IS NULL) / COUNT(*), 2) AS `pct_no_style`,   SUM(`ReleaseId` IS NULL) AS `no_release`,   ROUND(100 * SUM(`ReleaseId` IS NULL) / COUNT(*), 2) AS `pct_no_release` FROM `Recording`;
-- Top recordings by revenue and their % of total
SELECT
  r.`RecordingId`,
  r.`Name` AS `RecordingName`,
  SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,
  ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue`
FROM `SaleItem` si
JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`
JOIN (SELECT SUM(`Quantity` * `ItemPrice`) AS `total_revenue` FROM `SaleItem`) t
GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue`
ORDER BY `revenue` DESC
LIMIT 10;
SELECT   r.`RecordingId`,   r.`Name` AS `RecordingName`,   SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,   ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue` FROM `SaleItem` si JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId` JOIN (SELECT SUM(`Quantity` * `ItemPrice`) AS `total_revenue` FROM `SaleItem`) t GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue` ORDER BY `revenue` DESC LIMIT 10;
SELECT
  r.`RecordingId`,
  r.`Name` AS `RecordingName`,
  SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,
  ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue`
FROM `SaleItem` si
JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`
JOIN (SELECT SUM(`Quantity` * `ItemPrice`) AS `total_revenue` FROM `SaleItem`) t
GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue`
ORDER BY `revenue` DESC
;
SELECT   r.`RecordingId`,   r.`Name` AS `RecordingName`,   SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,   ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue` FROM `SaleItem` si JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId` JOIN (SELECT SUM(`Quantity` * `ItemPrice`) AS `total_revenue` FROM `SaleItem`) t GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue` ORDER BY `revenue` DESC;
-- Summary of recordings per release
SELECT
  ROUND(AVG(cnt), 2) AS `avg_recordings_per_release`,
  MIN(cnt) AS `min_recordings`,
  MAX(cnt) AS `max_recordings`
FROM (
  SELECT `ReleaseId`, COUNT(*) AS cnt
  FROM `Recording`
  GROUP BY `ReleaseId`
) x;
SELECT   ROUND(AVG(cnt), 2) AS `avg_recordings_per_release`,   MIN(cnt) AS `min_recordings`,   MAX(cnt) AS `max_recordings` FROM (   SELECT `ReleaseId`, COUNT(*) AS cnt   FROM `Recording`   GROUP BY `ReleaseId` ) x;
-- Top 10 largest releases
SELECT `ReleaseId`, COUNT(*) AS `recordings_per_release`
FROM `Recording`
GROUP BY `ReleaseId`
ORDER BY `recordings_per_release` DESC
LIMIT 10;
SELECT `ReleaseId`, COUNT(*) AS `recordings_per_release` FROM `Recording` GROUP BY `ReleaseId` ORDER BY `recordings_per_release` DESC LIMIT 10;
SELECT
  COUNT(*) AS `n_client`,
  SUM(`AccountRepId` IS NULL) AS `no_rep`,
  ROUND(100 * SUM(`AccountRepId` IS NULL) / COUNT(*), 2) AS `pct_no_rep`
FROM `Client`;
SELECT   COUNT(*) AS `n_client`,   SUM(`AccountRepId` IS NULL) AS `no_rep`,   ROUND(100 * SUM(`AccountRepId` IS NULL) / COUNT(*), 2) AS `pct_no_rep` FROM `Client`;
-- % of single-line sales and avg lines/sale
WITH lines AS (
  SELECT `SaleId`, COUNT(*) AS cnt
  FROM `SaleItem`
  GROUP BY `SaleId`
)
SELECT
  (SELECT COUNT(*) FROM `Sale`) AS `n_sales`,
  (SELECT COUNT(*) FROM lines WHERE cnt = 1) AS `single_line_sales`,
  ROUND(100 * (SELECT COUNT(*) FROM lines WHERE cnt = 1) / (SELECT COUNT(*) FROM `Sale`), 2) AS `pct_single_line`,
  ROUND(AVG(cnt), 2) AS `avg_lines_per_sale`
FROM lines;
WITH lines AS (   SELECT `SaleId`, COUNT(*) AS cnt   FROM `SaleItem`   GROUP BY `SaleId` ) SELECT   (SELECT COUNT(*) FROM `Sale`) AS `n_sales`,   (SELECT COUNT(*) FROM lines WHERE cnt = 1) AS `single_line_sales`,   ROUND(100 * (SELECT COUNT(*) FROM lines WHERE cnt = 1) / (SELECT COUNT(*) FROM `Sale`), 2) AS `pct_single_line`,   ROUND(AVG(cnt), 2) AS `avg_lines_per_sale` FROM lines;
-- Revenue by client and share of total
SELECT
  s.`ClientId`,
  CONCAT(c.`FirstName`, ' ', c.`LastName`) AS `ClientName`,
  SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,
  ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total`
FROM `SaleItem` si
JOIN `Sale` s    ON s.`SaleId`    = si.`SaleId`
JOIN `Client` c  ON c.`ClientId`  = s.`ClientId`
JOIN (SELECT SUM(`Quantity` * `ItemPrice`) AS `total_revenue` FROM `SaleItem`) t
GROUP BY s.`ClientId`, `ClientName`, t.`total_revenue`
ORDER BY `revenue` DESC
LIMIT 10;
SELECT   s.`ClientId`,   CONCAT(c.`FirstName`, ' ', c.`LastName`) AS `ClientName`,   SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,   ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total` FROM `SaleItem` si JOIN `Sale` s    ON s.`SaleId`    = si.`SaleId` JOIN `Client` c  ON c.`ClientId`  = s.`ClientId` JOIN (SELECT SUM(`Quantity` * `ItemPrice`) AS `total_revenue` FROM `SaleItem`) t GROUP BY s.`ClientId`, `ClientName`, t.`total_revenue` ORDER BY `revenue` DESC LIMIT 10;
-- Largest collections
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection`
FROM `CollectionItem` ci
JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId`
GROUP BY ci.`CollectionId`, c.`Name`
ORDER BY `items_per_collection` DESC
LIMIT 10;
SELECT ci.`CollectionId`, c.`Name` AS `CollectionName`, COUNT(*) AS `items_per_collection` FROM `CollectionItem` ci JOIN `Collection` c ON c.`CollectionId` = ci.`CollectionId` GROUP BY ci.`CollectionId`, c.`Name` ORDER BY `items_per_collection` DESC LIMIT 10;
-- Recordings appearing in the most collections
SELECT `RecordingId`, COUNT(*) AS `collections_per_recording`
FROM `CollectionItem`
GROUP BY `RecordingId`
ORDER BY `collections_per_recording` DESC
LIMIT 10;
SELECT `RecordingId`, COUNT(*) AS `collections_per_recording` FROM `CollectionItem` GROUP BY `RecordingId` ORDER BY `collections_per_recording` DESC LIMIT 10;
-- Sales by year-month (units and revenue)
SELECT
  DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,
  COUNT(DISTINCT s.`SaleId`) AS `sales`,
  SUM(si.`Quantity`) AS `units`,
  ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue`
FROM `Sale` s
JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId`
GROUP BY `year_month`
ORDER BY `year_month`;
SELECT   DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,   COUNT(DISTINCT s.`SaleId`) AS `sales`,   SUM(si.`Quantity`) AS `units`,   ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue` FROM `Sale` s JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId` GROUP BY `year_month` ORDER BY `year_month`;
-- Top months by revenue
SELECT
  DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,
  ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue`
FROM `Sale` s
JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId`
GROUP BY `year_month`
ORDER BY `revenue` DESC
LIMIT 10;
SELECT   DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,   ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue` FROM `Sale` s JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId` GROUP BY `year_month` ORDER BY `revenue` DESC LIMIT 10;
-- Sales by year-month (units and revenue)
SELECT
  DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,
  COUNT(DISTINCT s.`SaleId`) AS `sales`,
  SUM(si.`Quantity`) AS `units`,
  ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue`
FROM `Sale` s
JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId`
GROUP BY `year_month`
ORDER BY `year_month`;
SELECT   DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,   COUNT(DISTINCT s.`SaleId`) AS `sales`,   SUM(si.`Quantity`) AS `units`,   ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue` FROM `Sale` s JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId` GROUP BY `year_month` ORDER BY `year_month`;
-- Top months by revenue
SELECT
  DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,
  ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue`
FROM `Sale` s
JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId`
GROUP BY `year_month`
ORDER BY `revenue` DESC
LIMIT 10;
SELECT   DATE_FORMAT(s.`InvoiceDate`, '%Y-%m') AS `year_month`,   ROUND(SUM(si.`Quantity` * si.`ItemPrice`), 2) AS `revenue` FROM `Sale` s JOIN `SaleItem` si ON si.`SaleId` = s.`SaleId` GROUP BY `year_month` ORDER BY `revenue` DESC LIMIT 10;
SELECT `RecordingId`, `Name`, `DurationMs`
FROM `Recording`
ORDER BY `DurationMs` DESC
LIMIT 10;
SELECT `RecordingId`, `Name`, `DurationMs` FROM `Recording` ORDER BY `DurationMs` DESC LIMIT 10;
SELECT `RecordingId`, `Name`, `SizeBytes`
FROM `Recording`
WHERE `SizeBytes` IS NOT NULL
ORDER BY `SizeBytes` DESC
LIMIT 10;
SELECT `RecordingId`, `Name`, `SizeBytes` FROM `Recording` WHERE `SizeBytes` IS NOT NULL ORDER BY `SizeBytes` DESC LIMIT 10;
SELECT `ManagerId`, COUNT(*) AS `direct_reports`
FROM `Staff`
WHERE `ManagerId` IS NOT NULL
GROUP BY `ManagerId`
ORDER BY `direct_reports` DESC
LIMIT 10;
SELECT `ManagerId`, COUNT(*) AS `direct_reports` FROM `Staff` WHERE `ManagerId` IS NOT NULL GROUP BY `ManagerId` ORDER BY `direct_reports` DESC LIMIT 10;
SELECT c.`ClientId`, c.`FirstName`, c.`LastName`
FROM `Client` c
LEFT JOIN `Sale` s ON s.`ClientId` = c.`ClientId`
WHERE s.`ClientId` IS NULL;
SELECT c.`ClientId`, c.`FirstName`, c.`LastName` FROM `Client` c LEFT JOIN `Sale` s ON s.`ClientId` = c.`ClientId` WHERE s.`ClientId` IS NULL;
SELECT
  r.`RecordingId`,
  r.`Name` AS `RecordingName`,
  SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,
  ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue`
FROM `SaleItem` si
JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId`
JOIN (SELECT SUM(si2.`Quantity` * si2.`ItemPrice`) AS `total_revenue` FROM `SaleItem` si2) t
GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue`
ORDER BY `revenue` DESC
LIMIT 10;
SELECT   r.`RecordingId`,   r.`Name` AS `RecordingName`,   SUM(si.`Quantity` * si.`ItemPrice`) AS `revenue`,   ROUND(100 * SUM(si.`Quantity` * si.`ItemPrice`) / t.`total_revenue`, 2) AS `pct_of_total_revenue` FROM `SaleItem` si JOIN `Recording` r ON r.`RecordingId` = si.`RecordingId` JOIN (SELECT SUM(si2.`Quantity` * si2.`ItemPrice`) AS `total_revenue` FROM `SaleItem` si2) t GROUP BY r.`RecordingId`, r.`Name`, t.`total_revenue` ORDER BY `revenue` DESC LIMIT 10;
sed "s/\134\134\134040/ /g" < ~/.mysql_history
;
exit;