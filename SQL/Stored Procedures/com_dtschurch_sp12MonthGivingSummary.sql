SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Jason Snow <DTS>
-- Create Date: 02/23/2022
-- Description: Obtains a table of giving history for past 12 months
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[_com_dtschurch_sp12MonthGivingSummary]
(
    @StartDate DATETIME,
    @Accounts NVARCHAR(max)
)
AS
BEGIN
    DECLARE @Today DATETIME;
    SET @Today = ISNULL(@StartDate, GETDATE());

    DECLARE @OneYearAgo DATETIME;
    SET @OneYearAgo = DATEADD(Year, -1, @Today);

    WITH MonthTableCTE(MONTH_INDEX, [MONTH], [YEAR]) AS
    (
        SELECT
            0 AS MONTH_INDEX,
            MONTH(@Today) AS [MONTH],
            YEAR(@Today) AS [YEAR]
        UNION ALL
        SELECT
            MONTH_INDEX + 1 AS MONTH_INDEX,
            MONTH(DATEADD(month, -(MONTH_INDEX + 1), @Today)) AS [MONTH],
            YEAR(DATEADD(month, -(MONTH_INDEX + 1), @Today)) AS [YEAR]
        FROM MonthTableCTE
        WHERE MONTH_INDEX < 12
    )

    SELECT
        CASE 
            WHEN p.RecordTypeValueId = 1 THEN p.NickName + ' ' + p.LastName 
            ELSE p.LastName 
        END AS [Person/Business],
        (
        CASE
            WHEN p.AgeClassification = 1 AND p.MaritalStatusValueId = 143 THEN 
            (
                SELECT TOP 1
                    sp.NickName + ' ' + sp.LastName
                FROM Person sp
                WHERE
                    sp.PrimaryFamilyId = p.PrimaryFamilyId -- Be in the same family
                    AND sp.Id != p.Id -- Not the current person
                    AND sp.MaritalStatusValueId = 143 -- Must be married
                    AND sp.AgeClassification = 1 -- Must be an adult
            )
            ELSE NULL
        END
        ) AS [Spouse],
        p.Email,
        dbo.ufnCrm_GetPhoneNumber(p.Id) AS [PhoneNumber],
        gift_agg.*
    FROM (
    SELECT
        gift.PersonId,
        SUM(CASE
            WHEN gift.[TransactionMonth] = 0 THEN gift.Amount
            ELSE 0
        END) AS [Month1],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 1 THEN gift.Amount
            ELSE 0
        END) AS [Month2],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 2 THEN gift.Amount
            ELSE 0
        END) AS [Month3],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 3 THEN gift.Amount
            ELSE 0
        END) AS [Month4],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 4 THEN gift.Amount
            ELSE 0
        END) AS [Month5],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 5 THEN gift.Amount
            ELSE 0
        END) AS [Month6],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 6 THEN gift.Amount
            ELSE 0
        END) AS [Month7],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 7 THEN gift.Amount
            ELSE 0
        END) AS [Month8],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 8 THEN gift.Amount
            ELSE 0
        END) AS [Month9],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 9 THEN gift.Amount
            ELSE 0
        END) AS [Month10],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 10 THEN gift.Amount
            ELSE 0
        END) AS [Month11],
        SUM(CASE
            WHEN gift.[TransactionMonth] = 11 THEN gift.Amount
            ELSE 0
        END) AS [Month12],
        SUM(CASE 
            WHEN gift.[TransactionMonth] >= 0 THEN gift.Amount
            ELSE 0
        END) AS [TotalAmount]
    FROM (
        SELECT
            pa.PersonId AS [PersonId],
            (
                SELECT TOP 1
                    mt.MONTH_INDEX
                FROM MonthTableCTE mt
                WHERE
                    mt.[YEAR] = asd.CalendarYear
                    AND mt.[MONTH] = asd.CalendarMonth
            ) AS [TransactionMonth],
            SUM(td.Amount) AS [Amount]
            FROM FinancialTransaction [asft]
            JOIN FinancialTransactionDetail [td] ON 
                td.TransactionId = asft.Id
                AND td.Amount IS NOT NULL
            JOIN FinancialAccount [fa] ON 
                td.AccountId = fa.Id
            JOIN PersonAlias pa ON
                pa.Id = asft.AuthorizedPersonAliasId
            JOIN AnalyticsSourceDate asd ON
                asd.DateKey = asft.TransactionDateKey
            WHERE
                asft.TransactionDateTime >= DATEADD(DAY, 1, EOMONTH(@OneYearAgo,-0))
                AND asft.TransactionDateTime < DATEADD(DAY, 1, @Today)
                AND (
                    @Accounts IS NOT NULL
                    AND @Accounts != ''
                    AND fa.Guid IN (SELECT value FROM STRING_SPLIT(@Accounts, ',', 0))
                )
                OR (
                    (@Accounts IS NULL or @Accounts = '')
                    AND fa.Guid IS NOT NULL
                )
            GROUP BY
                pa.PersonId,
                asd.CalendarMonth,
                asd.CalendarYear
    ) gift
    GROUP BY
        gift.PersonId
) gift_agg
JOIN Person p ON 
    p.Id = gift_agg.PersonId
WHERE
	gift_agg.[TotalAmount] > 0
END
