-- =============================================
-- Author:      DTS - Michael Roth
-- Create date: 2018-08-11
-- Description: Will show all pledges base on setting in the block settings.  Can filter by date and or accounts.
-- =============================================
CREATE PROCEDURE [dbo].spDTS_Finance_PleadgeReport
(	@AccountList varchar(50) = NULL --List of accounts to include
	,@StartDate varchar(50) = NULL --Start date of the financial tranactions to include
	,@EndDate varchar(50) = NULL --End date of the financial transactions to include
	,@WithGifts varchar(10) = NULL --The variable to show if all pleadges should be shown or only those with gifts.
) WITH RECOMPILE
AS
BEGIN
DECLARE @ED datetime, @SD datetime
If (@WithGifts = 'true') BEGIN SET @WithGifts = 1 END
If (@WithGifts = 'WithGifts') BEGIN SET @WithGifts = 0 END
--SELECT @AccountList, @StartDate,@SD, @EndDate,@ED, @WithGifts
IF(@StartDate = 'startDate') begin set @SD = convert(date,GetDate()) END
	ELSE BEGIN set @SD = convert(date, @StartDate) END
IF(@EndDate = 'endDate') begin set @ED = convert(date, GetDate()) END
	ELSE BEGIN set @ED = convert(date, @EndDate) END



-- Tables for Query
SET NOCOUNT ON -- Added to prevent extra result sets from interfering with SELECT statements.
DECLARE @Pledges TABLE (AccountId INT, TotalAmount Decimal(18,2), PledgeFrequency NVARCHAR(50), StartDate DateTime, EndDate DateTime, PersonId INT)
DECLARE @Gifts TABLE (AccountId INT, TotalGiven Decimal(18,2), GiftCount INT, PersonId INT)
Insert INTO @Pledges 
	SELECT DISTINCT [fp].[AccountId]
		,[fp].[TotalAmount]
		,[dv].[Value] AS [PledgeFrequency]
		,[fp].[StartDate]
		,[fp].[EndDate]
		,[pa].[PersonId]
		FROM [FinancialPledge] fp
			INNER JOIN DefinedValue dv ON fp.PledgeFrequencyValueId = dv.Id
			INNER JOIN PersonAlias pa ON pa.Id = [fp].[PersonAliasId]
		WHERE [fp].[AccountId] IN ( SELECT * FROM ufnUtility_CsvToTable( @AccountList ) )
		--OPTION (RECOMPILE)
--SELECT * FROM @Pledges

-- If Showing all Pledges WITH gifts
If (@WithGifts = 1 AND @StartDate != 'startDate') BEGIN
	SELECT T.PersonId
		,p.FirstName
		,p.LastName
		,p.Email
		,(SELECT dbo.ufnCrm_GetAddress (p.Id,'Home','Full') ) AS Address
		,(SELECT dbo.ufnCrm_GetPHoneNumber (p.Id) ) AS PhoneNumber	
		,T.Account
		,T.PledgeAmount
		,T.PledgeFrequency
		,T.StartDate
		,T.EndDate
		,CAST(T.TotalGiven AS DECIMAL(18,2) ) AS TotalGiven
		,T.GivenCount
		,CAST( (T.TotalGiven *100 / T.PledgeAmount) AS DECIMAL(18,2) ) AS PercentGiven
	FROM
		(SELECT pl.PersonId
		,fa.Name AS Account
		,CAST( pl.TotalAmount AS DECIMAL(18,2) ) AS PledgeAmount
		, pl.PledgeFrequency
		, pl.StartDate
		, pl.EndDate
		,SUM(ftd.Amount) AS TotalGiven
		,COUNT(ft.Id) AS GivenCount
			FROM @Pledges pl
				INNER JOIN [PersonAlias] pa ON pa.PersonId = pl.PersonId			
				INNER JOIN [Person] p ON p.Id = pl.PersonId
				INNER JOIN [FinancialTransaction] ft ON ft.AuthorizedPersonAliasId = pa.Id AND ([ft].[TransactionDateTime] >= @SD AND [ft].[TransactionDateTime] < @ED +1)
				INNER JOIN [FinancialTransactionDetail] ftd ON ftd.TransactionId = ft.Id AND ftd.AccountId = pl.AccountId
				INNER JOIN [FinancialAccount] fa ON fa.Id = ftd.AccountId
			GROUP BY pl.PersonId,pl.AccountId,pl.TotalAmount, pl.PledgeFrequency, pl.StartDate, pl.EndDate,fa.Name
		) AS T
	INNER JOIN [Person] p ON p.Id = T.PersonId
	ORDER BY p.LastName ASC
END

--If showing all pledges with and without gifts
If (@WithGifts = 0 AND @StartDate != 'startDate' ) BEGIN
	SELECT T.PersonId
		,p.FirstName
		,p.LastName
		,p.Email
		,(SELECT dbo.ufnCrm_GetAddress (p.Id,'Home','Full') ) AS Address
		,(SELECT dbo.ufnCrm_GetPHoneNumber (p.Id) ) AS PhoneNumber	
		,T.Account
		,T.PledgeAmount
		,T.PledgeFrequency
		,T.StartDate
		,T.EndDate
		,CAST(T.TotalGiven AS DECIMAL(18,2) ) AS TotalGiven
		,T.GivenCount
		,CAST( (T.TotalGiven *100 / T.PledgeAmount) AS DECIMAL(18,2) ) AS PercentGiven
	FROM
		(SELECT pl.PersonId
		,fa.Name AS Account
		,CAST( pl.TotalAmount AS DECIMAL(18,2) ) AS PledgeAmount
		, pl.PledgeFrequency
		, pl.StartDate
		, pl.EndDate
		,SUM(ftd.Amount) AS TotalGiven
		,COUNT(ft.Id) AS GivenCount
			FROM @Pledges pl
				INNER JOIN [PersonAlias] pa ON pa.PersonId = pl.PersonId			
				INNER JOIN [Person] p ON p.Id = pl.PersonId
				INNER JOIN [FinancialTransaction] ft ON ft.AuthorizedPersonAliasId = pa.Id AND ([ft].[TransactionDateTime] >= @SD AND [ft].[TransactionDateTime] < @ED +1)
				INNER JOIN [FinancialTransactionDetail] ftd ON ftd.TransactionId = ft.Id AND ftd.AccountId = pl.AccountId
				INNER JOIN [FinancialAccount] fa ON fa.Id = ftd.AccountId
			GROUP BY pl.PersonId,pl.AccountId,pl.TotalAmount, pl.PledgeFrequency, pl.StartDate, pl.EndDate,fa.Name
		) AS T
	INNER JOIN [Person] p ON p.Id = T.PersonId
	ORDER BY p.LastName ASC
	End 

END
	

