SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Jason Snow <DTS>
-- Create Date: 03/18/2022
-- Description: (Wrapper) This function returns the mobile phone number for the selected person id
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[ufnCrm_GetPhoneNumber]
(
    @PersonId int
)
RETURNS varchar(1000)
AS
BEGIN
	RETURN (SELECT dbo.com_dtschurch_ufnCrm_GetPhoneNumber(@PersonId, 'Mobile'))
END
GO