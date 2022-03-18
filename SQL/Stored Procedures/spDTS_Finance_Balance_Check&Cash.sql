CREATE OR ALTER PROCEDURE [dbo].[spDTS_Finance_Balance_Check&Cash]
	  @StartDate varchar(50) = null
	, @EndDate varchar(50) = null
	WITH RECOMPILE
AS

BEGIN
Declare @SD datetime,@ED datetime

if(@StartDate = 'startDate')
begin
set @SD = convert(dateTime, DATEADD(month, DATEDIFF(month, 0,  GetDate()), 0)) 
END
ELSE
BEGIN
set @SD = convert(dateTime, @StartDate)
END

if(@EndDate = 'endDate')
begin
set @ED = convert(dateTime, GetDate()) 
END
ELSE
BEGIN
set @ED = convert(dateTime, @EndDate)
END

if(@StartDate != 'startDate')
begin
	SELECT [T].Id,[T].ContributorName,
		(CASE
			WHEN [T].[MaritalStatusValueId] IS NULL
				THEN 'Divorced'			
			ELSE (SELECT Value FROM DefinedValue WHERE Id = [T].[MaritalStatusValueId])
			END) AS MaritalStatus,		
		BatchName,
		(CASE
			WHEN [T].[ParentAccountId] IS NULL
				THEN AccountName			
			ELSE (SELECT Name FROM FinancialAccount WHERE Id = [T].[ParentAccountId])
			END) AS Fund,
		(CASE
			WHEN [T].[ParentAccountId] IS NULL
				THEN NULL			
			ELSE AccountName
			END) AS SubFund,
		(SELECT Value FROM DefinedValue WHERE Id = [T].[CurrencyTypeValueId]) AS FormOfPayment,
		[T].TransactionDateTime AS Date,
		[T].Amount,
		[T].TransId
	FROM (
		SELECT --distinct
			dbo.ufnCrm_GetFullName([p].Id) AS ContributorName,
			[p].Id,
			[ft].TransactionDateTime,
			[p].[MaritalStatusValueId],
			[fb].Name AS BatchName,
			[fa].[ParentAccountId],			
			[fa].[Name] AS AccountName,			
			[ftd].[Amount],			
			[fpd].[CurrencyTypeValueId],
			[ft].Id as TransId
		FROM [FinancialTransaction] [ft] WITH (NOLOCK)
		LEFT JOIN [FinancialBatch] [fb] WITH (NOLOCK)
			ON [fb].[Id] = [ft].[BatchId]
		INNER JOIN [FinancialTransactionDetail] [ftd] WITH (NOLOCK)
			ON [ftd].[TransactionId] = [ft].[Id]
		INNER JOIN [FinancialPaymentDetail] [fpd] WITH (NOLOCK)
			ON [fpd].Id = [ft].[FinancialPaymentDetailId]
		INNER JOIN [FinancialAccount] [fa] WITH (NOLOCK)
			ON [fa].[Id] = [ftd].[AccountId]
		INNER JOIN [PersonAlias] [pa] WITH (NOLOCK)
			ON [pa].[Id] = [ft].[AuthorizedPersonAliasId]
		INNER JOIN [Person] [p] WITH (NOLOCK)
			ON [p].[Id] = [pa].[PersonId]
		WHERE [ft].[TransactionDateTime] --BETWEEN @SD AND @ED+1
		>= @SD AND [ft].[TransactionDateTime] < @ED +1
		) AS [T]	
	--ORDER BY [T].[TransactionDateTime] 

END

END
