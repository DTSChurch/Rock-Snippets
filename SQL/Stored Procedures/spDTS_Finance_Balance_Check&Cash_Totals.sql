CREATE PROCEDURE [dbo].[spDTS_Finance_Balance_Check&Cash_Totals]
	  @StartDate varchar(50) = null
	, @EndDate varchar(50) = null
	WITH RECOMPILE
AS

BEGIN
Declare @SD datetime,@ED datetime

if(@StartDate = 'startDate')
begin
set @SD = convert(date, DATEADD(month, DATEDIFF(month, 0,  GetDate()), 0)) 
END
ELSE
BEGIN
set @SD = convert(date, @StartDate)
END

if(@EndDate = 'endDate')
begin
set @ED = convert(date, GetDate()) 
END
ELSE
BEGIN
set @ED = convert(date, @EndDate)
END

if(@StartDate != 'startDate')
begin
	SELECT	[T].BatchName,
		SUM([T].Amount) AS Amount
	FROM (
		SELECT-- distinct
			--[p].LastName AS ContributorName,			
			--[p].[MaritalStatusValueId],
			[fb].Name AS BatchName,
			[fa].[ParentAccountId],			
			[fa].[Name] AS AccountName,			
			[ftd].[Amount]--,			
			--[fpd].[CurrencyTypeValueId]
		FROM [FinancialTransaction] [ft] WITH (NOLOCK)
		LEFT JOIN [FinancialBatch] [fb] WITH (NOLOCK) ON [fb].[Id] = [ft].[BatchId]
		INNER JOIN [FinancialTransactionDetail] [ftd] WITH (NOLOCK)	ON [ftd].[TransactionId] = [ft].[Id]
		INNER JOIN [FinancialPaymentDetail] [fpd] WITH (NOLOCK)	ON [fpd].Id = [ft].[FinancialPaymentDetailId]
		INNER JOIN [FinancialAccount] [fa] WITH (NOLOCK) ON [fa].[Id] = [ftd].[AccountId]
		--INNER JOIN [PersonAlias] [pa] WITH (NOLOCK)	ON [pa].[Id] = [ft].[AuthorizedPersonAliasId]
		--INNER JOIN [Person] [p] WITH (NOLOCK)	ON [p].[Id] = [pa].[PersonId]
		WHERE [ft].[TransactionDateTime] --BETWEEN @SD AND @ED+1
		>= @SD AND [ft].[TransactionDateTime] < @ED +1
		) AS [T]	
	GROUP BY [T].BatchName	

END

END
