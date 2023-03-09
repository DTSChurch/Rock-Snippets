{% comment %}
This SQL is designed to be placed in a Dynamic Data Block with  Page Filter Block setup to configure it.

Filters and Keys Needed are on the Page Filter Block:

Pledge Amount (PledgeAmount) = Decimal Range
% Complete (Complete) = Integer Range
Amount Given (AmountGiven) = Decimal Range
Show (Show) Single-Select with the following value^text:

  1^Only those with pledges,
  2^Only those with gifts,
  3^Those with gifts or pledges,
  4^Gifts with no pledges

{% endcomment %}

{% assign ShowType = PageParameter.Show | Default:'3' %}

{% if PageParameter.PledgeAmount != null and PageParameter.PledgeAmount != empty %} 
    {% assign PledgeAmount = PageParameter.PledgeAmount | Default:'' | Split:',' %}
    {% assign PledgeAmountSize = PledgeAmount | Size %}
    {% assign MinPledgeAmount = null %}
    {% assign MaxPledgeAmount = null %}
    {% if PledgeAmountSize > 0 %}
        {% assign MinPledgeAmount = PledgeAmount | First | Default:'0.0' | AsDecimal %}
        {% if MinPledgeAmount < 0 %}
            {% assign MinPledgeAmount = 0.0 %}
        {% endif %}
        
        {% assign MaxPledgeAmount = PledgeAmount | Last | Default:'0.0' | AsDecimal %}
        {% if MaxPledgeAmount < 0 %}
            {% assign MaxPledgeAmount = 0.0 %}
        {% endif %}
    {% endif %}
{% endif %}

{% if PageParameter.Complete != null and PageParameter.Complete != empty %}
    {% assign Complete = PageParameter.Complete | Default:'' | Split:',' %}
    {% assign CompleteSize = Complete | Size %}
    {% assign MinComplete = null %}
    {% assign MaxComplete = null %}
    {% if CompleteSize > 0 %}
        {% assign MinComplete = Complete | First | Default:'0.0' | AsDecimal %}
        {% if MinComplete < 0 %}
            {% assign MinComplete = 0.0 %}
        {% endif %}
        
        {% assign MaxComplete = Complete | Last | Default:'0.0' | AsDecimal %}
        {% if MaxComplete < 0 %}
            {% assign MaxComplete = 0.0 %}
        {% endif %}
    {% endif %}
{% endif %}

{% if PageParameter.AmountGiven != null and PageParameter.AmountGiven != empty %}
    {% assign AmountGiven = PageParameter.AmountGiven | Default:'' | Split:',' %}
    {% assign AmountGivenSize = AmountGiven | Size %}
    {% assign MinAmountGiven = null %}
    {% assign MaxAmountGiven = null %}
    {% if AmountGivenSize > 0 %}
        {% assign MinAmountGiven = AmountGiven | First | Default:'0.0' | AsDecimal %}
        {% if MinAmountGiven < 0 %}
            {% assign MinAmountGiven = 0.0 %}
        {% endif %}
        
        {% assign MaxAmountGiven = AmountGiven | Last | Default:'0.0' | AsDecimal %}
        {% if MaxAmountGiven < 0 %}
            {% assign MaxAmountGiven = 0.0 %}
        {% endif %}
    {% endif %}
{% endif %}

BEGIN
	DECLARE @PledgeAccountId int = 46;
	{% case ShowType %}
	{% when '1' %}
	    DECLARE @PledgeIncludePledges bit = 1
	    DECLARE @PledgeIncludeGifts bit = 0
	{% when '2' %}
	    DECLARE @PledgeIncludePledges bit = 0
	    DECLARE @PledgeIncludeGifts bit = 1
	{% when '3' %}
	    DECLARE @PledgeIncludePledges bit = 1
	    DECLARE @PledgeIncludeGifts bit = 1
	{% when '4' %}
	    DECLARE @PledgeIncludePledges bit = 0
	    DECLARE @PledgeIncludeGifts bit = 1
	{% endcase %}
	
	IF OBJECT_ID(N'tempdb..#TempPledgeAnalytics') IS NOT NULL
	BEGIN
		DROP TABLE #TempPledgeAnalytics
	END
	
	CREATE TABLE #TempPledgeAnalytics
	(
		Id int,
		Guid uniqueidentifier,
		NickName nvarchar(50),
		LastName nvarchar(50),
		PersonName nvarchar(101),
		Email nvarchar(75),
		GivingId nvarchar(50),
		GivingLeaderId int,
		PledgeAmount decimal(38,2),
		PledgeCount int,
		GiftAmount decimal(38,2),
		GiftCount int,
		PercentComplete decimal(9,2)
	)
	
	INSERT INTO #TempPledgeAnalytics
	EXEC [dbo].[spFinance_PledgeAnalyticsQuery] @AccountId = @PledgeAccountId, @IncludePledges = @PledgeIncludePledges, @IncludeGifts = @PledgeIncludeGifts{% if MinPledgeAmount != null and MinPledgeAmount != empty %}, @MinAmountPledged = {{ MinPledgeAmount }}{% endif %}{% if MaxPledgeAmount != null and MaxPledgeAmount != empty %}, @MaxAmountPledged = {{ MaxPledgeAmount }}{% endif %}{% if MinComplete != null and MinComplete != empty %}, @MinComplete = {{ MinComplete }}{% endif %}{% if MaxComplete != null and MaxComplete != empty %}, @MaxComplete = {{ MaxComplete }}{% endif %}{% if MinAmountGiven != null and MinAmountGiven != empty %}, @MinAmountGiven = {{ MinAmountGiven }}{% endif %}{% if MaxAmountGiven != null and MaxAmountGiven != empty %}, @MaxAmountGiven = {{ MaxAmountGiven }}{% endif %}

	SELECT 
		tpa.GivingLeaderId AS PersonId,
		fa.PublicName AS AccountName,
		p.NickName AS FirstName,
		p.LastName AS LastName,
		(
			CASE
				WHEN p.AgeClassification = 1 AND p.MaritalStatusValueId = 143 THEN
					(
					SELECT TOP 1
						sp.NickName
					FROM Person sp
					WHERE
			            sp.PrimaryFamilyId = p.PrimaryFamilyId -- Be in the same family
			            AND sp.Id != p.Id -- Not the current person
			            AND sp.MaritalStatusValueId = 143 -- Must be married
			            AND sp.AgeClassification = 1 -- Must be an adult
					ORDER BY
						ABS(DATEDIFF(day, ISNULL(p.BirthDate, '1/1/0001'), ISNULL(sp.[BirthDate], '1/1/0001'))),
						sp.[Id]
					)
				ELSE NULL
			END
		) AS SpouseName,
		tpa.PledgeCount,
		fp.StartDate,
		fp.EndDate,
		(
			SELECT
				dv.Value
			FROM DefinedValue dv
			WHERE dv.Id = (
				SELECT TOP 1
					lfp.PledgeFrequencyValueId
				FROM FinancialPledge lfp 
				WHERE lfp.Id = fp.LatestPledgeId
			)
		) AS PaymentSchedule,
		FORMAT(tpa.PledgeAmount, 'C0') AS PledgeAmount,
		tpa.GiftCount,
		FORMAT(tpa.GiftAmount, 'C0') AS GiftAmount,
		'<div class="progress"><div class="progress-bar" role="progressbar" aria-valuenow="' + CAST(tpa.PercentComplete * 100 AS VARCHAR) + '" aria-valuemin="0" aria-valuemax="100" style="width:' + CAST(tpa.PercentComplete * 100 AS VARCHAR) + '%">' + CAST(tpa.PercentComplete * 100 AS VARCHAR) + '%</div></div>' AS PercentComplete,
		tpa.PercentComplete * 100 AS PercentCompleteValue
	FROM #TempPledgeAnalytics tpa
	JOIN FinancialAccount fa ON fa.Id = @PledgeAccountId
	JOIN Person p ON p.Id = tpa.GivingLeaderId
	CROSS APPLY (
		SELECT 
			MIN(ifp.StartDate) AS StartDate, 
			MAX(ifp.EndDate) AS EndDate, 
			COUNT(DISTINCT ifp.Id) AS FamilyPledgeCount,
			MAX(ifp.Id) AS LatestPledgeId
		FROM FinancialPledge ifp
		WHERE 
			ifp.AccountId = @PledgeAccountId
			AND ifp.PersonAliasId IN (
			SELECT
				ipa.Id
			FROM PersonAlias ipa
			WHERE ipa.PersonId IN (
				SELECT
					ip.Id
				FROM Person ip
				WHERE ip.GivingId = tpa.GivingId
			)
		)
	) fp
	{% if ShowType == '4' %}WHERE tpa.PledgeCount <= 0{% endif %}
END
