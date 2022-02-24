SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Jason Snow <DTS>
-- Create Date: 02/24/2022
-- Description: This function returns the most likely spouse for the person [Id] provided
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[com_dtschurch_ufnCrm_GetSpousePersonIdFromPersonId]
(
    @PersonId int,
	@PersonPrimaryFamilyId int,
	@PersonAgeClassification int,
	@PersonMaritalStatusValueId int,
	@PersonBirthDate date
)
RETURNS int
AS
BEGIN
    RETURN (
		CASE
            WHEN @PersonAgeClassification = 1 AND @PersonMaritalStatusValueId = 143 THEN 
            (
                SELECT TOP 1
                    sp.Id
                FROM Person sp
                WHERE
                    sp.PrimaryFamilyId = @PersonPrimaryFamilyId -- Be in the same family
                    AND sp.Id != @PersonId -- Not the current person
                    AND sp.MaritalStatusValueId = 143 -- Must be married
                    AND sp.AgeClassification = 1 -- Must be an adult
				ORDER BY
					ABS(DATEDIFF(day, ISNULL(@PersonBirthDate, '1/1/0001'), ISNULL(sp.[BirthDate], '1/1/0001'))),
					sp.[Id]
            )
            ELSE NULL
        END
	)
END
GO

