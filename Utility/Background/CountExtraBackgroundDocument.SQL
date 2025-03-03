DECLARE @bgFileTypeId INT = (SELECT Id from BinaryFileType WHERE Guid = '5C701472-8A6B-4BBE-AEC6-EC833C859F2D');  -- Find the File Type Id
DECLARE @bgFileAttribute INT = (SELECT Id FROM Attribute WHERE GUID = 'F3931952-460D-43E0-A6E0-EB6B5B1F9167'); -- Find the Attribute for the document linkage to a person
DECLARE @bgIdTable TABLE (Id INT); -- Make a temp table so we can loop through these records
DECLARE @bgAttributeValue TABLE (Guid uniqueidentifier); -- Store all the AttributeValues

-- Insert AttributeValues into @bgAttributeValue table
INSERT INTO @bgAttributeValue
	SELECT DISTINCT TRY_CAST(av.Value AS uniqueidentifier)
		FROM AttributeValue av
		WHERE av.AttributeId = @bgFileAttribute AND av.Value <> '';

-- Insert Ids into @bgIdTable
INSERT INTO @bgIdTable
	SELECT 
		CASE WHEN bc.ResponseDocumentId IS NULL AND bav.GUID IS NULL THEN bf.Id END AS BothMissing
		FROM BinaryFile bf
		LEFT JOIN @bgAttributeValue bav ON bf.Guid = bav.Guid
		LEFT JOIN BackgroundCheck bc ON bf.Id = bc.ResponseDocumentId AND bc.ResponseDocumentId <> ''
		WHERE bf.BinaryFileTypeId = @bgFileTypeId
		  AND (bav.Guid IS NULL OR bc.ResponseDocumentId IS NULL);

SELECT COUNT(bg.Id) TCOUNT
  FROM @bgIdTable bg
	
/*
--Optional SELECT Query you wont to see the files and path for validations.
SELECT bf.* 
    FROM @bgIdTable bg
    INNER JOIN BinaryFile bf ON bf.Id = bg.Id
*/