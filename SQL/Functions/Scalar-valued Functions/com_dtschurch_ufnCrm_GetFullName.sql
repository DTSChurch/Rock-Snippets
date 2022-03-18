SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Jason Snow <DTS>
-- Create Date: 03/18/2022
-- Description: This function returns the full name of the selected person id
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[com_dtschurch_ufnCrm_GetFullName]
(
    @PersonId int
)
RETURNS varchar(1000)
AS
BEGIN
	RETURN (
        SELECT 
			CASE 
				WHEN p.FirstName IS NULL THEN 
                    CASE
                        WHEN p.MiddleName IS NULL THEN p.LastName
						ELSE p.MiddleName + ' ' + p.LastName
                    END
				ELSE 
                    CASE
                        WHEN p.MiddleName IS NULL THEN p.FirstName + ' ' + p.LastName
                        ELSE p.FirstName + ' ' + p.MiddleName + ' ' + p.LastName
                    END
            END	AS [Name]
		FROM Person p
		WHERE p.Id = @PersonId
    )		
END
GO