SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Jason Snow <DTS>
-- Create Date: 03/18/2022
-- Description: (Wrapper) This function returns the full name of the selected person id
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[ufnCrm_GetFullName]
(
    @PersonId int
)
RETURNS varchar(1000)
AS
BEGIN
	RETURN (SELECT dbo.com_dtschurch_ufnCrm_GetFullName(@PersonId))		
END
GO