--IF @StartDate != 'null'
--BEGIN
--Variables
DECLARE @dtStartDate AS DateTime =  '2019-11-14'
DECLARE @dtEndDate AS DateTime = '2019-11-25'
DECLARE @Month1 AS INT = MONTH(DATEADD(MONTH, -1, @dtStartDate) )
DECLARE @Month2 AS INT = MONTH(DATEADD(MONTH, -2, @dtStartDate) )
DECLARE @Month3 AS INT = MONTH(DATEADD(MONTH, -3, @dtStartDate) )
DECLARE @Year AS INT = YEAR(@dtStartDate)
DECLARE @dAmount As DECIMAL(10,2) = 1
DECLARE @dPercent As DECIMAL(5,2) = 120
DECLARE @Accounts varchar(1000) = '13544'--'68,71,359,358,218,70,356,354,211,216,335,74,76,69,220,225,75,360,357,222'
DECLARE @RecentGiver AS Bit =  1

--Tables
DECLARE @RecentGifts TABLE (GiverId INT, TransactionId INT,TransactionDateTime DATETIME, GiftMonth INT, Amount DECIMAL(10,2))
DECLARE @DateRangeGifts TABLE (GiverId INT,GiftMonth INT, Amount DECIMAL(10,2),LastGiftAmount DECIMAL(10,2), LastGiftDate DATETIME)
DECLARE @PastGifts TABLE (GiverId INT,GiftMonth INT, Amount DECIMAL(10,2))

--Gifts Larger then the amount and in the date range to look at.
INSERT INTO @RecentGifts
        SELECT PA.PersonId AS GiverId,FT.Id AS TransactionId,FT.TransactionDateTime,MONTH(FT.TransactionDateTime) AS GiftMonth,SUM(FTD.Amount) AS Amount
            FROM FinancialTransaction AS FT
            INNER JOIN FinancialTransactionDetail AS FTD ON FTD.TransactionId = FT.Id AND FTD.Amount <> 0
            INNER JOIN FinancialAccount AS FA ON FA.Id = FTD.AccountId AND FTD.AccountId IN ( SELECT * FROM ufnUtility_CsvToTable(@Accounts) )
            INNER JOIN PersonAlias AS PA ON PA.Id = FT.AuthorizedPersonAliasId --AND PA.PersonId = 376
            WHERE FT.TransactionDateTime BETWEEN DATEADD(month, DATEDIFF(month, 0, @dtStartDate),0) AND @dtEndDate +1
            GROUP BY PA.PersonId, PA.Guid,FT.TransactionDateTime,FT.Id
            HAVING SUM(FTD.Amount) >= @dAmount        
    OPTION (RECOMPILE)
SELECT * FROM @RecentGifts

--The past 3 months of transactions and will sum by the month
INSERT INTO @PastGifts
    SELECT PA.PersonId AS GiverId,MONTH(FT.TransactionDateTime) AS GiftMonth, SUM(FTD.Amount) AS Amount
        FROM FinancialTransaction AS FT
        INNER JOIN FinancialTransactionDetail AS FTD ON FTD.TransactionId = FT.Id 
        INNER JOIN FinancialAccount AS FA ON FA.Id = FTD.AccountId AND FTD.AccountId IN ( SELECT * FROM ufnUtility_CsvToTable(@Accounts) )
        INNER JOIN PersonAlias AS PA ON PA.Id = FT.AuthorizedPersonAliasId
        WHERE FT.TransactionDateTime BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, @dtStartDate)-3, 0) AND DATEADD(MONTH, DATEDIFF(MONTH, -1, @dtStartDate)-1, -1)
            AND FTD.Amount > 0
            AND PA.PersonId IN (SELECT Distinct GiverId FROM @RecentGifts)
            GROUP BY PA.PersonId,MONTH(FT.TransactionDateTime)
    OPTION (RECOMPILE)
--SELECT * FROM @RecentGifts
--SELECT * FROM @PastGifts


--Pivot to show the 3 months on 1 row and to calc the average.  Will restrict based on the percent to average    
SELECT P.NickName, P.LastName
    --,p.Email
    --,(SELECT dbo.ufnCrm_GetPhoneNumber(GiverId)) AS Phone
    --,(SELECT [NickName] FROM [Person] WHERE [Id] = [T].[SpouseId]) AS [SpouseNickName]
    --,(SELECT p2.Email FROM Person p2 WHERE p2.Id = [T].[SpouseId]) AS SpouseEmail
    --,(SELECT dbo.ufnCrm_GetPhoneNumber([T].[SpouseId])) AS SpousePhone
    ,[T].GiverId,[3MonthsAgo],[2MonthsAgo],[1MonthsAgo]
    ,CONVERT(DECIMAL(10,2),AverageGift) AS AverageGift
    ,(SELECT SUM(RG.Amount) FROM @RecentGifts RG WHERE T.GiverId = RG.GiverId) AS FocusMonth
    ,CONVERT(DECIMAL(10,2),(FocusMonth/ AverageGift)*100) AS 'Percent'
    ,(SELECT SUM(RG.Amount) FROM @RecentGifts RG WHERE T.GiverId = RG.GiverId AND RG.TransactionDateTime BETWEEN @dtStartDate AND @dtEndDate +1) AS DateRangeAmount
    ,(SELECT RG.TransactionDateTime FROM @RecentGifts RG WHERE T.LastGiftId = RG.TransactionId) AS LastGiftDate
    ,(SELECT RG.Amount FROM @RecentGifts RG WHERE T.LastGiftId = RG.TransactionId) AS LastGiftAmount
    ,@RecentGiver AS RecentGiver
    FROM (
    SELECT PG.GiverId
        ,(SELECT dbo.ufnCrm_GetSpousePersonIdFromPersonId (PG.GiverId)) AS [SpouseId]
        ,(SELECT PG3.Amount FROM @PastGifts PG3 WHERE PG3.GiverId = PG.GiverId AND PG3.GiftMonth = @Month3) AS [3MonthsAgo] 
        ,(SELECT PG2.Amount FROM @PastGifts PG2 WHERE PG2.GiverId = PG.GiverId AND PG2.GiftMonth = @Month2) AS [2MonthsAgo]
        ,(SELECT PG1.Amount FROM @PastGifts PG1 WHERE PG1.GiverId = PG.GiverId AND PG1.GiftMonth = @Month1) AS [1MonthsAgo]
        ,AVG(PG.Amount) As AverageGift
        ,(SELECT SUM(RG.Amount) FROM @RecentGifts RG WHERE PG.GiverId = RG.GiverId) AS FocusMonth
        ,MAX(RG.TransactionId) AS LastGiftId
            FROM @PastGifts AS PG
            INNER JOIN @RecentGifts RG ON RG.GiverId = PG.GiverId
            GROUP BY PG.GiverId
    ) AS T
    INNER JOIN Person AS P ON P.Id = GiverId
    INNER JOIN @RecentGifts RG ON T.GiverId = RG.GiverId AND RG.TransactionDateTime BETWEEN @dtStartDate AND @dtEndDate +1
    GROUP BY P.NickName, P.LastName,p.Email,[T].GiverId,[T].[SpouseId],[3MonthsAgo],[2MonthsAgo],[1MonthsAgo]
    ,AverageGift,T.LastGiftId,T.FocusMonth
    HAVING (FocusMonth/ AverageGift)*100 >= @dPercent --AND @RecentGiver = 1

--END
