SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Jason Snow <DTS>
-- Create Date: 03/18/2022
-- Description: This function returns the phone number of the type for the selected person id
-- PhoneType defaults to Mobile
-- =============================================
CREATE OR ALTER FUNCTION [dbo].[com_dtschurch_ufnCrm_GetPhoneNumber]
(
    @PersonId int, 
	@PhoneType varchar(20) = 'Mobile'
)
RETURNS varchar(1000)
AS
BEGIN
	RETURN (
		SELECT TOP 1 pn.NumberFormatted as [Phone]
		FROM PhoneNumber pn
		JOIN DefinedValue dv ON 
			dv.Id = pn.NumberTypeValueId
			AND dv.[Value] = @PhoneType
		WHERE pn.PersonId = @PersonId
	)
END
GO